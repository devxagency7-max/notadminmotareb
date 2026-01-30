import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:motareb/core/extensions/loc_extension.dart';

import '../../../core/models/property_model.dart';
import '../../favorites/providers/favorites_provider.dart';
import 'booking_request_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/verification_screen.dart';

import '../widgets/property_gallery.dart';
import '../widgets/property_header.dart';
import '../widgets/property_features.dart';
import '../widgets/property_video.dart';
import '../widgets/property_owner.dart';
import '../widgets/property_booking.dart';
import '../widgets/property_description.dart';
import '../widgets/property_actions.dart';
import '../../../utils/guest_checker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/property_details_provider.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final Property? property;

  const PropertyDetailsScreen({super.key, this.property});

  @override
  Widget build(BuildContext context) {
    // Handling dummy data if null, purely for UI fallback or testing
    final activeProperty = property ?? _getDummyProperty();

    return ChangeNotifierProvider(
      create: (_) => PropertyDetailsProvider(property: activeProperty),
      child: const _PropertyDetailsContent(),
    );
  }

  Property _getDummyProperty() {
    return Property(
      id: 'default_1',
      title: 'شقة فندقية مودرن - المعادي',
      location: 'المعادي، القاهرة',
      price: 3500, // Changed to double
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
  }
}

class _PropertyDetailsContent extends StatefulWidget {
  const _PropertyDetailsContent();

  @override
  State<_PropertyDetailsContent> createState() =>
      _PropertyDetailsContentState();
}

class _PropertyDetailsContentState extends State<_PropertyDetailsContent> {
  final GlobalKey _unitSelectionKey = GlobalKey();
  bool _showSelectionError = false;

  void _onBookNow(BuildContext context, PropertyDetailsProvider provider) {
    if (!GuestChecker.check(context)) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isVerified =
        authProvider.userData?['verificationStatus'] == 'verified';

    if (!isVerified) {
      _showVerificationDialog(context);
      return;
    }

    if (!provider.validateBooking()) {
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
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.loc.bedsSelectionError,
                  style: GoogleFonts.cairo(),
                ),
              ),
            ],
          ),
          backgroundColor: const Color.fromARGB(255, 255, 17, 0),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Prepare selection details
    String selectionDetails = '';
    // double totalPrice = 0.0;

    if (provider.isWholeApartment) {
      selectionDetails = context.loc.fullApartment;
      // totalPrice = provider.property.price.toDouble();
    } else {
      if (provider.property.bookingMode == 'bed') {
        selectionDetails = '${provider.selectedBedCount} ${context.loc.beds}';
        // totalPrice = provider.selectedBedCount * provider.property.bedPrice;
      } else {
        // Unit mode
        selectionDetails = provider.selectionLabel ?? '';
      }
    }

    // Proceed to booking
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingRequestScreen(
          property: provider.property,
          selectionDetails: selectionDetails,
          price: provider.selectedPrice,
        ),
      ),
    );
  }

  void _showVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                context.loc.verificationRequired,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.loc.verificationRequiredDesc,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF39BB5E), Color(0xFF008695)],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF008695).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VerificationScreen(
                                topHint: context.loc.verificationTopHint,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          context.loc.verifyNow,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        context.loc.cancel,
                        style: GoogleFonts.cairo(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access Providers
    final favoritesProvider = context.watch<FavoritesProvider>();
    final detailsProvider = context.watch<PropertyDetailsProvider>();
    final property = detailsProvider.property;

    final isFavorite = favoritesProvider.isFavorite(property.id);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              PropertyGallery(
                property: property,
                onBack: () => Navigator.pop(context),
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
                            PropertyHeader(
                              property: property,
                              isFavorite: isFavorite,
                              onToggleFavorite: () {
                                if (GuestChecker.check(context)) {
                                  favoritesProvider.toggleFavorite(property);
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            PropertyFeatures(tags: property.tags),
                            PropertyVideo(videoUrl: property.videoUrl),
                            const PropertyOwner(), // Internal logic via Provider
                            PropertyBooking(
                              unitSelectionKey: _unitSelectionKey,
                              property: property,
                              selectedBedCount:
                                  detailsProvider.selectedBedCount,
                              onBedCountChanged: (count) {
                                detailsProvider.setBedCount(count, context);
                              },
                              isWholeApartment:
                                  detailsProvider.isWholeApartment,
                              selectedUnitKeys:
                                  detailsProvider.selectedUnitKeys,
                              showSelectionError: _showSelectionError,
                              onUnitSelectionChanged: (isWhole, key) {
                                setState(() {
                                  _showSelectionError = false;
                                });
                                detailsProvider.toggleUnitSelection(
                                  isWhole,
                                  key,
                                  context,
                                );
                              },
                            ),
                            PropertyDescription(
                              description: property.localizedDescription(
                                context,
                              ), // Use localized
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
          PropertyActions(
            property: property,
            selectedPrice: detailsProvider.selectedPrice,
            selectionLabel: detailsProvider.selectionLabel,
            onBook: () => _onBookNow(context, detailsProvider),
            isVerified:
                context.watch<AuthProvider>().userData?['verificationStatus'] ==
                'verified',
          ),
        ],
      ),
    );
  }
}
