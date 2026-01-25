import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../screens/full_screen_image.dart';
import 'property_video_card.dart';

class PropertyImagesCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final String? videoUrl;
  final String propertyId;

  const PropertyImagesCarousel({
    super.key,
    required this.imageUrls,
    this.videoUrl,
    required this.propertyId,
  });

  @override
  State<PropertyImagesCarousel> createState() => _PropertyImagesCarouselState();
}

class _PropertyImagesCarouselState extends State<PropertyImagesCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Media List: [...Images, Video (if exists)]
    // Actually, usually video is first or last. Let's put Video LAST as typical in real estate apps,
    // or separate? User said "Carousel item". Let's put it at the end.
    final hasVideo = widget.videoUrl != null && widget.videoUrl!.isNotEmpty;
    final totalItems = widget.imageUrls.length + (hasVideo ? 1 : 0);

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: totalItems,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            // Check if this index is the Video
            // If hasVideo is true, the last index is the video.
            // Index goes from 0 to imageUrls.length (if hasVideo).
            // So if index == imageUrls.length, it's the video.

            if (hasVideo && index == widget.imageUrls.length) {
              return PropertyVideoCard(
                videoUrl: widget.videoUrl!,
                autoPlay:
                    false, // User taps to play usually better for UX in carousel
                looping: true,
              );
            }

            // Otherwise, it's an image
            final imageUrl = widget.imageUrls[index];
            final uniqueTag = 'property_image_${widget.propertyId}_$index';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImage(
                      images: widget.imageUrls,
                      initialIndex: index,
                      baseHeroTag: 'property_image_${widget.propertyId}',
                    ),
                  ),
                );
              },
              child: Hero(
                tag: uniqueTag,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            );
          },
        ),

        // Gradient Overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              ),
            ),
          ),
        ),

        // Page Indicator
        if (totalItems > 1)
          Positioned(
            bottom: 20,
            left: 20,
            child: AnimatedSmoothIndicator(
              activeIndex: _currentIndex % (totalItems > 5 ? 5 : totalItems),
              count: totalItems > 5 ? 5 : totalItems,
              effect: const WormEffect(
                dotHeight: 8,
                dotWidth: 8,
                spacing: 8,
                activeDotColor: Colors.white,
                dotColor: Colors.white54,
                type: WormType.thin,
              ),
            ),
          ),

        // Image Counter Badge
        Positioned(
          top: 40, // Adjust based on SafeArea usually
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentIndex + 1} / $totalItems',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
