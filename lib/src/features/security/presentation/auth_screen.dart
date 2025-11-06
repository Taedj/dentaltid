import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/src/features/security/domain/user_role.dart';
import 'package:dentaltid/src/features/security/application/audit_service.dart';
import 'package:dentaltid/src/features/security/domain/audit_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/core/pin_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final PinService _pinService = PinService();
  final UserRole _userRole = UserRole.dentist; // Hardcoded for now
  bool _hasPin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPinSetup();
  }

  Future<void> _checkPinSetup() async {
    final hasPin = await _pinService.hasPinCode();
    setState(() {
      _hasPin = hasPin;
      _isLoading = false;
    });
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final isValidPin = await _pinService.verifyPinCode(_pinController.text);
      if (isValidPin) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAuthenticated', true);
        await prefs.setString('userRole', _userRole.toString());
        ref
            .read(auditServiceProvider)
            .logEvent(
              AuditAction.login,
              details: 'User logged in',
            ); // Log login event
        if (mounted) {
          context.go('/');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incorrect PIN'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _setupInitialPin() async {
    final TextEditingController pinController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Setup PIN Code'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: pinController,
                  decoration: const InputDecoration(
                    labelText: 'Enter PIN (4 digits)',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                ),
                TextFormField(
                  controller: confirmController,
                  decoration: const InputDecoration(labelText: 'Confirm PIN'),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Setup PIN'),
              onPressed: () async {
                final navigator = Navigator.of(context);
                if (pinController.text.length == 4 &&
                    pinController.text == confirmController.text &&
                    RegExp(r'^\d{4}$').hasMatch(pinController.text)) {
                  final success = await _pinService.setupPinCode(
                    pinController.text,
                  );
                  if (success) {
                    pinController.dispose();
                    confirmController.dispose();
                    navigator.pop(true); // Return success
                  } else {
                    navigator.pop(false); // Return failure
                  }
                } else {
                  // Show error and keep dialog open
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'PIN must be 4 digits and match confirmation',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );

    // Handle the result after dialog is dismissed
    if (result == true && mounted) {
      // After setting up PIN, authenticate the user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAuthenticated', true);
      await prefs.setString('userRole', _userRole.toString());
      ref
          .read(auditServiceProvider)
          .logEvent(
            AuditAction.login,
            details: 'User set up initial PIN and logged in',
          );
      // Navigate in next frame to avoid context issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show setup dialog if no PIN is configured
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isLoading && !_hasPin) {
        _setupInitialPin();
      }
    });

    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Enter PIN',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 200,
                      child: TextFormField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'PIN',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a PIN';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _login,
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
