// lib/services/audio_player_service.dart
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mplayer/Models/song.dart';

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal() {
    _initPlayer();
  }

  final AudioPlayer _player = AudioPlayer();
  List<Song> _songs = [];
  int _currentIndex = 0;
  final Set<String> _favoritePaths = {}; // store by file path

  // Stream controllers for UI
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _playerStateController = StreamController<PlayerState>.broadcast();

  // Getters
  List<Song> get songs => _songs;
  int get currentIndex => _currentIndex;
  Song? get currentSong => _songs.isNotEmpty ? _songs[_currentIndex] : null;
  bool get isPlaying => _player.state == PlayerState.playing;
  Set<String> get favoritePaths => _favoritePaths;

  // Streams for UI
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  void _initPlayer() {
    _player.onPositionChanged.listen((pos) {
      _positionController.add(pos);
    });
    _player.onDurationChanged.listen((dur) {
      _durationController.add(dur);
    });
    _player.onPlayerStateChanged.listen((state) {
      _playerStateController.add(state);
      notifyListeners(); // for play/pause button state
    });
    _player.onPlayerComplete.listen((_) {
      // Auto play next when song ends
      next();
    });
  }

  // Load a new list of songs (e.g., after folder selection)
  void loadSongs(List<Song> newSongs) {
    _songs = newSongs;
    _currentIndex = 0;
    _favoritePaths.clear(); // optional: reset favorites or try to preserve based on paths
    notifyListeners();
    
  }

 Future<void> playIndex(int index) async {
  if (index < 0 || index >= _songs.length) return;
  _currentIndex = index;
  final song = _songs[index];

  if (song.path != null) {
    await _player.play(DeviceFileSource(song.path!));      // user-picked file
  } else if (song.audioAsset != null) {
    await _player.play(AssetSource(song.audioAsset!));     // ← replaces the print()
  }

  notifyListeners();
}

  Future<void> playPause() async {
  if (_player.state == PlayerState.playing) {
    await _player.pause();
  } else if (_player.state == PlayerState.paused) {
    await _player.resume();
  } else {
    // player is idle/stopped (e.g. fresh load, never played yet)
    await playIndex(_currentIndex);
  }
}

  Future<void> next() async {
    if (_songs.isEmpty) return;
    final newIndex = (_currentIndex + 1) % _songs.length;
    await playIndex(newIndex);
  }

  Future<void> previous() async {
    if (_songs.isEmpty) return;
    final newIndex = (_currentIndex - 1 + _songs.length) % _songs.length;
    await playIndex(newIndex);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void toggleFavorite(String path) {
    if (_favoritePaths.contains(path)) {
      _favoritePaths.remove(path);
    } else {
      _favoritePaths.add(path);
    }
    notifyListeners();
  }

  bool isFavorite(String path) => _favoritePaths.contains(path);

  // Call this when app goes to background
  Future<void> pause() async {
    if (_player.state == PlayerState.playing) {
      await _player.pause();
    }
  }
   Future<void> resume() async {
    if (_player.state == PlayerState.paused) {
      await _player.resume();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _positionController.close();
    _durationController.close();
    _playerStateController.close();
    super.dispose();
  }
}