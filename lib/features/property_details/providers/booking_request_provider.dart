import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/property_model.dart';

class BookingRequestProvider extends ChangeNotifier {
  final Property property;
  final String selectionDetails;
  final double price;

  BookingRequestProvider({
    required this.property,
    required this.selectionDetails,
    required this.price,
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

  Future<bool> submitOrder({
    required String userId,
    required String userEmail,
    required String userName,
    required String userPhone,
    required String idName,
    required String idNumber,
    required String notes,
  }) async {
    if (_startDate == null || _endDate == null) {
      _error = 'Select dates';
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final orderData = {
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'userPhone': userPhone,
        'idName': idName,
        'idNumber': idNumber,
        'propertyId': property.id,
        'propertyTitle': property.title,
        'propertyLocation': property.location,
        'ownerId': 'TODO_OWNER_ID',
        'selectionDetails': selectionDetails,
        'unitPrice': price,
        'totalPrice': price * _totalMonths,
        'startDate': Timestamp.fromDate(_startDate!),
        'endDate': Timestamp.fromDate(_endDate!),
        'durationMonths': _totalMonths,
        'notes': notes,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('orders').add(orderData);

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}
