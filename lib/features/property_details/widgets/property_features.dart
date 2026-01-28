import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:motareb/core/extensions/loc_extension.dart';

class PropertyFeatures extends StatelessWidget {
  final List<String> tags;

  const PropertyFeatures({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.features,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: tags.map((tag) {
              IconData icon = Icons.star_border_rounded;
              if (tag.contains('wifi') || tag.contains('واي')) {
                icon = Icons.wifi_rounded;
              }
              if (tag.contains('تكييف') || tag.contains('ac')) {
                icon = Icons.ac_unit_rounded;
              }
              if (tag.contains('مطبخ')) icon = Icons.kitchen_rounded;
              if (tag.contains('مؤثثة') || tag.contains('فرش')) {
                icon = Icons.chair_rounded;
              }
              if (tag.contains('أسانسير')) icon = Icons.elevator_rounded;
              if (tag.contains('أمن')) icon = Icons.security_rounded;
              return _buildFeatureItem(
                context,
                icon,
                tag,
                const Color(0xFF008695),
                const Color(0xFF008695),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String label,
    Color bgColor,
    Color iconColor,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            shape: BoxShape.circle,
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}
