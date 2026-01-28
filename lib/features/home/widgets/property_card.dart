import 'dart:convert';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/models/property_model.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../property_details/screens/property_details_screen.dart';
import 'package:motareb/core/extensions/loc_extension.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../utils/guest_checker.dart';

class PropertyCard extends StatelessWidget {
  final Property property;

  const PropertyCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    bool isFav = context.watch<FavoritesProvider>().isFavorite(property.id);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        if (!GuestChecker.check(context)) return;
      },
      child: AbsorbPointer(
        absorbing: context.watch<AuthProvider>().isGuest,
        child: OpenContainer(
          transitionType: ContainerTransitionType.fade,
          transitionDuration: const Duration(milliseconds: 500),
          closedColor: Theme.of(context).cardTheme.color ?? Colors.white,
          closedElevation: isDark ? 0 : 4,
          openElevation: 0, // Flat during transition
          closedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isDark
                ? const BorderSide(color: Color(0xFF2A3038))
                : BorderSide.none,
          ),
          openBuilder: (context, _) =>
              PropertyDetailsScreen(property: property),
          closedBuilder: (context, openContainer) {
            return Container(
              width: 206, // Made wider as requested
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                // Border handled by Shape
                // Shadow handled by OpenContainer elevation
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Stack(
                        children: [
                          Hero(
                            tag: 'property_image_${property.id}',
                            child:
                                property.imageUrl.startsWith('http') ||
                                    property.imageUrl.startsWith('assets')
                                ? (property.imageUrl.startsWith('assets')
                                      ? Image.asset(
                                          property.imageUrl,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: property.imageUrl,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                                color: isDark
                                                    ? Colors.grey[800]
                                                    : Colors.grey.shade200,
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                                color: isDark
                                                    ? Colors.grey[800]
                                                    : Colors.grey.shade200,
                                                child: Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    color: isDark
                                                        ? Colors.grey[600]
                                                        : Colors.grey,
                                                  ),
                                                ),
                                              ),
                                        ))
                                : Image.memory(
                                    base64Decode(
                                      property.imageUrl,
                                    ), // Decode Base64
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: isDark
                                                  ? Colors.grey[800]
                                                  : Colors.grey.shade200,
                                              child: Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: isDark
                                                      ? Colors.grey[600]
                                                      : Colors.grey,
                                                ),
                                              ),
                                            ),
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                if (GuestChecker.check(context)) {
                                  context
                                      .read<FavoritesProvider>()
                                      .toggleFavorite(property);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.black.withOpacity(0.5)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 18,
                                  color: isFav ? Colors.red : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    property.title,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    property.location,
                    style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ).createShader(bounds),
                        child: Text(
                          property.price,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: Colors
                                .white, // Text color must be white for ShaderMask
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // "Book Now" Button Style
                  Container(
                    width: double.infinity,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: const Color(0xFF008695).withOpacity(0.3),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Center(
                      child: Text(
                        context.loc.bookNow,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
