import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;


enum SocketConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

class SocketService {
  IO.Socket? _socket;
  SocketConnectionState _state = SocketConnectionState.disconnected;
  
  final _storage = const FlutterSecureStorage();
  bool _isRefreshing = false;
  VoidCallback? onSessionExpired;
  
  final ValueNotifier<SocketConnectionState> connectionNotifier =
      ValueNotifier<SocketConnectionState>(SocketConnectionState.disconnected);

  // Event callbacks
  Function(String viewerSocketId)? onViewerJoined;
  Function(String viewerSocketId)? onViewerLeft;
  Function(String senderSocketId, dynamic sdp)? onAnswerReceived;
  Function(String senderSocketId, dynamic candidate)? onIceCandidateReceived;

  SocketConnectionState get state => _state;
  bool get isConnected => _state == SocketConnectionState.connected;

  void _updateState(SocketConnectionState newState) {
    _state = newState;
    connectionNotifier.value = newState;
    debugPrint('[SocketService] Connection state: $newState');
  }

  Future<String?> _getValidTokenOrRefresh(String url) async {
    final token = await _storage.read(key: 'camera_token');
    if (token == null) {
      debugPrint('[Auth] Access token missing');
      return null;
    }

    final parts = token.split('.');
    if (parts.length != 3) {
      debugPrint('[Auth] Invalid access token format');
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
      debugPrint('[Auth] Already refreshing token, waiting...');
      return null;
    }

    _isRefreshing = true;
    debugPrint('[Auth] Refreshing access token...');

    try {
      final refreshToken = await _storage.read(key: 'camera_refresh_token');
      if (refreshToken == null) {
        throw Exception('Refresh token missing');
      }

      final response = await http.post(
        Uri.parse('$url/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      final resJson = jsonDecode(response.body);
      if (response.statusCode != 200 || resJson['success'] != true) {
        throw Exception(resJson['message'] ?? 'Refresh request failed');
      }

      final newAccessToken = resJson['data']['accessToken'] as String;
      await _storage.write(key: 'camera_token', value: newAccessToken);
      
      debugPrint('[Auth] Refresh successful');
      _isRefreshing = false;
      return newAccessToken;
    } catch (e) {
      debugPrint('[Auth] Token refresh failed: $e');
      _isRefreshing = false;
      
      await _storage.delete(key: 'camera_token');
      await _storage.delete(key: 'camera_refresh_token');
      disconnect();
      
      if (onSessionExpired != null) {
        onSessionExpired!();
      }
      return null;
    }
  }

  /// Connects to the Socket.IO signaling server at the given URL with auth JWT token
  Future<bool> connect(String url, String babyId) async {
    disconnect();
    _updateState(SocketConnectionState.connecting);

    final token = await _getValidTokenOrRefresh(url);
    if (token == null) {
      _updateState(SocketConnectionState.error);
      return false;
    }

    // Printing required JWT details
    debugPrint('[Socket.IO] JWT length: ${token.length}');
    debugPrint('[Socket.IO] First 20 characters of the token: ${token.substring(0, token.length > 20 ? 20 : token.length)}');

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
          debugPrint('[Socket.IO] Token expiry: $expTime');
        }
      } catch (e) {
        debugPrint('[Socket.IO] Token expiry: unknown (error decoding)');
      }
    } else {
      debugPrint('[Socket.IO] Token expiry: unknown (invalid format)');
    }

    final authPayload = {'token': token};
    debugPrint('[Socket.IO] Socket.IO auth payload: $authPayload');

    try {
      _socket = IO.io(url, IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth(authPayload)
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build());

      _socket!.onConnect((_) {
        _updateState(SocketConnectionState.connected);
        debugPrint('[Socket.IO] Authentication successful');
        
        // Register this device as the baby cradle camera
        debugPrint('[SocketService] Connected. Registering as camera for baby: $babyId');
        _socket!.emit('join-room', {
          'babyId': babyId,
          'role': 'camera',
        });
      });

      _socket!.onDisconnect((reason) {
        _updateState(SocketConnectionState.disconnected);
        debugPrint('[SocketService] Disconnected: $reason');
      });

      _socket!.onConnectError((err) async {
        debugPrint('[SocketService] Connect Error: $err');
        
        final errMsg = err.toString();
        if (errMsg.contains('Unauthorized') || errMsg.contains('Invalid token')) {
          debugPrint('[Auth] Socket connection rejected due to invalid token. Refreshing...');
          final refreshedToken = await _getValidTokenOrRefresh(url);
          if (refreshedToken != null) {
            debugPrint('[Socket.IO] Connecting with refreshed JWT');
            connect(url, babyId);
          } else {
            _updateState(SocketConnectionState.error);
          }
        } else {
          _updateState(SocketConnectionState.error);
        }
      });

      // --- WebRTC Signaling Listeners ---
      _socket!.on('viewer-joined', (data) {
        debugPrint('[SocketService] Received viewer-joined event: $data');
        if (data is Map) {
          final viewerId = data['viewerSocketId'] as String?;
          if (viewerId != null && onViewerJoined != null) {
            onViewerJoined!(viewerId);
          }
        }
      });

      _socket!.on('viewer-left', (data) {
        debugPrint('[SocketService] Received viewer-left event: $data');
        if (data is Map) {
          final viewerId = data['viewerSocketId'] as String?;
          if (viewerId != null && onViewerLeft != null) {
            onViewerLeft!(viewerId);
          }
        }
      });

      _socket!.on('answer', (data) {
        debugPrint('[SocketService] Received SDP answer');
        if (data is Map) {
          final senderId = data['senderSocketId'] as String?;
          final sdp = data['sdp'];
          if (senderId != null && sdp != null && onAnswerReceived != null) {
            onAnswerReceived!(senderId, sdp);
          }
        }
      });

      _socket!.on('ice-candidate', (data) {
        debugPrint('[SocketService] Received remote ICE candidate');
        if (data is Map) {
          final senderId = data['senderSocketId'] as String?;
          final candidate = data['candidate'];
          if (senderId != null && candidate != null && onIceCandidateReceived != null) {
            onIceCandidateReceived!(senderId, candidate);
          }
        }
      });

      _socket!.connect();
      return true;
    } catch (e) {
      _updateState(SocketConnectionState.error);
      debugPrint('[SocketService] Connection setup failed: $e');
      return false;
    }
  }

  /// Helper to emit custom signaling events
  void emit(String event, dynamic data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(event, data);
    } else {
      debugPrint('[SocketService] Cannot emit $event: Socket is disconnected');
    }
  }

  /// Disconnects cleanly and releases socket resources
  void disconnect() {
    if (_socket != null) {
      debugPrint('[SocketService] Disconnecting signaling client...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _updateState(SocketConnectionState.disconnected);
  }
}
