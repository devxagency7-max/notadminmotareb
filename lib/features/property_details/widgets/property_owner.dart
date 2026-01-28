import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:motareb/core/extensions/loc_extension.dart';
import 'package:motareb/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/property_details_provider.dart';

class PropertyOwner extends StatelessWidget {
  const PropertyOwner({super.key});

  @override
  Widget build(BuildContext context) {
    // Clean Architecture: Access data from Provider
    final provider = context.watch<PropertyDetailsProvider>();
    final contactNumbers = provider.contactNumbers;
    final isLoading = provider.loadingContacts;

    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.only(bottom: 25),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(15),
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
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_in_talk_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
            title: ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(bounds),
              child: Text(
                context.loc.contactUs,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            children: [
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(15.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (contactNumbers.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Text(
                    context.loc.noNumbersAvailable,
                    style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14),
                  ),
                )
              else
                Column(
                  children: contactNumbers.map((data) {
                    return _buildContactNumberItem(context, data['number']);
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactNumberItem(BuildContext context, String number) {
    return InkWell(
      onTap: () async {
        final Uri launchUri = Uri(scheme: 'tel', path: number);
        try {
          if (await canLaunchUrl(launchUri)) {
            await launchUrl(launchUri);
          } else {
            debugPrint('Could not launch $launchUri');
          }
        } catch (e) {
          debugPrint('Error launching dialer: $e');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            // Number on the Right (RTL: First element)
            Text(
              number,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const Spacer(),
            // Icon on the Left (RTL: Last element)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF008695).withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.phone_in_talk_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
