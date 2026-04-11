class Song {
  final String title;
  final String artist;
  final String cover;
  final String? path;
  final String? audioAsset;

  // Use filename as id for picked songs — paths can vary across sessions on Android
  String get id {
    if (path != null) {
      return path!.split('/').last; // just "mysong.mp3", always stable
    }
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