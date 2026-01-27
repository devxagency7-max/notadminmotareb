import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/property_model.dart';
import '../../../screens/filter_screen.dart';

import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import 'large_property_card.dart'; // Import LargePropertyCard
import 'native_ad_widget.dart';
import 'package:motareb/core/extensions/loc_extension.dart';

class SearchContent extends StatelessWidget {
  const SearchContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header - Fixed at top
        Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder<List<Property>>(
                stream: context.read<HomeProvider>().propertiesStream,
                builder: (context, snapshot) {
                  final count = snapshot.data?.length ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.loc.availableApartments,
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        context.loc.propertiesCount(count),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  );
                },
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          FilterScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            const begin = Offset(0.0, 1.0);
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
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF39BB5E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tune,
                        size: 16,
                        color: Color(0xFF39BB5E),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        context.loc.filter,
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF39BB5E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF39BB5E),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '3',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 10,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: StreamBuilder<List<Property>>(
            stream: context.read<HomeProvider>().propertiesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    context.loc.errorLoadingData,
                    style: GoogleFonts.cairo(color: Colors.red),
                  ),
                );
              }

              final properties = snapshot.data ?? [];

              if (properties.isEmpty) {
                return Center(
                  child: Text(
                    context.loc.noPropertiesAvailable,
                    style: GoogleFonts.cairo(color: Colors.grey),
                  ),
                );
              }

              // Calculate total items including ads
              // Ad every 3 items
              // Pattern: P1, P2, P3, Ad, P4, P5, P6, Ad...
              final totalItems = properties.length + (properties.length ~/ 3);

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: totalItems,
                itemBuilder: (context, index) {
                  // Ad position: Every 4th item (index 3, 7, 11...)
                  if ((index + 1) % 4 == 0) {
                    return const NativeAdWidget(factoryId: 'listTileMedium');
                  }

                  // Calculate actual property index
                  final propertyIndex = index - (index ~/ 4);

                  if (propertyIndex >= properties.length) {
                    return const SizedBox.shrink();
                  }

                  return LargePropertyCard(property: properties[propertyIndex]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
