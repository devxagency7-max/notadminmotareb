import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:motareb/core/models/custom_ad_model.dart';
import 'package:motareb/features/home/screens/ad_details_screen.dart';

enum CustomAdSize { small, medium, large }

class CustomAdWidget extends StatelessWidget {
  final CustomAdModel ad;
  final CustomAdSize size;

  const CustomAdWidget({
    super.key,
    required this.ad,
    this.size = CustomAdSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    if (size == CustomAdSize.large) {
      return _buildLargeLayout(context);
    }
    return _buildCompactLayout(context);
  }

  Widget _buildLargeLayout(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: isDark ? Border.all(color: const Color(0xFF2A3038)) : null,
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  ad.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ad.images.first,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 180,
                            color: Colors.grey[200],
                            child: const Center(child: Icon(Icons.image)),
                          ),
                        )
                      : Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(Icons.campaign, size: 50),
                        ),

                  // Sponsored Badge
                  Positioned(
                    top: 15,
                    right: 15,
                    child: _buildBadge(context, ad.type, Icons.star),
                  ),

                  // Details Button
                  Positioned(
                    top: 15,
                    left: 15,
                    child: _buildDetailsButton(context),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? ad.nameAr
                        : ad.nameEn,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF856404),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? ad.addressAr
                              : ad.addressEn,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    bool isSmall = size == CustomAdSize.small;

    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      child: Container(
        height: isSmall ? 100 : 120,
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFC107).withOpacity(0.1),
              const Color(0xFFFF9800).withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFC107).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: isSmall ? 80 : 100,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFFFF3CD),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ad.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: ad.images.first,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.broken_image),
                      )
                    : const Icon(Icons.campaign, color: Color(0xFF856404)),
              ),
            ),
            const SizedBox(width: 15),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBadge(context, ad.type, null),
                  const SizedBox(height: 5),
                  Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? ad.nameAr
                        : ad.nameEn,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF856404),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isSmall)
                    Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? ad.addressAr
                          : ad.addressEn,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: const Color(0xFF856404).withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Details Button (Side - End)
            InkWell(
              onTap: () => _navigateToDetails(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF856404), Color(0xFFA67C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF856404).withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'التفاصيل'
                          : 'Details',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF856404),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            text.isEmpty ? 'Sponsored' : text,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
        ],
      ),
      child: Text(
        Localizations.localeOf(context).languageCode == 'ar'
            ? 'التفاصيل'
            : 'Details',
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdDetailsScreen(ad: ad)),
    );
  }
}
