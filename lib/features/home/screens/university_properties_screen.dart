import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/property_model.dart';
import '../widgets/large_property_card.dart';

import 'package:motareb/core/services/ad_service.dart';

class UniversityPropertiesScreen extends StatelessWidget {
  final String universityName;
  final List<Property> properties;

  const UniversityPropertiesScreen({
    super.key,
    required this.universityName,
    required this.properties,
  });

  @override
  Widget build(BuildContext context) {
    // Ad every 5 items
    // Pattern: P1, P2, P3, P4, P5, Ad, P6...
    final totalItems = properties.length + (properties.length ~/ 5);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          universityName,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: properties.isEmpty
          ? Center(
              child: Text(
                'لا توجد عقارات متاحة لهذه الجامعة حالياً',
                style: GoogleFonts.cairo(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: totalItems,
              itemBuilder: (context, index) {
                // Ad position: Every 6th slot (index 5, 11, etc.)
                if ((index + 1) % 6 == 0) {
                  return AdService().getAdWidget(
                    factoryId: 'listTileLarge',
                    height: 300, // Large card height
                  );
                }

                // Calculate actual property index
                final propertyIndex = index - (index ~/ 6);
                if (propertyIndex >= properties.length) {
                  return const SizedBox.shrink();
                }

                return LargePropertyCard(property: properties[propertyIndex]);
              },
            ),
    );
  }
}
