import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../storage/secure_storage_service.dart';
import '../config/app_config.dart';

enum WsConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  disconnecting,
  error,
}

/// Socket.IO service client that handles connection lifecycle, handshakes, and event streams.
class WebSocketService with WidgetsBindingObserver {
  final String wsBaseUrl;
  final SecureStorageService _secureStorage;
  IO.Socket? _socket;

  // Stream controllers to publish telemetry
  final StreamController<Map<String, dynamic>> _telemetryController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _alertController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<WsConnectionState> _stateController =
      StreamController<WsConnectionState>.broadcast();
  final StreamController<Map<String, dynamic>> _deviceStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _caregiverRevokedController =
      StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _caregiverGrantedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _caregiverPermissionsUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _caregiverExtendedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _caregiverStatusUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _caregiverAccessAcceptedController =
      StreamController<Map<String, dynamic>>.broadcast();

  WsConnectionState _currentState = WsConnectionState.disconnected;
  String? _selectedBabyId;
  bool _isConnecting = false;
  bool _isRefreshing = false;
  VoidCallback? onSessionExpired;
  VoidCallback? onAppResumed;
  
  // Custom signaling event handlers registry
  final Map<String, List<Function(dynamic)>> _customHandlers = {};

  WebSocketService({
    required this.wsBaseUrl,
    required SecureStorageService secureStorage,
  }) : _secureStorage = secureStorage {
    WidgetsBinding.instance.addObserver(this);
  }

