import 'package:cloud_firestore/cloud_firestore.dart';

class Property {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final double price;
  final String location;
  final List<String> images; // Stores Base64 strings or URLs
  final List<String> amenities;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? rejectedReason;

  // New Fields based on PropertyDetailsScreen analysis
  final double rating;
  final int ratingCount;
  final String agentName;
  final String agentImage;
  final bool isStudio;
  final bool isRoom;
  final bool isBed;
  final List<String> rules;

  Property({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.images,
    required this.amenities,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.rejectedReason,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.agentName = 'أحمد العقاري', // Default placeholder
    this.agentImage = '',
    this.isStudio = false,
    this.isRoom = true, // Default
    this.isBed = false,
    this.rules = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'price': price,
      'location': location,
      'images': images,
      'amenities': amenities,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectedReason': rejectedReason,
      'rating': rating,
      'ratingCount': ratingCount,
      'agentName': agentName,
      'agentImage': agentImage,
      'isStudio': isStudio,
      'isRoom': isRoom,
      'isBed': isBed,
      'rules': rules,
    };
  }

  factory Property.fromMap(Map<String, dynamic> map, String documentId) {
    return Property(
      id: documentId,
      ownerId: map['ownerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      location: map['location'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      amenities: List<String>.from(map['amenities'] ?? []),
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      approvedAt: map['approvedAt'] != null
          ? (map['approvedAt'] as Timestamp).toDate()
          : null,
      rejectedReason: map['rejectedReason'],
      rating: (map['rating'] ?? 0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      agentName: map['agentName'] ?? 'أحمد العقاري',
      agentImage: map['agentImage'] ?? '',
      isStudio: map['isStudio'] ?? false,
      isRoom: map['isRoom'] ?? true,
      isBed: map['isBed'] ?? false,
      rules: List<String>.from(map['rules'] ?? []),
    );
  }

  factory Property.fromSnapshot(DocumentSnapshot doc) {
    return Property.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
