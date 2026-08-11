import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'voice_recorder_stub.dart';
export 'voice_recorder_stub.dart';

html.MediaRecorder? _mediaRecorder;
html.MediaStream? _audioStream;
final List<html.Blob> _audioChunks = [];

Future<bool> startVoiceRecording() async {
  try {
    _audioChunks.clear();
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      debugPrint('[VoiceRecorderWeb] mediaDevices not supported');
      return false;
    }
    _audioStream = await mediaDevices.getUserMedia({'audio': true});
    _mediaRecorder = html.MediaRecorder(_audioStream!);

    _mediaRecorder!.addEventListener('dataavailable', (event) {
      final blob = (event as dynamic).data as html.Blob?;
      if (blob != null) {
        _audioChunks.add(blob);
      }
    });

    _mediaRecorder!.start();
    debugPrint('[VoiceRecorderWeb] Recording started successfully');
    return true;
  } catch (e) {
    debugPrint('[VoiceRecorderWeb] Error starting recording: $e');
    return false;
  }
}

Future<VoiceRecorderResult?> stopVoiceRecording(int durationSecs) async {
  final completer = Completer<VoiceRecorderResult?>();
  try {
    if (_mediaRecorder == null || _mediaRecorder!.state == 'inactive') {
      _stopStreamTracks();
      return null;
    }

    _mediaRecorder!.addEventListener('stop', (event) {
      try {
        final blob = html.Blob(_audioChunks, 'audio/webm');
        final reader = html.FileReader();
        reader.readAsDataUrl(blob);
        reader.onLoadEnd.listen((_) {
          final dataUrl = reader.result as String?;
          _stopStreamTracks();
          if (dataUrl != null && dataUrl.isNotEmpty) {
            completer.complete(VoiceRecorderResult(dataUrl: dataUrl, durationSeconds: durationSecs));
          } else {
            completer.complete(null);
          }
        });
        reader.onError.listen((_) {
          _stopStreamTracks();
          completer.complete(null);
        });
      } catch (e) {
        debugPrint('[VoiceRecorderWeb] Error in stop listener: $e');
        _stopStreamTracks();
        completer.complete(null);
      }
    });

    _mediaRecorder!.stop();
  } catch (e) {
    debugPrint('[VoiceRecorderWeb] Error stopping recording: $e');
    _stopStreamTracks();
    completer.complete(null);
  }
  return completer.future;
}

void _stopStreamTracks() {
  if (_audioStream != null) {
    for (final track in _audioStream!.getTracks()) {
      track.stop();
    }
    _audioStream = null;
  }
  _mediaRecorder = null;
}
