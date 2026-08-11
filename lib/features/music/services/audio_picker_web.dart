import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'audio_picker_stub.dart';
export 'audio_picker_stub.dart';

Future<AudioPickerResult?> pickAudioFile({AudioPickerResult? preselected}) async {
  if (preselected != null) {
    return preselected;
  }
  
  final completer = Completer<AudioPickerResult?>();
  try {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'audio/*,.mp3,.wav,.m4a,.aac,.ogg,.flac';
    uploadInput.click();

    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((_) {
          completer.complete(
            AudioPickerResult(
              name: file.name,
              dataUrl: reader.result as String?,
              duration: const Duration(minutes: 3, seconds: 30),
              artist: 'Device Storage',
            ),
          );
        });
        reader.onError.listen((_) {
          completer.complete(null);
        });
      } else {
        completer.complete(null);
      }
    });
  } catch (e) {
    debugPrint('[AudioPicker] Web error: $e');
    completer.complete(null);
  }
  return completer.future;
}
