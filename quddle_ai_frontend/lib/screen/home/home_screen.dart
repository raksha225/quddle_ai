import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quddle_ai_frontend/utils/constants/colors.dart';
import '../../services/hls_cache_manager.dart';
import '../../services/reels_service.dart';
import '../../utils/routes.dart';
import '../../services/auth_service.dart';
import '../../utils/helpers/storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = 'User';
  bool isLoading = true;
  List<dynamic> videos = [];
  List<dynamic> myReels = [];
  bool reelsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadReels();
  }

  Future<void> _loadReels() async {
    try {
      List<dynamic> _allReelsResponse = await ReelsService.listAllReels();
      List<dynamic> _myReelsResponse = await ReelsService.listMyReels();

      List<dynamic> _allReels = [];
      List<dynamic> _myReels = [];

      const oldDomain =
          'quddle-ai-reel-upload-process-videos.s3.ap-south-1.amazonaws.com';
      const newDomain = 'db1e7qdc0cu2m.cloudfront.net';

// Update _allReels
      for (final reel in _allReelsResponse) {
        final updatedReel = Map<String, dynamic>.from(reel);
        updatedReel['s3_serve_url'] =
            updatedReel['s3_serve_url']?.replaceAll(oldDomain, newDomain);
        _allReels.add(updatedReel);
      }

// Update _myReels
      for (final reel in _myReelsResponse) {
        final updatedReel = Map<String, dynamic>.from(reel);
        updatedReel['s3_serve_url'] =
            updatedReel['s3_serve_url']?.replaceAll(oldDomain, newDomain);
        _myReels.add(updatedReel);
      }

      final topReels = _allReels.take(5);

      for (dynamic reelUrl in topReels) {
        unawaited(
            HlsCacheManager().cacheVideoInBackground(reelUrl['s3_serve_url']));
      }

      // if (!mounted) return;

      // setState(() {
      //   videos = _allReels;
      //   myReels = _myReels;
      //   reelsLoaded = true;
      //   // _loading = false;
      // });
    } catch (e) {
      if (!mounted) return;
      print("Can't load reels at Home!");
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = await SecureStorage.readUserId();
      final token = await SecureStorage.readToken();
      final refreshToken = await SecureStorage.readRefreshToken();

      // print('Stored tokens - UserId: ${userId != null}, AccessToken: ${token != null}, RefreshToken: ${refreshToken != null}');

      if (userId != null && token != null) {
        // First try to get profile with current token
        final result = await AuthService.getProfile(userId, token);

        if (result['success'] && result['user'] != null) {
          setState(() {
            userName = result['user']['name'] ?? 'User';
            isLoading = false;
          });
        } else {
          // print('Token might be expired, attempting refresh...');
          // print('result: ${result['message']}');

          // Try to refresh the token
          final refreshSuccess = await AuthService.refreshSessionIfNeeded();
          if (refreshSuccess) {
            // Try again with refreshed token
            final newToken = await SecureStorage.readToken();
            final retryResult = await AuthService.getProfile(userId, newToken);

            if (retryResult['success'] && retryResult['user'] != null) {
              setState(() {
                userName = retryResult['user']['name'] ?? 'User';
                isLoading = false;
              });
            } else {
              // print('Still failed after refresh: ${retryResult['message']}');
              setState(() {
                userName = 'User';
                isLoading = false;
              });
            }
          } else {
            // print('Token refresh failed - redirecting to login');
            // Clear stored session and redirect to login
            await SecureStorage.clear();
            if (mounted) {
              AppRoutes.navigateToLogin(context);
            }
            return;
          }
        }
      } else {
        setState(() {
          userName = 'User';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        userName = 'User';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light gray background
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: MyColors.navbarGradient,
          ),
        ),
        elevation: 0,
        toolbarHeight: 60,
        title: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          // Profile iconR
          GestureDetector(
            onTap: () {
              AppRoutes.navigateToProfileHome(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                color: Colors.grey[600],
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // App icon right after profile
          Image.asset('assets/quddle_logo.png', width: 35, height: 35),
        ]),
        actions: [
          // Search icon
          GestureDetector(
            onTap: () {
              AppRoutes.navigateToHomeSearch(context);  
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/Search_duotone@3x.png',
                width: 30,
                height: 30,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Notification icon
          GestureDetector(
            onTap: () {
              AppRoutes.navigateToNotifications(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 224, 224, 224),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: Colors.grey[600],
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal:
                MediaQuery.of(context).size.width * 0.02, // 2% of screen width
            vertical: 20.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "What will you explore today?",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w300),
              ),
              // Divider(
              //   color: Colors.grey[300],
              //   thickness: 1,
              // ),
              const SizedBox(height: 20),
              Container(
                constraints: const BoxConstraints(
                  minHeight: 220,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: Colors.black.withOpacity(0.2),
                  //     blurRadius: 8,
                  //     offset: const Offset(0, 4),
                  //   ),
                  // ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16), 
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            'Sections',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Services grid - 4 in first row, 2 in second row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          // First row - 4 services left aligned
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _buildCircularServiceButton(
                                Icons.video_library_outlined,
                                'Reels',
                                () =>
                                    _navigateToShots(context, videos, myReels),
                              ),
                              const SizedBox(width: 32),
                              _buildCircularServiceButton(
                                Icons.live_tv_outlined,
                                'Live Streaming',
                                () => _navigateToLiveStream(context),
                              ),
                              const SizedBox(width: 32),
                              _buildCircularServiceButton(
                                Icons.message_outlined,
                                'Messages',
                                () => _navigateToChatting(context),
                              ),
                              const SizedBox(width: 32),
                              _buildCircularServiceButton(
                                Icons.store_outlined,
                                'Classifieds',
                                () => _navigateToStore(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Second row - 3 services left aligned
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _buildCircularServiceButton(
                                Icons.local_offer_outlined,
                                'Coupons',
                                () => _navigateToCoupons(context),
                              ),
                              const SizedBox(width: 32),
                              _buildCircularServiceButton(
                                Icons.build_outlined,
                                'Services',
                                () => _navigateToUrbanClap(context),
                              ),
                              const SizedBox(width: 32),
                              _buildCircularServiceButton(
                                Icons.campaign_outlined,
                                'Advertiser',
                                () => _navigateToAdvertiser(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          gradient: MyColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            AppRoutes.navigateToChatbot(context);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipOval(
            child: Image.asset(
              'assets/parrot2.gif',
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to icon if GIF fails to load
                return const Icon(
                  Icons.chat_bubble,
                  color: Colors.white,
                  size: 28,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildCategoryButton(String text, Color backgroundColor, VoidCallback onTap) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: backgroundColor,
  //         borderRadius: BorderRadius.circular(12),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withOpacity(0.2),
  //             blurRadius: 8,
  //             offset: const Offset(0, 4),
  //           ),
  //         ],
  //       ),
  //       child: Center(
  //         child: Text(
  //           text,
  //           style: const TextStyle(
  //             color: Colors.white,
  //             fontSize: 24,
  //             fontWeight: FontWeight.w600,
  //           ),
  //           textAlign: TextAlign.center,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildCircularServiceButton(
      IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular icon container
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF7D017C)
                  .withOpacity(0.1), // Translucent purple
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF7D017C), // Purple icon
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          // Title
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Reserve consistent space for all buttons
          const SizedBox(height: 4),
          // Add "Coming Soon" badge for specific services
          if (title.toLowerCase().contains('live streaming') ||
              title.toLowerCase().contains('messages') ||
              // title.toLowerCase().contains('classifieds') ||
              title.toLowerCase().contains('coupons') ||
              title.toLowerCase().contains('services'))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[400]!,
                  width: 0.5,
                ),
              ),
              child: Text(
                'Coming Soon',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            const SizedBox(height: 16), // Placeholder for consistent spacing
        ],
      ),
    );
  }

  void _navigateToShots(
      BuildContext context, List<dynamic> videos, List<dynamic> myReels) {
    // if (!reelsLoaded) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Reels loading. Wait a sec!'), duration: Duration(seconds: 1)),
    //   );
    //   return;
    // }
    AppRoutes.navigateToReelHome(context, videos: videos, myReels: myReels);
  }

  void _navigateToLiveStream(BuildContext context) {
    // TODO: Implement navigation to live stream screen
    // SnackBar removed - using "Coming Soon" badge instead
  }

  void _navigateToUrbanClap(BuildContext context) {
    // TODO: Implement navigation to urban clap screen
    // SnackBar removed - using "Coming Soon" badge instead
  }

  void _navigateToStore(BuildContext context) {
  AppRoutes.navigateToClassifieds(context);
}


  void _navigateToChatting(BuildContext context) {
    // TODO: Implement navigation to chatting screen
    // SnackBar removed - using "Coming Soon" badge instead
  }

  void _navigateToCoupons(BuildContext context) {
    // TODO: Implement navigation to coupons screen
    // SnackBar removed - using "Coming Soon" badge instead
  }

  void _navigateToAdvertiser(BuildContext context) {
    AppRoutes.navigateToAdvertiserDashboard(context);
  }
}
