import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';

class AppointmentRepository {
  final DatabaseService _databaseService;

  AppointmentRepository(this._databaseService);

  static const String _tableName = 'appointments';

  Future<Appointment> createAppointment(Appointment appointment) async {
    final db = await _databaseService.database;
    final id = await db.insert(_tableName, appointment.toJson());
    return appointment.copyWith(id: id);
  }

  Future<List<Appointment>> getAppointments() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return List.generate(maps.length, (i) {
      return Appointment.fromJson(maps[i]);
    });
  }

  Future<void> updateAppointment(Appointment appointment) async {
    final db = await _databaseService.database;
    await db.update(
      _tableName,
      appointment.toJson(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }

  Future<void> deleteAppointment(int id) async {
    final db = await _databaseService.database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Appointment>> getUpcomingAppointments() async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'dateTime >= ?',
      whereArgs: [now.toIso8601String()],
      orderBy: 'dateTime ASC',
      limit: 5,
    );
    return List.generate(maps.length, (i) {
      return Appointment.fromJson(maps[i]);
    });
  }

  Future<Appointment?> getAppointmentByPatientAndDateTime(
    int patientId,
    DateTime dateTime,
  ) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'sessionId = ?',
      whereArgs: [patientId],
    );
    // Check if there's an appointment within 30 minutes of the requested time
    for (final map in maps) {
      final existingDateTime = DateTime.parse(map['dateTime']);
      final difference = existingDateTime.difference(dateTime).inMinutes.abs();
      if (difference < 30) {
        // Allow minimum 30-minute slots
        return Appointment.fromJson(map);
      }
    }
    return null;
  }

  Future<Appointment?> getAppointmentById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Appointment.fromJson(maps.first);
    }
    return null;
  }

  Future<void> updateAppointmentStatus(int id, AppointmentStatus status) async {
    final db = await _databaseService.database;
    await db.update(
      _tableName,
      {'status': status.toString()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Appointment>> getAppointmentsByStatusForDate(
    DateTime dateTime,
    AppointmentStatus status,
  ) async {
    final db = await _databaseService.database;
    final startOfDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'dateTime >= ? AND dateTime < ? AND status = ?',
      whereArgs: [
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
        status.toString(),
      ],
      orderBy: 'dateTime ASC',
    );
    return List.generate(maps.length, (i) {
      return Appointment.fromJson(maps[i]);
    });
  }

  Future<List<Appointment>> getTodaysAppointments() async {
    final db = await _databaseService.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfDay = today.add(const Duration(days: 1));

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'dateTime >= ? AND dateTime < ?',
      whereArgs: [today.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'dateTime ASC',
    );
    return List.generate(maps.length, (i) {
      return Appointment.fromJson(maps[i]);
    });
  }

  Future<List<Appointment>> getTodaysAppointmentsForEmergencyPatients(
    List<int> emergencyPatientIds,
  ) async {
    if (emergencyPatientIds.isEmpty) return [];

    final db = await _databaseService.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfDay = today.add(const Duration(days: 1));

    final placeholders = List.filled(emergencyPatientIds.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'dateTime >= ? AND dateTime < ? AND sessionId IN ($placeholders)',
      whereArgs: [
        today.toIso8601String(),
        endOfDay.toIso8601String(),
        ...emergencyPatientIds,
      ],
      orderBy: 'dateTime ASC',
    );
    return List.generate(maps.length, (i) {
      return Appointment.fromJson(maps[i]);
    });
  }

  Future<List<Appointment>> getAppointmentsForPatient(int patientId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'sessionId = ?',
      whereArgs: [patientId],
      orderBy: 'dateTime DESC', // Most recent first
    );
    return List.generate(maps.length, (i) {
      return Appointment.fromJson(maps[i]);
    });
  }
}
