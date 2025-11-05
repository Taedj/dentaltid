import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static const String _databaseName = 'dentaltid.db';
  static const int _databaseVersion = 5;

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
      await db.execute(
        'ALTER TABLE patients ADD COLUMN isEmergency INTEGER DEFAULT 0',
      );
      await db.execute('ALTER TABLE patients ADD COLUMN severity TEXT');
      await db.execute('ALTER TABLE patients ADD COLUMN healthAlerts TEXT');
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
        date TEXT,
        time TEXT
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
  }
}
