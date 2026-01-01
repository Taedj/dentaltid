import 'dart:io';
import 'package:logging/logging.dart';

class DeviceUtils {
  static final Logger _log = Logger('DeviceUtils');

  /// Fetches the unique Device ID (UUID) for Windows.
  /// Returns null if failed or not on Windows.
  static Future<String?> getWindowsDeviceId() async {
    if (!Platform.isWindows) return null;

    try {
      final result = await Process.run('wmic', ['csproduct', 'get', 'uuid']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        // Output format is usually:
        // UUID
        // XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
        final lines = output.split('\n');
        if (lines.length >= 2) {
          final uuid = lines[1].trim();
          if (uuid.isNotEmpty) {
            return uuid;
          }
        }
      }
    } catch (e) {
      _log.warning('Failed to get device ID: $e');
    }
    return null;
  }
}
