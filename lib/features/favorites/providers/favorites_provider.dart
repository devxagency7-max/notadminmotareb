import 'package:flutter/material.dart';
import '../../../core/models/property_model.dart';

class FavoritesProvider extends ChangeNotifier {
  final List<Property> _favorites = [];

  List<Property> get favorites => _favorites;

  void toggleFavorite(Property property) {
    bool isExist = _favorites.any((element) => element.id == property.id);
    if (isExist) {
      _favorites.removeWhere((element) => element.id == property.id);
    } else {
      _favorites.add(property);
    }
    notifyListeners();
  }

  bool isFavorite(String id) {
    return _favorites.any((element) => element.id == id);
  }
}
