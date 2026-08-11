import 'package:flutter/foundation.dart';

class AudioPickerResult {
  final String name;
  final String? dataUrl;
  final Uint8List? bytes;
  final Duration? duration;
  final String? artist;
  final String? category;

  AudioPickerResult({
    required this.name,
    this.dataUrl,
    this.bytes,
    this.duration,
    this.artist,
    this.category,
  });
}

/// Built-in gallery music presets available for quick addition
final List<AudioPickerResult> galleryPresets = [
  AudioPickerResult(
    name: 'Mother\'s Gentle Humming.mp3',
    dataUrl: 'assets/audio/lullaby_classic.wav',
    duration: const Duration(minutes: 3, seconds: 12),
    artist: 'Family Voice & Gallery',
    category: 'Lullabies',
  ),
  AudioPickerResult(
    name: 'Sweet Baby Brahms Lullaby.mp3',
    dataUrl: 'assets/audio/lullaby_classic.wav',
    duration: const Duration(minutes: 2, seconds: 45),
    artist: 'Gallery Classics',
    category: 'Nursery Rhymes',
  ),
  AudioPickerResult(
    name: 'Soft Bedtime Acoustic Guitar.mp3',
    dataUrl: 'assets/audio/lullaby_classic.wav',
    duration: const Duration(minutes: 4, seconds: 05),
    artist: 'Gallery Acoustics',
    category: 'Instrumental',
  ),
  AudioPickerResult(
    name: 'Calming Rainfall & Womb Echoes.wav',
    dataUrl: 'assets/audio/lullaby_classic.wav',
    duration: const Duration(minutes: 5, seconds: 30),
    artist: 'Nature Gallery',
    category: 'Nature Sounds',
  ),
];

Future<AudioPickerResult?> pickAudioFile({AudioPickerResult? preselected}) async {
  if (preselected != null) return preselected;
  
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return AudioPickerResult(
    name: 'Gallery_Track_$timestamp.mp3',
    dataUrl: 'assets/audio/lullaby_classic.wav',
    duration: const Duration(minutes: 3, seconds: 15),
    artist: 'Device Storage',
    category: 'Lullabies',
  );
}
