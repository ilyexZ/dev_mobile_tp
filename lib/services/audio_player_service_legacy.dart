// lib/services/audio_player_service_legacy.dart
//
// ══════════════════════════════════════════════════════════════════════════════
// LEGACY IMPLEMENTATION: audioplayers package
//
// TO SWAP BACK:
//   1. Delete (or rename) lib/services/audio_player_service.dart.
//   2. Copy this file → lib/services/audio_player_service.dart.
//   3. Ensure pubspec.yaml has:  audioplayers: ^6.x.x
//   4. You can safely revert the Kotlin MusicService / MainActivity to the
//      original versions (no foreground service needed by this implementation).
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:collection';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mplayer/Models/song.dart';
import 'package:mplayer/db/database_helper.dart';

class AudioPlayerService extends ChangeNotifier {
  // ── Singleton ─────────────────────────────────────────────────────────────
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  AudioPlayerService._internal() {
    _loadFavoritesFromDb();
    _setupPlayerListeners();
  }

  // ── Player ────────────────────────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();

  // ── Song lists ────────────────────────────────────────────────────────────
  final LinkedHashMap<String, Song> _songsMap         = LinkedHashMap();
  final LinkedHashMap<String, Song> _favoriteSongsMap = LinkedHashMap();

  int  _currentIndex = 0;
  bool _isPlaying    = false;

  // ── Streams (re-exposed so widgets keep the same API) ─────────────────────
  Stream<Duration>  get positionStream    => _player.onPositionChanged;
  Stream<Duration?> get durationStream    => _player.onDurationChanged;

  /// Emits `true` when playing, `false` when paused/stopped.
  Stream<bool> get playerStateStream =>
      _player.onPlayerStateChanged.map((s) => s == PlayerState.playing);

  // ── Public getters ────────────────────────────────────────────────────────
  List<Song> get songs         => _songsMap.values.toList();
  List<Song> get favoriteSongs => _favoriteSongsMap.values.toList();

  int   get currentIndex => _currentIndex;
  Song? get currentSong  =>
      _songsMap.isNotEmpty ? _songsMap.values.elementAt(_currentIndex) : null;
  bool  get isPlaying    => _isPlaying;

  // ── Internal setup ────────────────────────────────────────────────────────
  void _setupPlayerListeners() {
    _player.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _player.onPlayerComplete.listen((_) => next());
  }

  Future<void> _loadFavoritesFromDb() async {
    final saved = await DatabaseHelper.instance.getAllFavorites();
    for (final s in saved) {
      _favoriteSongsMap[s.id] = s;
      _songsMap[s.id]         = s;
    }
    notifyListeners();
  }

  // ── Song management ───────────────────────────────────────────────────────
  void loadSongs(List<Song> newSongs) {
    for (final s in newSongs) {
      _songsMap[s.id] = s;
    }
    notifyListeners();
  }

  /// Appends newly picked files. Returns the index of the first new song,
  /// or null if every picked file was already in the list.
  int? addPickedSongs(List<Song> picked) {
    final beforeCount = _songsMap.length;
    for (final s in picked) {
      _songsMap[s.id] = s;
    }
    notifyListeners();
    return _songsMap.length > beforeCount ? beforeCount : null;
  }

  // ── Playback ──────────────────────────────────────────────────────────────
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
    if (_isPlaying) {
      await _player.pause();
    } else {
      final pos = await _player.getCurrentPosition();
      if (pos == null || pos == Duration.zero) {
        await playIndex(_currentIndex);
      } else {
        await _player.resume();
      }
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

  Future<void> seek(Duration position) => _player.seek(position);

  // ── These are kept so Favorites page compiles without changes ─────────────
  Future<void> pause()  => _player.pause();
  Future<void> resume() => _player.resume();

  // ── Favourites ────────────────────────────────────────────────────────────
  bool isFavorite(String songId) => _favoriteSongsMap.containsKey(songId);

  Future<void> toggleFavorite(String songId, {Song? song}) async {
    if (_favoriteSongsMap.containsKey(songId)) {
      _favoriteSongsMap.remove(songId);
      await DatabaseHelper.instance.deleteFavorite(songId);
    } else {
      final target = song ?? _songsMap[songId];
      if (target != null) {
        _favoriteSongsMap[songId] = target;
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

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}