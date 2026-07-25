import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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

  WsConnectionState _currentState = WsConnectionState.disconnected;
  String? _selectedBabyId;
  bool _isConnecting = false;

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

  /// Establishes the Socket.IO connection with authentication token parameters.
  Future<void> connect() async {
    if (_currentState == WsConnectionState.connected || _isConnecting) {
      return;
    }

    _isConnecting = true;
    _updateState(WsConnectionState.connecting);

    final token = await _secureStorage.getAccessToken();
    if (token == null) {
      _isConnecting = false;
      _updateState(WsConnectionState.error);
      _log('Socket Error: Access token missing.');
      throw Exception('Cannot establish Socket.IO connection: Access token missing.');
    }

    // Determine target URL for Socket.IO
    // We use the HTTP API Base URL directly because socket_io_client will perform the upgrade itself.
    final targetUrl = AppConfig.apiBaseUrl;
    _log('Connecting to Socket.IO server at $targetUrl...');

    try {
      // Disconnect existing socket if any
      if (_socket != null) {
        _socket!.dispose();
      }

      _socket = IO.io(targetUrl, IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
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

      _socket!.onConnectError((err) {
        _isConnecting = false;
        _log('Socket Error: $err');
        _updateState(WsConnectionState.error);
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
        if (data is Map<String, dynamic>) {
          _handleTelemetryUpdate(data);
        }
      });

      _socket!.on('device:status', (data) {
        _log('Device Status Updated');
        if (data is Map<String, dynamic>) {
          _deviceStatusController.add(data);
        }
      });

      _socket!.on('alert:new', (data) {
        _log('Alert Received');
        if (data is Map<String, dynamic>) {
          _alertController.add(data);
        }
      });

      _socket!.on('join:error', (data) {
        _log('Socket Error: Room join failure: $data');
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
    if (_selectedBabyId == babyId) return;

    final oldBabyId = _selectedBabyId;
    _selectedBabyId = babyId;

    if (_socket != null && _socket!.connected) {
      if (oldBabyId != null) {
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
    final telemetry = data['telemetry'] as Map<String, dynamic>?;
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

  /// Clean resources.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disconnect();
    _telemetryController.close();
    _alertController.close();
    _stateController.close();
    _deviceStatusController.close();
  }
}
