import 'package:cloud_firestore/cloud_firestore.dart';

class Property {
  final String id;
  final String title;
  final String location;
  final String price;
  final String imageUrl;
  final String type; // e.g., 'غرفة مفردة'
  final bool isVerified;
  final bool isNew;
  final double rating;
  final List<String> tags; // e.g., ['1 شخص', 'ممنوع التدخين']
  final List<String> rules;
  final String? featuredLabel;
  final double? discountPrice;
  final String? agentName;
  final String? description;
  final String? governorate;
  final String? gender;
  final List<String> paymentMethods;
  final List<String> universities;
  final int bedsCount;
  final int roomsCount;
  final int bathroomsCount; // Added
  final List<String> images;

  final String? videoUrl;
  final List<Map<String, dynamic>> rooms;

  // Helpers
  bool get hasAC => tags.contains('ac') || tags.contains('تكييف');

  Property({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.type,
    this.isVerified = false,
    this.isNew = false,
    this.rating = 0.0,
    this.tags = const [],
    this.rules = const [],
    this.featuredLabel,
    this.discountPrice,
    this.agentName,
    this.description,
    this.governorate,
    this.gender,
    this.paymentMethods = const [],
    this.universities = const [],
    this.bedsCount = 0,
    this.roomsCount = 0,
    this.bathroomsCount = 1, // Default 1
    this.images = const [],
    this.videoUrl,
    this.rooms = const [],
  });

  factory Property.fromMap(Map<String, dynamic> map, String documentId) {
    return Property(
      id: documentId,
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      price: '${map['price']?.toString() ?? '0'} ج.م',
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
      agentName: map['agentName'],
      description: map['description'],
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
      bathroomsCount:
          (map['bathroomsCount'] as num?)?.toInt() ?? 1, // Default 1
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
    );
  }
}
