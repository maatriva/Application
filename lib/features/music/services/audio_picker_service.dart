import 'audio_picker_stub.dart'
    if (dart.library.html) 'audio_picker_web.dart';

export 'audio_picker_stub.dart';

class AudioPickerService {
  static Future<AudioPickerResult?> pick([AudioPickerResult? preselected]) =>
      pickAudioFile(preselected: preselected);
}
