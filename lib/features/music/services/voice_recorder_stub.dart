import 'package:flutter/foundation.dart';

class VoiceRecorderResult {
  final String dataUrl;
  final int durationSeconds;

  VoiceRecorderResult({required this.dataUrl, required this.durationSeconds});
}

Future<bool> startVoiceRecording() async {
  debugPrint('[VoiceRecorderStub] Recording started');
  return true;
}

Future<VoiceRecorderResult?> stopVoiceRecording(int durationSecs) async {
  debugPrint('[VoiceRecorderStub] Recording stopped');
  return VoiceRecorderResult(
    dataUrl: 'assets/audio/apalonbeats-bollywood-indian-hindi-song-music-576335.mp3',
    durationSeconds: durationSecs > 0 ? durationSecs : 10,
  );
}
