import 'package:dentaltid/src/core/network/sync_broadcaster.dart';
import 'package:dentaltid/src/core/network/sync_event.dart';
import 'package:dentaltid/src/core/settings_service.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currencyProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) {
  return CurrencyNotifier(ref);
});

class CurrencyNotifier extends StateNotifier<String> {
  final Ref _ref;

  CurrencyNotifier(this._ref) : super(r'$') {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    await SettingsService.instance.init();
    state = SettingsService.instance.getString('currency') ?? r'$';
  }

  Future<void> setCurrency(String currency) async {
    await SettingsService.instance.setString('currency', currency);
    state = currency;

    // Broadcast change to other devices if we are the dentist (server)
    final userProfile = _ref.read(userProfileProvider).value;
    if (userProfile?.role == UserRole.dentist) {
      _ref
          .read(syncBroadcasterProvider)
          .broadcast(
            table: 'app_settings',
            action: SyncAction.update,
            data: {'currency': currency},
          );
    }
  }
}
