import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static const String _databaseName = 'dentaltid.db';
  static const int _databaseVersion = 1;

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
    );
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      '''
      CREATE TABLE appointments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId INTEGER,
        date TEXT,
        time TEXT
      )
      '''
    );
    await db.execute(
      '''
      CREATE TABLE patients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        familyName TEXT,
        age INTEGER,
        healthState TEXT,
        diagnosis TEXT,
        treatment TEXT,
        payment REAL,
        createdAt TEXT
      )
      '''
    );
    await db.execute(
      '''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT,
        amount REAL,
        type TEXT,
        date TEXT
      )
      '''
    );
    await db.execute(
      '''
      CREATE TABLE inventory(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        quantity INTEGER,
        expirationDate TEXT,
        supplier TEXT
      )
      '''
    );
  }
}
