import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/core/settings_service.dart';
import 'package:dentaltid/src/features/security/domain/audit_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final auditServiceProvider = Provider<AuditService>((ref) {
  return AuditService(DatabaseService.instance);
});

class AuditService {
  final DatabaseService _databaseService;

  AuditService(this._databaseService);

  static const String _tableName = 'audit_events';

  Future<void> logEvent(AuditAction action, {String? details}) async {
    final userRole =
        SettingsService.instance.getString('userRole') ?? 'unknown';

    final event = AuditEvent(
      action: action,
      userId: userRole,
      timestamp: DateTime.now(),
      details: details,
    );
    final db = await _databaseService.database;
    await db.insert(_tableName, event.toJson());
  }

  Future<List<AuditEvent>> getAuditEvents() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return List.generate(maps.length, (i) {
      return AuditEvent.fromJson(maps[i]);
    });
  }
}
