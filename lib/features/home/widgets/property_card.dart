import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/models/property_model.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../../screens/property_details_screen.dart';

class PropertyCard extends StatelessWidget {
  final Property property;

  const PropertyCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    bool isFav = context.watch<FavoritesProvider>().isFavorite(property.id);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PropertyDetailsScreen(property: property),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: isDark ? Border.all(color: const Color(0xFF2A3038)) : null,
          boxShadow: isDark
              ? []
              : const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
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
                                : Image.network(
                                    property.imageUrl,
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
                                                  Icons.image_not_supported,
                                                  color: isDark
                                                      ? Colors.grey[600]
                                                      : Colors.grey,
                                                ),
                                              ),
                                            ),
                                  ))
                          : Image.memory(
                              base64Decode(property.imageUrl), // Decode Base64
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
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
                          context.read<FavoritesProvider>().toggleFavorite(
                            property,
                          );
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
                            isFav ? Icons.favorite : Icons.favorite_border,
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
                Text(
                  property.price,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
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
                  'احجز الآن',
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
