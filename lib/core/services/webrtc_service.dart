import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'websocket_service.dart';

enum WebrtcStatus {
  disconnected,
  connecting,
  streaming,
  offline,
  error,
}

class WebrtcState {
  final WebrtcStatus status;
  final String? errorMessage;
  final bool isMuted;

  const WebrtcState({
    required this.status,
    this.errorMessage,
    this.isMuted = false,
  });

  factory WebrtcState.initial() => const WebrtcState(status: WebrtcStatus.disconnected);

  WebrtcState copyWith({
    WebrtcStatus? status,
    String? errorMessage,
    bool? isMuted,
  }) {
    return WebrtcState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

class WebrtcNotifier extends StateNotifier<WebrtcState> {
  final WebSocketService _wsService;
  
  final RTCVideoRenderer videoRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _remoteStream;
  String? _currentBabyId;
  bool _isRendererInitialized = false;

  Timer? _reconnectTimer;
  Timer? _offlinePollingTimer;
  StreamSubscription? _caregiverRevokedSub;

  StreamSubscription? _caregiverPermsSub;
  StreamSubscription? _wsStateSubscription;
  bool _isReconnecting = false;

  WebrtcNotifier(this._wsService) : super(WebrtcState.initial()) {
    _listenToSocketState();
    _listenToCaregiverEvents();
  }

  DateTime? _lastJoinEmitTime;

  void _listenToCaregiverEvents() {
    _caregiverRevokedSub = _wsService.caregiverRevokedStream.listen((_) {
      debugPrint('[WebRTC] Caregiver revoked/expired. Disconnecting WebRTC stream...');
      disconnectStream();
    });

    _caregiverPermsSub = _wsService.caregiverPermissionsUpdatedStream.listen((data) {
      if (data is Map && data['permissions'] is Map) {
        final perms = data['permissions'] as Map;
        final canViewCamera = perms['camera_snapshot'] == true || perms['canViewCamera'] == true;
        if (!canViewCamera) {
          debugPrint('[WebRTC] Camera permission disabled by parent. Disconnecting WebRTC stream...');
          disconnectStream();
        }
      }
    });
  }

  void _listenToSocketState() {

    WsConnectionState? lastState;
    _wsStateSubscription = _wsService.stateStream.listen((wsState) {
      if (lastState != WsConnectionState.connected && 
          wsState == WsConnectionState.connected && 
          _currentBabyId != null) {
        debugPrint('[WebRTC] WebSocket re-connected. Re-joining WebRTC room for baby: $_currentBabyId');
        _joinRoom(_currentBabyId!);
      }
      lastState = wsState;
    });
  }

  Future<void> initializeRenderer() async {
    if (!_isRendererInitialized) {
      await videoRenderer.initialize();
      _isRendererInitialized = true;
      debugPrint('[WebRTC] Video renderer initialized');
    }
  }

  Future<void> connectStream(String babyId, {bool forceReconnect = false}) async {
    if (!forceReconnect &&
        _currentBabyId == babyId && 
        state.status == WebrtcStatus.streaming) {
      return;
    }

    _currentBabyId = babyId;
    state = state.copyWith(status: WebrtcStatus.connecting, errorMessage: null);

    try {
      await initializeRenderer();

      // Register signaling callbacks
      _wsService.registerHandler('camera-status', _handleCameraStatus);
      _wsService.registerHandler('offer', _handleOffer);
      _wsService.registerHandler('ice-candidate', _handleIceCandidate);

      _joinRoom(babyId);
    } catch (e) {
      debugPrint('[WebRTC] Error connecting stream: $e');
      state = state.copyWith(status: WebrtcStatus.error, errorMessage: e.toString());
      _scheduleAutoReconnect();
    }
  }

  void _joinRoom(String babyId) {
    final now = DateTime.now();
    if (_lastJoinEmitTime != null && 
        now.difference(_lastJoinEmitTime!) < const Duration(seconds: 3)) {
      return;
    }
    _lastJoinEmitTime = now;

    debugPrint('[WebRTC] Joining room for baby: $babyId');
    _wsService.emit('join-room', {
      'babyId': babyId,
      'role': 'viewer',
    });
  }

  Future<void> reconnectStream({String? babyId}) async {
    final targetBabyId = babyId ?? _currentBabyId;
    if (targetBabyId == null) return;
    debugPrint('[WebRTC] Force reconnecting stream for baby: $targetBabyId');
    _stopOfflinePolling();
    _reconnectTimer?.cancel();
    _isReconnecting = false;
    await _cleanupPeerConnection();
    _currentBabyId = null;
    await connectStream(targetBabyId, forceReconnect: true);
  }

  Future<void> disconnectStream() async {
    if (_currentBabyId == null) return;

    debugPrint('[WebRTC] Disconnecting stream for baby: $_currentBabyId');

    _stopOfflinePolling();
    _reconnectTimer?.cancel();
    _isReconnecting = false;

    // Unregister handlers
    _wsService.unregisterHandler('camera-status');
    _wsService.unregisterHandler('offer');
    _wsService.unregisterHandler('ice-candidate');

    // Leave room
    _wsService.emit('leave-room', {
      'babyId': _currentBabyId,
    });

    await _cleanupPeerConnection();

    _currentBabyId = null;
    state = WebrtcState.initial();
  }

  Future<void> _cleanupPeerConnection() async {
    if (_peerConnection != null) {
      debugPrint('[WebRTC] Disposing peer connection');
      try {
        await _peerConnection!.close();
      } catch (e) {
        debugPrint('[WebRTC] Error closing peer connection: $e');
      }
      _peerConnection = null;
    }
    
    _remoteStream = null;
    videoRenderer.srcObject = null;
  }

  void _scheduleAutoReconnect() {
    if (_isReconnecting || _currentBabyId == null) return;
    _isReconnecting = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      _isReconnecting = false;
      if (_currentBabyId != null && state.status != WebrtcStatus.disconnected) {
        debugPrint('[WebRTC] Executing scheduled auto-reconnect for baby: $_currentBabyId');
        await reconnectStream();
      }
    });
  }

