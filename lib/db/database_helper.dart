// lib/db/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:mplayer/Models/song.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'favorites.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE favorites (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        song_id     TEXT    NOT NULL UNIQUE,
        title       TEXT    NOT NULL,
        artist      TEXT    NOT NULL,
        cover       TEXT    NOT NULL,
        path        TEXT,
        audio_asset TEXT
      )
    ''');
  }

  Future<void> insertFavorite(Song song) async {
    final db = await database;
    await db.insert(
      'favorites',
      {
        'song_id'    : song.id,
        'title'      : song.title,
        'artist'     : song.artist,
        'cover'      : song.cover,
        'path'       : song.path,
        'audio_asset': song.audioAsset,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteFavorite(String songId) async {
    final db = await database;
    await db.delete('favorites', where: 'song_id = ?', whereArgs: [songId]);
  }

  /// Wipe the entire favorites table (used by the "clear all" button).
  Future<void> clearAllFavorites() async {
    final db = await database;
    await db.delete('favorites');
  }

  Future<List<Song>> getAllFavorites() async {
    final db   = await database;
    final rows = await db.query('favorites');
    return rows
        .map((row) => Song(
              title     : row['title']       as String,
              artist    : row['artist']      as String,
              cover     : row['cover']       as String,
              path      : row['path']        as String?,
              audioAsset: row['audio_asset'] as String?,
            ))
        .toList();
  }
}