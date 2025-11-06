import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment_status.dart';

class AppointmentRepository {
  final DatabaseService _databaseService;

  AppointmentRepository(this._databaseService);

  static const String _tableName = 'appointments';

  Future<void> createAppointment(Appointment appointment) async {
    final db = await _databaseService.database;
    await db.insert(_tableName, appointment.toJson());
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
    final today = DateTime(now.year, now.month, now.day);
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'date >= ?',
      whereArgs: [today.toIso8601String()],
      orderBy: 'date ASC',
      limit: 5,
    );
    return List.generate(maps.length, (i) {
      return Appointment.fromJson(maps[i]);
    });
  }

  Future<Appointment?> getAppointmentByDetails(
    int patientId,
    DateTime date,
    String time,
  ) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'patientId = ? AND date = ? AND time = ?',
      whereArgs: [patientId, date.toIso8601String(), time],
    );
    if (maps.isNotEmpty) {
      return Appointment.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<void> updateAppointmentStatus(
    int id,
    AppointmentStatus status,
  ) async {
    final db = await _databaseService.database;
    await db.update(
      _tableName,
      {'status': status.toString()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Appointment>> getAppointmentsByStatusForDate(
    DateTime date,
    AppointmentStatus status,
  ) async {
    final db = await _databaseService.database;
    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'date(date) = ? AND status = ?',
      whereArgs: [dateString, status.toString()],
      orderBy: 'time ASC',
    );
    return List.generate(maps.length, (i) {
      return Appointment.fromJson(maps[i]);
    });
  }
}