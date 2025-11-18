import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../home/home_screen.dart';
import '../../utils/helpers/storage.dart';
import '../../utils/routes.dart';
import '../../bloc/Profile/profile_bloc.dart';
import '../../bloc/Profile/profile_event.dart';
import '../../bloc/Profile/profile_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  _initializeApp() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    final token = await SecureStorage.readToken();
    
    
    if (token != null && token.isNotEmpty) {
      // User is logged in - load profile data in background
      final profileBloc = context.read<ProfileBloc>();
      profileBloc.add(const LoadProfileEvent());
      
      // Wait for profile to load (with timeout)
      // This ensures profile is ready when user navigates to profile screen
      await Future.any([
        _waitForProfileLoad(profileBloc),
        Future.delayed(const Duration(seconds: 2)), // Max 2 seconds wait
      ]);
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // Navigate to initial screen instead of login
      AppRoutes.navigateToInitial(context);
    }
  }

  Future<void> _waitForProfileLoad(ProfileBloc profileBloc) async {
    // Listen to profile state changes
    await for (final state in profileBloc.stream) {
      if (state is ProfileLoaded || state is ProfileError) {
        break; // Profile loaded or error occurred, we can proceed
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFFFACC70), // Center color
              Color(0xFFF09A3E), // Corner color
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/quddle_logo_gif.gif',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

