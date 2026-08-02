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

  WsConnectionState _currentState = WsConnectionState.disconnected;
  String? _selectedBabyId;
  bool _isConnecting = false;
  bool _isRefreshing = false;
  VoidCallback? onSessionExpired;
  
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
      final payloadString = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(payloadString);
      if (decoded is Map && decoded['exp'] != null) {
        final expSecs = decoded['exp'] as int;
        final expDateTime = DateTime.fromMillisecondsSinceEpoch(expSecs * 1000, isUtc: true);
        final nowUtc = DateTime.now().toUtc();
        
        debugPrint('[Auth] Access token expires at $expDateTime');
        if (nowUtc.isAfter(expDateTime.subtract(const Duration(seconds: 10)))) {
          debugPrint('[Auth] Token expired');
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

    if (_isRefreshing) {
      _log('Already refreshing token, waiting...');
      return null;
    }

    _isRefreshing = true;
    debugPrint('[Auth] Refreshing access token...');

    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        throw Exception('Refresh token missing');
      }

      final response = await http.post(
        Uri.parse('$targetUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      final resJson = jsonDecode(response.body);
      if (response.statusCode != 200 || resJson['success'] != true) {
        throw Exception(resJson['message'] ?? 'Refresh request failed');
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
      
      debugPrint('[Auth] Refresh successful');
      _isRefreshing = false;
      return newAccessToken;
    } catch (e) {
      debugPrint('[Auth] Token refresh failed: $e');
      _isRefreshing = false;
      
      await _secureStorage.clearSession();
      await disconnect();
      
      if (onSessionExpired != null) {
        onSessionExpired!();
      }
      return null;
    }
  }

  /// Establishes the Socket.IO connection with authentication token parameters.
  Future<void> connect() async {
    if (_currentState == WsConnectionState.connected || _isConnecting) {
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
        final payloadString = utf8.decode(base64Url.decode(normalized));
        final decoded = jsonDecode(payloadString);
        if (decoded is Map && decoded['exp'] != null) {
          final expTime = DateTime.fromMillisecondsSinceEpoch(decoded['exp'] * 1000);
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
      }

      _socket = IO.io(targetUrl, IO.OptionBuilder()
          .setTransports(['websocket'])
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
        if (errMsg.contains('Unauthorized') || errMsg.contains('Invalid token')) {
          _log('Socket connection rejected due to invalid token. Refreshing...');
          final refreshedToken = await _getValidTokenOrRefresh(targetUrl);
          if (refreshedToken != null) {
            debugPrint('[Socket.IO] Connecting with refreshed JWT');
            connect();
          } else {
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
        _log('Telemetry Received');
        if (data is Map) {
          _handleTelemetryUpdate(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('device:status', (data) {
        _log('Device Status Updated');
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

      _socket!.on('caregiver:access_revoked', (data) {
        _log('Caregiver Access Revoked event received: $data');
        final msg = (data is Map && data.containsKey('message'))
            ? data['message'] as String
            : 'Your caregiver monitoring access has been revoked by the parent.';
        _caregiverRevokedController.add(msg);
      });

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
  }
}
