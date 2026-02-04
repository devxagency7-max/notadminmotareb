import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/chat_content.dart';
import '../widgets/custom_nav_bar.dart';
import '../widgets/home_content.dart';
import '../widgets/profile_content.dart';
import '../widgets/search_content.dart';
import '../../owner/screens/add_property_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ramadan_overlay.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final authProvider = context.watch<AuthProvider>();

    return RamadanOverlay(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            // Ambient Gradient Background (Glows - Enhanced Diffusion)
            Positioned(
              top: -150,
              right: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.ambientGlow.withOpacity(
                        Theme.of(context).brightness == Brightness.dark
                            ? 0.12
                            : 0.5,
                      ),
                      AppTheme.ambientGlow.withOpacity(0),
                    ],
                    stops: const [0.2, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.ambientGlow.withOpacity(
                        Theme.of(context).brightness == Brightness.dark
                            ? 0.12
                            : 0.5,
                      ),
                      AppTheme.ambientGlow.withOpacity(0),
                    ],
                    stops: const [0.2, 1.0],
                  ),
                ),
              ),
            ),
            // Dynamic Content Body with Padding
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: 65 + 20 + MediaQuery.of(context).padding.bottom + 10,
                ),
                child: _buildBody(homeProvider.selectedIndex),
              ),
            ),

            // Bottom Navigation Bar
            Positioned(
              bottom: 20 + MediaQuery.of(context).padding.bottom,
              left: 20,
              right: 20,
              child: const CustomNavBar(),
            ),
          ],
        ),
        floatingActionButton: authProvider.isOwner
            ? Padding(
                padding: EdgeInsets.only(
                  bottom: 65 + 20 + 20 + MediaQuery.of(context).padding.bottom,
                ),
                child: Container(
                  height: 65,
                  width: 65,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF39BB5E).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddPropertyScreen(),
                        ),
                      );
                    },
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildBody(int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return HomeContent();
      case 1:
        return const SearchContent();
      case 2:
        return const ChatContent();
      case 3:
        return const ProfileContent();
      default:
        return HomeContent();
    }
  }
}
