import 'package:dentaltid/src/core/settings_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currencyProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<String> {
  CurrencyNotifier() : super(r'$') {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    await SettingsService.instance.init();
    state = SettingsService.instance.getString('currency') ?? r'$';
  }

  Future<void> setCurrency(String currency) async {
    await SettingsService.instance.setString('currency', currency);
    state = currency;
  }
}
