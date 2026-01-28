import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/property_model.dart';
import '../../../core/services/properties_service.dart';

class HomeProvider extends ChangeNotifier {
  final PropertiesService _propertiesService = PropertiesService();
  StreamSubscription? _propertiesSubscription;

  // Data State
  List<Property> _allProperties = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _currentLimit = 10;
  bool _hasMore = true;

  // UI State
  int _selectedIndex = 0;
  int _selectedCategoryIndex = 0;

  // Getters
  List<Property> get allProperties => _allProperties;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  int get selectedIndex => _selectedIndex;
  int get selectedCategoryIndex => _selectedCategoryIndex;
  bool get hasMore => _hasMore;

  HomeProvider() {
    _loadProperties();
  }

  void _loadProperties() {
    _isLoading = true;
    notifyListeners();

    _subscribeToStream();
  }

  void _subscribeToStream() {
    _propertiesSubscription?.cancel();
    _propertiesSubscription = _propertiesService
        .getPropertiesStream(limit: _currentLimit)
        .listen(
          (properties) {
            _allProperties = properties;
            _isLoading = false;
            _isLoadingMore = false;

            // Simple check: if we got less than requested limit, end reached
            _hasMore = properties.length >= _currentLimit;

            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _isLoading = false;
            _isLoadingMore = false;
            notifyListeners();
          },
        );
  }

  Future<void> loadMoreProperties() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _currentLimit += 10;
    notifyListeners();

    // Re-subscribe with higher limit
    // Note: In real production with huge data, using cursors (startAfter)
    // and manual state list management is better to avoid reading N documents again.
    // But for < 1000 items, increasing limit on stream is acceptable and keeps realtime sync simpler.
    _subscribeToStream();
  }

  @override
  void dispose() {
    _propertiesSubscription?.cancel();
    super.dispose();
  }

  // Navigation
  void setIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void setCategoryIndex(int index) {
    if (_selectedCategoryIndex != index) {
      _selectedCategoryIndex = index;
      notifyListeners();
    }
  }

  // Business Logic: Filtering & Sorting

  List<Property> get featuredProperties {
    final featured = _allProperties.where((p) => p.rating >= 4.5).toList();
    return featured.isNotEmpty ? featured : _allProperties.take(5).toList();
  }

  List<Property> get recentProperties {
    return _allProperties;
  }

  List<String> get uniqueUniversities {
    final Set<String> allUniversities = {};
    for (var p in _allProperties) {
      allUniversities.addAll(p.universities);
    }
    return allUniversities.toList()..sort();
  }

  List<Property> getPropertiesForUniversity(String universityName) {
    return _allProperties
        .where((p) => p.universities.contains(universityName))
        .toList();
  }

  List<Property> get filteredByCategory {
    switch (_selectedCategoryIndex) {
      case 2: // Youth (Male)
        return _allProperties
            .where(
              (p) =>
                  p.gender == 'male' ||
                  p.tags.contains('شباب') ||
                  p.tags.contains('ذكور'),
            )
            .toList();
      case 3: // Girls (Female)
        return _allProperties
            .where(
              (p) =>
                  p.gender == 'female' ||
                  p.tags.contains('بنات') ||
                  p.tags.contains('إناث'),
            )
            .toList();
      case 4: // Bed
        return _allProperties
            .where((p) => p.type.contains('سرير') || p.type.contains('Bed'))
            .toList();
      case 5: // Room
        return _allProperties
            .where((p) => p.type.contains('غرفة') || p.type.contains('Room'))
            .toList();
      default:
        return _allProperties;
    }
  }
}
