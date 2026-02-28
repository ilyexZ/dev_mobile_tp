// lib/widgets/progress_bar.dart
import 'package:flutter/material.dart';
import 'dart:async';

class ProgressBar extends StatefulWidget {
  final Stream<Duration> positionStream;
  final Stream<Duration?> durationStream;
  final Future<void> Function(Duration) onSeek;

  const ProgressBar({
    super.key,
    required this.positionStream,
    required this.durationStream,
    required this.onSeek,
  });

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  Duration _position = Duration.zero;
  Duration? _duration;
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  void initState() {
    super.initState();
    widget.positionStream.listen((pos) {
      if (!_isDragging) {
        setState(() => _position = pos);
      }
    });
    widget.durationStream.listen((dur) {
      setState(() => _duration = dur);
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final duration = _duration ?? Duration.zero;
    final double max = duration.inMilliseconds.toDouble();
    final double value = _position.inMilliseconds.toDouble().clamp(0, max);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbColor: Colors.orange,
              activeTrackColor: Colors.orange,
              inactiveTrackColor: Colors.grey,
            ),
            child: Slider(
              min: 0,
              max: max,
              value: _isDragging ? _dragValue : value,
              onChanged: (v) {
                setState(() {
                  _isDragging = true;
                  _dragValue = v;
                });
              },
              onChangeEnd: (v) {
                widget.onSeek(Duration(milliseconds: v.round()));
                setState(() {
                  _isDragging = false;
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_position),
                  style: const TextStyle(color: Colors.white)),
              Text(_formatDuration(duration),
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}