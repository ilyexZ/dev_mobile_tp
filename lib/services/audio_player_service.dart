// lib/services/audio_player_service.dart
import 'dart:async';
import 'dart:collection';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mplayer/Models/song.dart';
import 'package:mplayer/db/database_helper.dart';

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal() {
    _initPlayer();
    _loadFavoritesFromDb();
  }

  final AudioPlayer _player = AudioPlayer();

  // ── Collections backed by LinkedHashMap ───────────────────────────────────
  // Key = song.id (path | audioAsset | title).
  // Inserting the same key a second time just overwrites – no duplicates ever.

  /// All songs available to the player (defaults + picked files).
  final LinkedHashMap<String, Song> _songsMap = LinkedHashMap();

  /// Mirror of the DB rows; used as the source for the Favorites page.
  final LinkedHashMap<String, Song> _favoriteSongsMap = LinkedHashMap();

  // ── State ─────────────────────────────────────────────────────────────────
  int _currentIndex = 0;

  // Streams
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _playerStateController = StreamController<PlayerState>.broadcast();

  // ── Getters ────────────────────────────────────────────────────────────────
  List<Song> get songs => _songsMap.values.toList();
  List<Song> get favoriteSongs => _favoriteSongsMap.values.toList();

  int get currentIndex => _currentIndex;
  Song? get currentSong =>
      _songsMap.isNotEmpty ? _songsMap.values.elementAt(_currentIndex) : null;
  bool get isPlaying => _player.state == PlayerState.playing;

  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  // ── DB restore ─────────────────────────────────────────────────────────────
  Future<void> _loadFavoritesFromDb() async {
    final saved = await DatabaseHelper.instance.getAllFavorites();
    for (final s in saved) {
      _favoriteSongsMap[s.id] = s; // overwrites if somehow already there
      _songsMap[s.id] = s; // merge back into playable list
    }
    notifyListeners();
  }

  // ── Player setup ───────────────────────────────────────────────────────────
  void _initPlayer() {
    _player.onPositionChanged.listen((p) => _positionController.add(p));
    _player.onDurationChanged.listen((d) => _durationController.add(d));
    _player.onPlayerStateChanged.listen((state) {
      _playerStateController.add(state);
      notifyListeners();
    });
    _player.onPlayerComplete.listen((_) => next());
  }

  // ── Song management ────────────────────────────────────────────────────────

  /// Initial load for default asset songs (called from main.dart once).
  void loadSongs(List<Song> newSongs) {
    for (final s in newSongs) {
      _songsMap[s.id] = s; // map key guarantees no duplicates
    }
    notifyListeners();
  }

  /// Append user-picked files.  Returns the index of the first NEW song
  /// so the caller can start playback there.
  /// Picking the same file again is silently ignored.
  int? addPickedSongs(List<Song> picked) {
    final beforeCount = _songsMap.length;

    // Collect existing paths (not just keys) to guard against any path variant
    final existingPaths = _songsMap.values
        .map((s) => s.path)
        .whereType<String>()
        .toSet();

    for (final s in picked) {
      // Skip if this path is already loaded under ANY key
      if (s.path != null && existingPaths.contains(s.path)) continue;
      _songsMap[s.id] = s;
    }

    notifyListeners();
    return _songsMap.length > beforeCount ? beforeCount : null;
  }

  // ── Playback ───────────────────────────────────────────────────────────────
  Future<void> playIndex(int index) async {
    final list = _songsMap.values.toList();
    if (index < 0 || index >= list.length) return;
    _currentIndex = index;
    final song = list[index];

    if (song.path != null) {
      await _player.play(DeviceFileSource(song.path!));
    } else if (song.audioAsset != null) {
      await _player.play(AssetSource(song.audioAsset!));
    }
    notifyListeners();
  }

  Future<void> playPause() async {
    if (_player.state == PlayerState.playing) {
      await _player.pause();
    } else if (_player.state == PlayerState.paused) {
      await _player.resume();
    } else {
      await playIndex(_currentIndex);
    }
  }

  Future<void> next() async {
    if (_songsMap.isEmpty) return;
    await playIndex((_currentIndex + 1) % _songsMap.length);
  }

  Future<void> previous() async {
    if (_songsMap.isEmpty) return;
    await playIndex((_currentIndex - 1 + _songsMap.length) % _songsMap.length);
  }

  Future<void> seek(Duration position) async => _player.seek(position);

  // ── Favourites ─────────────────────────────────────────────────────────────
  bool isFavorite(String songId) => _favoriteSongsMap.containsKey(songId);

  Future<void> toggleFavorite(String songId, {Song? song}) async {
    if (_favoriteSongsMap.containsKey(songId)) {
      // ── Remove ────────────────────────────────────────────────────────────
      _favoriteSongsMap.remove(songId);
      await DatabaseHelper.instance.deleteFavorite(songId);
    } else {
      // ── Add ───────────────────────────────────────────────────────────────
      final target = song ?? _songsMap[songId];
      if (target != null) {
        _favoriteSongsMap[songId] = target; // map key = no duplicates
        await DatabaseHelper.instance.insertFavorite(target);
      }
    }
    notifyListeners();
  }

  Future<void> clearAllFavorites() async {
    _favoriteSongsMap.clear();
    await DatabaseHelper.instance.clearAllFavorites();
    notifyListeners();
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  Future<void> pause() async {
    if (_player.state == PlayerState.playing) await _player.pause();
  }

  Future<void> resume() async {
    if (_player.state == PlayerState.paused) await _player.resume();
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
