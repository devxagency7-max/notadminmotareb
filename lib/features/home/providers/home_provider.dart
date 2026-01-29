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
  String _searchQuery = '';
  RangeValues _priceRange = const RangeValues(0, 10000);
  List<String> _filterHousingTypes = [];
  List<String> _filterGenders = [];

  String get searchQuery => _searchQuery;
  RangeValues get priceRange => _priceRange;
  List<String> get filterHousingTypes => _filterHousingTypes;
  List<String> get filterGenders => _filterGenders;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void applyFilters({
    required RangeValues priceRange,
    required List<String> housingTypes,
    required List<String> genders,
  }) {
    _priceRange = priceRange;
    _filterHousingTypes = housingTypes;
    _filterGenders = genders;
    notifyListeners();
  }

  void resetFilters() {
    _priceRange = const RangeValues(0, 10000);
    _filterHousingTypes = [];
    _filterGenders = [];
    _searchQuery = '';
    notifyListeners();
  }

  List<Property> get filteredProperties {
    return _applyFullFilters(_allProperties);
  }

  List<Property> get featuredProperties {
    var list = _applySearchOnly(_allProperties);
    final featured = list.where((p) => p.rating >= 4.5).toList();
    return featured.isNotEmpty ? featured : list.take(5).toList();
  }

  List<Property> get recentProperties {
    return _applySearchOnly(_allProperties);
  }

  // Used for Home Screen: Only applies Text Search
  List<Property> _applySearchOnly(List<Property> properties) {
    if (_searchQuery.isEmpty) return properties;

    final query = _searchQuery.toLowerCase();
    return properties.where((p) {
      return p.title.toLowerCase().contains(query) ||
          p.location.toLowerCase().contains(query) ||
          p.universities.any((u) => u.toLowerCase().contains(query)) ||
          p.tags.any((t) => t.toLowerCase().contains(query));
    }).toList();
  }

  // Used for Search Screen: Applies Search + Advanced Filters
  List<Property> _applyFullFilters(List<Property> properties) {
    return properties.where((p) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch =
            p.title.toLowerCase().contains(query) ||
            p.location.toLowerCase().contains(query) ||
            p.universities.any((u) => u.toLowerCase().contains(query)) ||
            p.tags.any((t) => t.toLowerCase().contains(query));
        if (!matchesSearch) return false;
      }

      // 2. Price Range
      // Assuming price format is "2000 ج.م" or similar
      try {
        // Remove non-numeric characters except dot
        // String priceString = p.price.replaceAll(RegExp(r'[^0-9.]'), '');
        double price = p.price;
        if (price < _priceRange.start || price > _priceRange.end) {
          return false;
        }
      } catch (e) {
        // If parsing fails, ignore price filter or exclude? currently ignoring
      }

      // 3. Housing Type
      // 'Bed' -> 'سرير'
      // 'Apartment' -> 'شقة' (or 'شقه كامله')
      // 'Room' -> 'غرفة' (or 'متقسمه')
      if (_filterHousingTypes.isNotEmpty) {
        bool matchesType = false;
        // Check exact matches or mapped values
        // You might need to adjust these strings based on your actual data
        for (var type in _filterHousingTypes) {
          if (type == 'Bed' &&
              (p.type.contains('سرير') || p.bookingMode == 'bed'))
            matchesType = true;
          if (type == 'Apartment' &&
              (p.type.contains('شقة') || p.isFullApartmentBooking))
            matchesType = true;
          if (type == 'Room' &&
              (p.type.contains('غرفة') || p.generalRoomType != null))
            matchesType = true;
        }
        if (!matchesType) return false;
      }

      // 4. Gender
      if (_filterGenders.isNotEmpty) {
        bool matchesGender = false;
        // Assuming p.gender is 'male', 'female', or null/mixed
        // Adjust based on your actual data values
        String? propGender = p.gender?.toLowerCase();

        if (_filterGenders.contains('Male') &&
            (propGender == 'male' ||
                p.tags.contains('شباب') ||
                p.tags.contains('ذكور')))
          matchesGender = true;
        if (_filterGenders.contains('Female') &&
            (propGender == 'female' ||
                p.tags.contains('بنات') ||
                p.tags.contains('إناث')))
          matchesGender = true;
        // If property has no gender specified, deciding whether to show it.
        // Usually assume mixed or show all? strictly filtering:
        if (propGender == null && !matchesGender) {
          // Check headers/tags if not in gender field
          if (_filterGenders.contains('Male') && p.title.contains('شباب'))
            matchesGender = true;
          if (_filterGenders.contains('Female') && p.title.contains('بنات'))
            matchesGender = true;
        }

        if (!matchesGender) return false;
      }

      return true;
    }).toList();
  }

  List<String> get uniqueUniversities {
    final Set<String> allUniversities = {};
    for (var p in _applySearchOnly(_allProperties)) {
      allUniversities.addAll(p.universities);
    }
    return allUniversities.toList()..sort();
  }

  List<Property> getPropertiesForUniversity(String universityName) {
    return _applySearchOnly(
      _allProperties,
    ).where((p) => p.universities.contains(universityName)).toList();
  }

  // Deprecated usage of category index filter, consider removing if moving fully to new filter system
  // Keeping it for backward compatibility but making it use the new filter logic if needed OR just ignore it
  List<Property> get filteredByCategory {
    // If using new filters, return filteredProperties
    return _applySearchOnly(_allProperties);
  }
}
