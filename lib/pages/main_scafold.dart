import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:mplayer/widgets/cover_art.dart';
import 'package:mplayer/pages/favorites.dart';
import 'package:mplayer/widgets/player_controls.dart';
import 'package:mplayer/Models/song.dart';
import 'package:mplayer/widgets/song_info.dart';
import 'package:mplayer/styles.dart'; // your centralized styling

class MainScafold extends StatefulWidget {
  final List<Song> songs;

  const MainScafold({super.key, required this.songs});

  @override
  State<MainScafold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScafold> {
  int index = 0;
  bool isPaused = true;
  bool isControlsVisible = false;
  HashSet<int> favorites = HashSet();
  double _coverOpacity = 0.0;

  void next() {
    setState(() {
      index = (index + 1) % widget.songs.length;
    });
  }

  void previous() {
    setState(() {
      index = (index - 1 + widget.songs.length) % widget.songs.length;
    });
  }
void togglePause() {
  setState(() {
    isPaused = !isPaused;
    isControlsVisible = true;
  });
}

  void toggleFavorite() {
    setState(() {
      favorites.contains(index)
          ? favorites.remove(index)
          : favorites.add(index);
    });
  }

  void setControlsVisible() {
    setState(() {
      isControlsVisible = true;
    });
  }

  @override
  void initState() {
    super.initState();



    // Fade in the first time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _coverOpacity = 1.0;
      });
    });
  }



  @override
  Widget build(BuildContext context) {
    final song = widget.songs[index];

    return Scaffold(
      backgroundColor: AppStyles.primaryColor,
      appBar: AppBar(
        title: Text("mPlayer", style: AppStyles.appBarTitleStyle),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,

            children: [
              SizedBox(height: 16),
              // Cover Image
              CoverArt(
                coverOpacity: _coverOpacity,
                imagePath: widget.songs[index].cover,
                isPaused: isPaused,
              ),
              // Song title & artist
              SongInfo(
                song: song,
                isFavorite: favorites.contains(index),
                onFavoriteTap: toggleFavorite,
                onFavoriteLongPress: navigateToFavorite,
                isVisible: isControlsVisible,
              ),
              const SizedBox(height: 16),

              // Controls
              PlayerControls(
                isPaused: isPaused,
                isVisible: isControlsVisible,
                onPlayPause: togglePause,
                onNext: next,
                onPrevious: previous,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void navigateToFavorite() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            Favorites(favorites: favorites, songs: widget.songs),
      ),
    );
  }
}
