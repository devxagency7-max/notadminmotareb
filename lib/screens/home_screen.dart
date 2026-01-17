import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/home/providers/home_provider.dart';
import '../features/home/widgets/chat_content.dart';
import '../features/home/widgets/custom_nav_bar.dart';
import '../features/home/widgets/home_content.dart';
import '../features/home/widgets/profile_content.dart';
import '../features/home/widgets/search_content.dart';
import '../owner/add_property_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F9),
        body: Stack(
          children: [
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
