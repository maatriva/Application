import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'secure_storage_service.dart';

enum WsConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  disconnecting,
  error,
}

/// WebSocket service client that handles connection lifecycle, handshakes, and event streams.
class WebSocketService {
  final String wsBaseUrl;
  final SecureStorageService _secureStorage;
  WebSocketChannel? _channel;

  // Stream controllers to publish telemetry
  final StreamController<Map<String, dynamic>> _telemetryController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _alertController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<WsConnectionState> _stateController =
      StreamController<WsConnectionState>.broadcast();

  WsConnectionState _currentState = WsConnectionState.disconnected;
  bool _shouldReconnect = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectDelaySeconds = 30;

  WebSocketService({
    required this.wsBaseUrl,
    required SecureStorageService secureStorage,
  }) : _secureStorage = secureStorage;

  // Getters
  Stream<Map<String, dynamic>> get telemetryStream =>
      _telemetryController.stream;
  Stream<Map<String, dynamic>> get alertStream => _alertController.stream;
  Stream<WsConnectionState> get stateStream => _stateController.stream;
  WsConnectionState get currentState => _currentState;

  void _updateState(WsConnectionState state) {
    _currentState = state;
    _stateController.add(state);
  }

  /// Establishes the WebSocket connection with authentication token parameters.
  Future<void> connect() async {
    if (_currentState == WsConnectionState.connected ||
        _currentState == WsConnectionState.connecting) {
      return;
    }

    _shouldReconnect = true;
    _updateState(WsConnectionState.connecting);

    final token = await _secureStorage.getAccessToken();
    if (token == null) {
      _updateState(WsConnectionState.error);
      throw Exception('Cannot establish WebSocket: Access token missing.');
    }

    final connectionUri = Uri.parse('$wsBaseUrl/ws?token=$token');
    debugPrint('Connecting to WebSocket server at $connectionUri...');

    try {
      _channel = WebSocketChannel.connect(connectionUri);
      _updateState(WsConnectionState.connected);
      _reconnectAttempts = 0;

      // Start listening to the socket stream
      _channel!.stream.listen(
        (message) => _onMessageReceived(message as String),
        onDone: _onConnectionClosed,
        onError: _onConnectionError,
        cancelOnError: true,
      );
    } catch (e) {
      _onConnectionError(e);
    }
  }

  /// Disconnects cleanly.
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _updateState(WsConnectionState.disconnecting);
    await _channel?.sink.close();
    _updateState(WsConnectionState.disconnected);
  }

  void _onMessageReceived(String rawMessage) {
    try {
      final data = jsonDecode(rawMessage) as Map<String, dynamic>;
      final event = data['event'] as String?;

      if (event == 'telemetry') {
        _telemetryController.add(data['data'] as Map<String, dynamic>);
      } else if (event == 'alert') {
        _alertController.add(data['data'] as Map<String, dynamic>);
      }
    } catch (_) {
      // Decode fail
    }
  }

  void _onConnectionClosed() {
    debugPrint('WebSocket connection closed by remote endpoint.');
    _updateState(WsConnectionState.disconnected);
    if (_shouldReconnect) {
      _triggerReconnectFlow();
    }
  }

  void _onConnectionError(dynamic error) {
    debugPrint('WebSocket connection error encountered: $error');
    _updateState(WsConnectionState.error);
    if (_shouldReconnect) {
      _triggerReconnectFlow();
    }
  }

  /// Implements exponential backoff reconnect scheduling.
  void _triggerReconnectFlow() {
    _updateState(WsConnectionState.reconnecting);
    _reconnectAttempts++;

    // Calculate exponential delay: 2^attempts (clamped at 30s)
    final delaySeconds = min(
      pow(2, _reconnectAttempts).toInt(),
      _maxReconnectDelaySeconds,
    );
    debugPrint(
      'Scheduling WebSocket reconnection retry in $delaySeconds seconds (Attempt #$_reconnectAttempts)...',
    );

    Timer(Duration(seconds: delaySeconds), () async {
      if (_shouldReconnect) {
        try {
          await connect();
        } catch (_) {
          // Retry will occur automatically via onConnectionError/onConnectionClosed hooks
        }
      }
    });
  }

  /// Clean resources.
  void dispose() {
    disconnect();
    _telemetryController.close();
    _alertController.close();
    _stateController.close();
  }
}
