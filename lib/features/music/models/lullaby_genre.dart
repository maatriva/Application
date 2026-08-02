/// Represents a broad lullaby genre category shown on the home screen.
class LullabyGenre {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final String colorKey;
  final List<String> categories; // maps to Song.category values

  const LullabyGenre({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.colorKey,
    required this.categories,
  });
}
