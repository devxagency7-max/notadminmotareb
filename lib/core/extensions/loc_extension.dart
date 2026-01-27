import 'package:flutter/material.dart';
import 'package:motareb/l10n/app_localizations.dart';

extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this)!;

  bool get isAr => Localizations.localeOf(this).languageCode == 'ar';

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
}
