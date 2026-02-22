import 'package:flutter/material.dart';
import 'package:mplayer/styles.dart';

class PlayerControls extends StatelessWidget {
  final bool isPaused;
  final bool isVisible;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const PlayerControls({
    super.key,
    required this.isPaused,
    required this.isVisible,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isVisible)
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.skip_previous),
            iconSize: AppStyles.controlIconSize,
            color: AppStyles.primaryIconColor,
          ),
        IconButton(
          onPressed: onPlayPause,
          icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
          iconSize: AppStyles.controlIconSize,
          color: AppStyles.primaryIconColor,
        ),
        if (isVisible)
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.skip_next),
            iconSize: AppStyles.controlIconSize,
            color: AppStyles.primaryIconColor,
          ),
      ],
    );
  }
}