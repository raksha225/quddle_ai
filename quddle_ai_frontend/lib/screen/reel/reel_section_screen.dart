import 'package:flutter/material.dart';
import 'package:quddle_ai_frontend/screen/reel/profile_screen.dart';
import 'package:quddle_ai_frontend/screen/reel/reel_player_item.dart';
import 'package:quddle_ai_frontend/screen/reel/reel_screen.dart';
import '../../services/reels_service.dart';
import '../../utils/routes.dart';
import '../../utils/constants/colors.dart';

class ReelSectionScreen extends StatefulWidget {
  final List<dynamic> videos;
  final List<dynamic> myReels;
  final bool showReelTab;

  const ReelSectionScreen({super.key, required this.videos, required this.myReels, required this.showReelTab});

  @override
  State<ReelSectionScreen> createState() => _ReelSectionScreenState();
}

class _ReelSectionScreenState extends State<ReelSectionScreen> {
  late bool _showReelTab; // true: all reels, false: profile (my reels)
  List<dynamic> videos = [];
  List<dynamic> myReels = [];

  @override
  void initState() {
    super.initState();
    _showReelTab = widget.showReelTab;
    _loadReels();
  }

  Future<void> _loadReels() async {
    try {
      List<dynamic> _allReelsResponse = await ReelsService.listAllReels();
      List<dynamic> _myReelsResponse = await ReelsService.listMyReels();

      List<dynamic> _allReels = [];
      List<dynamic> _myReels = [];

      const oldDomain = 'quddle-ai-reel-upload-process-videos.s3.ap-south-1.amazonaws.com';
      const newDomain = 'db1e7qdc0cu2m.cloudfront.net';

// Update _allReels
      for (final reel in _allReelsResponse) {
        final updatedReel = Map<String, dynamic>.from(reel);
        updatedReel['s3_serve_url'] = updatedReel['s3_serve_url']?.replaceAll(oldDomain, newDomain);
        _allReels.add(updatedReel);
      }

// Update _myReels
      for (final reel in _myReelsResponse) {
        final updatedReel = Map<String, dynamic>.from(reel);
        updatedReel['s3_serve_url'] = updatedReel['s3_serve_url']?.replaceAll(oldDomain, newDomain);
        _myReels.add(updatedReel);
      }

      if (!mounted) return;

      setState(() {
        videos = _allReels;
        myReels = _myReels;
      });
    } catch (e) {
      if (!mounted) return;
      print("Can't load reels at Home!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content: My Reels grid
          Positioned.fill(
            child: _showReelTab
                ? ReelsScreen(videos: videos)
                : ProfileScreen(
                    loading: false,
                    reels: myReels,
                    onSelect: (reel) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReelPlayerItem(
                            video: reel,
                            videoUrl: reel['s3_serve_url'],
                            isPlaying: true,
                            onLikeChanged: (reelId, isLiked, likeCount) {
                              // Update the myReels list when like status changes
                              setState(() {
                                final index = myReels.indexWhere((r) => r['id'].toString() == reelId);
                                if (index != -1) {
                                  myReels[index]['isLikedByMe'] = isLiked;
                                  myReels[index]['likes_count'] = likeCount;
                                }
                              });
                            },
                          ),
                        ),
                      );
                    },
                    onLikeChanged: (reelId, isLiked, likeCount) {
                      // Update the myReels list when like status changes
                      setState(() {
                        final index = myReels.indexWhere((r) => r['id'].toString() == reelId);
                        if (index != -1) {
                          myReels[index]['isLikedByMe'] = isLiked;
                          myReels[index]['likes_count'] = likeCount;
                        }
                      });
                    },
                  ),
          ),

          // Back button - only show on Profile tab
          if (!_showReelTab)
            Positioned(
              top: 50,
              left: 20,
              child: GestureDetector(
                onTap: () {
                  AppRoutes.goBack(context);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ),

          // Bottom navigation bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: MyColors.navbarGradient,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reel tab with home icon
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showReelTab = true;
                        });
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home,
                            color: _showReelTab ? Colors.white : Colors.grey[600],
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reel',
                            style: TextStyle(
                              color: _showReelTab ? Colors.white : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Upload button with plus icon
                  GestureDetector(
                    onTap: () {
                      AppRoutes.navigateToUploadReel(context);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),

                  // Profile tab with person icon
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showReelTab = false;
                        });
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person,
                            color: !_showReelTab ? Colors.white : Colors.grey[600],
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Profile',
                            style: TextStyle(
                              color: !_showReelTab ? Colors.white : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
