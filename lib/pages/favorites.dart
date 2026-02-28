// lib/pages/favorites.dart
import 'package:flutter/material.dart';
import 'package:mplayer/Models/song.dart';
import 'package:mplayer/services/audio_player_service.dart';
import 'package:mplayer/styles.dart';
import 'package:mplayer/widgets/favoriteTile.dart';

import 'package:mplayer/widgets/lyricsPanel.dart';


class Favorites extends StatefulWidget {
  const Favorites({super.key});

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  final AudioPlayerService _service = AudioPlayerService();
  Song? _selectedSong;
  
  bool _pausedOnEnter= false;
  @override
  void initState() {
    super.initState();
    // Pause when entering
    _service.pause();
    _pausedOnEnter = true;
  }

  @override
  void dispose() {
    // _service.resume();
    super.dispose();
  }
  
  Widget _buildList(List<Song> favoriteSongs) {
    if (favoriteSongs.isEmpty) {
      return const Center(
        child: Text('No favorites yet', style: TextStyle(color: Colors.white)),
      );
    }
    return ListView.builder(
      itemCount: favoriteSongs.length,
      itemBuilder: (ctx, i) {
        final song = favoriteSongs[i];
        return FavoriteTile(
          song: song,
          isSelected: _selectedSong?.id == song.id,
          onTap: () => setState(() {
            _selectedSong = _selectedSong?.id == song.id ? null : song;
          }),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final showLyrics = _selectedSong != null;

    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final favoriteSongs = _service.songs
            .where((s) => _service.isFavorite(s.id))
            .toList();

        return Scaffold(
          backgroundColor: AppStyles.primaryColor,
          appBar: AppBar(
            title: const Text('Favorites',
                style: TextStyle(color: AppStyles.textColor)),
            backgroundColor: AppStyles.primaryColor,
          ),
          body: OrientationBuilder(
            builder: (context, orientation) {
              // landscape + lyrics open → side by side
              if (orientation == Orientation.landscape && showLyrics) {
                return Row(
                  children: [
                    Expanded(child: _buildList(favoriteSongs)),
                    const VerticalDivider(color: Colors.white24, width: 1),
                    Expanded(
                      child: LyricsPanel(
                        song: _selectedSong!,
                        onClose: () => setState(() => _selectedSong = null),
                      ),
                    ),
                  ],
                );
              }

              // portrait (or lyrics closed) → stack overlay
              return Stack(
                children: [
                  _buildList(favoriteSongs),
                  if (showLyrics)
                    Positioned.fill(
                      child: LyricsPanel(
                        song: _selectedSong!,
                        onClose: () => setState(() => _selectedSong = null),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}