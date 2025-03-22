import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  // List of supported languages
  final Map<String, String> supportedLanguages = {
    'en': 'English',
    'uz': 'O\'zbekcha',
    // 'ru': 'Русский',
  };

  String getCurrentLanguageName() {
    return supportedLanguages[_locale.languageCode] ?? 'English';
  }

  void setLocale(Locale locale) {
    if (supportedLanguages.containsKey(locale.languageCode)) {
      _locale = locale;
      notifyListeners();
    }
  }
}
