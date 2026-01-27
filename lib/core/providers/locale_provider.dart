import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _prefsKey = 'selected_language';
  Locale? _locale;

  Locale? get locale => _locale;

  /// Lazy loads the saved locale or falls back to system/default.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedLang = prefs.getString(_prefsKey);

    if (savedLang != null) {
      _locale = Locale(savedLang);
    } else {
      // Default to Arabic as requested by the user
      _locale = const Locale('ar');
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale newLocale) async {
    if (!['ar', 'en'].contains(newLocale.languageCode)) return;

    _locale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, newLocale.languageCode);
  }

  bool get isArabic => _locale?.languageCode == 'ar';
}
