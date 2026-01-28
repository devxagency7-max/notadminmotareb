import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/property_model.dart';
import 'package:motareb/core/extensions/loc_extension.dart';

class PropertyDetailsProvider extends ChangeNotifier {
  final Property property;

  // Selected State
  double _selectedPrice = 0.0;
  String? _selectionLabel;
  bool _isWholeApartment = false;
  final Set<String> _selectedUnitKeys =
      {}; // Keys: "r{idx}" or "r{idx}_b{bIdx}"
  int _selectedBedCount = 1;

  // Contact State
  bool _loadingContacts = true;
  List<Map<String, dynamic>> _contactNumbers = [];
  String? _error;

  PropertyDetailsProvider({required this.property}) {
    _init();
    _fetchContactNumbers();
  }

  // Getters
  double get selectedPrice => _selectedPrice;
  String? get selectionLabel => _selectionLabel;
  bool get isWholeApartment => _isWholeApartment;
  Set<String> get selectedUnitKeys => _selectedUnitKeys;
  int get selectedBedCount => _selectedBedCount;

  bool get loadingContacts => _loadingContacts;
  List<Map<String, dynamic>> get contactNumbers => _contactNumbers;
  String? get error => _error;

  void _init() {
    // Initialize defaults based on property mode
    if (property.bookingMode == 'unit' && property.isFullApartmentBooking) {
      _isWholeApartment = true;
    }

    // Initial calculation (requires context for label usually, will use default/setter)
    _calculatePrice();
  }

  StreamSubscription? _contactSubscription;

  // Logic: Fetch Contact Numbers (Stream)
  void _fetchContactNumbers() {
    _loadingContacts = true;
    notifyListeners();

    _contactSubscription = FirebaseFirestore.instance
        .collection('contact_numbers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _contactNumbers = snapshot.docs.map((doc) => doc.data()).toList();
            _loadingContacts = false;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _loadingContacts = false;
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    _contactSubscription?.cancel();
    super.dispose();
  }

  // Logic: Calculate Price based on state
  void updatePriceCalculations(BuildContext context) {
    // This public method allows updating label with context context.loc
    _calculatePrice(context: context);
  }

  void _calculatePrice({BuildContext? context}) {
    double base =
        property.discountPrice ??
        double.tryParse(property.price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0.0;

    // 1. Bed Mode
    if (property.bookingMode == 'bed') {
      _selectedPrice = property.bedPrice * _selectedBedCount;
      if (context != null) {
        _selectionLabel = context.loc.bed;
      }
      notifyListeners();
      return;
    }

    // 2. Unit Mode - Full Apartment Fixed
    if (property.isFullApartmentBooking) {
      _selectedPrice = base;
      if (context != null) {
        _selectionLabel = context.loc.fullApartmentPrice;
      }
      notifyListeners();
      return;
    }

    // 3. Unit Mode - Selection
    if (_isWholeApartment) {
      _selectedPrice = base;
      if (context != null) _selectionLabel = context.loc.fullApartmentPrice;
    } else if (_selectedUnitKeys.isNotEmpty) {
      double total = 0.0;
      for (var key in _selectedUnitKeys) {
        final parts = key.split('_');
        final roomIdx = int.parse(parts[0].substring(1));

        if (roomIdx < 0 || roomIdx >= property.rooms.length) continue;

        final room = property.rooms[roomIdx];

        if (parts.length > 1) {
          // Bed selection
          total += (room['bedPrice'] as num?)?.toDouble() ?? 0.0;
        } else {
          // Room selection
          total += (room['price'] as num?)?.toDouble() ?? 0.0;
        }
      }
      _selectedPrice = total;
      if (context != null) _selectionLabel = context.loc.totalChoices;
    } else {
      _selectedPrice = base;
      if (context != null) _selectionLabel = context.loc.apartmentPrice;
    }
    notifyListeners();
  }

  // Logic: Actions
  void setBedCount(int count, BuildContext context) {
    if (count < 1) return;
    if (property.totalBeds > 0 && count > property.totalBeds) return;

    _selectedBedCount = count;
    _calculatePrice(context: context);
  }

  void toggleUnitSelection(bool isWhole, String? key, BuildContext context) {
    if (isWhole) {
      if (_isWholeApartment) {
        _isWholeApartment = false;
      } else {
        _isWholeApartment = true;
        _selectedUnitKeys.clear();
      }
    } else if (key != null) {
      if (_isWholeApartment) {
        _isWholeApartment = false;
        _selectedUnitKeys.clear();
      }

      if (_selectedUnitKeys.contains(key)) {
        _selectedUnitKeys.remove(key);
        if (_selectedUnitKeys.isEmpty) {
          _isWholeApartment = true;
        }
      } else {
        _selectedUnitKeys.add(key);
      }
    }
    _calculatePrice(context: context);
  }

  bool validateBooking() {
    if (property.bookingMode == 'unit' &&
        !property.isFullApartmentBooking &&
        !_isWholeApartment &&
        _selectedUnitKeys.isEmpty) {
      return false;
    }
    return true;
  }
}
