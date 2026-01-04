import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  final Box _settingsBox = Hive.box('settings');
  
  Locale _locale = const Locale('en');
  
  LocaleProvider() {
    _loadLocale();
  }
  
  Locale get locale => _locale;
  
  String get languageCode => _locale.languageCode;
  
  bool get isNepali => _locale.languageCode == 'ne';
  
  bool get isEnglish => _locale.languageCode == 'en';
  
  void _loadLocale() {
    final savedLocale = _settingsBox.get(_localeKey, defaultValue: 'en');
    _locale = Locale(savedLocale);
  }
  
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    await _settingsBox.put(_localeKey, locale.languageCode);
    notifyListeners();
  }
  
  Future<void> setEnglish() async {
    await setLocale(const Locale('en'));
  }
  
  Future<void> setNepali() async {
    await setLocale(const Locale('ne'));
  }
  
  Future<void> toggleLocale() async {
    if (isEnglish) {
      await setNepali();
    } else {
      await setEnglish();
    }
  }
}
