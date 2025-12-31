import 'dart:convert';
import 'dart:isolate';
import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:dentaltid/src/features/inventory/application/inventory_service.dart';
import 'package:dentaltid/src/features/patients/application/patient_service.dart';
import 'package:dentaltid/src/features/settings/application/staff_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Service responsible for exporting and importing the entire app database
/// for the purpose of synchronizing between a Dentist (Server) and Staff (Client) device.
class SyncService {
  final Ref _ref;
  final _log = Logger('SyncService');

  SyncService(this._ref);

  /// Exports all relevant tables into a single Map.
  Future<Map<String, List<Map<String, dynamic>>>>
  exportDatabaseMapForSync() async {
    _log.info('Starting full database export for sync...');
    try {
      final db = await _ref.read(databaseServiceProvider).database;

      final tablesToExport = [
        'patients',
        'appointments',
        'transactions',
        'inventory',
        'visits',
        'sessions',
        'recurring_charges',
        'audit_events',
        'staff_users',
        'managed_users',
      ];

      final Map<String, List<Map<String, dynamic>>> allData = {};

      for (final table in tablesToExport) {
        final List<Map<String, dynamic>> tableData = await db.query(table);
        allData[table] = tableData;
        _log.info('Exported ${tableData.length} rows from "$table".');
      }

      return allData;
    } catch (e, s) {
      _log.severe('Failed to export database', e, s);
      rethrow;
    }
  }

  /// Exports all relevant tables into a single JSON string.
  Future<String> exportDatabaseForSync() async {
    final allData = await exportDatabaseMapForSync();
    try {
      final jsonData = await Isolate.run(() => jsonEncode(allData));
      _log.info(
        'Database export complete. Total size: ${jsonData.length} bytes.',
      );
      return jsonData;
    } catch (e, s) {
      _log.severe('Failed to jsonEncode exported database', e, s);
      rethrow;
    }
  }

  /// Clears local data and imports a full dataset from a Map.
  Future<void> importDatabaseMapFromSync(Map<String, dynamic> allData) async {
    _log.info('Starting full database import from sync map...');
    try {
      final db = await _ref.read(databaseServiceProvider).database;

      final tablesToImport = [
        'patients',
        'appointments',
        'transactions',
        'inventory',
        'visits',
        'sessions',
        'recurring_charges',
        'audit_events',
        'staff_users',
        'managed_users',
      ];

      await db.transaction((txn) async {
        // Clear existing data in reverse order of dependencies if any
        for (final table in tablesToImport.reversed) {
          await txn.delete(table);
          _log.info('Cleared table "$table".');
        }

        // Insert new data
        for (final table in tablesToImport) {
          if (allData.containsKey(table) && allData[table] is List) {
            final List<dynamic> tableData = allData[table];
            int count = 0;
            for (final row in tableData) {
              if (row is Map<String, dynamic>) {
                await txn.insert(
                  table,
                  row,
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
                count++;
              }
            }
            _log.info('Imported $count rows into "$table".');
          }
        }
      });

      _log.info('Database import complete.');
      _invalidateAllProviders();
    } catch (e, s) {
      _log.severe('Failed to import database from map', e, s);
      rethrow;
    }
  }

  /// Clears local data and imports a full dataset from a JSON string.
  /// This is a destructive operation.
  Future<void> importDatabaseFromSync(String jsonData) async {
    _log.info('Starting full database import from sync string...');
    try {
      final Map<String, dynamic> allData = await Isolate.run(
        () => jsonDecode(jsonData) as Map<String, dynamic>,
      );
      await importDatabaseMapFromSync(allData);
    } catch (e, s) {
      _log.severe('Failed to import database from string', e, s);
      rethrow;
    }
  }

  /// Invalidates all data-related providers to force a UI refresh.
  void _invalidateAllProviders() {
    _ref.read(patientServiceProvider).notifyDataChanged();
    _ref.read(appointmentServiceProvider).notifyDataChanged();
    _ref.read(inventoryServiceProvider).notifyDataChanged();
    _ref.read(staffServiceProvider).notifyDataChanged();
    _ref.read(financeServiceProvider).notifyDataChanged();

    _ref.invalidate(patientsProvider);
    _ref.invalidate(inventoryItemsProvider);
    _ref.invalidate(staffListProvider);
    _ref.invalidate(appointmentsProvider);
    
    _log.info('Invalidated all data providers via notifyDataChanged and invalidate.');
  }
}

final databaseServiceProvider = Provider((ref) => DatabaseService.instance);

final syncServiceProvider = Provider((ref) => SyncService(ref));
