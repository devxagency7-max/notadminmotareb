import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:motareb/core/extensions/loc_extension.dart';
import 'package:motareb/core/theme/app_theme.dart';
import '../../home/widgets/property_card.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>().favorites;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Premium Header with Gradient
          _buildHeader(context, isDark),

          Expanded(
            child: favorites.isEmpty
                ? _buildEmptyState(context)
                : _buildFavoritesGrid(favorites),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 20,
        left: 10,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF39BB5E).withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            context.loc.favorites,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48), // Spacer for balance
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                Icons.favorite_outline,
                size: 80,
                color: const Color(0xFF008695).withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              // Using context.loc.noFavorites if it fails, fallback to hardcoded
              _getNoFavoritesText(context),
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _getNoFavoritesDesc(context),
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for safety during arb generation
  String _getNoFavoritesText(BuildContext context) {
    try {
      return context.loc.noFavorites;
    } catch (_) {
      return 'المفضلة فارغة';
    }
  }

  String _getNoFavoritesDesc(BuildContext context) {
    try {
      return context.loc.noFavoritesDesc;
    } catch (_) {
      return 'استكشف العقارات وأضفها لقائمتك للرجوع إليها لاحقاً';
    }
  }

  Widget _buildFavoritesGrid(List favorites) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        return FadeInUp(
          duration: const Duration(milliseconds: 500),
          delay: Duration(milliseconds: index * 100),
          child: PropertyCard(property: favorites[index]),
        );
      },
    );
  }
}
