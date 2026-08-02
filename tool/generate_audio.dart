// tool/generate_audio.dart
// Run with: dart tool/generate_audio.dart
// Generates 8 WAV placeholder audio files for the Maatriva lullaby library.

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() async {
  final outputDir = Directory('assets/audio');
  await outputDir.create(recursive: true);

  stdout.writeln('\nMatriva Audio Generator');
  stdout.writeln('=======================');

  await generateSine(outputDir, 'lullaby_classic.wav', 440.0, 0.40);
  await generateWhiteNoise(outputDir, 'white_noise.wav', 0.15);
  await generateNature(outputDir, 'nature_sounds.wav', 0.40);
  await generateRain(outputDir, 'rain_sounds.wav', 0.30);
  await generateOcean(outputDir, 'ocean_waves.wav', 0.40);
  await generateHeartbeat(outputDir, 'heartbeat.wav', 0.70);
  await generateChord(outputDir, 'instrumental.wav', 0.35);
  await generateMeditation(outputDir, 'meditation.wav', 0.35);

  stdout.writeln('\nDone! 8 WAV files in assets/audio/\n');
}

const sampleRate = 44100;
const durationSecs = 8.0;

Uint8List buildWav(List<int> samples) {
  final dataSize = samples.length * 2;
  final buffer = ByteData(44 + dataSize);
  buffer.setUint8(0, 0x52); buffer.setUint8(1, 0x49);
  buffer.setUint8(2, 0x46); buffer.setUint8(3, 0x46);
  buffer.setUint32(4, 36 + dataSize, Endian.little);
  buffer.setUint8(8, 0x57); buffer.setUint8(9, 0x41);
  buffer.setUint8(10, 0x56); buffer.setUint8(11, 0x45);
  buffer.setUint8(12, 0x66); buffer.setUint8(13, 0x6D);
  buffer.setUint8(14, 0x74); buffer.setUint8(15, 0x20);
  buffer.setUint32(16, 16, Endian.little);
  buffer.setUint16(20, 1, Endian.little);
  buffer.setUint16(22, 1, Endian.little);
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, sampleRate * 2, Endian.little);
  buffer.setUint16(32, 2, Endian.little);
  buffer.setUint16(34, 16, Endian.little);
  buffer.setUint8(36, 0x64); buffer.setUint8(37, 0x61);
  buffer.setUint8(38, 0x74); buffer.setUint8(39, 0x61);
  buffer.setUint32(40, dataSize, Endian.little);
  for (int i = 0; i < samples.length; i++) {
    buffer.setInt16(44 + i * 2, samples[i], Endian.little);
  }
  return buffer.buffer.asUint8List();
}

List<int> makeSamples(double Function(int i) generator) {
  final n = (sampleRate * durationSecs).toInt();
  final fadeLen = (sampleRate * 0.3).toInt();
  return List<int>.generate(n, (i) {
    double fade = 1.0;
    if (i < fadeLen) fade = i / fadeLen;
    if (i > n - fadeLen) fade = (n - i) / fadeLen;
    return (generator(i) * fade * 32767).toInt().clamp(-32768, 32767);
  });
}

Future<void> write(Directory dir, String name, List<int> samples) async {
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(buildWav(samples));
  final kb = ((44 + samples.length * 2) / 1024).round();
  stdout.writeln('  [OK] $name  ($kb KB)');
}

Future<void> generateSine(Directory d, String name, double freq, double amp) =>
    write(d, name, makeSamples((i) => amp * sin(2 * pi * freq * i / sampleRate)));

Future<void> generateMeditation(Directory d, String name, double amp) =>
    write(d, name, makeSamples((i) {
      final t = i / sampleRate;
      return amp * (0.85 + 0.15 * sin(2 * pi * 6 * t)) * sin(2 * pi * 528 * t);
    }));

Future<void> generateChord(Directory d, String name, double amp) =>
    write(d, name, makeSamples((i) {
      final t = i / sampleRate;
      return amp * (sin(2 * pi * 261.63 * t) + sin(2 * pi * 329.63 * t) * 0.7 +
          sin(2 * pi * 392.00 * t) * 0.5) / 2.2;
    }));

Future<void> generateNature(Directory d, String name, double amp) =>
    write(d, name, makeSamples((i) {
      final t = i / sampleRate;
      final s1 = sin(2 * pi * 220 * t);
      final s2 = sin(2 * pi * 330 * t) * 0.6;
      return amp * (s1 + s2) / 1.6 * (1.0 + 0.1 * sin(2 * pi * 0.3 * t));
    }));

Future<void> generateWhiteNoise(Directory d, String name, double amp) async {
  final rng = Random(42);
  double prev = 0;
  final samples = makeSamples((i) {
    final w = rng.nextDouble() * 2 - 1;
    final filtered = prev * 0.6 + w * 0.4;
    prev = filtered;
    return amp * filtered;
  });
  await write(d, name, samples);
}

Future<void> generateRain(Directory d, String name, double amp) async {
  final rng = Random(7);
  double prev = 0;
  final samples = makeSamples((i) {
    final w = rng.nextDouble() * 2 - 1;
    final filtered = prev * 0.75 + w * 0.25;
    prev = filtered;
    return amp * filtered;
  });
  await write(d, name, samples);
}

Future<void> generateOcean(Directory d, String name, double amp) async {
  final rng = Random(13);
  double prev = 0;
  final samples = makeSamples((i) {
    final t = i / sampleRate;
    final env = 0.5 + 0.5 * sin(2 * pi * 0.08 * t);
    final noise = rng.nextDouble() * 2 - 1;
    final filtered = prev * 0.8 + noise * 0.2;
    prev = filtered;
    return amp * filtered * env;
  });
  await write(d, name, samples);
}

Future<void> generateHeartbeat(Directory d, String name, double amp) =>
    write(d, name, makeSamples((i) {
      final t = i / sampleRate;
      const period = 60.0 / 66.0;
      final phase = (t % period) / period;
      if (phase < 0.06) {
        final p = phase / 0.06;
        return amp * sin(2 * pi * 55 * t) * (1 - p) * p * 4;
      } else if (phase >= 0.22 && phase < 0.27) {
        final p = (phase - 0.22) / 0.05;
        return amp * 0.7 * sin(2 * pi * 70 * t) * (1 - p) * p * 4;
      }
      return 0.0;
    }));
