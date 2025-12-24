import 'dart:convert';
import 'package:dentaltid/src/core/network/sync_client.dart';
import 'package:dentaltid/src/core/network/sync_event.dart';
import 'package:dentaltid/src/core/network/sync_server.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncBroadcaster {
  final Ref _ref;

  SyncBroadcaster(this._ref);

  void broadcast({
    required String table,
    required SyncAction action,
    required Map<String, dynamic> data,
  }) {
    final event = SyncEvent(table: table, action: action, data: data);

    final userProfile = _ref.read(userProfileProvider).value;

    if (userProfile?.role == UserRole.dentist) {
      _ref.read(syncServerProvider).broadcast(jsonEncode(event.toJson()));
    } else {
      _ref.read(syncClientProvider).send(event);
    }
  }
}

final syncBroadcasterProvider = Provider<SyncBroadcaster>((ref) {
  return SyncBroadcaster(ref);
});
