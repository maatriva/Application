import 'package:audioplayers/audioplayers.dart';

/// Wraps the [AudioPlayer] from the audioplayers package so that the rest of
/// the codebase is decoupled from the concrete player implementation.
/// Swap this class for a different implementation (e.g. just_audio, or a
/// cloud-streaming player) without touching any UI or provider code.
class AudioService {
  final AudioPlayer _player = AudioPlayer();

  // ── Streams ─────────────────────────────────────────────────────────────
  Stream<Duration> get positionStream => _player.onPositionChanged;
  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;
  Stream<Duration?> get durationStream => _player.onDurationChanged;
  Stream<void> get onComplete => _player.onPlayerComplete;

  // ── Playback ─────────────────────────────────────────────────────────────
  /// Plays an asset at [assetPath] (relative to the `assets/` folder, e.g.
  /// `'audio/lullaby_classic.wav'`).  Loops the clip seamlessly so short
  /// placeholder files feel like continuous ambient audio.
  Future<void> playAsset(String assetPath) async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource(assetPath));
  }

  /// Plays audio from a remote [url] (future cloud support).
  Future<void> playUrl(String url) async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(UrlSource(url));
  }

  Future<void> pause() async => _player.pause();
  Future<void> resume() async => _player.resume();
  Future<void> stop() async => _player.stop();

  Future<void> seek(Duration position) async => _player.seek(position);

  Future<void> setVolume(double volume) async =>
      _player.setVolume(volume.clamp(0.0, 1.0));

  Future<void> setReleaseMode(ReleaseMode mode) async =>
      _player.setReleaseMode(mode);

  void dispose() => _player.dispose();
}
