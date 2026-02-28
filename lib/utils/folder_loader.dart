// lib/utils/folder_loader.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:mplayer/Models/song.dart';
// import 'package:permission_handler/permission_handler.dart';

class FolderLoader {
  static Future<List<Song>?> pickFolderAndLoadSongs() async {
    // No permission request needed
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return null;

    // Scan directory for audio files
    final dir = Directory(selectedDirectory);
    List<Song> songs = [];

    try {
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final path = entity.path;
          final extension = path.split('.').last.toLowerCase();
          if (['mp3', 'm4a', 'aac', 'wav', 'flac'].contains(extension)) {
            // Use filename (without extension) as title, folder name as artist? Or unknown.
            final name = path.split('/').last.split('.').first;
            songs.add(
              Song(
                title: name,
                artist: 'Unknown Artist',
                cover: 'default_cover.png', // provide a default asset
                path: path,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error reading folder: $e');
      return null;
    }

    return songs;
  }
}
