import '../models/lullaby_genre.dart';
import '../models/song.dart';
import 'lullaby_local_data_source.dart';

// ── Abstract interface ──────────────────────────────────────────────────────
abstract class LullabyRepository {
  Future<List<Song>> getSongs();
  Future<List<LullabyGenre>> getGenres();
}

// ── Concrete implementation ─────────────────────────────────────────────────
class LullabyRepositoryImpl implements LullabyRepository {
  final LullabyDataSource dataSource;

  const LullabyRepositoryImpl({required this.dataSource});

  @override
  Future<List<Song>> getSongs() => dataSource.fetchSongs();

  @override
  Future<List<LullabyGenre>> getGenres() => dataSource.fetchGenres();
}

// ── Default instance (local / offline) ─────────────────────────────────────
final lullabyRepository = LullabyRepositoryImpl(
  dataSource: const LocalLullabyDataSource(),
);
