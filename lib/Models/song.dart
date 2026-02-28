class Song {
  final String title;
  final String artist;
  final String cover;  // still a filename (maybe default)
  final String? path;  // full file path (null for default assets)
  final String? audioAsset;

  String get id => path ?? audioAsset ?? title;
  const Song({
    required this.title,
    required this.artist,
    required this.cover,
    this.path,
    this.audioAsset,
  });
}