import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/property_model.dart';
import '../../../screens/filter_screen.dart';

import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import 'large_property_card.dart'; // Import LargePropertyCard
// import 'native_ad_widget.dart';

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
                        'الشقاق المتاحة',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$count عقارات متاحة',
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
                        'تصفية',
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
                    'حدث خطأ في تحميل البيانات',
                    style: GoogleFonts.cairo(color: Colors.red),
                  ),
                );
              }

              final properties = snapshot.data ?? [];

              if (properties.isEmpty) {
                return Center(
                  child: Text(
                    'لا توجد عقارات متاحة حالياً',
                    style: GoogleFonts.cairo(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                // Insert an ad after every 5 items
                itemCount: properties.length + (properties.length ~/ 5),
                itemBuilder: (context, index) {
                  // Calculate if this position should be an ad
                  // Pattern: 5 items, Ad, 5 items, Ad...
                  // Indices: 0-4 (Items), 5 (Ad), 6-10 (Items), 11 (Ad)...
                  // (index + 1) % 6 == 0 means it's an Ad position
                  // if ((index + 1) % 6 == 0) {
                  //   return const Padding(
                  //     padding: EdgeInsets.only(bottom: 15),
                  //     child: NativeAdWidget(),
                  //   );
                  // }

                  // Calculate the actual property index
                  // Subtract the number of ads that appeared before this index
                  final propertyIndex = index - (index ~/ 6);

                  // Safety check
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
