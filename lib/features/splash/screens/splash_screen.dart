import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../home/screens/home_screen.dart';
import 'intro_screen.dart';
import '../../home/providers/home_provider.dart';

import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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
          debugPrint("Splash: User logged in, waiting for home data...");

          if (mounted) {
            final homeProvider = Provider.of<HomeProvider>(
              context,
              listen: false,
            );

            // Wait for data to load if it's still loading
            // We give it a max of 5 more seconds (on top of the 3s already waited)
            int retryCount = 0;
            while (homeProvider.isLoading && retryCount < 10) {
              await Future.delayed(const Duration(milliseconds: 500));
              retryCount++;
            }
          }

          debugPrint(
            "Splash: Home data ready or timeout, navigating to HomeScreen.",
          );
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    Localizations.localeOf(context).languageCode == 'en'
                        ? 'assets/images/logo_en.jpg'
                        : 'assets/images/logo.png',
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
          Positioned(
            bottom: 35,
            left: 0,
            right: 0,
            child: FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: () async {
                      const url = 'https://dev-x-one.vercel.app/';
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).cardTheme.color,
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(
                                    0xFF008695,
                                  ).withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                      ),
                      child: const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        backgroundImage: AssetImage('assets/images/devx.png'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    'Powered By',
                    style: GoogleFonts.cairo(
                      color: Colors.grey.shade600,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
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
