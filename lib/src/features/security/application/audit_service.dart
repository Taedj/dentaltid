import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/core/settings_service.dart';
import 'package:dentaltid/src/features/security/domain/audit_event.dart';
import 'package:dentaltid/src/features/security/domain/paginated_audit_events.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';

final _log = Logger('AuditService');

final auditServiceProvider = Provider<AuditService>((ref) {
  return AuditService(DatabaseService.instance);
});

class AuditService {
  final DatabaseService _databaseService;

  AuditService(this._databaseService);

  static const String _tableName = 'audit_events';

  Future<void> logEvent(AuditAction action, {String? details}) async {
    try {
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
    } catch (e) {
      // Don't crash the app if auditing fails
      _log.severe('Failed to log audit event', e);
    }
  }

  Future<PaginatedAuditEvents> getAuditEvents({
    int page = 1,
    int pageSize = 20,
  }) async {
    final db = await _databaseService.database;

    // Total Count
    final countResult = await db.query(_tableName, columns: ['COUNT(*)']);
    final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

    // Data
    final offset = (page - 1) * pageSize;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'timestamp DESC',
      limit: pageSize,
      offset: offset,
    );

    final events = List.generate(maps.length, (i) {
      return AuditEvent.fromJson(maps[i]);
    });

    return PaginatedAuditEvents(
      events: events,
      totalCount: totalCount,
      currentPage: page,
      totalPages: (totalCount / pageSize).ceil(),
    );
  }
}
