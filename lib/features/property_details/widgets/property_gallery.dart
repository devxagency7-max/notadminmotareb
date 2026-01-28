import 'package:flutter/material.dart';
import '../../../../core/models/property_model.dart';
import '../../../../widgets/property_images_carousel.dart';

class PropertyGallery extends StatelessWidget {
  final Property property;
  final VoidCallback onBack;

  const PropertyGallery({
    super.key,
    required this.property,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.height * 0.4,
      pinned: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.4),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: PropertyImagesCarousel(
          imageUrls: property.images.isNotEmpty
              ? property.images
              : [property.imageUrl],
          propertyId: property.id,
        ),
      ),
    );
  }
}
