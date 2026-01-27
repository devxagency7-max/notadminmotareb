import 'package:cloud_firestore/cloud_firestore.dart';

class CustomAdModel {
  final String id;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String addressAr;
  final String addressEn;
  final String type;
  final String phone;
  final String whatsapp;
  final String? googleMapUrl;
  final List<String> images;
  final bool isActive;
  final DateTime createdAt;

  CustomAdModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.addressAr,
    required this.addressEn,
    required this.type,
    required this.phone,
    required this.whatsapp,
    this.googleMapUrl,
    required this.images,
    required this.isActive,
    required this.createdAt,
  });

  factory CustomAdModel.fromMap(Map<String, dynamic> map) {
    return CustomAdModel(
      id: map['id'] ?? '',
      nameAr: map['nameAr'] ?? '',
      nameEn: map['nameEn'] ?? '',
      descriptionAr: map['descriptionAr'] ?? '',
      descriptionEn: map['descriptionEn'] ?? '',
      addressAr: map['addressAr'] ?? '',
      addressEn: map['addressEn'] ?? '',
      type: map['type'] ?? '',
      phone: map['phone'] ?? '',
      whatsapp: map['whatsapp'] ?? '',
      googleMapUrl: map['googleMapUrl'],
      images: List<String>.from(map['images'] ?? []),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
