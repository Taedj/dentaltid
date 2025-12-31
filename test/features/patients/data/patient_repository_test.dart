import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/features/patients/data/patient_repository.dart';

void main() {
  late PatientRepository repository;
  late Database database;

  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Use in-memory database
    database = await databaseFactory.openDatabase(inMemoryDatabasePath);

    // Create tables (simplified for test)
    await database.execute('''
      CREATE TABLE patients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        familyName TEXT,
        age INTEGER,
        dateOfBirth TEXT,
        healthState TEXT,
        diagnosis TEXT,
        treatment TEXT,
        payment REAL,
        createdAt TEXT,
        isEmergency INTEGER DEFAULT 0,
        severity TEXT,
        healthAlerts TEXT,
        phoneNumber TEXT,
        isBlacklisted INTEGER DEFAULT 0
      )
    ''');

    await database.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId INTEGER,
        description TEXT,
        totalAmount REAL,
        paidAmount REAL,
        type TEXT,
        date TEXT,
        status TEXT,
        paymentMethod TEXT,
        sourceType TEXT,
        sourceId INTEGER,
        category TEXT
      )
    ''');

    await database.execute('''
      CREATE TABLE appointments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId INTEGER,
        dateTime TEXT,
        status TEXT DEFAULT 'waiting',
        appointmentType TEXT,
        healthState TEXT,
        diagnosis TEXT,
        treatment TEXT,
        notes TEXT
      )
    ''');

    // Create a concrete DatabaseService implementation using the in-memory db
    final databaseService = _TestDatabaseService(database);
    repository = PatientRepository(databaseService);
  });

  tearDown(() async {
    await database.close();
  });

  test('getPatients should calculate totalDue correctly', () async {
    // 1. Create a patient
    final patientId = await database.insert('patients', {
      'name': 'John',
      'familyName': 'Doe',
      'age': 30,
      'createdAt': DateTime.now().toIso8601String(),
      'healthState': 'Good',
      'diagnosis': 'None',
      'treatment': 'None',
      'payment': 0.0,
      'severity': 'low',
    });

    // 2. Create two appointments linked to the patient (via sessionId = patientId)
    final appointmentId1 = await database.insert('appointments', {
      'sessionId': patientId,
      'dateTime': DateTime.now().toIso8601String(),
    });

    final appointmentId2 = await database.insert('appointments', {
      'sessionId': patientId,
      'dateTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
    });

    // 3. Create transactions linked to these appointments
    // Transaction 1: Total 100, Paid 20 -> Due 80
    await database.insert('transactions', {
      'sessionId': appointmentId1,
      'totalAmount': 100.0,
      'paidAmount': 20.0,
    });

    // Transaction 2: Total 50, Paid 0 -> Due 50
    await database.insert('transactions', {
      'sessionId': appointmentId2,
      'totalAmount': 50.0,
      'paidAmount': 0.0,
    });

    // Total Due should be 80 + 50 = 130

    // 4. Fetch patients
    final paginated = await repository.getPatients();

    // 5. Verify
    expect(paginated.patients.length, 1);
    expect(paginated.patients.first.id, patientId);
    expect(paginated.patients.first.totalDue, 130.0);
  });
}

class _TestDatabaseService implements DatabaseService {
  final Database _db;
  _TestDatabaseService(this._db);

  @override
  Future<Database> get database async => _db;

  @override
  Future<void> close() async => _db.close();

  // Implement other members if necessary or throw UnimplementedError
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
