// lib/widgets/lyrics_panel.dart
import 'package:flutter/material.dart';
import 'package:mplayer/Models/song.dart';
import 'package:mplayer/lyrics_placeholders.dart';
import 'package:mplayer/styles.dart';


class LyricsPanel extends StatelessWidget {
  final Song song;
  final VoidCallback onClose;

  const LyricsPanel({
    super.key,
    required this.song,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final lyrics = lyricsPlaceholders[song.title] ??
        '🎶 Lyrics not available yet.\n\nCheck back soon!';

    return Container(
      color: AppStyles.primaryColor,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${song.title} — Lyrics',
                    style: const TextStyle(
                      color: AppStyles.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),

          // Lyrics scroll area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                lyrics,
                style: const TextStyle(
                  color: AppStyles.textColor,
                  fontSize: 16,
                  height: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}