  void _startOfflinePolling() {
    if (_offlinePollingTimer != null && _offlinePollingTimer!.isActive) {
      return;
    }
    _offlinePollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_currentBabyId != null && 
          (state.status == WebrtcStatus.offline || 
           state.status == WebrtcStatus.error)) {
        debugPrint('[WebRTC] Offline polling: re-emitting join-room to check if camera came back online...');
        _joinRoom(_currentBabyId!);
      }
    });
  }

  void _stopOfflinePolling() {
    _offlinePollingTimer?.cancel();
    _offlinePollingTimer = null;
  }

  void _handleCameraStatus(dynamic data) {
    debugPrint('[WebRTC] camera-status event received: $data');
    if (data is Map) {
      final status = data['status'] as String?;
      if (status == 'offline') {
        debugPrint('[WebRTC] Camera is offline. Cleaning up peer connection...');
        _cleanupPeerConnection();
        state = state.copyWith(status: WebrtcStatus.offline, errorMessage: 'Cradle Camera is Offline');
        _startOfflinePolling();
      } else if (status == 'online') {
        debugPrint('[WebRTC] Camera came ONLINE! Re-joining WebRTC room...');
        _stopOfflinePolling();
        state = state.copyWith(status: WebrtcStatus.connecting, errorMessage: null);
        if (_currentBabyId != null) {
          _joinRoom(_currentBabyId!);
        }
      }
    }
  }

  Future<void> _handleOffer(dynamic data) async {
    debugPrint('[Socket.IO] Offer Received');
    if (data is! Map) return;

    final senderSocketId = data['senderSocketId'] as String?;
    final sdpMap = data['sdp'];
    if (senderSocketId == null || sdpMap == null) return;

    try {
      _stopOfflinePolling();
      await _cleanupPeerConnection();

      debugPrint('[WebRTC] Creating PeerConnection');
      final pc = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ]
      });
      _peerConnection = pc;

      pc.onIceCandidate = (candidate) {
        _wsService.emit('ice-candidate', {
          'babyId': _currentBabyId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
          'targetSocketId': senderSocketId,
        });
      };

      pc.onConnectionState = (connectionState) {
        debugPrint('[WebRTC] Peer Connection state changed: $connectionState');
        if (connectionState == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            connectionState == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          debugPrint('[WebRTC] Connection lost/failed. Scheduling auto-reconnect...');
          state = state.copyWith(status: WebrtcStatus.error, errorMessage: 'Connection lost. Reconnecting...');
          _scheduleAutoReconnect();
        }
      };

      pc.onIceConnectionState = (iceState) {
        debugPrint('[WebRTC] ICE Connection state changed: $iceState');
        if (iceState == RTCIceConnectionState.RTCIceConnectionStateFailed ||
            iceState == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
          debugPrint('[WebRTC] ICE Connection lost/failed. Scheduling auto-reconnect...');
          state = state.copyWith(status: WebrtcStatus.error, errorMessage: 'Stream connection dropped. Reconnecting...');
          _scheduleAutoReconnect();
        }
      };

      pc.onAddStream = (stream) {
        debugPrint('[WebRTC] Remote Stream Received');
        _remoteStream = stream;
        videoRenderer.srcObject = stream;
        debugPrint('[WebRTC] Remote Stream Attached');
        
        _applyMute(state.isMuted);
        state = state.copyWith(status: WebrtcStatus.streaming, errorMessage: null);
      };

      pc.onTrack = (event) {
        debugPrint('[WebRTC] Remote Track Received');
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          videoRenderer.srcObject = event.streams[0];
          debugPrint('[WebRTC] Remote Stream Attached');
          
          _applyMute(state.isMuted);
          state = state.copyWith(status: WebrtcStatus.streaming, errorMessage: null);
        }
      };

      // Handle the SDP
      await pc.setRemoteDescription(RTCSessionDescription(sdpMap['sdp'], sdpMap['type']));
      debugPrint('[WebRTC] Remote Description Set');

      debugPrint('[WebRTC] Creating Answer');
      final answer = await pc.createAnswer();
      
      await pc.setLocalDescription(answer);
      debugPrint('[WebRTC] Local Description Set');

      _wsService.emit('answer', {
        'babyId': _currentBabyId,
        'sdp': {
          'sdp': answer.sdp,
          'type': answer.type,
        },
        'targetSocketId': senderSocketId,
      });
      debugPrint('[Socket.IO] Sending Answer');
    } catch (e) {
      debugPrint('[WebRTC] Error handling offer: $e');
      state = state.copyWith(status: WebrtcStatus.error, errorMessage: 'Failed to negotiate stream connection.');
      _scheduleAutoReconnect();
    }
  }

  void _handleIceCandidate(dynamic data) async {
    debugPrint('[WebRTC] ICE Candidate Received');
    if (data is! Map) return;
    final candidateMap = data['candidate'];
    if (candidateMap == null || _peerConnection == null) return;

    try {
      await _peerConnection!.addCandidate(RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      ));
      debugPrint('[WebRTC] ICE Candidate Added');
    } catch (e) {
      debugPrint('[WebRTC] Error adding ICE candidate: $e');
    }
  }

  void toggleMute() {
    final nextMuted = !state.isMuted;
    _applyMute(nextMuted);
    state = state.copyWith(isMuted: nextMuted);
  }

  void _applyMute(bool mute) {
    if (_remoteStream != null) {
      _remoteStream!.getAudioTracks().forEach((track) {
        track.enabled = !mute;
      });
      debugPrint('[WebRTC] Audio tracks enabled: ${!mute}');
    }
  }

  @override
  void dispose() {
    _caregiverRevokedSub?.cancel();
    _caregiverPermsSub?.cancel();
    _wsStateSubscription?.cancel();

    _reconnectTimer?.cancel();
    _stopOfflinePolling();
    disconnectStream().then((_) {
      if (_isRendererInitialized) {
        videoRenderer.dispose();
      }
    });
    super.dispose();
  }
}
