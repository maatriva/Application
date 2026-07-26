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

  WebrtcNotifier(this._wsService)
      : super(WebrtcState.initial());


  Future<void> initializeRenderer() async {
    if (!_isRendererInitialized) {
      await videoRenderer.initialize();
      _isRendererInitialized = true;
      debugPrint('[WebRTC] Video renderer initialized');
    }
  }

  Future<void> connectStream(String babyId) async {
    if (_currentBabyId == babyId && 
        state.status != WebrtcStatus.disconnected && 
        state.status != WebrtcStatus.error) {
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

      // Join WebRTC room
      debugPrint('[WebRTC] Joining room for baby: $babyId');
      _wsService.emit('join-room', {
        'babyId': babyId,
        'role': 'viewer',
      });
    } catch (e) {
      debugPrint('[WebRTC] Error connecting stream: $e');
      state = state.copyWith(status: WebrtcStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> disconnectStream() async {
    if (_currentBabyId == null) return;

    debugPrint('[WebRTC] Disconnecting stream for baby: $_currentBabyId');

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

  void _handleCameraStatus(dynamic data) {
    debugPrint('[WebRTC] camera-status event received: $data');
    if (data is Map) {
      final status = data['status'] as String?;
      if (status == 'offline') {
        _cleanupPeerConnection();
        state = state.copyWith(status: WebrtcStatus.offline);
      } else if (status == 'online') {
        if (state.status == WebrtcStatus.offline) {
          state = state.copyWith(status: WebrtcStatus.connecting);
        }
      }
    }
  }

  Future<void> _handleOffer(dynamic data) async {
    debugPrint('[WebRTC] offer event received');
    if (data is! Map) return;

    final senderSocketId = data['senderSocketId'] as String?;
    final sdpMap = data['sdp'];
    if (senderSocketId == null || sdpMap == null) return;

    try {
      await _cleanupPeerConnection();

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
        if (connectionState == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          state = state.copyWith(status: WebrtcStatus.error, errorMessage: 'WebRTC connection failed');
        }
      };

      pc.onAddStream = (stream) {
        debugPrint('[WebRTC] Remote stream added via onAddStream');
        _remoteStream = stream;
        videoRenderer.srcObject = stream;
        
        // Apply current mute preference to new stream tracks
        _applyMute(state.isMuted);
        
        state = state.copyWith(status: WebrtcStatus.streaming);
      };

      pc.onTrack = (event) {
        debugPrint('[WebRTC] Track event received via onTrack');
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          videoRenderer.srcObject = event.streams[0];
          
          // Apply current mute preference to new stream tracks
          _applyMute(state.isMuted);
          
          state = state.copyWith(status: WebrtcStatus.streaming);
        }
      };

      // Handle the SDP
      await pc.setRemoteDescription(RTCSessionDescription(sdpMap['sdp'], sdpMap['type']));
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);

      _wsService.emit('answer', {
        'babyId': _currentBabyId,
        'sdp': {
          'sdp': answer.sdp,
          'type': answer.type,
        },
        'targetSocketId': senderSocketId,
      });
    } catch (e) {
      debugPrint('[WebRTC] Error handling offer: $e');
      state = state.copyWith(status: WebrtcStatus.error, errorMessage: 'Failed to negotiate stream connection.');
    }
  }

  void _handleIceCandidate(dynamic data) async {
    if (data is! Map) return;
    final candidateMap = data['candidate'];
    if (candidateMap == null || _peerConnection == null) return;

    try {
      await _peerConnection!.addCandidate(RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      ));
      debugPrint('[WebRTC] Remote ICE candidate added successfully');
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
    disconnectStream().then((_) {
      if (_isRendererInitialized) {
        videoRenderer.dispose();
      }
    });
    super.dispose();
  }
}
