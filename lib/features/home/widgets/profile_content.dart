import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import 'package:motareb/core/providers/theme_provider.dart';
import 'package:motareb/core/providers/locale_provider.dart';
import 'package:motareb/core/extensions/loc_extension.dart';

import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/verification_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/signup_screen.dart';
import '../../favorites/screens/favorites_screen.dart';
import '../../favorites/providers/favorites_provider.dart';
import 'banner_ad_widget.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileContent extends StatefulWidget {
  const ProfileContent({super.key});

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    String userName = authProvider.userData?['name'] ?? context.loc.guest;
    String userEmail = authProvider.user?.email ?? context.loc.loginNow;
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isDark = themeProvider.isDarkMode;

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 1. Expanded Header (Gradient Background)
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 280,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: CircleAvatar(
                                    radius: 45,
                                    backgroundColor: Colors.white,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(45),
                                      child:
                                          authProvider.userData?['photoUrl'] !=
                                              null
                                          ? CachedNetworkImage(
                                              imageUrl: authProvider
                                                  .userData!['photoUrl'],
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(
                                                        Icons.person,
                                                        size: 50,
                                                        color: Colors.grey,
                                                      ),
                                            )
                                          : const Icon(
                                              Icons.person,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  ),
                                ),
                                // Badge Logic
                                if (authProvider
                                        .userData?['verificationStatus'] !=
                                    null)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: _buildStatusBadge(
                                        authProvider
                                            .userData?['verificationStatus'],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Text(
                              userName,
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              userEmail,
                              style: GoogleFonts.cairo(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Floating Stats Card
                    Positioned(
                      bottom: -40,
                      left: 20,
                      right: 20,
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 15,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            border: isDark
                                ? Border.all(color: AppTheme.darkBorder)
                                : null,
                            boxShadow: isDark
                                ? []
                                : [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF008695,
                                      ).withValues(alpha: 0.15),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                context.loc.favorites,
                                favoritesProvider.favorites.length.toString(),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: isDark
                                    ? const Color(0xFF2A3038)
                                    : Colors.grey.shade200,
                              ),
                              _buildStatItem(context.loc.reviews, '0'),
                              Container(
                                width: 1,
                                height: 40,
                                color: isDark
                                    ? const Color(0xFF2A3038)
                                    : Colors.grey.shade200,
                              ),
                              _buildStatItem(context.loc.myBookings, '0'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // 3. Verification Alert
                      if (!authProvider.isGuest)
                        FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const VerificationScreen(),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 25),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(
                                      0xFFFFC107,
                                    ).withValues(alpha: 0.1),
                                    const Color(
                                      0xFFFF9800,
                                    ).withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFFFFC107,
                                  ).withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3CD),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.verified_user_outlined,
                                      color: Color(0xFF856404),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.loc.verification,
                                          style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: const Color(0xFF856404),
                                          ),
                                        ),
                                        Text(
                                          context.loc.verificationDetail,
                                          style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            color: const Color(0xFF856404),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Color(0xFF856404),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Theme Toggle Tile
                      _buildThemeToggle(context, themeProvider),

                      // Language Toggle Tile (Expansion Style)
                      _buildLanguageToggle(context, localeProvider),

                      // 4. Menu Items
                      if (authProvider.isAuthenticated &&
                          !authProvider.isGuest) ...[
                        _buildProfileMenuItem(
                          context.loc.personalInfo,
                          Icons.person_outline,
                          delay: 100,
                          onTap: () {},
                        ),
                        _buildProfileMenuItem(
                          context.loc.myBookings,
                          Icons.calendar_today_outlined,
                          delay: 200,
                          onTap: () {},
                        ),
                        _buildProfileMenuItem(
                          context.loc.favorites,
                          Icons.favorite_border,
                          delay: 300,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FavoritesScreen(),
                              ),
                            );
                          },
                        ),
                        _buildProfileMenuItem(
                          context.loc.settings,
                          Icons.settings_outlined,
                          delay: 400,
                          onTap: () {},
                        ),
                        _buildProfileMenuItem(
                          context.loc.logout,
                          Icons.logout,
                          isDestructive: true,
                          delay: 500,
                          onTap: () async {
                            await authProvider.signOut();
                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                        ),
                      ] else ...[
                        _buildProfileMenuItem(
                          context.loc.loginAction,
                          Icons.login,
                          delay: 100,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                        ),
                        _buildProfileMenuItem(
                          context.loc.createAccount,
                          Icons.person_add_outlined,
                          delay: 150,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                        ),
                        _buildProfileMenuItem(
                          context.loc.favorites,
                          Icons.favorite_border,
                          delay: 200,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FavoritesScreen(),
                              ),
                            );
                          },
                        ),
                        _buildProfileMenuItem(
                          context.loc.settings,
                          Icons.settings_outlined,
                          delay: 300,
                          onTap: () {},
                        ),
                      ],

                      const SizedBox(height: 40),

                      // 5. Large Footer Logo
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        child: Column(
                          children: [
                            Text(
                              'Powered By',
                              style: GoogleFonts.cairo(
                                color: Colors.grey,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 15),
                            GestureDetector(
                              onTap: () async {
                                const url = 'https://dev-x-one.vercel.app/';
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url));
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).cardTheme.color,
                                  boxShadow: isDark
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF008695,
                                            ).withValues(alpha: 0.2),
                                            blurRadius: 25,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                ),
                                child: const CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: AssetImage(
                                    'assets/images/devx.png',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(top: false, child: BannerAdWidget()),
        ),
      ],
    );
  }

  Widget _buildThemeToggle(BuildContext context, ThemeProvider provider) {
    bool isDark = provider.isDarkMode;
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: () => provider.toggleTheme(),
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: isDark ? Border.all(color: AppTheme.darkBorder) : null,
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF008695).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 5,
            ),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF39BB5E).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: Colors.white,
                size: 22,
              ),
            ),
            title: Text(
              isDark ? context.loc.darkMode : context.loc.lightMode,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            trailing: Switch(
              value: isDark,
              onChanged: (val) => provider.toggleTheme(),
              activeThumbColor: const Color(0xFF16A34A),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageToggle(BuildContext context, LocaleProvider provider) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isArabic = provider.locale?.languageCode == 'ar';

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: AppTheme.darkBorder) : null,
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF008695).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 5,
            ),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF39BB5E).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: const Icon(Icons.language, color: Colors.white, size: 22),
            ),
            title: Text(
              context.loc.language,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isArabic ? 'العربية' : 'English',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF16A34A),
                ),
              ],
            ),
            children: [
              _buildLanguageItem(
                context: context,
                label: 'العربية',
                isSelected: isArabic,
                onTap: () => provider.setLocale(const Locale('ar')),
              ),
              _buildLanguageItem(
                context: context,
                label: 'English',
                isSelected: !isArabic,
                onTap: () => provider.setLocale(const Locale('en')),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageItem({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 30),
      title: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF16A34A) : Colors.grey,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20)
          : null,
    );
  }

  Widget _buildStatItem(String label, String count) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(label, style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildProfileMenuItem(
    String title,
    IconData icon, {
    bool isDestructive = false,
    int delay = 0,
    VoidCallback? onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: Duration(milliseconds: delay),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: isDark ? Border.all(color: AppTheme.darkBorder) : null,
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF008695).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 5,
            ),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isDestructive
                    ? LinearGradient(
                        colors: [
                          Colors.red.withValues(alpha: 0.1),
                          Colors.red.withValues(alpha: 0.05),
                        ],
                      )
                    : AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: (isDark || isDestructive)
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF39BB5E).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : Colors.white,
                size: 22,
              ),
            ),
            title: Text(
              title,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDestructive
                    ? Colors.red
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    if (status == 'verified') {
      return const Icon(Icons.verified, color: Colors.blue, size: 24);
    } else if (status == 'pending') {
      return const Icon(
        Icons.access_time_filled,
        color: Colors.orange,
        size: 24,
      );
    } else if (status == 'rejected') {
      return const Icon(Icons.error, color: Colors.red, size: 24);
    }
    return const SizedBox();
  }
}
