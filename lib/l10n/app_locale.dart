import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class AppLocale {
  static const String _localeCodeKey = 'app_locale_code';
  static final ValueNotifier<Locale> current =
      ValueNotifier<Locale>(const Locale('en'));

  static Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeCodeKey);
    if (code == 'ur') {
      current.value = const Locale('ur');
      return;
    }
    current.value = const Locale('en');
  }

  static Future<void> setLocale(Locale locale) async {
    current.value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeCodeKey, locale.languageCode);
  }
}
