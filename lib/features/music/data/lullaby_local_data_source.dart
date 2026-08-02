import '../models/lullaby_genre.dart';
import '../models/song.dart';
import 'mock_genres.dart';
import 'mock_songs.dart';

// ── Abstract interface ──────────────────────────────────────────────────────
/// Data source abstraction.  Swap [LocalLullabyDataSource] with a cloud
/// implementation without changing any provider or UI code.
abstract class LullabyDataSource {
  Future<List<Song>> fetchSongs();
  Future<List<LullabyGenre>> fetchGenres();
}

// ── Local (mock) implementation ─────────────────────────────────────────────
class LocalLullabyDataSource implements LullabyDataSource {
  const LocalLullabyDataSource();

  @override
  Future<List<Song>> fetchSongs() async {
    // Simulates a short async fetch; replace with a real DB/HTTP call later.
    await Future.delayed(Duration.zero);
    return List<Song>.from(rawMockSongs);
  }

  @override
  Future<List<LullabyGenre>> fetchGenres() async {
    await Future.delayed(Duration.zero);
    return List<LullabyGenre>.from(mockGenres);
  }
}
