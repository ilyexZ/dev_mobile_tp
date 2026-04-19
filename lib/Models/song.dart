class Song {
  final String title;
  final String artist;
  final String cover;
  final String? path;
  final String? audioAsset;

  // Filename is used as id for picked songs — full paths can vary across
  // sessions on Android, but the filename is always stable.
  String get id {
    if (path != null) return path!.split('/').last;
    return audioAsset ?? title;
  }

  const Song({
    required this.title,
    required this.artist,
    required this.cover,
    this.path,
    this.audioAsset,
  });
}