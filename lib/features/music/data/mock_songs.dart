import '../models/song.dart';

final List<Song> rawMockSongs = [
  // Lullabies
  Song(
    id: 'l1',
    title: 'Twinkle Twinkle Little Star',
    artist: 'Maatriva Dreamers',
    duration: const Duration(minutes: 3, seconds: 15),
    category: 'Lullabies',
    albumArtColor: 'lavender',
    isFavorite: true,
  ),
  Song(
    id: 'l2',
    title: "Brahms' Lullaby",
    artist: 'Sweet Dreams Ensemble',
    duration: const Duration(minutes: 4, seconds: 20),
    category: 'Lullabies',
    albumArtColor: 'purple',
    isFavorite: false,
  ),
  Song(
    id: 'l3',
    title: 'Rock-a-bye Baby',
    artist: 'Nursery Strings',
    duration: const Duration(minutes: 2, seconds: 50),
    category: 'Lullabies',
    albumArtColor: 'blue',
  ),
  Song(
    id: 'l4',
    title: 'Sweet Lullaby',
    artist: 'Acoustic Lullaby Duo',
    duration: const Duration(minutes: 3, seconds: 45),
    category: 'Lullabies',
    albumArtColor: 'rose',
  ),
  Song(
    id: 'l5',
    title: 'Baby Dreams Orchestral',
    artist: 'Maatriva Symphony',
    duration: const Duration(minutes: 5, seconds: 10),
    category: 'Lullabies',
    albumArtColor: 'indigo',
  ),

  // White Noise
  Song(
    id: 'wn1',
    title: 'Pure White Noise',
    artist: 'Hush Acoustic Labs',
    duration: const Duration(minutes: 10, seconds: 00),
    category: 'White Noise',
    albumArtColor: 'teal',
  ),
  Song(
    id: 'wn2',
    title: 'Pink Noise Calm',
    artist: 'Deep Sleep Frequency',
    duration: const Duration(minutes: 15, seconds: 00),
    category: 'White Noise',
    albumArtColor: 'sunset',
  ),
  Song(
    id: 'wn3',
    title: 'Womb Simulation',
    artist: 'Maatriva Vitals',
    duration: const Duration(minutes: 8, seconds: 30),
    category: 'White Noise',
    albumArtColor: 'rose',
    isFavorite: true,
  ),

  // Nature Sounds
  Song(
    id: 'ns1',
    title: 'Forest Birds',
    artist: 'Nature Whispers',
    duration: const Duration(minutes: 6, seconds: 12),
    category: 'Nature Sounds',
    albumArtColor: 'emerald',
  ),
  Song(
    id: 'ns2',
    title: 'Soft Wind Rustle',
    artist: 'Natural Harmony',
    duration: const Duration(minutes: 7, seconds: 40),
    category: 'Nature Sounds',
    albumArtColor: 'mint',
  ),
  Song(
    id: 'ns3',
    title: 'Morning Birds Chorus',
    artist: 'Eco Echoes',
    duration: const Duration(minutes: 5, seconds: 00),
    category: 'Nature Sounds',
    albumArtColor: 'sunset',
  ),

  // Rain Sounds
  Song(
    id: 'r1',
    title: 'Gentle Rain on Window',
    artist: 'Raindrop Melody',
    duration: const Duration(minutes: 8, seconds: 15),
    category: 'Rain Sounds',
    albumArtColor: 'blue',
    isFavorite: true,
  ),
  Song(
    id: 'r2',
    title: 'Soft Thunder & Rain',
    artist: 'Cozy Cabin Atmosphere',
    duration: const Duration(minutes: 12, seconds: 40),
    category: 'Rain Sounds',
    albumArtColor: 'indigo',
  ),
  Song(
    id: 'r3',
    title: 'Under the Umbrella',
    artist: 'Pure Raindrops',
    duration: const Duration(minutes: 6, seconds: 50),
    category: 'Rain Sounds',
    albumArtColor: 'teal',
  ),

  // Heartbeat Sounds
  Song(
    id: 'h1',
    title: 'Heartbeat Comfort',
    artist: 'Maternal Rhythm',
    duration: const Duration(minutes: 9, seconds: 05),
    category: 'Heartbeat Sounds',
    albumArtColor: 'rose',
    isFavorite: true,
  ),
  Song(
    id: 'h2',
    title: 'Slow Heartbeat Pulse',
    artist: 'Guardian Angel Sounds',
    duration: const Duration(minutes: 10, seconds: 00),
    category: 'Heartbeat Sounds',
    albumArtColor: 'lavender',
  ),

  // Ocean Waves
  Song(
    id: 'o1',
    title: 'Ocean Breeze Whispers',
    artist: 'Shoreline Ambient',
    duration: const Duration(minutes: 11, seconds: 20),
    category: 'Ocean Waves',
    albumArtColor: 'blue',
  ),
  Song(
    id: 'o2',
    title: 'Calm Waves Crashing',
    artist: 'Sea Salt Relaxation',
    duration: const Duration(minutes: 14, seconds: 15),
    category: 'Ocean Waves',
    albumArtColor: 'teal',
  ),

  // Meditation
  Song(
    id: 'm1',
    title: 'Zen Sleep Journey',
    artist: 'Mindful Nursery',
    duration: const Duration(minutes: 7, seconds: 30),
    category: 'Meditation',
    albumArtColor: 'purple',
  ),
  Song(
    id: 'm2',
    title: 'Astral Floatation',
    artist: 'Cosmic Slumber',
    duration: const Duration(minutes: 8, seconds: 45),
    category: 'Meditation',
    albumArtColor: 'indigo',
  ),

  // Classical
  Song(
    id: 'c1',
    title: 'Clair de Lune (Debussy)',
    artist: 'Baby Mozart Ensemble',
    duration: const Duration(minutes: 5, seconds: 05),
    category: 'Classical',
    albumArtColor: 'lavender',
  ),
  Song(
    id: 'c2',
    title: 'Gymnopédie No. 1 (Satie)',
    artist: 'Classical Slumber',
    duration: const Duration(minutes: 4, seconds: 40),
    category: 'Classical',
    albumArtColor: 'blue',
  ),
  Song(
    id: 'c3',
    title: 'Moonlight Sonata (Beethoven)',
    artist: 'Peaceful Night Ensemble',
    duration: const Duration(minutes: 6, seconds: 15),
    category: 'Classical',
    albumArtColor: 'purple',
  ),

  // Piano & Instrumental
  Song(
    id: 'p1',
    title: 'Calm Piano Nocturne',
    artist: 'Keyboard Lullabies',
    duration: const Duration(minutes: 4, seconds: 55),
    category: 'Piano',
    albumArtColor: 'rose',
    isFavorite: true,
  ),
  Song(
    id: 'p2',
    title: 'Soft Harp Melody',
    artist: 'Heavenly Strings',
    duration: const Duration(minutes: 5, seconds: 25),
    category: 'Instrumental',
    albumArtColor: 'mint',
  ),
  Song(
    id: 'p3',
    title: 'Woodwind Whisper',
    artist: 'Forest Flute',
    duration: const Duration(minutes: 3, seconds: 50),
    category: 'Instrumental',
    albumArtColor: 'emerald',
  ),

  // Sleep Stories
  Song(
    id: 's1',
    title: 'The Little Sleepy Star',
    artist: 'Uncle Dave (Storyteller)',
    duration: const Duration(minutes: 12, seconds: 30),
    category: 'Sleep Stories',
    albumArtColor: 'sunset',
  ),
  Song(
    id: 's2',
    title: 'Luna the Owl Nursery Adventure',
    artist: 'Aunt Clara (Storyteller)',
    duration: const Duration(minutes: 15, seconds: 45),
    category: 'Sleep Stories',
    albumArtColor: 'indigo',
  ),
  Song(
    id: 's3',
    title: 'Dreamy Cloud Castle',
    artist: 'Storyland Ambient',
    duration: const Duration(minutes: 14, seconds: 00),
    category: 'Sleep Stories',
    albumArtColor: 'lavender',
  ),
  Song(
    id: 's4',
    title: 'The Quiet Forest Slumber',
    artist: 'Deep Dream Narrator',
    duration: const Duration(minutes: 18, seconds: 20),
    category: 'Sleep Stories',
    albumArtColor: 'emerald',
  ),
];