  // Getters
  Stream<Map<String, dynamic>> get telemetryStream =>
      _telemetryController.stream;
  Stream<Map<String, dynamic>> get alertStream => _alertController.stream;
  Stream<WsConnectionState> get stateStream => _stateController.stream;
  Stream<Map<String, dynamic>> get deviceStatusStream =>
      _deviceStatusController.stream;
  Stream<String> get caregiverRevokedStream =>
      _caregiverRevokedController.stream;
  Stream<Map<String, dynamic>> get caregiverGrantedStream =>
      _caregiverGrantedController.stream;
  Stream<Map<String, dynamic>> get caregiverPermissionsUpdatedStream =>
      _caregiverPermissionsUpdatedController.stream;
  Stream<Map<String, dynamic>> get caregiverExtendedStream =>
      _caregiverExtendedController.stream;
  Stream<Map<String, dynamic>> get caregiverStatusUpdateStream =>
      _caregiverStatusUpdateController.stream;
  Stream<Map<String, dynamic>> get caregiverAccessAcceptedStream =>
      _caregiverAccessAcceptedController.stream;
  WsConnectionState get currentState => _currentState;
  String? get selectedBabyId => _selectedBabyId;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[Socket.IO] $message');
    }
  }

  void _updateState(WsConnectionState state) {
    _currentState = state;
    _stateController.add(state);
  }

  Future<String?> _getValidTokenOrRefresh(String targetUrl) async {
    final token = await _secureStorage.getAccessToken();
    if (token == null) {
      _log('Access token missing');
      return null;
    }

    final parts = token.split('.');
    if (parts.length != 3) {
      _log('Invalid access token format');
      return null;
    }

    bool isExpired = false;
    try {
      var normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final payloadString = utf8.decode(base64.decode(normalized));
      final decoded = jsonDecode(payloadString);
      if (decoded is Map && decoded['exp'] != null) {
        final expSecs = decoded['exp'] as int;
        final expDateTime = DateTime.fromMillisecondsSinceEpoch(expSecs * 1000, isUtc: true);
        final nowUtc = DateTime.now().toUtc();
        
        debugPrint('[Auth] Access token expires at $expDateTime');
        if (nowUtc.isAfter(expDateTime.subtract(const Duration(seconds: 90)))) {
          debugPrint('[Auth] Token expired or near expiration (90s buffer)');
          isExpired = true;
        }
      }
    } catch (e) {
      debugPrint('[Auth] Error parsing access token expiration: $e');
      isExpired = true;
    }

    if (!isExpired) {
      return token;
    }

    return await _forceRefreshToken(targetUrl);
  }

  Future<String?> _forceRefreshToken(String targetUrl) async {
    if (_isRefreshing) {
      _log('Token refresh already in progress, returning stored token');
      return await _secureStorage.getAccessToken();
    }
    _isRefreshing = true;
    debugPrint('[Auth] Refreshing access token via /auth/refresh...');

    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw Exception('Refresh token missing');
      }

      final response = await http.post(
        Uri.parse('$targetUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      final resJson = jsonDecode(response.body);
      if (response.statusCode != 200 || resJson['success'] != true) {
        throw Exception(resJson['message'] ?? 'Refresh request failed with status ${response.statusCode}');
      }

      final newAccessToken = resJson['data']['accessToken'] as String;
      final userId = await _secureStorage.getUserId() ?? '';
      final userRole = await _secureStorage.getUserRole() ?? 'PARENT';

      await _secureStorage.saveSession(
        accessToken: newAccessToken,
        refreshToken: refreshToken,
        userId: userId,
        userRole: userRole,
      );

      debugPrint('[Auth] Token refresh successful. New token saved.');
      _isRefreshing = false;
      return newAccessToken;
    } catch (e) {
      debugPrint('[Auth] Token refresh failed: $e');
      _isRefreshing = false;
      return null;
    }
  }

  /// Establishes the Socket.IO connection with authentication token parameters.
  Future<void> connect({bool force = false}) async {
    if (force) {
      await disconnect();
    } else if (_currentState == WsConnectionState.connected || _isConnecting) {
      return;
    }

    _isConnecting = true;
    _updateState(WsConnectionState.connecting);

    final targetUrl = AppConfig.apiBaseUrl;

    final token = await _getValidTokenOrRefresh(targetUrl);
    if (token == null) {
      _isConnecting = false;
      _updateState(WsConnectionState.error);
      _log('Socket Error: Access token missing or refresh failed.');
      return;
    }

    // Printing required JWT details
    _log('JWT length: ${token.length}');
    _log('First 20 characters of the token: ${token.substring(0, token.length > 20 ? 20 : token.length)}');

    final parts = token.split('.');
    if (parts.length == 3) {
      try {
        var normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
        while (normalized.length % 4 != 0) {
          normalized += '=';
        }
        final payloadString = utf8.decode(base64.decode(normalized));
        final decoded = jsonDecode(payloadString);
        if (decoded is Map && decoded['exp'] != null) {
          final expTime = DateTime.fromMillisecondsSinceEpoch(decoded['exp'] * 1000, isUtc: true);
          _log('Token expiry: $expTime');
        }
      } catch (e) {
        _log('Token expiry: unknown (error decoding)');
      }
    } else {
      _log('Token expiry: unknown (invalid format)');
    }

    final authPayload = {'token': token};
    _log('Socket.IO auth payload: $authPayload');
    _log('Connecting to Socket.IO server at $targetUrl...');

    try {
      // Disconnect existing socket if any
      if (_socket != null) {
        _socket!.dispose();
        _socket = null;
      }

      String cleanUrl = targetUrl.trim();
      cleanUrl = cleanUrl.replaceAll(RegExp(r'/+$'), '');
      cleanUrl = cleanUrl.replaceAll(RegExp(r'/api$'), '');
      cleanUrl = cleanUrl.replaceAll(RegExp(r'/+$'), '');

      if (cleanUrl.startsWith('ws://')) {
        cleanUrl = cleanUrl.replaceFirst('ws://', 'http://');
      } else if (cleanUrl.startsWith('wss://')) {
        cleanUrl = cleanUrl.replaceFirst('wss://', 'https://');
      }

      _socket = IO.io(cleanUrl, IO.OptionBuilder()
          .setTransports(kIsWeb ? ['polling', 'websocket'] : ['websocket', 'polling'])
          .setAuth(authPayload)
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(99999)
          .build());


      // Connection event handlers
      _socket!.onConnect((_) {
        _isConnecting = false;
        _log('Socket Connected');
        _log('JWT Authentication Success');
        debugPrint('[Socket.IO] Authentication successful');
        _updateState(WsConnectionState.connected);

        // Join selected baby's room if one is set
        if (_selectedBabyId != null) {
          _log('Re-joining Baby Room: $_selectedBabyId');
          _socket!.emit('join:baby', _selectedBabyId);
        }
      });

      _socket!.onDisconnect((reason) {
        _isConnecting = false;
        _log('Socket Disconnected: $reason');
        _updateState(WsConnectionState.disconnected);
      });

      _socket!.onConnectError((err) async {
        _isConnecting = false;
        _log('Socket Error: $err');
        
        final errMsg = err.toString();
        if (errMsg.contains('Unauthorized') || errMsg.contains('Invalid token') || errMsg.contains('expired')) {
          _log('Socket connection rejected due to authentication error. Disposing socket...');
          await disconnect();

          final currentToken = await _secureStorage.getAccessToken();
          final refreshedToken = await _forceRefreshToken(targetUrl);
          if (refreshedToken != null && refreshedToken != currentToken) {
            debugPrint('[Socket.IO] Re-connecting with newly refreshed JWT token...');
            await connect(force: true);
          } else {
            debugPrint('[Socket.IO] Token refresh did not yield a new token. Stopping reconnect loop.');
            _updateState(WsConnectionState.error);
          }
        } else {
          _updateState(WsConnectionState.error);
        }
      });

      _socket!.onReconnectAttempt((attempt) {
        _log('Reconnect Attempt #$attempt');
        _updateState(WsConnectionState.reconnecting);
      });

      _socket!.onReconnectFailed((_) {
        _log('Reconnect Failure');
        _updateState(WsConnectionState.error);
      });

      // Telemetry, Device Status & Alert listeners
      _socket!.on('telemetry:update', (data) {
        if (data is Map) {
          _handleTelemetryUpdate(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('device:status', (data) {
        if (data is Map) {
          _deviceStatusController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('alert:new', (data) {
        _log('Alert Received');
        if (data is Map) {
          _alertController.add(Map<String, dynamic>.from(data));
        }
      });

      void handleRevoked(dynamic data) {
        _log('Caregiver Access Revoked event received: $data');
        final msg = (data is Map && data.containsKey('message'))
            ? data['message'] as String
            : 'Your caregiver monitoring access has been revoked by the parent.';
        _caregiverRevokedController.add(msg);
      }
      _socket!.on('caregiver:access_revoked', handleRevoked);
      _socket!.on('caregiver_access_revoked', handleRevoked);

      void handleExpired(dynamic data) {
        _log('Caregiver Access Expired event received: $data');
        final msg = (data is Map && data.containsKey('message'))
            ? data['message'] as String
            : 'Your caregiver access has expired.';
        _caregiverRevokedController.add(msg);
      }
      _socket!.on('caregiver:access_expired', handleExpired);
      _socket!.on('caregiver_access_expired', handleExpired);

      void handleGranted(dynamic data) {
        _log('Caregiver Access Granted event received: $data');
        if (data is Map) {
          _caregiverGrantedController.add(Map<String, dynamic>.from(data));
        }
      }
      _socket!.on('caregiver:access_granted', handleGranted);
      _socket!.on('caregiver_access_granted', handleGranted);

      void handleAccessAccepted(dynamic data) {
        _log('Caregiver access accepted event received: $data');
        if (data is Map) _caregiverAccessAcceptedController.add(Map<String, dynamic>.from(data));
      }
      _socket!.on('caregiver.access.accepted', handleAccessAccepted);
      _socket!.on('caregiver_access_accepted', handleAccessAccepted);
      _socket!.on('caregiver:access_accepted', handleAccessAccepted);

      void handlePermissionsUpdated(dynamic data) {
        _log('Caregiver Permissions Updated event received: $data');
        if (data is Map) {
          _caregiverPermissionsUpdatedController.add(Map<String, dynamic>.from(data));
        }
      }
      _socket!.on('caregiver:permissions_updated', handlePermissionsUpdated);
      _socket!.on('caregiver_permissions_updated', handlePermissionsUpdated);
      _socket!.on('caregiver.permission.updated', handlePermissionsUpdated);

      void handleExtended(dynamic data) {
        _log('Caregiver Access Extended event received: $data');
        if (data is Map) {
          _caregiverExtendedController.add(Map<String, dynamic>.from(data));
        }
      }
      _socket!.on('caregiver:access_extended', handleExtended);
      _socket!.on('caregiver_access_extended', handleExtended);
      _socket!.on('caregiver.access.extended', handleExtended);

      void handleStatusUpdate(dynamic data) {
        _log('Caregiver Status Update event received: $data');
        if (data is Map) {
          _caregiverStatusUpdateController.add(Map<String, dynamic>.from(data));
        }
      }
      _socket!.on('caregiver:status_update', handleStatusUpdate);
      _socket!.on('caregiver_status_update', handleStatusUpdate);

      _socket!.on('join:error', (data) {
        _log('Socket Error: Room join failure: $data');
      });

      // Re-register any custom signaling handlers on the new socket instance
      _customHandlers.forEach((event, callbacks) {
        _log('Re-registering event handler for: $event');
        for (final cb in callbacks) {
          _socket!.on(event, cb);
        }
      });

      _socket!.connect();
    } catch (e) {
      _isConnecting = false;
      _log('Socket Error during initialization: $e');
      _updateState(WsConnectionState.error);
      rethrow;
    }
  }

  /// Sets the selected baby and handles room joining/leaving
  void setSelectedBaby(String? babyId) {
    if (_selectedBabyId == babyId && _socket != null && _socket!.connected) return;

    final oldBabyId = _selectedBabyId;
    _selectedBabyId = babyId;

    if (_socket != null && _socket!.connected) {
      if (oldBabyId != null && oldBabyId != babyId) {
        _log('Leaving Baby Room: $oldBabyId');
        _socket!.emit('leave:baby', oldBabyId);
      }
      if (babyId != null) {
        _log('Joined Baby Room: $babyId');
        _socket!.emit('join:baby', babyId);
      }
    }
  }

  /// Disconnects cleanly.
  Future<void> disconnect() async {
    _log('Disconnecting socket...');
    _updateState(WsConnectionState.disconnecting);
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnecting = false;
    _updateState(WsConnectionState.disconnected);
  }

  void _handleTelemetryUpdate(Map<String, dynamic> data) {
    final rawTelemetry = data['telemetry'];
    final telemetry = rawTelemetry is Map ? Map<String, dynamic>.from(rawTelemetry) : null;
    if (telemetry == null) return;

    final deviceId = telemetry['deviceId'] as String? ?? '';
    final timestamp = telemetry['timestamp'] as String? ?? DateTime.now().toIso8601String();
    final battery = telemetry['batteryLevel'] as int?;

    void emitSensor(String sensorType, dynamic value, String unit) {
      if (value != null) {
        _telemetryController.add({
          'deviceId': deviceId,
          'sensorId': sensorType,
          'type': sensorType,
          'value': value,
          'unit': unit,
          'timestamp': timestamp,
          'quality': 'good',
          'status': 'online',
          'battery': battery,
          'cradleId': deviceId,
          'sequenceNumber': 0,
        });
      }
    }

    emitSensor('heart_rate', telemetry['heartRate'], 'bpm');
    emitSensor('breathing_rate', telemetry['respirationRate'], 'rpm');
    emitSensor('body_temperature', telemetry['bodyTemperature'], '°C');
    emitSensor('room_temperature', telemetry['roomTemperature'], '°C');
    emitSensor('humidity', telemetry['humidity'], '%');
    emitSensor('air_quality', telemetry['airQuality'], 'AQI');
    
    if (telemetry['sleepStage'] != null) {
      emitSensor('sleep_stage', 1.0, telemetry['sleepStage'] as String);
    }
    if (telemetry['cryDetected'] != null) {
      emitSensor('cry_detection', (telemetry['cryDetected'] as bool) ? 1.0 : 0.0, '');
    }
    if (telemetry['movementDetected'] != null) {
      emitSensor('movement_detection', (telemetry['movementDetected'] as bool) ? 1.0 : 0.0, '');
    }
    if (battery != null) {
      emitSensor('battery_level', battery.toDouble(), '%');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _log('App resumed: checking Socket.IO connection state...');
      if (_socket != null && !_socket!.connected) {
        _log('Socket not connected, forcing connection...');
        _socket!.connect();
      }
      onAppResumed?.call();
    }
  }

  /// Emits an event to the Socket.IO server.
  void emit(String event, [dynamic data]) {
    if (_socket != null) {
      _log('Emitting event: $event');
      _socket!.emit(event, data);
    } else {
      _log('Cannot emit event $event: Socket is null.');
    }
  }

  /// Registers a handler for a specific event from the Socket.IO server.
  void registerHandler(String event, Function(dynamic) callback) {
    _log('Registering handler for event: $event');
    _customHandlers.putIfAbsent(event, () => []).add(callback);
    if (_socket != null) {
      _socket!.on(event, callback);
    }
  }

  /// Unregisters all handlers or a specific handler for a specific event.
  void unregisterHandler(String event, [Function(dynamic)? callback]) {
    _log('Unregistering handler for event: $event');
    if (callback == null) {
      _customHandlers.remove(event);
      if (_socket != null) {
        _socket!.off(event);
      }
    } else {
      final list = _customHandlers[event];
      if (list != null) {
        list.remove(callback);
        if (list.isEmpty) {
          _customHandlers.remove(event);
        }
      }
      if (_socket != null) {
        _socket!.off(event);
        if (_customHandlers.containsKey(event)) {
          for (final cb in _customHandlers[event]!) {
            _socket!.on(event, cb);
          }
        }
      }
    }
  }

  /// Clean resources.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disconnect();
    _customHandlers.clear();
    _telemetryController.close();
    _alertController.close();
    _stateController.close();
    _deviceStatusController.close();
    _caregiverAccessAcceptedController.close();
  }
}
