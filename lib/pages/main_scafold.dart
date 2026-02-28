// lib/pages/main_scafold.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mplayer/Models/song.dart';
import 'package:mplayer/pages/favorites.dart';
import 'package:mplayer/services/audio_player_service.dart';
import 'package:mplayer/styles.dart';
import 'package:mplayer/widgets/cover_art.dart';
import 'package:mplayer/widgets/player_controls.dart';
import 'package:mplayer/widgets/progress_bar.dart';
import 'package:mplayer/widgets/song_info.dart';

class MainScafold extends StatefulWidget {
  const MainScafold({super.key});

  @override
  State<MainScafold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScafold>
    with WidgetsBindingObserver {
  final AudioPlayerService _service = AudioPlayerService();

  double _coverOpacity = 0.0;
  bool _controlsVisible = false;
  bool _pausedByLifecycle = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _coverOpacity = 1.0);
    });

    _service.playerStateStream.listen((state) {
      if (!_controlsVisible &&
          (state == PlayerState.playing || state == PlayerState.paused)) {
        setState(() => _controlsVisible = true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_service.isPlaying) {
        _service.pause();
        _pausedByLifecycle = true;
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedByLifecycle) {
        _service.resume();
        _pausedByLifecycle = false;
      }
    }
  }

  Future<void> _pickFolder() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      final songs = result.paths
          .map(
            (path) => Song(
              title: path!.split('/').last.split('.').first,
              artist: 'Unknown',
              cover: 'default_cover.jpeg',
              path: path,
            ),
          )
          .toList();

      _service.loadSongs(songs);
      await _service.playIndex(0);
    }
  }

  void _navigateToFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Favorites()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final song = _service.currentSong;

        return Scaffold(
          backgroundColor: AppStyles.primaryColor,
          appBar: _buildAppBar(),
          body: song == null
              ? _buildEmptyState()
              : _buildPlayer(song),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: Center(
        child: Image.asset(
          "assets/icon/icon.jpeg",
          height: 40,
          width: 40,
           fit: BoxFit.cover,
        ),
      ),
      title: Text("mPlayer", style: AppStyles.appBarTitleStyle),
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          icon: const Icon(Icons.folder_open, color: Colors.white),
          onPressed: _pickFolder,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No songs loaded',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildPlayer(Song song) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(height: 16),

          CoverArt(
            coverOpacity: _coverOpacity,
            imagePath: song.cover,
            isPaused: !_service.isPlaying,
          ),

          SongInfo(
            song: song,
            isFavorite: _service.isFavorite(song.id),
            onFavoriteTap: () => _service.toggleFavorite(song.id),
            onFavoriteLongPress: _navigateToFavorites,
            isVisible: _controlsVisible,
          ),

          const SizedBox(height: 16),

          ProgressBar(
            positionStream: _service.positionStream,
            durationStream: _service.durationStream,
            onSeek: _service.seek,
          ),

          PlayerControls(
            isPaused: !_service.isPlaying,
            isVisible: _controlsVisible,
            onPlayPause: _service.playPause,
            onNext: _service.next,
            onPrevious: _service.previous,
          ),
        ],
      ),
    );
  }
}