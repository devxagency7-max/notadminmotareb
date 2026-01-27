import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/custom_ad_model.dart';
import 'dart:math';

class CustomAdService {
  static final CustomAdService _instance = CustomAdService._internal();
  factory CustomAdService() => _instance;
  CustomAdService._internal();

  List<CustomAdModel> _activeAds = [];
  bool _isLoading = false;

  List<CustomAdModel> get activeAds => _activeAds;

  Future<void> fetchActiveAds() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ads')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      _activeAds = snapshot.docs
          .map((doc) => CustomAdModel.fromMap(doc.data()))
          .toList();

      debugPrint('✅ CustomAdService: Fetched ${_activeAds.length} active ads');
    } catch (e) {
      debugPrint('❌ CustomAdService Error: $e');
    } finally {
      _isLoading = false;
    }
  }

  CustomAdModel? getRandomAd() {
    if (_activeAds.isEmpty) return null;
    return _activeAds[Random().nextInt(_activeAds.length)];
  }
}
