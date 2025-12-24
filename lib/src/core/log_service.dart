import 'dart:async';
import 'package:logging/logging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogService {
  static final LogService instance = LogService._();
  LogService._();

  final _logController = StreamController<String>.broadcast();
  Stream<String> get onLog => _logController.stream;

  final List<String> _history = [];
  List<String> get history => List.unmodifiable(_history);

  void init() {
    Logger.root.onRecord.listen((record) {
      final msg = '[${record.time.hour}:${record.time.minute}:${record.time.second}] ${record.message}';
      _history.add(msg);
      if (_history.length > 200) _history.removeAt(0);
      _logController.add(msg);
    });
  }
}

final logServiceProvider = Provider((ref) => LogService.instance);
