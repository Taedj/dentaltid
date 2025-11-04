import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';

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
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
