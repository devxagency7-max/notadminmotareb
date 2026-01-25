import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'screens/intro_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:provider/provider.dart';
import 'package:motareb/features/auth/providers/auth_provider.dart';
import 'package:motareb/features/home/providers/home_provider.dart';
import 'package:motareb/features/favorites/providers/favorites_provider.dart';
import 'package:motareb/features/chat/providers/chat_provider.dart';
import 'package:motareb/core/providers/theme_provider.dart';
import 'package:motareb/core/theme/app_theme.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await MobileAds.instance.initialize(); // ✅ تشغيل AdMob

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ), // Provider Added
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (context) => ChatProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) =>
              (previous ?? ChatProvider(auth))..updateAuth(auth),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Motareb',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
      locale: const Locale('ar', 'EG'),
      home: const SplashScreen(),
    );
  }
}

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
