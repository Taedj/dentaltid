import 'dart:convert';
import 'package:dentaltid/src/features/settings/domain/finance_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final financeSettingsProvider =
    StateNotifierProvider<FinanceSettingsNotifier, FinanceSettings>((ref) {
      return FinanceSettingsNotifier();
    });

class FinanceSettingsNotifier extends StateNotifier<FinanceSettings> {
  FinanceSettingsNotifier() : super(const FinanceSettings()) {
    _loadSettings();
  }

  static const _key = 'finance_settings';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString != null) {
      try {
        final jsonMap = jsonDecode(jsonString);
        state = FinanceSettings.fromJson(jsonMap);
      } catch (e) {
        // Fallback to default if load fails
        state = const FinanceSettings();
      }
    }
  }

  Future<void> _saveSettings(FinanceSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }

  void updateSettings(FinanceSettings settings) {
    state = settings;
    _saveSettings(settings);
  }

  void toggleInventory(bool value) {
    updateSettings(state.copyWith(includeInventory: value));
  }

  void toggleAppointments(bool value) {
    updateSettings(state.copyWith(includeAppointments: value));
  }

  void toggleRecurring(bool value) {
    updateSettings(state.copyWith(includeRecurring: value));
  }

  void setMonthlyBudgetCap(double? value) {
    updateSettings(state.copyWith(monthlyBudgetCap: value));
  }

  void setTaxRatePercentage(double value) {
    updateSettings(state.copyWith(taxRatePercentage: value));
  }

  void toggleCompactNumbers(bool value) {
    updateSettings(state.copyWith(useCompactNumbers: value));
  }
}
