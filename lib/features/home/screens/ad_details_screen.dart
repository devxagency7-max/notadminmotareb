import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:motareb/core/models/custom_ad_model.dart';
import 'package:url_launcher/url_launcher.dart';

class AdDetailsScreen extends StatelessWidget {
  final CustomAdModel ad;

  const AdDetailsScreen({super.key, required this.ad});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = isArabic ? ad.nameAr : ad.nameEn;
    final description = isArabic ? ad.descriptionAr : ad.descriptionEn;
    final address = isArabic ? ad.addressAr : ad.addressEn;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Slider (Hero Image)
            SizedBox(
              height: 300,
              width: double.infinity,
              child: PageView.builder(
                itemCount: ad.images.length,
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: ad.images[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 50),
                    ),
                  );
                },
              ),
            ),

            // Content
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFC107)),
                      ),
                      child: Text(
                        ad.type,
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF856404),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Title
                    Text(
                      name,
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Address
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF008695),
                          size: 20,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            address,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 30),

                    // Description
                    Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'الوصف'
                          : 'Description',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Google Maps Button
            if (ad.googleMapUrl != null)
              Expanded(
                child: _buildActionButton(
                  icon: Icons.map_outlined,
                  label: 'Map',
                  color: Colors.blue,
                  onTap: () => _launchUrl(ad.googleMapUrl!),
                ),
              ),
            if (ad.googleMapUrl != null) const SizedBox(width: 10),

            // Call Button
            if (ad.phone.isNotEmpty)
              Expanded(
                child: _buildActionButton(
                  icon: Icons.phone,
                  label: 'Call',
                  color: Colors.green,
                  onTap: () => _launchUrl('tel:${ad.phone}'),
                ),
              ),

            // WhatsApp Button (Optional, can replace one if needed or add third)
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon),
      label: Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
    );
  }
}
