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

  @override
  void initState() {
    super.initState();
    _service.pause();
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  Future<bool> _confirm({required String title, required String content, String confirmLabel = 'OK'}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title  : Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child    : const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child    : Text(confirmLabel, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _confirmClearAll() async {
    if (await _confirm(
      title  : 'Clear all favourites',
      content: 'This will remove every song from your favourites. Continue?',
      confirmLabel: 'Clear',
    )) {
      await _service.clearAllFavorites();
      setState(() => _selectedSong = null);
    }
  }

  Future<void> _confirmRemove(Song song) async {
    if (await _confirm(
      title  : 'Remove from Favorites',
      content: 'Remove this song from favorites?',
      confirmLabel: 'Remove',
    )) {
      await _service.toggleFavorite(song.id, song: song);
      setState(() {
        if (_selectedSong?.id == song.id) _selectedSong = null;
      });
    }
  }

  // ── List ──────────────────────────────────────────────────────────────────
  Widget _buildList(List<Song> favoriteSongs) {
    if (favoriteSongs.isEmpty) {
      return const Center(
        child: Text('No favorites yet', style: TextStyle(color: Colors.white)),
      );
    }

    return ListView.builder(
      itemCount  : favoriteSongs.length,
      itemBuilder: (ctx, i) {
        final song = favoriteSongs[i];
        return GestureDetector(
          onLongPress: () => _confirmRemove(song),
          child: FavoriteTile(
            song      : song,
            isSelected: _selectedSong?.id == song.id,
            onTap     : () => setState(() {
              _selectedSong = _selectedSong?.id == song.id ? null : song;
            }),
          ),
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final showLyrics = _selectedSong != null;

    return ListenableBuilder(
      listenable: _service,
      builder   : (context, _) {
        final favoriteSongs = _service.favoriteSongs;

        return Scaffold(
          backgroundColor: AppStyles.primaryColor,
          appBar: AppBar(
            title          : const Text('Favorites', style: TextStyle(color: AppStyles.textColor)),
            backgroundColor: AppStyles.primaryColor,
            actions: [
              if (favoriteSongs.isNotEmpty)
                IconButton(
                  icon     : const Icon(Icons.delete_sweep, color: Colors.white),
                  tooltip  : 'Clear all favourites',
                  onPressed: _confirmClearAll,
                ),
            ],
          ),
          body: OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.landscape && showLyrics) {
                return Row(
                  children: [
                    Expanded(child: _buildList(favoriteSongs)),
                    const VerticalDivider(color: Colors.white24, width: 1),
                    Expanded(
                      child: LyricsPanel(
                        song   : _selectedSong!,
                        onClose: () => setState(() => _selectedSong = null),
                      ),
                    ),
                  ],
                );
              }

              return Stack(
                children: [
                  _buildList(favoriteSongs),
                  if (showLyrics)
                    Positioned.fill(
                      child: LyricsPanel(
                        song   : _selectedSong!,
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