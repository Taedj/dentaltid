import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  static SettingsService get instance => _instance;

  final Logger _logger = Logger('SettingsService');
  Map<String, dynamic> _settings = {};
  File? _file;
  bool _initialized = false;

  SettingsService._internal();

  Future<void> init() async {
    if (_initialized) return;

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final settingsDir = Directory(
        path.join(docsDir.path, 'DentalTid', 'settings'),
      );

      if (!await settingsDir.exists()) {
        await settingsDir.create(recursive: true);
      }

      _file = File(path.join(settingsDir.path, 'settings.json'));

      if (await _file!.exists()) {
        final content = await _file!.readAsString();
        if (content.isNotEmpty) {
          try {
            _settings = jsonDecode(content);
          } catch (e) {
            _logger.warning(
              'Failed to parse settings.json, resetting to empty.',
              e,
            );
            _settings = {};
          }
        }
      } else {
        await _file!.create();
        await _file!.writeAsString('{}');
      }
      _initialized = true;
      _logger.info('Settings initialized at ${_file!.path}');
    } catch (e) {
      _logger.severe('Failed to initialize settings service', e);
    }
  }

  Future<void> _save() async {
    if (_file == null) return;
    try {
      await _file!.writeAsString(jsonEncode(_settings));
    } catch (e) {
      _logger.severe('Failed to save settings', e);
    }
  }

  // Getters
  String? getString(String key) => _settings[key] as String?;
  bool? getBool(String key) => _settings[key] as bool?;
  int? getInt(String key) => _settings[key] as int?;
  double? getDouble(String key) => _settings[key] as double?;

  // Setters
  Future<void> setString(String key, String value) async {
    _settings[key] = value;
    await _save();
  }

  Future<void> setBool(String key, bool value) async {
    _settings[key] = value;
    await _save();
  }

  Future<void> setInt(String key, int value) async {
    _settings[key] = value;
    await _save();
  }

  Future<void> setDouble(String key, double value) async {
    _settings[key] = value;
    await _save();
  }

  Future<void> remove(String key) async {
    _settings.remove(key);
    await _save();
  }

  Future<void> clear() async {
    _settings.clear();
    await _save();
  }
}
