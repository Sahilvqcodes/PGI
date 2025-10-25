import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

class PrefUtils {
  static SharedPreferences? _sharedPreferences;

  static const String _languageCodeKey = "language_code";
  static const String _countryCodeKey = "country_code";


  // Language save karne ke liye
  static Future<void> setLanguageCode(String languageCode, String countryCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, languageCode);
    await prefs.setString(_countryCodeKey, countryCode);
  }

  // App start hone par language read karne ke liye
  static Future<Locale?> getLanguageSelect() async {
    final prefs = await SharedPreferences.getInstance();
    String? lang = prefs.getString(_languageCodeKey);
    String? country = prefs.getString(_countryCodeKey);
    if (lang != null && country != null) {
      return Locale(lang, country);
    }
    return null; // Default me English
  }

  /// Initialize preferences once
  Future<void> init() async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    print('SharedPreference Initialized');
  }

  // ---------------- THEME ----------------
  Future<void> setThemeData(String value) async {
    await _sharedPreferences!.setString('themeData', value);
  }

  String getThemeData() {
    return _sharedPreferences!.getString('themeData') ?? 'primary';
  }

  // ---------------- TOKEN ----------------
  static Future<void> setToken(String value) async {
    await _sharedPreferences!.setString('token', value);
  }

  static String getToken() {
    return _sharedPreferences!.getString('token') ?? '';
  }

  // ---------------- LANGUAGE ----------------
  static Future<void> setLanguage(bool value) async {
    await _sharedPreferences!.setBool('language', value);
  }

  static bool getLanguage() {
    return _sharedPreferences!.getBool('language') ?? false;
  }

  // ---------------- LOGIN & ROLE ----------------
  static Future<void> setLoggedIn(bool value) async {
    await _sharedPreferences!.setBool('isLoggedIn', value);
  }

  static bool getLoggedIn() {
    return _sharedPreferences!.getBool('isLoggedIn') ?? false;
  }

  static Future<void> setUserRole(String role) async {
    await _sharedPreferences!.setString('userRole', role);
  }

  static String getUserRole() {
    return _sharedPreferences!.getString('userRole') ?? 'user';
  }

  // ---------------- CLEAR PREFS ----------------
  static Future<void> clearPreferencesData() async {
    bool? languageValue = _sharedPreferences!.getBool('language');
    await _sharedPreferences!.clear();
    if (languageValue != null) {
      await _sharedPreferences!.setBool('language', languageValue);
    }
  }
}
