import 'voice_recorder_stub.dart'
    if (dart.library.html) 'voice_recorder_web.dart';

export 'voice_recorder_stub.dart';

class VoiceRecorderService {
  static Future<bool> start() => startVoiceRecording();
  static Future<VoiceRecorderResult?> stop(int durationSecs) => stopVoiceRecording(durationSecs);
}
