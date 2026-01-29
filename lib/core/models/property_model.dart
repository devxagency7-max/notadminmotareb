import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:motareb/core/extensions/loc_extension.dart';

class Property {
  final String id;
  final String title;
  final String titleEn; // Added
  final String location;
  final String locationEn; // Added
  final double price; // Changed to double
  final String imageUrl;
  final String type; // e.g., 'غرفة مفردة'
  final bool isVerified;
  final bool isNew;
  final double rating;
  final List<String> tags; // e.g., ['1 شخص', 'ممنوع التدخين']
  final List<String> rules;
  final String? featuredLabel;
  final String? featuredLabelEn; // Added
  final double? discountPrice;

  // Booking Modes
  final String bookingMode; // 'unit' or 'bed'
  final bool isFullApartmentBooking;
  final int totalBeds;
  final int apartmentRoomsCount;
  final double bedPrice;
  final String? generalRoomType;
  final String? agentName;
  final String? description;
  final String? descriptionEn; // Added
  final String? governorate;
  final String? gender;
  final List<String> paymentMethods;
  final List<String> universities;
  final int bedsCount;
  final int roomsCount;
  final int bathroomsCount;
  final List<String> images;

  final String? videoUrl;
  final List<Map<String, dynamic>> rooms;

  // Helpers
  bool get hasAC => tags.contains('ac') || tags.contains('تكييف');

  Property({
    required this.id,
    required this.title,
    this.titleEn = '',
    required this.location,
    this.locationEn = '',
    required this.price,
    required this.imageUrl,
    required this.type,
    this.isVerified = false,
    this.isNew = false,
    this.rating = 0.0,
    this.tags = const [],
    this.rules = const [],
    this.featuredLabel,
    this.featuredLabelEn,
    this.discountPrice,
    this.agentName,
    this.description,
    this.descriptionEn,
    this.governorate,
    this.gender,
    this.paymentMethods = const [],
    this.universities = const [],
    this.bedsCount = 0,
    this.roomsCount = 0,
    this.bathroomsCount = 1,
    this.images = const [],
    this.videoUrl,
    this.rooms = const [],
    this.bookingMode = 'unit',
    this.isFullApartmentBooking = false,
    this.totalBeds = 0,
    this.apartmentRoomsCount = 0,
    this.bedPrice = 0.0,
    this.generalRoomType,
  });

  factory Property.fromMap(Map<String, dynamic> map, String documentId) {
    return Property(
      id: documentId,
      title: map['title'] ?? '',
      titleEn: map['titleEn'] ?? map['title'] ?? '',
      location: map['location'] ?? '',
      locationEn: map['locationEn'] ?? map['location'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      discountPrice: (map['discountPrice'] as num?)?.toDouble(),
      imageUrl: (map['images'] as List<dynamic>?)?.isNotEmpty == true
          ? (map['images'] as List<dynamic>).first.toString()
          : '',
      type: map['isBed'] == true
          ? 'سرير'
          : map['isRoom'] == true
          ? 'غرفة'
          : 'شقة',
      isVerified: map['isVerified'] ?? false,
      isNew: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate().isAfter(
              DateTime.now().subtract(const Duration(days: 7)),
            )
          : false,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      tags:
          (map['amenities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      rules:
          (map['rules'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      featuredLabel: map['featuredLabel'],
      featuredLabelEn: map['featuredLabelEn'],
      agentName: map['agentName'],
      description: map['description'],
      descriptionEn: map['descriptionEn'],
      governorate: map['governorate'],
      gender: map['gender'],
      paymentMethods:
          (map['paymentMethods'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      universities:
          (map['universities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      bedsCount: (map['bedsCount'] as num?)?.toInt() ?? 0,
      roomsCount: (map['roomsCount'] as num?)?.toInt() ?? 0,
      bathroomsCount: (map['bathroomsCount'] as num?)?.toInt() ?? 1,
      images:
          (map['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      videoUrl: map['videoUrl'],
      rooms:
          (map['rooms'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      bookingMode: map['bookingMode'] ?? 'unit',
      isFullApartmentBooking: map['isFullApartmentBooking'] ?? false,
      totalBeds: (map['totalBeds'] as num?)?.toInt() ?? 0,
      apartmentRoomsCount: (map['apartmentRoomsCount'] as num?)?.toInt() ?? 0,
      bedPrice: (map['bedPrice'] as num?)?.toDouble() ?? 0.0,
      generalRoomType: map['generalRoomType'],
    );
  }

  // Helpers for Localization
  String localizedTitle(BuildContext context) {
    return context.isAr ? title : (titleEn.isNotEmpty ? titleEn : title);
  }

  String localizedLocation(BuildContext context) {
    return context.isAr
        ? location
        : (locationEn.isNotEmpty ? locationEn : location);
  }

  String localizedDescription(BuildContext context) {
    return context.isAr
        ? (description ?? '')
        : (descriptionEn != null && descriptionEn!.isNotEmpty
              ? descriptionEn!
              : description ?? '');
  }

  String localizedFeaturedLabel(BuildContext context) {
    return context.isAr
        ? (featuredLabel ?? '')
        : (featuredLabelEn != null && featuredLabelEn!.isNotEmpty
              ? featuredLabelEn!
              : featuredLabel ?? '');
  }

  String localizedType(BuildContext context) {
    // Basic mapping for type if strictly defined.
    // Assuming 'type' is stored in Arabic ('سرير', 'غرفة', 'شقة')
    if (context.isAr) return type;
    if (type == 'سرير') return 'Bed';
    if (type == 'غرفة') return 'Room';
    if (type == 'شقة') return 'Apartment';
    return type;
  }
}
