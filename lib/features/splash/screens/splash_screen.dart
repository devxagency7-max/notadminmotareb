import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../home/screens/home_screen.dart';
import 'intro_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    debugPrint("Splash: Starting navigation check...");
    // Wait for minimum splash time
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      debugPrint("Splash: Initializing SharedPreferences...");
      final prefs = await SharedPreferences.getInstance();
      final bool seenIntro = prefs.getBool('seenIntro') ?? false;
      debugPrint("Splash: seenIntro value: $seenIntro");

      if (!seenIntro) {
        debugPrint("Splash: Navigating to IntroScreen");
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(seconds: 1),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const IntroScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      } else {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Check if user is already logged in
        if (authProvider.isAuthenticated) {
          debugPrint("Splash: User logged in, navigating to HomeScreen.");
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(seconds: 1),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const HomeScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          );
        } else {
          debugPrint("Splash: No user logged in, navigating to LoginScreen.");
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(seconds: 1),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const LoginScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Splash Error: $e");
      // Fallback: navigation to Intro if everything fails
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const IntroScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/images/logo.png',
                height: 350, // Increased height
              ),
              const SizedBox(height: 50),
              // Linear Loading Indicator
              const SizedBox(
                width: 150,
                child: LinearProgressIndicator(
                  color: Colors.teal, // Primary Color
                  backgroundColor: Color(0xFF69F0AE), // Mint Green Accent
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
