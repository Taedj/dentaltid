import 'dart:developer' as developer;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static const String _databaseName = 'dentaltid.db';
  static const int _databaseVersion = 9; // Incremented version

  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    databaseFactory = databaseFactoryFfi;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add missing core columns that should have been in the original schema
      try {
        await db.execute('ALTER TABLE patients ADD COLUMN age INTEGER');
      } catch (e, s) {
        developer.log(
          'Error altering table (age column): $e',
          error: e,
          stackTrace: s,
        );
      }
      try {
        await db.execute('ALTER TABLE patients ADD COLUMN healthState TEXT');
      } catch (e, s) {
        developer.log(
          'Error altering table (healthState column): $e',
          error: e,
          stackTrace: s,
        );
      }
      try {
        await db.execute('ALTER TABLE patients ADD COLUMN diagnosis TEXT');
      } catch (e, s) {
        developer.log(
          'Error altering table (diagnosis column): $e',
          error: e,
          stackTrace: s,
        );
      }
      try {
        await db.execute('ALTER TABLE patients ADD COLUMN treatment TEXT');
      } catch (e, s) {
        developer.log(
          'Error altering table (treatment column): $e',
          error: e,
          stackTrace: s,
        );
      }
      try {
        await db.execute('ALTER TABLE patients ADD COLUMN payment REAL');
      } catch (e, s) {
        developer.log(
          'Error altering table (payment column): $e',
          error: e,
          stackTrace: s,
        );
      }
      try {
        await db.execute('ALTER TABLE patients ADD COLUMN createdAt TEXT');
      } catch (e, s) {
        developer.log(
          'Error altering table (createdAt column): $e',
          error: e,
          stackTrace: s,
        );
      }
      try {
        await db.execute(
          'ALTER TABLE patients ADD COLUMN isEmergency INTEGER DEFAULT 0',
        );
      } catch (e, s) {
        developer.log(
          'Error altering table (isEmergency column): $e',
          error: e,
          stackTrace: s,
        );
      }
      try {
        await db.execute('ALTER TABLE patients ADD COLUMN severity TEXT');
      } catch (e, s) {
        developer.log(
          'Error altering table (severity column): $e',
          error: e,
          stackTrace: s,
        );
      }
      try {
        await db.execute('ALTER TABLE patients ADD COLUMN healthAlerts TEXT');
      } catch (e, s) {
        developer.log(
          'Error altering table (healthAlerts column): $e',
          error: e,
          stackTrace: s,
        );
      }
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE transactions ADD COLUMN status TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE audit_events(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          action TEXT,
          userId TEXT,
          timestamp TEXT,
          details TEXT
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE patients ADD COLUMN phoneNumber TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN patientId INTEGER');
      await db.execute('ALTER TABLE transactions ADD COLUMN totalAmount REAL');
      await db.execute('ALTER TABLE transactions ADD COLUMN paidAmount REAL');
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN paymentMethod TEXT',
      );
    }
    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE appointments ADD COLUMN status TEXT DEFAULT \'waiting\'',
      );
    }
    if (oldVersion < 8) {
      // Migration for combining date and time into a single dateTime column
      await db.execute('ALTER TABLE appointments ADD COLUMN dateTime TEXT');
      await db.execute(
        'UPDATE appointments SET dateTime = date || \'T\' || time || \':00.000\'',
      ); // Combine date and time
      await db.execute(
        'CREATE TEMPORARY TABLE appointments_backup(id, patientId, dateTime, status)',
      );
      await db.execute(
        'INSERT INTO appointments_backup SELECT id, patientId, dateTime, status FROM appointments',
      );
      await db.execute('DROP TABLE appointments');
      await db.execute('''
        CREATE TABLE appointments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          patientId INTEGER,
          dateTime TEXT,
          status TEXT DEFAULT 'waiting'
        )
      ''');
      await db.execute(
        'INSERT INTO appointments SELECT id, patientId, dateTime, status FROM appointments_backup',
      );
      await db.execute('DROP TABLE appointments_backup');
    }
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE visits(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          patientId INTEGER,
          dateTime TEXT,
          reasonForVisit TEXT,
          notes TEXT,
          diagnosis TEXT,
          treatment TEXT
        )
      ''');
      await db.execute('ALTER TABLE appointments ADD COLUMN visitId INTEGER');
      await db.execute('ALTER TABLE transactions ADD COLUMN visitId INTEGER');
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE appointments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId INTEGER,
        visitId INTEGER,
        dateTime TEXT,
        status TEXT DEFAULT 'waiting'
      )
      ''');
    await db.execute('''
      CREATE TABLE patients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        familyName TEXT,
        age INTEGER,
        healthState TEXT,
        diagnosis TEXT,
        treatment TEXT,
        payment REAL,
        createdAt TEXT,
        isEmergency INTEGER DEFAULT 0,
        severity TEXT,
        healthAlerts TEXT,
        phoneNumber TEXT
      )
      ''');
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId INTEGER,
        visitId INTEGER,
        description TEXT,
        totalAmount REAL,
        paidAmount REAL,
        type TEXT,
        date TEXT,
        status TEXT,
        paymentMethod TEXT
      )
      ''');
    await db.execute('''
      CREATE TABLE inventory(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        quantity INTEGER,
        expirationDate TEXT,
        supplier TEXT
      )
      ''');
    await db.execute('''
      CREATE TABLE audit_events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT,
        userId TEXT,
        timestamp TEXT,
        details TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE visits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId INTEGER,
        dateTime TEXT,
        reasonForVisit TEXT,
        notes TEXT,
        diagnosis TEXT,
        treatment TEXT
      )
    ''');
  }
}
