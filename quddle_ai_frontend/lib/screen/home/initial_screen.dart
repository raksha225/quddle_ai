import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../utils/routes.dart';
import '../../utils/constants/colors.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoSwipeTimer;

  
final List<Map<String, dynamic>> _slides = [
  {
    'title': 'Welcome to Quddle !',
    'description': 'Your all-in-one platform for social media, services, and more',
    'image': 'assets/Frame_47.png', // 47 , 43 ,51 ,52 ,56 ,53 ,54
  },
  {
    'title': 'Reels',
    'description':
        'Discover trending short videos and create engaging content with simple tools.',
    'image': 'assets/Frame_43.png',
  },
  {
    'title': 'Live Streaming',
    'description':
        'Go live instantly, interact with viewers, and build your audience community.',
    'image': 'assets/Frame_52.png',
  },
  {
    'title': 'Messages',
    'description':
        'Chat seamlessly with friends, manage conversations, and stay connected easily.',
    'image': 'assets/Frame_51.png',
  },
  {
    'title': 'Classifieds',
    'description':
        'Buy or sell items locally with trusted listings and quick communication.',
    'image': 'assets/Frame_56.png',
  },
  {
    'title': 'Coupons',
    'description':
        'Browse exclusive deals, save money daily, and enjoy exciting discount offers.',
    'image': 'assets/Frame_53.png',
  },
  {
    'title': 'Services',
    'description':
        'Find reliable local professionals and book essential services with confidence.',
    'image': 'assets/Frame_54.png',
  },
];

  @override
  void initState() {
    super.initState();
    _startAutoSwipe();
  }

  void _startAutoSwipe() {
    _autoSwipeTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage >= _slides.length) {
          nextPage = 0; // Loop back to first slide
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoSwipe() {
    _autoSwipeTimer?.cancel();
    _autoSwipeTimer = null;
  }

  void _restartAutoSwipe() {
    _stopAutoSwipe();
    _startAutoSwipe();
  }

  @override
  void dispose() {
    _stopAutoSwipe();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Header: App name and language selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // App name with logo
                    Row(
                      children: [
                        Image.asset(
                          'assets/quddle_logo.png',
                          width: 35,
                          height: 35,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Quddle',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    // Language selector
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey[400]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.language,
                            size: 18,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'English',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                // Sliding image carousel
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.35,
                      width: double.infinity,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                          // Restart auto-swipe timer when user manually swipes
                          _restartAutoSwipe();
                        },
                        itemCount: _slides.length,
                        itemBuilder: (context, index) {
                          return _buildSlide(_slides[index], index);
                        },
                      ),
                    ),
                  ),
                ),
                // Title (from current slide)
                Center(
                  child: Text(
                    _slides[_currentPage]['title'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Description (from current slide)
                Center(
                  child: Text(
                    _slides[_currentPage]['description'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Pagination dots for carousel
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildDot(index == _currentPage),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Login button
                Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Login button
                        Container(
                          decoration: BoxDecoration(
                            gradient: MyColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              AppRoutes.navigateToLogin(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: MyColors.textWhite,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                            child: const Text(
                              'Sign in',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Sign Up button
                        OutlinedButton(
                          onPressed: () {
                            AppRoutes.navigateToSignup(context);
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: MyColors.primary,
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "I'm new, sign me up",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: MyColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Legal disclaimer
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(
                          text: 'By logging in or registering, you agree to our ',
                        ),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            fontSize: 12,
                            color: MyColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // TODO: Navigate to Terms of Service
                            },
                        ),
                        const TextSpan(
                          text: ' and ',
                        ),
                        TextSpan(
                          text: 'Privacy policy',
                          style: TextStyle(
                            fontSize: 12,
                            color: MyColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // TODO: Navigate to Privacy Policy
                            },
                        ),
                        const TextSpan(
                          text: '.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: Colors.transparent,
          child: slide['image'] != null
              ? // Use actual image if available
              Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 4/3, 
                      child: Image.asset(
                        slide['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to placeholder if image fails to load
                          return Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                )
              : // Placeholder icon (reduced size)
              Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.image,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? MyColors.primary // Primary color for active
            : Colors.grey[300]!, // Light gray for inactive
        shape: BoxShape.circle,
      ),
    );
  }
}

