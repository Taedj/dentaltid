import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinService {
  static const String _pinKey = 'user_pin_code';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Check if a PIN code is already set up
  Future<bool> hasPinCode() async {
    final pin = await _secureStorage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  /// Set up a new PIN code
  Future<bool> setupPinCode(String pinCode) async {
    if (pinCode.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pinCode)) {
      return false; // PIN must be exactly 4 digits
    }

    await _secureStorage.write(key: _pinKey, value: pinCode);
    return true;
  }

  /// Verify if the provided PIN code matches the stored one
  Future<bool> verifyPinCode(String pinCode) async {
    final storedPin = await _secureStorage.read(key: _pinKey);
    return storedPin == pinCode;
  }

  /// Change the existing PIN code
  Future<bool> changePinCode(String currentPin, String newPin) async {
    // First verify the current PIN
    final isCurrentValid = await verifyPinCode(currentPin);
    if (!isCurrentValid) {
      return false;
    }

    // Set up the new PIN
    return await setupPinCode(newPin);
  }

  /// Clear the PIN code (for logout or reset)
  Future<void> clearPinCode() async {
    await _secureStorage.delete(key: _pinKey);
  }

  /// Get the stored PIN code (for internal use only)
  Future<String?> getPinCode() async {
    return await _secureStorage.read(key: _pinKey);
  }
}
