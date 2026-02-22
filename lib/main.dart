import 'package:flutter/material.dart';
import 'package:mplayer/pages/main_scafold.dart';
import 'package:mplayer/Models/song.dart';
import 'package:flutter/services.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar text/icons to light
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // optional, keep transparent
      statusBarIconBrightness: Brightness.light, // <-- text/icons color
      statusBarBrightness: Brightness.dark, // for iOS
    ),
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Song> songs = [
      Song(title: 'Abbey Road ', artist: 'The Beatles', cover: 'i2.jpeg'),
      Song(
        title: 'The Dark Side of the Moon',
        artist: 'Pink Floyd',
        cover: 'i1.png',
      ),
      Song(title: 'We Will Rock You', artist: 'Queen', cover: 'i3.jpg'),

      Song(title: 'Survivor / I Will Survive', artist: 'Glee Cast', cover: 'i4.jpeg'),
    ];

    return MaterialApp(home: MainScafold(songs: songs));
  }
}
