import 'package:flutter/material.dart';
import 'package:mplayer/styles.dart';
class CoverArt extends StatefulWidget {
  final double coverOpacity;
  final String imagePath;
  final bool isPaused;

  const CoverArt({
    super.key,
    required this.coverOpacity,
    required this.imagePath,
    required this.isPaused,
  });

  @override
  State<CoverArt> createState() => _CoverArtState();
}

class _CoverArtState extends State<CoverArt>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _animation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(CoverArt oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _controller.stop();
        _controller.animateTo(0.0);
      } else {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.coverOpacity,
      duration: const Duration(seconds: 2),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (_, child) {
          return Transform.scale(
            scale: _animation.value,
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            "assets/covers/${widget.imagePath}",
            // widget.imagePath,
            height: AppStyles.coverSize,
            width: AppStyles.coverSize,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}