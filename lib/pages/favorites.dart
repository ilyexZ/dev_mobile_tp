import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:mplayer/Models/song.dart';
import 'package:mplayer/styles.dart';

class Favorites extends StatefulWidget {
  const Favorites({super.key, required this.favorites, required this.songs});

  final HashSet<int> favorites;
  final List<Song> songs;

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  bool b = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.primaryColor,
      appBar: AppBar(
        title: const Text(
          'Favorites',
          style: TextStyle(color: AppStyles.textColor),
        ),
        backgroundColor: AppStyles.primaryColor,
      ),
      body: widget.favorites.isEmpty
          ? Center(
              child: AnimatedContainer(
                color: Colors.pink,
                curve: Curves.bounceOut,
                width: b ? 100 : 200,
                duration: Duration(seconds: 2),
                height: 100,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      b = !b;
                    });
                  },
                  child: new Text("Hi ILYES!"),
                ),
                alignment: Alignment(0, 0),
                margin: EdgeInsets.only(left: 20.0, bottom: 40.0, top: 50.0),
                padding: EdgeInsets.all(20.0),
                transform: Matrix4.rotationZ(0.5),
              ),
            )
          : ListView(
              children: widget.favorites.map((index) {
                final song = widget.songs[index];
                return ListTile(
                  leading: Image.asset(
                    "assets/covers/${song.cover}",
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                  title: Text(
                    song.title,
                    style: TextStyle(color: AppStyles.textColor),
                  ),
                  subtitle: Text(song.artist),
                );
              }).toList(),
            ),
    );
  }
}
