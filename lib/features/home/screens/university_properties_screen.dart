import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/property_model.dart';
import '../widgets/large_property_card.dart';

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
              itemCount: properties.length,
              itemBuilder: (context, index) {
                return LargePropertyCard(property: properties[index]);
              },
            ),
    );
  }
}
