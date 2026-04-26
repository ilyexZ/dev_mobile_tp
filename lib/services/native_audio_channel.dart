// lib/services/native_audio_channel.dart
import 'dart:async';
import 'package:flutter/services.dart';

/// Thin Dart wrapper around the two platform channels exposed by MainActivity.
///
///  • [_method] (MethodChannel)  – Flutter  → Native commands
///  • [_event]  (EventChannel)   – Native   → Flutter state / position events
class NativeAudioChannel {
  NativeAudioChannel._();

  static const _method = MethodChannel('mplayer/audio');
  static const _event  = EventChannel('mplayer/audio_events');

  // Cache a single broadcast stream so multiple listeners can subscribe.
  static Stream<Map>? _stream;
  static Stream<Map> get events {
    _stream ??= _event
        .receiveBroadcastStream()
        .map((e) => Map<String, dynamic>.from(e as Map));
    return _stream!;
  }

  // ── Playback commands ─────────────────────────────────────────────────────

  /// Play a Flutter asset (e.g. "audio/abbey_road.mp3").
  static Future<void> playAsset(String path, String title, String artist) =>
      _method.invokeMethod('playAsset', {
        'path':   path,
        'title':  title,
        'artist': artist,
      });

  /// Play an absolute device file path.
  static Future<void> playFile(String path, String title, String artist) =>
      _method.invokeMethod('playFile', {
        'path':   path,
        'title':  title,
        'artist': artist,
      });

  static Future<void> pause()  => _method.invokeMethod('pause');
  static Future<void> resume() => _method.invokeMethod('resume');
  static Future<void> stop()   => _method.invokeMethod('stop');

  static Future<void> seek(Duration position) =>
      _method.invokeMethod('seek', {'ms': position.inMilliseconds});

  // ── State queries (one-shot) ──────────────────────────────────────────────
  static Future<bool> isPlaying() async =>
      (await _method.invokeMethod<bool>('isPlaying')) ?? false;

  static Future<Duration> getPosition() async {
    final ms = (await _method.invokeMethod<int>('getPosition')) ?? 0;
    return Duration(milliseconds: ms);
  }

  static Future<Duration> getDuration() async {
    final ms = (await _method.invokeMethod<int>('getDuration')) ?? 0;
    return Duration(milliseconds: ms);
  }
}