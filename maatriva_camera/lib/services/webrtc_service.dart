import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'socket_service.dart';

class WebrtcService {
  final SocketService _socketService;
  
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  bool _isRendererInitialized = false;

  // Active peer connections map: viewerSocketId -> RTCPeerConnection
  final Map<String, RTCPeerConnection> _peerConnections = {};
  
  final ValueNotifier<bool> isStreamingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> activeCameraNotifier = ValueNotifier<String>('Rear');
  final ValueNotifier<int> viewerCountNotifier = ValueNotifier<int>(0);

  bool _isFrontCamera = false;
  String? _currentBabyId;

  WebrtcService(this._socketService) {
    // Bind signaling events to WebRTC handlers
    _socketService.onViewerJoined = _handleViewerJoined;
    _socketService.onViewerLeft = _handleViewerLeft;
    _socketService.onAnswerReceived = _handleAnswerReceived;
    _socketService.onIceCandidateReceived = _handleIceCandidateReceived;
  }

  bool get isStreaming => isStreamingNotifier.value;

  /// Initializes the local renderer.
  Future<void> initialize() async {
    if (!_isRendererInitialized) {
      await localRenderer.initialize();
      _isRendererInitialized = true;
      debugPrint('[WebRTC] Video renderer initialized successfully');
    }
  }

  /// Starts local media capture (720p, 30 FPS).
  Future<void> startLocalStream() async {
    await initialize();
    if (_localStream != null) return;

    final mediaConstraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '1280', // 720p resolution
          'minHeight': '720',
          'minFrameRate': '30',
        },
        'facingMode': _isFrontCamera ? 'user' : 'environment',
        'optional': [],
      }
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      localRenderer.srcObject = _localStream;
      debugPrint('[WebRTC] Local video/audio stream captured');
    } catch (e) {
      debugPrint('[WebRTC] Error acquiring local media stream: $e');
      rethrow;
    }
  }

  /// Switches camera between Front and Rear facing modules.
  Future<void> toggleCamera() async {
    if (_localStream == null) return;
    
    try {
      _isFrontCamera = !_isFrontCamera;
      activeCameraNotifier.value = _isFrontCamera ? 'Front' : 'Rear';

      final videoTrack = _localStream!.getVideoTracks().first;
      await Helper.switchCamera(videoTrack);
      debugPrint('[WebRTC] Camera switched successfully to ${activeCameraNotifier.value}');
    } catch (e) {
      debugPrint('[WebRTC] Error switching camera tracks: $e');
      // Revert state
      _isFrontCamera = !_isFrontCamera;
      activeCameraNotifier.value = _isFrontCamera ? 'Front' : 'Rear';
      rethrow;
    }
  }

  /// Puts the app in Streaming Mode: captures camera and accepts incoming peer connections.
  Future<void> startStreaming(String babyId) async {
    if (isStreaming) return;
    _currentBabyId = babyId;
    
    try {
      await startLocalStream();
      isStreamingNotifier.value = true;
      debugPrint('[WebRTC] Streaming mode enabled for baby room: $babyId');
    } catch (e) {
      isStreamingNotifier.value = false;
      _currentBabyId = null;
      rethrow;
    }
  }

  /// Exits Streaming Mode: closes all viewer connections and stops camera tracks.
  Future<void> stopStreaming() async {
    if (!isStreaming) return;
    debugPrint('[WebRTC] Stopping live stream publisher...');
    
    await _clearAllConnections();
    
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await track.stop();
      }
      _localStream = null;
    }
    localRenderer.srcObject = null;
    
    isStreamingNotifier.value = false;
    _currentBabyId = null;
    viewerCountNotifier.value = 0;
  }

  /// Callback: A viewer joined the signaling room. Camera creates a peer connection,
  /// adds its local tracks, and emits an offer.
  Future<void> _handleViewerJoined(String viewerSocketId) async {
    if (!isStreaming || _localStream == null || _currentBabyId == null) return;
    
    debugPrint('[WebRTC] Creating PeerConnection');

    try {
      final pc = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ]
      });

      _peerConnections[viewerSocketId] = pc;
      viewerCountNotifier.value = _peerConnections.length;

      debugPrint('[WebRTC] Adding local tracks');
      _localStream!.getTracks().forEach((track) {
        pc.addTrack(track, _localStream!);
      });

      pc.onIceCandidate = (candidate) {
        debugPrint('[WebRTC] ICE Candidate Generated');
        _socketService.emit('ice-candidate', {
          'babyId': _currentBabyId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
          'targetSocketId': viewerSocketId,
        });
        debugPrint('[Socket.IO] Sending ICE Candidate');
      };

      pc.onConnectionState = (state) {
        debugPrint('[WebRTC] Connection state changed for viewer $viewerSocketId: $state');
      };

      debugPrint('[WebRTC] Creating Offer');
      final offer = await pc.createOffer({
        'mandatory': {
          'OfferToReceiveAudio': false,
          'OfferToReceiveVideo': false,
        },
        'optional': [],
      });
      debugPrint('[WebRTC] Offer Created');

      await pc.setLocalDescription(offer);
      debugPrint('[WebRTC] Local Description Set');

      _socketService.emit('offer', {
        'babyId': _currentBabyId,
        'sdp': {
          'sdp': offer.sdp,
          'type': offer.type,
        },
        'targetSocketId': viewerSocketId,
      });
      debugPrint('[Socket.IO] Sending Offer');

    } catch (e) {
      debugPrint('[WebRTC] Failed to initialize peer connection for viewer $viewerSocketId: $e');
      _peerConnections.remove(viewerSocketId);
      viewerCountNotifier.value = _peerConnections.length;
    }
  }

  /// Callback: A viewer left the room or disconnected. Closes and cleans up their connection.
  Future<void> _handleViewerLeft(String viewerSocketId) async {
    debugPrint('[WebRTC] Client disconnected: $viewerSocketId. Disposing connection.');
    final pc = _peerConnections.remove(viewerSocketId);
    if (pc != null) {
      await pc.close();
      viewerCountNotifier.value = _peerConnections.length;
    }
  }

  /// Callback: A viewer sent back their SDP Answer. Sets the remote description.
  Future<void> _handleAnswerReceived(String senderSocketId, dynamic sdp) async {
    debugPrint('[Socket.IO] Answer Received');
    final pc = _peerConnections[senderSocketId];
    if (pc != null) {
      try {
        debugPrint('[WebRTC] Remote Description Set');
        await pc.setRemoteDescription(RTCSessionDescription(sdp['sdp'], sdp['type']));
      } catch (e) {
        debugPrint('[WebRTC] Error setting remote description: $e');
      }
    }
  }

  /// Callback: A viewer sent their ICE Candidate. Adds it to their connection.
  Future<void> _handleIceCandidateReceived(String senderSocketId, dynamic candidate) async {
    final pc = _peerConnections[senderSocketId];
    if (pc != null && candidate != null) {
      try {
        await pc.addCandidate(RTCIceCandidate(
          candidate['candidate'],
          candidate['sdpMid'],
          candidate['sdpMLineIndex'],
        ));
      } catch (e) {
        debugPrint('[WebRTC] Error adding ICE candidate: $e');
      }
    }
  }

  /// Helper to close and clear all connections
  Future<void> _clearAllConnections() async {
    for (var pc in _peerConnections.values) {
      await pc.close();
    }
    _peerConnections.clear();
    viewerCountNotifier.value = 0;
  }

  /// Disposes of all tracks, streams, and renderer instances
  void dispose() {
    stopStreaming().then((_) {
      if (_isRendererInitialized) {
        localRenderer.dispose();
      }
    });
  }
}
