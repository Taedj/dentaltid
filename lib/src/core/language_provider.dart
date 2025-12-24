import 'package:dentaltid/src/core/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier() : super(const Locale('en')) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    await SettingsService.instance.init();
    final languageCode = SettingsService.instance.getString('languageCode');
    if (languageCode != null) {
      state = Locale(languageCode);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await SettingsService.instance.setString(
      'languageCode',
      locale.languageCode,
    );
  }
}
