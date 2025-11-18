import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoTimelineBar extends StatelessWidget {
  final VideoPlayerController? controller;
  final double height;
  final Color progressColor;
  final Color backgroundColor;
  final bool allowScrubbing;

  const VideoTimelineBar({
    super.key,
    this.controller,
    this.height = 4.0,
    this.progressColor = const Color(0xFF800080),
    this.backgroundColor = Colors.white30,
    this.allowScrubbing = true,
  });

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      );
    }

    return ValueListenableBuilder(
      valueListenable: controller!,
      builder: (context, VideoPlayerValue value, child) {
        final progress = value.duration.inMilliseconds > 0 
            ? value.position.inMilliseconds / value.duration.inMilliseconds 
            : 0.0;
        
        return GestureDetector(
          onTapDown: allowScrubbing ? (details) => _handleSeek(context, details, value) : null,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: Stack(
              children: [
                // Progress bar
                Container(
                  height: height,
                  width: MediaQuery.of(context).size.width * progress,
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
                // Buffered content indicator
                if (value.buffered.isNotEmpty)
                  ...value.buffered.map((range) {
                    final bufferedProgress = range.end.inMilliseconds / value.duration.inMilliseconds;
                    return Positioned(
                      left: 0,
                      child: Container(
                        height: height,
                        width: MediaQuery.of(context).size.width * bufferedProgress,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(height / 2),
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSeek(BuildContext context, TapDownDetails details, VideoPlayerValue value) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final double seekPosition = localPosition.dx / box.size.width;
    final Duration newPosition = Duration(
      milliseconds: (seekPosition * value.duration.inMilliseconds).round(),
    );
    controller!.seekTo(newPosition);
  }
}
