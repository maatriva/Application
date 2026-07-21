import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// Represents connection status for the MQTT client.
enum MqttServiceState {
  disconnected,
  connecting,
  connected,
  error
}

/// Structured wrapper for an incoming MQTT message.
class MqttMessagePacket {
  final String topic;
  final String payload;

  const MqttMessagePacket({required this.topic, required this.payload});
}

/// Abstract definition of the MQTT manager layer.
abstract class MqttService {
  /// Stream of connection status updates.
  Stream<MqttServiceState> get stateStream;

  /// Returns current connection state.
  MqttServiceState get currentState;

  /// Connects to the remote MQTT broker.
  Future<void> connect({
    required String host,
    required int port,
    required String clientId,
    String? username,
    String? password,
    bool useTls = true,
    String? clientCertificatePem, // Per-device X.509 client certificate contents
    String? privateKeyPem,         // Per-device private key contents
    String? lwtTopic,
    String? lwtMessage,
  });

  /// Disconnects from the MQTT broker.
  Future<void> disconnect();

  /// Subscribes to a topic.
  Stream<MqttMessagePacket> subscribe(String topic, {MqttQos qos = MqttQos.atMostOnce});

  /// Unsubscribes from a topic.
  void unsubscribe(String topic);

  /// Publishes a payload string to a topic.
  Future<void> publish(
    String topic,
    String payload, {
    MqttQos qos = MqttQos.atMostOnce,
    bool retain = false,
  });

  /// Returns size of local offline unsent messages queue.
  int get offlineQueueLength;
}

/// Production implementation of [MqttService] using `mqtt_client`.
class ProductionMqttService implements MqttService {
  MqttServerClient? _client;
  final StreamController<MqttServiceState> _stateController =
      StreamController<MqttServiceState>.broadcast();
  MqttServiceState _currentState = MqttServiceState.disconnected;

  // Stream controller for combining and routing incoming message updates
  final StreamController<MqttMessagePacket> _messageController =
      StreamController<MqttMessagePacket>.broadcast();

  // Internal memory queue for offline publish queuing
  final List<Map<String, dynamic>> _offlineQueue = [];

  ProductionMqttService();

  @override
  Stream<MqttServiceState> get stateStream => _stateController.stream;

  @override
  MqttServiceState get currentState => _currentState;

  @override
  int get offlineQueueLength => _offlineQueue.length;

  void _updateState(MqttServiceState state) {
    _currentState = state;
    _stateController.add(state);
  }

  @override
  Future<void> connect({
    required String host,
    required int port,
    required String clientId,
    String? username,
    String? password,
    bool useTls = true,
    String? clientCertificatePem,
    String? privateKeyPem,
    String? lwtTopic,
    String? lwtMessage,
  }) async {
    _updateState(MqttServiceState.connecting);
    
    _client = MqttServerClient.withPort(host, clientId, port);
    _client!.secure = useTls;
    _client!.keepAlivePeriod = 20;
    _client!.autoReconnect = true;

    // Callbacks
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    _client!.onAutoReconnected = _onAutoReconnected;
    _client!.pongCallback = _onPingResponse;

    // Configure security contexts for per-device certificate if supplied
    if (useTls && clientCertificatePem != null && privateKeyPem != null) {
      // Production configuration would assign client certificate bytes to SecurityContext.
      // E.g., SecurityContext.defaultContext.useCertificateChainBytes(...)
      // and SecurityContext.defaultContext.usePrivateKeyBytes(...)
    }

    // Connection configuration setup
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean();

    if (username != null && password != null) {
      _client!.connectionMessage = connMessage.authenticateAs(username, password);
    } else {
      _client!.connectionMessage = connMessage;
    }

    // Last Will and Testament configuration
    if (lwtTopic != null && lwtMessage != null) {
      connMessage.withWillTopic(lwtTopic)
          .withWillMessage(lwtMessage)
          .withWillQos(MqttQos.atLeastOnce)
          .withWillRetain();
    }

    try {
      await _client!.connect();
    } catch (e) {
      _updateState(MqttServiceState.error);
      disconnect();
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    _client?.disconnect();
    _client = null;
    _updateState(MqttServiceState.disconnected);
  }

  @override
  Stream<MqttMessagePacket> subscribe(String topic, {MqttQos qos = MqttQos.atMostOnce}) {
    if (_currentState != MqttServiceState.connected || _client == null) {
      throw Exception('MQTT Client is not connected. Subscription failed.');
    }

    _client!.subscribe(topic, qos);

    // Forward updates that match the subscribed topic
    return _messageController.stream.where((packet) {
      return _isTopicMatch(packet.topic, topic);
    });
  }

  @override
  void unsubscribe(String topic) {
    _client?.unsubscribe(topic);
  }

  @override
  Future<void> publish(
    String topic,
    String payload, {
    MqttQos qos = MqttQos.atMostOnce,
    bool retain = false,
  }) async {
    if (_currentState != MqttServiceState.connected || _client == null) {
      // Client offline: enqueue payload to offline storage list
      _offlineQueue.add({
        'topic': topic,
        'payload': payload,
        'qos': qos,
        'retain': retain,
      });
      return;
    }

    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client!.publishMessage(topic, qos, builder.payload!, retain: retain);
  }

  // Handle client updates stream
  void _setupIncomingUpdatesListener() {
    _client?.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final msg in messages) {
        final recMessage = msg.payload as MqttPublishMessage;
        final payloadStr =
            MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

        _messageController.add(MqttMessagePacket(
          topic: msg.topic,
          payload: payloadStr,
        ));
      }
    });
  }

  // Connection Callbacks
  void _onConnected() {
    _updateState(MqttServiceState.connected);
    _setupIncomingUpdatesListener();
    _drainOfflineQueue();
  }

  void _onDisconnected() {
    _updateState(MqttServiceState.disconnected);
  }

  void _onAutoReconnected() {
    _updateState(MqttServiceState.connected);
    _drainOfflineQueue();
  }

  void _onPingResponse() {
    // Heartbeat received
  }

  // Drain queued offline packets
  void _drainOfflineQueue() {
    if (_offlineQueue.isEmpty) return;

    final List<Map<String, dynamic>> items = List.from(_offlineQueue);
    _offlineQueue.clear();

    for (final item in items) {
      publish(
        item['topic'] as String,
        item['payload'] as String,
        qos: item['qos'] as MqttQos,
        retain: item['retain'] as bool,
      );
    }
  }

  // Helper matching wildcard topics
  bool _isTopicMatch(String actualTopic, String filterTopic) {
    if (actualTopic == filterTopic) return true;

    final actualParts = actualTopic.split('/');
    final filterParts = filterTopic.split('/');

    for (int i = 0; i < filterParts.length; i++) {
      if (filterParts[i] == '#') return true;
      if (i >= actualParts.length) return false;
      if (filterParts[i] == '+') continue;
      if (filterParts[i] != actualParts[i]) return false;
    }

    return actualParts.length == filterParts.length;
  }
}
