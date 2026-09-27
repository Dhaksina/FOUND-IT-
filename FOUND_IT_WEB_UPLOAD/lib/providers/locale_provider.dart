import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Supported languages ───────────────────────────────────────────────────────
class AppLanguage {
  final String code;       // IETF locale tag
  final String name;       // Native name
  final String englishName;
  final String flag;       // Emoji flag

  const AppLanguage({
    required this.code,
    required this.name,
    required this.englishName,
    required this.flag,
  });
}

const List<AppLanguage> supportedLanguages = [
  AppLanguage(code: 'en', name: 'English',    englishName: 'English',    flag: '🇬🇧'),
  AppLanguage(code: 'ta', name: 'தமிழ்',      englishName: 'Tamil',      flag: '🇮🇳'),
  AppLanguage(code: 'hi', name: 'हिंदी',       englishName: 'Hindi',      flag: '🇮🇳'),
  AppLanguage(code: 'te', name: 'తెలుగు',      englishName: 'Telugu',     flag: '🇮🇳'),
  AppLanguage(code: 'ml', name: 'മലയാളം',     englishName: 'Malayalam',  flag: '🇮🇳'),
  AppLanguage(code: 'kn', name: 'ಕನ್ನಡ',      englishName: 'Kannada',    flag: '🇮🇳'),
  AppLanguage(code: 'fr', name: 'Français',    englishName: 'French',     flag: '🇫🇷'),
  AppLanguage(code: 'ar', name: 'العربية',     englishName: 'Arabic',     flag: '🇸🇦'),
];

// ── Notifier ──────────────────────────────────────────────────────────────────
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('en');

  void setLocale(String languageCode) {
    state = Locale(languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

// Convenience: current language code as a string
final languageCodeProvider = Provider<String>((ref) {
  return ref.watch(localeProvider).languageCode;
});
