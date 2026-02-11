import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/property_model.dart';
import '../widgets/large_property_card.dart';
import '../widgets/add_property_card.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

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
    final bool isOwner = context.watch<AuthProvider>().isOwner;
    final int extraCount = isOwner ? 1 : 0;
    final int baseItems = properties.length + extraCount;
    final totalItems = baseItems + (baseItems ~/ 5);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          universityName,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: properties.isEmpty && !isOwner
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
                if (isOwner && index == 0) {
                  return const AddPropertyCard(
                    height: 250,
                    isHorizontal: false,
                  );
                }

                final int adjustedIndex = isOwner ? index - 1 : index;

                // Ad position: Every 6th slot (index 5, 11, etc.)
                if ((adjustedIndex + 1) % 6 == 0) {
                  return AdService().getAdWidget(
                    factoryId: 'listTileLarge',
                    height: 300, // Large card height
                  );
                }

                // Calculate actual property index
                final propertyIndex = adjustedIndex - (adjustedIndex ~/ 6);
                if (propertyIndex < 0 || propertyIndex >= properties.length) {
                  return const SizedBox.shrink();
                }

                return LargePropertyCard(property: properties[propertyIndex]);
              },
            ),
    );
  }
}
