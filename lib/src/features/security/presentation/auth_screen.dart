import 'package:dentaltid/src/core/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/src/features/security/domain/user_role.dart';
import 'package:dentaltid/src/features/security/application/audit_service.dart';
import 'package:dentaltid/src/features/security/domain/audit_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:uuid/uuid.dart';

enum AuthMode { login, register }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _dentistNameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final FirebaseService _firebaseService = FirebaseService();

  AuthMode _authMode = AuthMode.login;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _clinicNameController.dispose();
    _dentistNameController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_authMode == AuthMode.register && !_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_authMode == AuthMode.register) {
        final User? user = await _firebaseService.signUpWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );

        if (user != null) {
          final licenseKey = const Uuid().v4();
          final userProfile = UserProfile(
            uid: user.uid,
            email: user.email!,
            clinicName: _clinicNameController.text,
            dentistName: _dentistNameController.text,
            plan: SubscriptionPlan.free,
            licenseKey: licenseKey,
            status: SubscriptionStatus.active,
            licenseExpiry: DateTime.now().add(
              const Duration(days: 36500),
            ), // 100 years
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
            lastSync: DateTime.now(),
          );

          await _firebaseService.createUserProfile(userProfile, licenseKey);
        }
      } else {
        await _firebaseService.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', UserRole.dentist.toString());

      ref
          .read(auditServiceProvider)
          .logEvent(
            _authMode == AuthMode.login
                ? AuditAction.login
                : AuditAction.createPatient, // Placeholder
            details:
                '${_authMode == AuthMode.login ? 'User logged in' : 'User registered'}: ${_emailController.text}',
          );

      if (!mounted) return;
      context.go('/');
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred, please check your credentials.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _switchAuthMode() {
    setState(() {
      _authMode = _authMode == AuthMode.login
          ? AuthMode.register
          : AuthMode.login;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorScheme.primary, colorScheme.primaryContainer],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // DentalTid Logo and Branding
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Dental Icon (using emoji as placeholder)
                      Text('🦷', style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 16),
                      Text(
                        'DentalTid',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      Text(
                        'Professional Dental Management',
                        style: TextStyle(
                          color: colorScheme.onPrimary.withAlpha(178),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Auth Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withAlpha(50),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _authMode == AuthMode.login
                              ? 'Welcome Back'
                              : 'Create Account',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (_authMode == AuthMode.register &&
                                value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                        ),

                        if (_authMode == AuthMode.register) ...[
                          const SizedBox(height: 16),

                          // Clinic Name
                          TextFormField(
                            controller: _clinicNameController,
                            decoration: InputDecoration(
                              labelText: 'Clinic Name',
                              prefixIcon: const Icon(Icons.business),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your clinic name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Dentist Name
                          TextFormField(
                            controller: _dentistNameController,
                            decoration: InputDecoration(
                              labelText: 'Your Name',
                              prefixIcon: const Icon(Icons.person),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Terms and Conditions
                          CheckboxListTile(
                            title: const Text(
                              'I accept the Terms and Conditions',
                            ),
                            value: _acceptTerms,
                            onChanged: (value) {
                              setState(() => _acceptTerms = value ?? false);
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Auth Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _authenticate,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : Text(
                                  _authMode == AuthMode.login
                                      ? 'Login'
                                      : 'Create Free Account',
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),

                        const SizedBox(height: 16),

                        // Switch Auth Mode
                        TextButton(
                          onPressed: _switchAuthMode,
                          child: Text(
                            _authMode == AuthMode.login
                                ? "Don't have an account? Sign up"
                                : 'Already have an account? Login',
                            style: TextStyle(color: colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Footer
                Text(
                  '© 2025 DentalTid. Professional dental practice management.',
                  style: TextStyle(
                    color: colorScheme.onPrimary.withAlpha(178),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
