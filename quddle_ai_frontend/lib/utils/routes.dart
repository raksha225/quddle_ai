import 'package:flutter/material.dart';
import 'package:quddle_ai_frontend/screen/reel/reel_section_screen.dart';
import '../screen/home/home_screen.dart';
import '../screen/auth/login_screen.dart';
import '../screen/auth/signup_screen.dart';
import '../screen/splash_screen/splash_screen.dart';
import '../screen/reel/upload_reel.dart';
import '../screen/classifieds/classifieds_list_screen.dart';
import '../screen/wallet/wallet_screen.dart';

// import '../screen/reel/video_player_screen.dart'; // For ReelPlaybackRegistry
import '../screen/store/store_welcome_screen.dart';
import '../screen/store/buyer/store_buyer_screen.dart';
import '../screen/home/Profile_home_screen.dart';
import '../screen/home/notification_screen.dart';
// import '../screen/chat/chatbot_screen.dart';
import '../screen/home/Home_search.dart';
import '../screen/home/initial_screen.dart';
import '../screen/advertiser/advertiser_dashboard_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String initial = '/initial';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String reelHome = '/reel-home';
  static const String uploadReel = '/upload-reel';
  static const String storeWelcome = '/store-welcome';
  static const String storeBuyer = '/store-buyer';
  static const String profileHome = '/profile-home';
  static const String notifications = '/notifications';
  static const String music = '/music';
  static const String chatbot = '/chatbot';
  static const String homeSearch = '/home-search';
  static const String advertiserDashboardScreen = '/advertiser-dashboard-screen';
  static const String classifieds = '/classifieds';
  static const String wallet = '/wallet';
  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case initial:
        return MaterialPageRoute(
          builder: (_) => const InitialScreen(),
          settings: settings,
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case signup:
        return MaterialPageRoute(
          builder: (_) => const SignupScreen(),
          settings: settings,
        );

      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );

      case reelHome:
        final args = settings.arguments as Map<String, dynamic>?;
        final bool showReelTab = args != null && args['showReelTab'] == true;
        List<dynamic> videos = [];
        List<dynamic> myReels = [];
        if (args != null) {
          videos = args['videos'];
          myReels = args['myReels'];
        }
        return MaterialPageRoute(
          builder: (_) => ReelSectionScreen(videos: videos, myReels: myReels, showReelTab: showReelTab),
          settings: settings,
        );

      case uploadReel:
        return MaterialPageRoute(
          builder: (_) => const UploadReelScreen(),
          settings: settings,
        );

      case storeWelcome:
        return MaterialPageRoute(
          builder: (_) => const StoreWelcomeScreen(),
          settings: settings,
        );

      case storeBuyer:
        return MaterialPageRoute(
          builder: (_) => const StoreBuyerScreen(),
          settings: settings,
        );

      case profileHome:
        return MaterialPageRoute(
          builder: (_) => const ProfileHomeScreen(),
          settings: settings,
        );

      case notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationScreen(),
          settings: settings,
        );

      case chatbot:
        return MaterialPageRoute(
          builder: (_) => const ChatbotScreen(),
          settings: settings,
        );

      case homeSearch:
        return MaterialPageRoute(
          builder: (_) => const HomeSearch(),
          settings: settings,
        );

      case advertiserDashboardScreen:
        return MaterialPageRoute(
          builder: (_) => const AdvertiserDashboardScreen(),
          settings: settings,
        );

      case classifieds:
        return MaterialPageRoute(
          builder: (_) => const ClassifiedsListScreen(),
          settings: settings,
        );

      case wallet:
        return MaterialPageRoute(
          builder: (_) => const WalletScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
    }
  }

// Navigation helper methods
  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      home,
      (route) => false,
    );
  }

  static void navigateToInitial(BuildContext context) {
    Navigator.pushReplacementNamed(context, initial);
  }

  static void navigateToLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, login);
  }

  static void navigateToSignup(BuildContext context) {
    Navigator.pushReplacementNamed(context, signup);
  }

  static void navigateToReelHome(BuildContext context,
      {bool showReelTab = true, required List<dynamic> videos, required List<dynamic> myReels}) {
    Navigator.pushNamed(
      context,
      reelHome,
      arguments: {'showReelTab': showReelTab, 'videos': videos, 'myReels': myReels},
    );
  }
  static void navigateToAdvertiserDashboard(BuildContext context) {
    Navigator.pushNamed(context, advertiserDashboardScreen);
  }

  static void navigateToUploadReel(BuildContext context) {
// ReelPlaybackRegistry.pauseAll();
    Navigator.pushNamed(context, uploadReel);
  }

  static void navigateToStoreWelcome(BuildContext context) {
// ReelPlaybackRegistry.pauseAll();
    Navigator.pushNamed(context, storeWelcome);
  }

  static void navigateToStoreBuyer(BuildContext context) {
// ReelPlaybackRegistry.pauseAll();
    Navigator.pushNamed(context, storeBuyer);
  }

  static void navigateToProfileHome(BuildContext context) {
// ReelPlaybackRegistry.pauseAll();
    Navigator.pushNamed(context, profileHome);
  }

  static void navigateToNotifications(BuildContext context) {
    Navigator.pushNamed(context, notifications);
  }

  static void navigateToMusic(BuildContext context) {
// ReelPlaybackRegistry.pauseAll();
    Navigator.pushNamed(context, music);
  }

  static void navigateToChatbot(BuildContext context) {
    Navigator.pushNamed(context, chatbot);
  }

  static void goBack(BuildContext context) {
// ReelPlaybackRegistry.pauseAll();
    Navigator.pop(context);
  }
  static void navigateToHomeSearch(BuildContext context){
    Navigator.pushNamed(context, homeSearch);
  }

  static void navigateToClassifieds(BuildContext context) {
  Navigator.pushNamed(context, classifieds);
}

static void navigateToWallet(BuildContext context) {
  Navigator.pushNamed(context, wallet);
}

}
