import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('en', '');
  bool _isLanguageSelected = false;

  LanguageProvider() {
    loadSavedLanguage();
  }

  Locale get locale => _locale;
  bool get isLanguageSelected => _isLanguageSelected;

  Future<void> setLocale(Locale locale) async {
    if (locale == const Locale('en', '') || locale == const Locale('ur', '')) {
      _locale = locale;
      _isLanguageSelected = true;
      
      // Save the selected language preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('languageCode', locale.languageCode);
      await prefs.setBool('isLanguageSelected', true);
      
      notifyListeners();
    }
  }

  // Load saved language preference
  Future<void> loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('languageCode');
      final isSelected = prefs.getBool('isLanguageSelected');
      
      if (languageCode != null) {
        _locale = Locale(languageCode, '');
      }
      
      if (isSelected != null) {
        _isLanguageSelected = isSelected;
      }
      
      notifyListeners();
    } catch (e) {
      // Handle any errors during loading
      debugPrint('Error loading language preference: $e');
    }
  }
}