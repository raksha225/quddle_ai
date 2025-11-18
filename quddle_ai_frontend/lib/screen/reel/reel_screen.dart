import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quddle_ai_frontend/services/hls_cache_manager.dart';
import 'reel_player_item.dart';

class ReelsScreen extends StatefulWidget {
  final List<dynamic> videos;

  const ReelsScreen({super.key, required this.videos});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  final HlsCacheManager _cacheManager = HlsCacheManager();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
    _precacheNextVideos(0);
  }


  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _precacheNextVideos(int currentIndex) async {
    // Cache next 5 videos (if available)
    final start = currentIndex + 1;
    final end = (currentIndex + 6).clamp(0, widget.videos.length);

    for (int i = start; i < end; i++) {
      final url = widget.videos[i]["s3_serve_url"];
      debugPrint("Pre-caching video: $url");

      try {
        unawaited(_cacheManager.cacheVideoInBackground(url));
      } catch (e) {
        debugPrint("Failed to cache $url: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.videos.length,
        // This callback is fired when a new page is snapped to.
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
          debugPrint("Current Page: $_currentPage");
        },
        itemBuilder: (context, index) {
          final videoMap = widget.videos[index];
          final videoUrl = videoMap['s3_serve_url'];

          return ReelPlayerItem(
            video: videoMap,
            videoUrl: videoUrl,
            // Pass a boolean to tell the child widget if it is the active page.
            isPlaying: index == _currentPage,
          );
        },
      ),
    );
  }
}
