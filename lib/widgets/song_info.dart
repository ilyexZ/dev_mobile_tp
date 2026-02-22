import 'package:flutter/material.dart';
import 'package:mplayer/Models/song.dart';
import 'package:mplayer/styles.dart';

class SongInfo extends StatelessWidget {
  final Song song;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onFavoriteLongPress;
  final bool isVisible;

  const SongInfo({
    super.key,
    required this.song,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onFavoriteLongPress,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox(height: 100);

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(song.title, style: AppStyles.songTitle),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(song.artist, style: AppStyles.songArtist),
                IconButton(
                  onPressed: onFavoriteTap,
                  onLongPress: onFavoriteLongPress,
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite
                        : Icons.favorite_outline,
                    color: isFavorite ? Colors.red : Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}