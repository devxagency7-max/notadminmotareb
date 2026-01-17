import 'package:animate_do/animate_do.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/models/property_model.dart'; // Import Property Model
import '../features/favorites/providers/favorites_provider.dart'; // Import Favorites Provider
import 'full_screen_image.dart';
import 'questionnaire_screen.dart';

class PropertyDetailsScreen extends StatefulWidget {
  // Add property argument
  final Property? property;

  const PropertyDetailsScreen({super.key, this.property});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final PageController _pageController = PageController();

  late Property _property;

  int _currentImageIndex = 0; // Track current image index

  @override
  void initState() {
    super.initState();
    // Use passed property or default dummy one if null (for backward compatibility during refactor)
    _property =
        widget.property ??
        Property(
          id: 'default_1',
          title: 'شقة فندقية مودرن - المعادي',
          location: 'المعادي، القاهرة',
          price: '3,500 ج.م / شهرياً',
          imageUrl: 'assets/images/intro2.png',
          type: 'شقة',
          description:
              'شقة فندقية مميزة بتصميم مودرن في قلب المعادي، تتميز بقربها الشديد من الجامعة الأمريكية والخدمات الرئيسية. الشقة مجهزة بالكامل بأحدث الأجهزة وتوفر بيئة هادئة ومثالية للمذاكرة والعمل عن بعد...',
          rating: 4.8,
          isVerified: true,
          tags: ['سكن طالبات', 'فايبر سريع', 'مؤثثة', 'مطبخ'],
          gender: 'female',
          paymentMethods: ['monthly', 'term'],
          universities: ['الجامعة الأمريكية'],
          bedsCount: 2,
          roomsCount: 1,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Watch FavoritesProvider
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isFavorite = favoritesProvider.isFavorite(_property.id);

    // Calculate total images
    final int totalImages = _property.images.isNotEmpty
        ? _property.images.length
        : 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Scrollable Content
            CustomScrollView(
              slivers: [
                // App Bar + Carousel
                SliverAppBar(
                  expandedHeight: MediaQuery.of(context).size.height * 0.4,
                  pinned: true,
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  actions: [
                    // Image Counter Badge
                    Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          '${_currentImageIndex + 1} / $totalImages',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: totalImages,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            // Use property images if available, otherwise default/fallback
                            final String imageSource =
                                (_property.images.isNotEmpty &&
                                    index < _property.images.length)
                                ? _property.images[index]
                                : _property.imageUrl; // Fallback to main image

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      // Ensure we have a valid list of images
                                      final List<String> galleryImages =
                                          _property.images.isNotEmpty
                                          ? _property.images
                                          : [_property.imageUrl];

                                      return FullScreenImage(
                                        images: galleryImages,
                                        initialIndex: index,
                                        baseHeroTag:
                                            'property_image_${_property.id}',
                                      );
                                    },
                                  ),
                                );
                              },
                              child: Hero(
                                tag: index == 0
                                    ? 'property_image_${_property.id}'
                                    : 'property_image_${_property.id}_$index', // Match Home tag for first image
                                child:
                                    imageSource.startsWith('http') ||
                                        imageSource.startsWith('assets')
                                    ? (imageSource.startsWith('assets')
                                          ? Image.asset(
                                              imageSource,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.network(
                                              imageSource,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(Icons.error),
                                            ))
                                    : Image.memory(
                                        base64Decode(imageSource),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.error),
                                      ),
                              ),
                            );
                          },
                        ),
                        // Gradient Overlay for readability
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
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Page Indicator
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: AnimatedSmoothIndicator(
                            activeIndex:
                                _currentImageIndex %
                                (totalImages > 5 ? 5 : totalImages),
                            count: totalImages > 5 ? 5 : totalImages,
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

                        // View Gallery Button
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    final List<String> galleryImages =
                                        _property.images.isNotEmpty
                                        ? _property.images
                                        : [_property.imageUrl];

                                    return FullScreenImage(
                                      images: galleryImages,
                                      initialIndex: _currentImageIndex,
                                      baseHeroTag:
                                          'property_image_${_property.id}',
                                    );
                                  },
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.grid_view_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'عرض الصور',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // White Body Container
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        transform: Matrix4.translationValues(0, -20, 0),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 45, 20, 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title and Rating
                              FadeInUp(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _property.title,
                                            style: GoogleFonts.cairo(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              height: 1.2,
                                            ),
                                          ),
                                          if (_property.featuredLabel != null &&
                                              _property
                                                  .featuredLabel!
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF39BB5E),
                                                    Color(0xFF008695),
                                                  ],
                                                  begin: Alignment.centerRight,
                                                  end: Alignment.centerLeft,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFF008695,
                                                    ).withOpacity(0.2),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                _property.featuredLabel!,
                                                style: GoogleFonts.cairo(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF008695,
                                                  ).withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.location_on_rounded,
                                                  size: 18,
                                                  color: Color(0xFF008695),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  _property.governorate != null
                                                      ? '${_property.governorate} - ${_property.location}'
                                                      : _property.location,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Favorite Button Restructured
                                    Container(
                                      margin: const EdgeInsets.only(
                                        right: 10,
                                      ), // Add some spacing
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2555,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          isFavorite
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          color: isFavorite
                                              ? Colors.red
                                              : const Color(0xFF008695),
                                          size: 28,
                                        ),
                                        onPressed: () {
                                          favoritesProvider.toggleFavorite(
                                            _property,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // --- Features Section (New Position) ---
                              if (_property.tags.isNotEmpty)
                                FadeInUp(
                                  delay: const Duration(milliseconds: 100),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'المميزات',
                                        style: GoogleFonts.cairo(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      Wrap(
                                        spacing: 15,
                                        runSpacing: 15,
                                        children: _property.tags.map((tag) {
                                          IconData icon =
                                              Icons.star_border_rounded;
                                          if (tag.contains('wifi') ||
                                              tag.contains('واي'))
                                            icon = Icons.wifi_rounded;
                                          if (tag.contains('تكييف') ||
                                              tag.contains('ac'))
                                            icon = Icons.ac_unit_rounded;
                                          if (tag.contains('مطبخ'))
                                            icon = Icons.kitchen_rounded;
                                          if (tag.contains('مؤثثة') ||
                                              tag.contains('فرش'))
                                            icon = Icons.chair_rounded;
                                          if (tag.contains('أسانسير'))
                                            icon = Icons.elevator_rounded;
                                          if (tag.contains('أمن'))
                                            icon = Icons.security_rounded;

                                          return _buildFeatureItem(
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
                                ),

                              // --- Contact Us Expandable Card ---
                              FadeInUp(
                                delay: const Duration(milliseconds: 200),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 25),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color.fromARGB(
                                          255,
                                          95,
                                          101,
                                          101,
                                        ).withOpacity(0.25),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent,
                                    ),
                                    child: ExpansionTile(
                                      tilePadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      // RTL: Leading is Right -> Phone Icon
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF39BB5E),
                                              Color(0xFF008695),
                                            ],
                                            begin: Alignment.centerRight,
                                            end: Alignment.centerLeft,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.phone_in_talk_rounded,
                                          color: Colors.white,
                                          size: 25,
                                        ),
                                      ),
                                      title: ShaderMask(
                                        shaderCallback: (bounds) {
                                          return const LinearGradient(
                                            colors: [
                                              Color(0xFF39BB5E),
                                              Color(0xFF008695),
                                            ],
                                            begin: Alignment.centerRight,
                                            end: Alignment.centerLeft,
                                          ).createShader(bounds);
                                        },
                                        child: Text(
                                          'تواصل معنا',
                                          style: GoogleFonts.cairo(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      // RTL: Trailing is Left -> Arrow
                                      trailing: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Color(0xFF008695),
                                        size: 28,
                                      ),
                                      children: [
                                        _buildContactNumberItem(
                                          '+201113927464',
                                        ),
                                        _buildContactNumberItem(
                                          '+201026064819',
                                        ),
                                        _buildContactNumberItem(
                                          '+201011335761',
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // --- Description Section (New Position) ---
                              if (_property.description != null &&
                                  _property.description!.isNotEmpty)
                                FadeInUp(
                                  delay: const Duration(milliseconds: 300),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'عن المكان',
                                        style: GoogleFonts.cairo(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          _property.description!,
                                          style: GoogleFonts.cairo(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                            height: 1.7,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                    ],
                                  ),
                                ),

                              // --- Unit Details Table ---
                              FadeInUp(
                                delay: const Duration(milliseconds: 400),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 25),
                                  padding: const EdgeInsets.all(
                                    15,
                                  ), // Increased padding
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      // Row 1: Unit Type | Rooms | Beds
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          // Unit Type
                                          Expanded(
                                            child: Column(
                                              children: [
                                                Text(
                                                  'نوع الوحدة',
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  _property.type.isNotEmpty
                                                      ? _property.type
                                                      : '-',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(
                                                      0xFF008695,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            height: 30,
                                            width: 1,
                                            color: Colors.grey.shade300,
                                          ),
                                          // Rooms Count
                                          Expanded(
                                            child: Column(
                                              children: [
                                                Text(
                                                  'عدد الغرف',
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  _property.roomsCount > 0
                                                      ? '${_property.roomsCount}'
                                                      : '-',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(
                                                      0xFF008695,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            height: 30,
                                            width: 1,
                                            color: Colors.grey.shade300,
                                          ),
                                          // Beds Count
                                          Expanded(
                                            child: Column(
                                              children: [
                                                Text(
                                                  'عدد الغرف',
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  _property.bedsCount > 0
                                                      ? '${_property.bedsCount}'
                                                      : '-',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(
                                                      0xFF008695,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      Divider(
                                        height: 1,
                                        color: Colors.grey.shade200,
                                      ),
                                      const SizedBox(height: 15),
                                      // Row 2: Housing Type | Payment Method
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          // Housing Type
                                          Expanded(
                                            child: Column(
                                              children: [
                                                Text(
                                                  'نوع السكن',
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  _property.gender == 'male'
                                                      ? 'سكن شباب'
                                                      : (_property.gender ==
                                                                'female'
                                                            ? 'سكن بنات'
                                                            : 'عائلي'),
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(
                                                      0xFF008695,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            height: 30,
                                            width: 1,
                                            color: Colors.grey.shade300,
                                          ),
                                          // Payment Method
                                          Expanded(
                                            child: Column(
                                              children: [
                                                Text(
                                                  'طريقة الدفع',
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  _property
                                                          .paymentMethods
                                                          .isNotEmpty
                                                      ? (_property
                                                                    .paymentMethods
                                                                    .first ==
                                                                'monthly'
                                                            ? 'شهري'
                                                            : _property
                                                                      .paymentMethods
                                                                      .first ==
                                                                  'term'
                                                            ? 'ترم'
                                                            : 'سنوي')
                                                      : '-',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(
                                                      0xFF008695,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // --- Universities ---
                              if (_property.universities.isNotEmpty)
                                FadeInUp(
                                  delay: const Duration(milliseconds: 500),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'جامعات قريبة',
                                        style: GoogleFonts.cairo(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: _property.universities.map((
                                          uni,
                                        ) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.teal.withOpacity(
                                                  0.2,
                                                ),
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.teal
                                                      .withOpacity(0.05),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              uni,
                                              style: GoogleFonts.cairo(
                                                color: Colors.teal.shade700,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 25),
                                    ],
                                  ),
                                ),

                              // --- Rules Section ---
                              if (_property.rules.isNotEmpty)
                                FadeInUp(
                                  delay: const Duration(milliseconds: 600),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'قواعد السكن',
                                        style: GoogleFonts.cairo(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      ..._property.rules.map((rule) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: _buildRuleItem(
                                            Icons.rule,
                                            rule,
                                            '',
                                            Colors.indigo,
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              // NO MAP WIDGET HERE
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Bottom Action Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'السعر',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        if (_property.discountPrice != null) ...[
                          Text(
                            '${_property.discountPrice} ج.م',
                            style: GoogleFonts.cairo(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF008695),
                            ),
                          ),
                          Text(
                            _property.price,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                        ] else
                          Text(
                            _property.price,
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF008695),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF008695).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QuestionnaireScreen(),
                            ),
                          );
                        },
                        child: Center(
                          child: Text(
                            'احجز الآن',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
    );
  }

  Widget _buildFeatureItem(
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
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
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
          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRuleItem(
    IconData icon,
    String title,
    String subTitle,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subTitle,
                  style: GoogleFonts.cairo(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactNumberItem(String number) {
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
            bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
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
                color: Colors.black87,
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
