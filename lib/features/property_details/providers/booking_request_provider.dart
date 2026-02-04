import 'package:flutter/material.dart';
import '../../../../core/models/property_model.dart';

class BookingRequestProvider extends ChangeNotifier {
  final Property property;
  final String selectionDetails;
  final double price;
  final List<String> selections;
  final bool isWhole;

  BookingRequestProvider({
    required this.property,
    required this.selectionDetails,
    required this.price,
    required this.selections,
    required this.isWhole,
  });

  // State
  DateTime? _startDate;
  DateTime? _endDate;
  int _totalMonths = 0;
  bool _isSubmitting = false;
  String? _error;

  // Getters
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  int get totalMonths => _totalMonths;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  void setStartDate(DateTime date) {
    _startDate = date;
    if (_endDate != null && _endDate!.isBefore(_startDate!)) {
      _endDate = null;
    }
    _calculateDuration();
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    if (_startDate != null && date.isBefore(_startDate!)) {
      // Ideally handle validation in UI or throw/return error status
      return;
    }
    _endDate = date;
    _calculateDuration();
    notifyListeners();
  }

  void _calculateDuration() {
    if (_startDate != null && _endDate != null) {
      int months =
          (_endDate!.year - _startDate!.year) * 12 +
          _endDate!.month -
          _startDate!.month;

      if (months < 1) months = 1;
      _totalMonths = months;
    } else {
      _totalMonths = 0;
    }
    // No notifyListener needed here as it's called by setters which notify
  }
}
