import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/models/property_model.dart';
import '../features/favorites/providers/favorites_provider.dart';
import '../widgets/property_images_carousel.dart';
import '../widgets/property_video_card.dart';
import 'booking_request_screen.dart';

import '../core/theme/app_theme.dart';
import 'package:motareb/core/extensions/loc_extension.dart';
import 'package:intl/intl.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final Property? property;

  const PropertyDetailsScreen({super.key, this.property});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  late Property _property;

  // State for Unit Selection
  double? _selectedPrice;
  String? _selectionLabel;

  // Selection Indices
  bool _isWholeApartment = false;
  bool _showSelectionError = false;
  final Set<String> _selectedUnitKeys =
      {}; // Keys: "r{idx}" or "r{idx}_b{bIdx}"
  final GlobalKey _unitSelectionKey = GlobalKey();

  // Booking Mode State
  int _selectedBedCount = 1;

  @override
  void initState() {
    super.initState();
    // Default dummy data if null
    _property =
        widget.property ??
        Property(
          id: 'default_1',
          title: 'شقة فندقية مودرن - المعادي',
          location: 'المعادي، القاهرة',
          price: '3500',
          imageUrl: 'https://via.placeholder.com/600',
          type: 'شقة',
          description: 'شقة فندقية مميزة بتصميم مودرن في قلب المعادي...',
          rating: 4.8,
          isVerified: true,
          tags: ['سكن طالبات', 'فايبر سريع', 'مؤثثة', 'مطبخ'],
          gender: 'female',
          paymentMethods: ['monthly', 'term'],
          universities: ['الجامعة الأمريكية'],
          bedsCount: 2,
          roomsCount: 1,
          discountPrice: null,
          bookingMode: 'unit',
          isFullApartmentBooking: false,
          totalBeds: 2,
          apartmentRoomsCount: 1,
          bedPrice: 0.0,
          generalRoomType: '',
          rooms: [
            {'type': 'Single', 'beds': 1, 'price': 2000, 'bedPrice': 2000},
            {'type': 'Double', 'beds': 2, 'price': 2000, 'bedPrice': 1000},
          ],
        );

    // Initialize based on mode
    if (_property.bookingMode == 'unit' && _property.isFullApartmentBooking) {
      _isWholeApartment = true;
    }

    // Initial Price calculation moved to didChangeDependencies to safely access context
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePrice();
  }

  void _updatePrice() {
    double base =
        _property.discountPrice ??
        double.tryParse(_property.price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0.0;

    // 1. Bed Mode Logic
    if (_property.bookingMode == 'bed') {
      _selectedPrice = _property.bedPrice * _selectedBedCount;
      _selectionLabel =
          context.loc.bed; // Using simple 'Bed' or we can add plurals later
      setState(() {});
      return;
    }

    // 2. Unit Mode - Full Apartment Only
    if (_property.isFullApartmentBooking) {
      _selectedPrice = base;
      _selectionLabel = context.loc.fullApartmentPrice;
      setState(() {});
      return;
    }

    // 3. Unit Mode - Selection Logic
    if (_isWholeApartment) {
      _selectedPrice = base;
      _selectionLabel = context.loc.fullApartmentPrice;
    } else if (_selectedUnitKeys.isNotEmpty) {
      double total = 0.0;
      for (var key in _selectedUnitKeys) {
        final parts = key.split('_');
        final roomIdx = int.parse(parts[0].substring(1));
        final room = _property.rooms[roomIdx];

        if (parts.length > 1) {
          // It's a bed: rX_bY
          total += (room['bedPrice'] as num?)?.toDouble() ?? 0.0;
        } else {
          // It's a room: rX
          total += (room['price'] as num?)?.toDouble() ?? 0.0;
        }
      }
      _selectedPrice = total;
      _selectionLabel = context.loc.totalChoices;
    } else {
      // Default state: nothing selected but show apartment price
      _selectedPrice = base;
      _selectionLabel = context.loc.apartmentPrice;
    }
    setState(() {});
  }

  void _toggleSelection(String key) {
    setState(() {
      _showSelectionError = false;
      // If currently whole apartment is selected, clear it
      if (_isWholeApartment) {
        _isWholeApartment = false;
        _selectedUnitKeys.clear();
      }

      if (_selectedUnitKeys.contains(key)) {
        _selectedUnitKeys.remove(key);
        // If everything deselected, go back to whole apartment?
        // User might prefer "Select Units" state with 0 price.
        // Let's keep it as is, or default to whole if empty.
        if (_selectedUnitKeys.isEmpty) {
          _isWholeApartment = true;
        }
      } else {
        _selectedUnitKeys.add(key);
      }
      _updatePrice();
    });
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isFavorite = favoritesProvider.isFavorite(_property.id);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.4,
                pinned: true,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.4),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: PropertyImagesCarousel(
                    imageUrls: _property.images.isNotEmpty
                        ? _property.images
                        : [_property.imageUrl],
                    propertyId: _property.id,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // White Body Container
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.only(
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
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient:
                                                  AppTheme.primaryGradient,
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
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF008695,
                                                ).withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.location_on_rounded,
                                                size: 18,
                                                color:
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? const Color(0xFF39BB5E)
                                                    : const Color(0xFF008695),
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
                                                  color: Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium?.color,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Favorite Button
                                  Container(
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardTheme.color,
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? []
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
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

                            const SizedBox(height: 20),

                            if (_property.tags.isNotEmpty)
                              FadeInUp(
                                delay: const Duration(milliseconds: 100),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.loc.features,
                                      style: GoogleFonts.cairo(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
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

                            if (_property.videoUrl != null &&
                                _property.videoUrl!.isNotEmpty)
                              FadeInUp(
                                delay: const Duration(milliseconds: 150),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.loc.propertyVideo,
                                      style: GoogleFonts.cairo(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Container(
                                      height: 250,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: PropertyVideoCard(
                                          videoUrl: _property.videoUrl!,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                  ],
                                ),
                              ),

                            FadeInUp(
                              delay: const Duration(milliseconds: 200),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 25),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardTheme.color,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                ),
                                child: Theme(
                                  data: Theme.of(
                                    context,
                                  ).copyWith(dividerColor: Colors.transparent),
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
                                      shaderCallback: (bounds) => AppTheme
                                          .primaryGradient
                                          .createShader(bounds),
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
                                      StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('contact_numbers')
                                            .orderBy(
                                              'createdAt',
                                              descending: true,
                                            )
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(15.0),
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            );
                                          }

                                          if (!snapshot.hasData ||
                                              snapshot.data!.docs.isEmpty) {
                                            return Padding(
                                              padding: const EdgeInsets.all(
                                                15.0,
                                              ),
                                              child: Text(
                                                context.loc.noNumbersAvailable,
                                                style: GoogleFonts.cairo(
                                                  color: Colors.grey,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            );
                                          }

                                          return Column(
                                            children: snapshot.data!.docs.map((
                                              doc,
                                            ) {
                                              var data =
                                                  doc.data()
                                                      as Map<String, dynamic>;
                                              return _buildContactNumberItem(
                                                data['number'],
                                              );
                                            }).toList(),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // --- UNIT SELECTION WIDGET ---
                            _buildBookingSelection(),

                            if (_property.description != null &&
                                _property.description!.isNotEmpty)
                              FadeInUp(
                                delay: const Duration(milliseconds: 300),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.loc.aboutPlace,
                                      style: GoogleFonts.cairo(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Theme.of(context).cardTheme.color
                                            : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _property.description!,
                                        style: GoogleFonts.cairo(
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.color,
                                          fontSize: 14,
                                          height: 1.7,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                  ],
                                ),
                              ),
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
                color:
                    Theme.of(context).bottomAppBarTheme.color ??
                    Theme.of(context).cardTheme.color,
                boxShadow: Theme.of(context).brightness == Brightness.dark
                    ? []
                    : [
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
                        _selectionLabel ?? context.loc.price,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${NumberFormat.decimalPattern().format(_selectedPrice ?? 0)} ${context.loc.currency}',
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFE6F4F4)
                              : const Color(0xFF008695),
                        ),
                      ),
                      if (_property.discountPrice != null)
                        Text(
                          '${_property.price}',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.grey.withOpacity(0.6),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
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
                        bool canBook = true;
                        if (_property.bookingMode == 'unit' &&
                            !_property.isFullApartmentBooking &&
                            !_isWholeApartment &&
                            _selectedUnitKeys.isEmpty) {
                          canBook = false;
                        }

                        if (!canBook) {
                          setState(() {
                            _showSelectionError = true;
                          });

                          // Scroll to unit selection section
                          if (_unitSelectionKey.currentContext != null) {
                            Scrollable.ensureVisible(
                              _unitSelectionKey.currentContext!,
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOut,
                            );
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      context.loc.bedsSelectionError,
                                      style: GoogleFonts.cairo(),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color.fromARGB(
                                255,
                                255,
                                17,
                                0,
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        // Pass details to questionnaire if needed
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BookingRequestScreen(),
                          ),
                        );
                      },
                      child: Center(
                        child: Text(
                          context.loc.bookNow,
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
    );
  }

  // --- Helpers ---
  Widget _buildBookingSelection() {
    // 1. Bed Mode UI
    if (_property.bookingMode == 'bed') {
      return FadeInUp(
        delay: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.only(bottom: 25),
          padding: const EdgeInsets.all(20),
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
            border: Border.all(color: const Color(0xFF39BB5E).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF39BB5E).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bed, color: Color(0xFF39BB5E)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.loc.bookBeds,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                context.loc.roomType(
                  _property.generalRoomType ?? context.loc.shared,
                ),
                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              // 1. Bed Mode - Styled Counter
              FadeInUp(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 25),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.loc.requestedBedsCount,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCounterButton(
                            icon: Icons.remove,
                            onPressed: _selectedBedCount > 1
                                ? () {
                                    setState(() {
                                      _selectedBedCount--;
                                      _updatePrice();
                                    });
                                  }
                                : null,
                          ),
                          Container(
                            width: 100,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Theme.of(context).canvasColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              '$_selectedBedCount',
                              style: GoogleFonts.cairo(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF008695),
                              ),
                            ),
                          ),
                          _buildCounterButton(
                            icon: Icons.add,
                            onPressed:
                                (_property.totalBeds > 0 &&
                                    _selectedBedCount < _property.totalBeds)
                                ? () {
                                    setState(() {
                                      _selectedBedCount++;
                                      _updatePrice();
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      // Availability Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value:
                              1 -
                              (_selectedBedCount /
                                  (_property.totalBeds > 0
                                      ? _property.totalBeds
                                      : 1)),
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _property.totalBeds - _selectedBedCount < 2
                                ? Colors.orange
                                : const Color(0xFF39BB5E),
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            context.loc.remainingBeds(
                              _property.totalBeds - _selectedBedCount,
                              _property.totalBeds,
                            ),
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
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
    // 2. Unit Mode - Full Apartment Fixed
    else if (_property.isFullApartmentBooking) {
      return FadeInUp(
        child: Container(
          margin: const EdgeInsets.only(bottom: 25),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF008695).withOpacity(0.08),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF008695).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF008695).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.home_work_rounded,
                      color: Color(0xFF008695),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.loc.bookApartmentFull,
                          style: GoogleFonts.cairo(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF008695),
                          ),
                        ),
                        Text(
                          context.loc.includesComponents,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Composition Summary
              Row(
                children: [
                  Expanded(
                    child: _buildCompositionCard(
                      context,
                      icon: Icons.meeting_room_rounded,
                      count: _property.rooms.length.toString(),
                      label: context.loc.rooms,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCompositionCard(
                      context,
                      icon: Icons.bed_rounded,
                      count: _property.rooms
                          .fold<int>(
                            0,
                            (sum, room) => sum + ((room['beds'] as int?) ?? 1),
                          )
                          .toString(),
                      label: context.loc.beds,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCompositionCard(
                      context,
                      icon: Icons.bathtub_outlined,
                      count: _property.bathroomsCount.toString(),
                      label: context.loc.bathrooms,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Room Types Breakdown
              Builder(
                builder: (context) {
                  final typeCounts = <String, int>{};
                  for (final room in _property.rooms) {
                    final type = room['type']?.toString() ?? 'Other';
                    typeCounts[type] = (typeCounts[type] ?? 0) + 1;
                  }

                  final arabicTypes = {
                    'Single': context.loc.single,
                    'Double': context.loc.double,
                    'Triple': context.loc.triple,
                    'Quadruple': context.loc.quadruple,
                  };

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: typeCounts.entries.map((entry) {
                      final label = arabicTypes[entry.key] ?? entry.key;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF008695).withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF008695),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${entry.value} $label',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF008695),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }
    // 3. Unit Mode - Standard Selection
    else {
      if (_property.rooms.isEmpty) return const SizedBox.shrink();
      return Column(
        children: [
          _UnitSelectionWidget(
            key: _unitSelectionKey,
            property: _property,
            isWholeApartment: _isWholeApartment,
            selectedUnitKeys: _selectedUnitKeys,
            showError: _showSelectionError,
            onSelectionChanged: (isWhole, key) {
              setState(() {
                _showSelectionError = false;
                if (isWhole) {
                  if (_isWholeApartment) {
                    _isWholeApartment = false;
                  } else {
                    _isWholeApartment = true;
                    _selectedUnitKeys.clear();
                  }
                  _updatePrice();
                } else {
                  _toggleSelection(key!);
                }
              });
            },
          ),
          const SizedBox(height: 25),
        ],
      );
    }
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

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: onPressed == null
              ? Colors.grey.shade200
              : const Color(0xFF008695).withOpacity(0.5),
        ),
        boxShadow: onPressed == null
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF008695).withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: onPressed == null ? Colors.grey : const Color(0xFF008695),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCompositionCard(
    BuildContext context, {
    required IconData icon,
    required String count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 22),
          const SizedBox(height: 5),
          Text(
            count,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF008695),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _UnitSelectionWidget extends StatelessWidget {
  final Property property;
  final bool isWholeApartment;
  final Set<String> selectedUnitKeys;
  final bool showError;
  final Function(bool isWhole, String? key) onSelectionChanged;
  final bool isReadOnly;

  const _UnitSelectionWidget({
    super.key,
    required this.property,
    required this.isWholeApartment,
    required this.selectedUnitKeys,
    this.showError = false,
    required this.onSelectionChanged,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final rooms = property.rooms;
    if (rooms.isEmpty) return const SizedBox();

    // Split rooms into rows (max 6 beds per row)
    final List<List<Map<String, dynamic>>> roomRows = [];
    List<Map<String, dynamic>> currentRow = [];
    int currentBedsInRow = 0;

    for (int i = 0; i < rooms.length; i++) {
      final room = rooms[i] as Map<String, dynamic>;
      final bedsCount = (room['beds'] as int?) ?? 1;

      if (currentBedsInRow + bedsCount > 4 && currentRow.isNotEmpty) {
        roomRows.add(currentRow);
        currentRow = [];
        currentBedsInRow = 0;
      }

      currentRow.add({...room, 'originalIndex': i});
      currentBedsInRow += bedsCount;
    }
    if (currentRow.isNotEmpty) {
      roomRows.add(currentRow);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.loc.selectNeed,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 15),

        // Header: "Whole Apartment" Option
        GestureDetector(
          onTap: () {
            if (isReadOnly) return;
            onSelectionChanged(true, null);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              gradient: isWholeApartment
                  ? const LinearGradient(
                      colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                    )
                  : null,
              color: isWholeApartment
                  ? null
                  : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: isWholeApartment
                  ? null
                  : Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1.5,
                    ),
              boxShadow: isWholeApartment
                  ? [
                      BoxShadow(
                        color: const Color(0xFF008695).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.loc.bookApartmentFull,
                  style: GoogleFonts.cairo(
                    color: isWholeApartment
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (isWholeApartment)
                  const Icon(Icons.check_circle, color: Colors.white, size: 22),
              ],
            ),
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              context.loc.selectUnitsFirst,
              style: GoogleFonts.cairo(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // Visualizer Rectangle (Now Multi-row)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: showError ? Colors.red : Theme.of(context).dividerColor,
              width: showError ? 2 : 1,
            ),
            color: showError
                ? Colors.red.withOpacity(0.05)
                : Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).cardTheme.color
                : const Color(0xFFF5F5F5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Column(
              children: roomRows.asMap().entries.map((rowEntry) {
                final rowIndex = rowEntry.key;
                final rowRooms = rowEntry.value;

                return Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: rowIndex < roomRows.length - 1
                        ? Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    children: rowRooms.asMap().entries.map((roomEntry) {
                      final roomInRowIndex = roomEntry.key;
                      final room = roomEntry.value;
                      final globalIndex = room['originalIndex'];

                      final type = room['type'];
                      final bedsCount = (room['beds'] as int?) ?? 1;
                      final roomKey = 'r$globalIndex';

                      final isRoomSelected =
                          !isWholeApartment &&
                          selectedUnitKeys.contains(roomKey);

                      return Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: roomInRowIndex < rowRooms.length - 1
                                ? Border(
                                    left: BorderSide(
                                      color: Theme.of(context).dividerColor,
                                      width: 1,
                                    ),
                                  )
                                : null,
                          ),
                          child: Column(
                            children: [
                              // Room Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[800]?.withOpacity(0.5)
                                    : Colors.grey[200],
                                width: double.infinity,
                                child: Text(
                                  type == 'Single'
                                      ? context.loc.single
                                      : (type == 'Double'
                                            ? context.loc.double
                                            : context.loc.room),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                              // Unit Area
                              Expanded(
                                child: type == 'Single'
                                    ? _buildSelectableUnit(
                                        context: context,
                                        isSelected: isRoomSelected,
                                        label: context.loc.room,
                                        onTap: () {
                                          if (isReadOnly) return;
                                          onSelectionChanged(false, roomKey);
                                        },
                                      )
                                    : Row(
                                        // Split for beds
                                        children: List.generate(bedsCount, (
                                          bedIdx,
                                        ) {
                                          final bedKey = '${roomKey}_b$bedIdx';
                                          final isBedSelected =
                                              !isWholeApartment &&
                                              selectedUnitKeys.contains(bedKey);
                                          return Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: bedIdx < bedsCount - 1
                                                    ? Border(
                                                        left: BorderSide(
                                                          color: Theme.of(
                                                            context,
                                                          ).dividerColor,
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                              child: _buildSelectableUnit(
                                                context: context,
                                                isSelected: isBedSelected,
                                                label: context.loc.bed,
                                                onTap: () {
                                                  if (isReadOnly) return;
                                                  onSelectionChanged(
                                                    false,
                                                    bedKey,
                                                  );
                                                },
                                                isSmall: true,
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableUnit({
    required BuildContext context,
    required bool isSelected,
    required String label,
    required VoidCallback onTap,
    bool isSmall = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).cardTheme.color
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Theme.of(context).dividerColor,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF008695).withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isSelected
              ? const Icon(Icons.check_circle, color: Colors.white, size: 24)
              : Text(
                  label,
                  style: GoogleFonts.cairo(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: isSmall ? 10 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
