import 'dart:developer' as developer;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static const String _databaseName = 'dentaltid.db';
  static const int _databaseVersion = 14; // Incremented version

  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {

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
    if (oldVersion < 10) {
      // Add isBlacklisted to patients
      await db.execute(
        'ALTER TABLE patients ADD COLUMN isBlacklisted INTEGER DEFAULT 0',
      );

      // Add new columns to visits
      await db.execute(
        'ALTER TABLE visits ADD COLUMN visitNumber INTEGER DEFAULT 1',
      );
      await db.execute(
        'ALTER TABLE visits ADD COLUMN isEmergency INTEGER DEFAULT 0',
      );
      await db.execute('ALTER TABLE visits ADD COLUMN emergencySeverity TEXT');
      await db.execute('ALTER TABLE visits ADD COLUMN healthAlerts TEXT');

      // Create sessions table
      await db.execute('''
        CREATE TABLE sessions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          visitId INTEGER,
          sessionNumber INTEGER,
          dateTime TEXT,
          notes TEXT,
          treatmentDetails TEXT,
          totalAmount REAL DEFAULT 0.0,
          paidAmount REAL DEFAULT 0.0,
          status TEXT DEFAULT 'scheduled'
        )
      ''');

      // Modify appointments table: drop patientId, add sessionId
      await db.execute('ALTER TABLE appointments ADD COLUMN sessionId INTEGER');
      await db.execute(
        'UPDATE appointments SET sessionId = patientId',
      ); // Temporary migration
      await db.execute(
        'CREATE TEMPORARY TABLE appointments_backup(id, sessionId, visitId, dateTime, status)',
      );
      await db.execute(
        'INSERT INTO appointments_backup SELECT id, sessionId, visitId, dateTime, status FROM appointments',
      );
      await db.execute('DROP TABLE appointments');
      await db.execute('''
        CREATE TABLE appointments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sessionId INTEGER,
          dateTime TEXT,
          status TEXT DEFAULT 'waiting'
        )
      ''');
      await db.execute(
        'INSERT INTO appointments SELECT id, sessionId, dateTime, status FROM appointments_backup',
      );
      await db.execute('DROP TABLE appointments_backup');

      // Modify transactions table: drop patientId, add sessionId
      await db.execute('ALTER TABLE transactions ADD COLUMN sessionId INTEGER');
      await db.execute(
        'UPDATE transactions SET sessionId = patientId',
      ); // Temporary migration
      await db.execute(
        'CREATE TEMPORARY TABLE transactions_backup(id, sessionId, visitId, description, totalAmount, paidAmount, type, date, status, paymentMethod)',
      );
      await db.execute(
        'INSERT INTO transactions_backup SELECT id, sessionId, visitId, description, totalAmount, paidAmount, type, date, status, paymentMethod FROM transactions',
      );
      await db.execute('DROP TABLE transactions');
      await db.execute('''
        CREATE TABLE transactions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sessionId INTEGER,
          description TEXT,
          totalAmount REAL,
          paidAmount REAL,
          type TEXT,
          date TEXT,
          status TEXT,
          paymentMethod TEXT
        )
      ''');
      await db.execute(
        'INSERT INTO transactions SELECT id, sessionId, description, totalAmount, paidAmount, type, date, status, paymentMethod FROM transactions_backup',
      );
      await db.execute('DROP TABLE transactions_backup');
    }
    if (oldVersion < 11) {
      // Add dateOfBirth column to patients table
      await db.execute('ALTER TABLE patients ADD COLUMN dateOfBirth TEXT');
    }
    if (oldVersion < 12) {
      // Add new columns to appointments table for visit details
      await db.execute(
        'ALTER TABLE appointments ADD COLUMN appointmentType TEXT',
      );
      await db.execute('ALTER TABLE appointments ADD COLUMN healthState TEXT');
      await db.execute('ALTER TABLE appointments ADD COLUMN diagnosis TEXT');
      await db.execute('ALTER TABLE appointments ADD COLUMN treatment TEXT');
      await db.execute('ALTER TABLE appointments ADD COLUMN notes TEXT');
    }
    if (oldVersion < 13) {
      // Add thresholdDays to inventory table
      await db.execute(
        'ALTER TABLE inventory ADD COLUMN thresholdDays INTEGER DEFAULT 30',
      );
    }
    if (oldVersion < 14) {
      // Add lowStockThreshold to inventory table
      await db.execute(
        'ALTER TABLE inventory ADD COLUMN lowStockThreshold INTEGER DEFAULT 5',
      );
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
    await db.execute('''
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
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId INTEGER,
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
        supplier TEXT,
        thresholdDays INTEGER DEFAULT 30,
        lowStockThreshold INTEGER DEFAULT 5
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
        treatment TEXT,
        visitNumber INTEGER DEFAULT 1,
        isEmergency INTEGER DEFAULT 0,
        emergencySeverity TEXT,
        healthAlerts TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        visitId INTEGER,
        sessionNumber INTEGER,
        dateTime TEXT,
        notes TEXT,
        treatmentDetails TEXT,
        totalAmount REAL DEFAULT 0.0,
        paidAmount REAL DEFAULT 0.0,
        status TEXT DEFAULT 'scheduled'
      )
    ''');
  }
}
