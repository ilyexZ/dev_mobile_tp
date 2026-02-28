// lib/main.dart
import 'package:flutter/material.dart';
import 'package:mplayer/pages/main_scafold.dart';
import 'package:mplayer/Models/song.dart';
import 'package:flutter/services.dart';
import 'package:mplayer/services/audio_player_service.dart'; // new

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  // Load default songs into service
  final defaultSongs = [
    Song(title: 'Because', artist: 'The Beatles', cover: 'i2.jpeg',audioAsset: 'audio/abbey_road.mp3'),
    Song(title: 'The Dark Side of the Moon', artist: 'Pink Floyd', cover: 'i1.png',audioAsset: 'audio/dark_side.mp3'),
    Song(title: 'We Will Rock You', artist: 'Queen', cover: 'i3.jpg',audioAsset: 'audio/we_will_rock_you.mp3'),
    Song(title: 'Survivor / I Will Survive', artist: 'Glee Cast', cover: 'i4.jpeg',audioAsset: 'audio/survivor.mp3'),
  ];
  AudioPlayerService().loadSongs(defaultSongs);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainScafold(),
    );
  }
}