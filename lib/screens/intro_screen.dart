import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<IntroContent> _contents = [
    IntroContent(
      image: 'assets/images/intro2.png',
      title: 'سكنك وانت مطمن',
      description: 'شقق موثوقة ومجهزة للمغتربين. احجز أونلاين بكل أمان.',
    ),
    IntroContent(
      image: 'assets/images/intro3.png',
      title: 'شوف سكنك المستقبلي\nوانت بمكانك',
      description: 'جولات افتراضية 360 تخليك تتفرج على كل زاوية قبل ما تحجز.',
    ),
    IntroContent(
      image: 'assets/images/intro.png',
      title: 'ادفع وانت مرتاح',
      description: 'طرق دفع متعددة وآمنة. ابدأ رحلتك معنا الآن.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background: Light Green Semi-Circle Top-Right
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFFE0F2F1,
                ).withOpacity(0.8), // Very Light Teal
              ),
            ),
          ),
          // Background: Light Green Semi-Circle Bottom-Left
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFFE0F2F1,
                ).withOpacity(0.8), // Very Light Teal
              ),
            ),
          ),

          // Blur Effect (Optional, kept light to smooth edges)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.white.withOpacity(0.0)),
          ),

          // Content
          Column(
            children: [
              // Skip Button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _navigateToHome,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'تخطي',
                          style: GoogleFonts.cairo(
                            color: Colors.teal[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _contents.length,
                  onPageChanged: (int index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return IntroContentWidget(content: _contents[index]);
                  },
                ),
              ),

              // Bottom Control Section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 40,
                ),
                child: Column(
                  children: [
                    // Worm Indicator
                    SmoothPageIndicator(
                      controller: _controller,
                      count: _contents.length,
                      effect: const WormEffect(
                        dotHeight: 12,
                        dotWidth: 12,
                        spacing: 16,
                        activeDotColor: Colors.teal,
                        dotColor: Color(0xFFB2DFDB),
                        type: WormType.thin,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Action Button
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF008695).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentIndex == _contents.length - 1) {
                            _navigateToHome();
                          } else {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutQuart,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          _currentIndex == _contents.length - 1
                              ? 'ابدأ رحلتك'
                              : 'التالي',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenIntro', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0); // Come from Right
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800), // Smooth 0.8s
      ),
    );
  }
}

class IntroContentWidget extends StatelessWidget {
  final IntroContent content;

  const IntroContentWidget({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Image Container
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.all(20),
            child: Image.asset(content.image, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 20),
        // Typography
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Text(
                  content.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  content.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class IntroContent {
  final String image;
  final String title;
  final String description;

  IntroContent({
    required this.image,
    required this.title,
    required this.description,
  });
}
