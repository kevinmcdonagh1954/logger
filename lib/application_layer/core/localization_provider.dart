import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logging_service.dart';
import 'service_locator.dart';

class LocalizationProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  Locale _locale = const Locale('en'); // Default to English
  final _logger = locator<LoggingService>();

  static final List<Locale> supportedLocales = [
    const Locale('en'), // English
    const Locale('es'), // Spanish
    const Locale('zh'), // Chinese
    const Locale('pt'), // Portuguese
  ];

  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'zh':
        return '中文';
      case 'pt':
        return 'Português';
      default:
        return 'Unknown';
    }
  }

  LocalizationProvider() {
    _logger.debug('LocalizationProvider',
        'Initializing with default locale: ${_locale.languageCode}');
    _loadSavedLanguage();
  }

  Locale get locale => _locale;

  Future<void> _loadSavedLanguage() async {
    try {
      _logger.debug(
          'LocalizationProvider', 'Loading saved language preference');
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      if (savedLanguage != null) {
        _logger.debug(
            'LocalizationProvider', 'Found saved language: $savedLanguage');
        _locale = Locale(savedLanguage);
        notifyListeners();
      } else {
        _logger.debug('LocalizationProvider',
            'No saved language found, using default: ${_locale.languageCode}');
      }
    } catch (e) {
      _logger.error('LocalizationProvider', 'Error loading saved language: $e');
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    _logger.debug('LocalizationProvider',
        'Setting new locale: ${newLocale.languageCode}');
    if (!supportedLocales.contains(newLocale)) {
      _logger.warning('LocalizationProvider',
          'Unsupported locale requested: ${newLocale.languageCode}');
      return;
    }

    try {
      _locale = newLocale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, newLocale.languageCode);
      _logger.debug('LocalizationProvider',
          'Successfully saved new locale: ${newLocale.languageCode}');
      notifyListeners();
    } catch (e) {
      _logger.error('LocalizationProvider', 'Error saving new locale: $e');
    }
  }
}
