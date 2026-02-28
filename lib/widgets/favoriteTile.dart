// lib/widgets/favorite_tile.dart
import 'package:flutter/material.dart';
import 'package:mplayer/Models/song.dart';
import 'package:mplayer/styles.dart';

class FavoriteTile extends StatelessWidget {
  final Song song;
  final bool isSelected;
  final VoidCallback onTap;

  const FavoriteTile({
    super.key,
    required this.song,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
      leading: Image.asset(
        "assets/covers/${song.cover}",
        width: 48,
        height: 48,
        fit: BoxFit.cover,
      ),
      title: Text(song.title,
          style: const TextStyle(color: AppStyles.textColor)),
      subtitle: Text(song.artist,
          style: const TextStyle(color: AppStyles.textColor)),
      onTap: onTap,
    );
  }
}