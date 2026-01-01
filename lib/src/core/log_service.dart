import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class LogService {
  static final LogService instance = LogService._();
  LogService._();

  final _logController = StreamController<String>.broadcast();
  Stream<String> get onLog => _logController.stream;

  final List<String> _history = [];
  List<String> get history => List.unmodifiable(_history);

  File? _logFile;
  IOSink? _fileSink;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final logDir = Directory(p.join(docsDir.path, 'DentalTid', 'logs'));
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      _logFile = File(p.join(logDir.path, 'logs_for_developer.txt'));

      if (await _logFile!.exists() &&
          await _logFile!.length() > 5 * 1024 * 1024) {
        await _logFile!.writeAsString('--- Log Reset (File too large) ---\n');
      }

      _fileSink = _logFile!.openWrite(mode: FileMode.append);

      Logger.root.onRecord.listen((record) {
        final timestamp =
            '${record.time.year}-${record.time.month}-${record.time.day} '
            '${record.time.hour.toString().padLeft(2, '0')}:'
            '${record.time.minute.toString().padLeft(2, '0')}:'
            '${record.time.second.toString().padLeft(2, '0')}';

        final msg = '[$timestamp] [${record.level.name}] ${record.message}';

        String fullMsg = msg;
        if (record.error != null) {
          fullMsg += '\nError: ${record.error}';
        }
        if (record.stackTrace != null) {
          fullMsg += '\nStackTrace: ${record.stackTrace}';
        }

        _writeToBoth(fullMsg);

        _history.add(msg);
        if (_history.length > 200) _history.removeAt(0);
        _logController.add(msg);
      });

      _initialized = true;
      Logger(
        'LogService',
      ).info('File logging initialized at: ${_logFile!.path}');
    } catch (e) {
      // ignore: avoid_print
      print('Failed to initialize file logging: $e');
    }
  }

  void _writeToBoth(String message) {
    // Write to console for debug
    // ignore: avoid_print
    print(message);

    // Write to file
    try {
      _fileSink?.writeln(message);
    } catch (e) {
      // ignore: avoid_print
      print('Error writing to log file: $e');
    }
  }

  Future<void> dispose() async {
    await _fileSink?.close();
    await _logController.close();
  }
}

final logServiceProvider = Provider((ref) => LogService.instance);
