import 'dart:async';
import 'dart:io';

import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/core/firebase_service.dart';
import 'package:dentaltid/src/core/network_discovery_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:dentaltid/src/features/security/application/audit_service.dart';
import 'package:dentaltid/src/features/security/domain/audit_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

enum AuthMode { login, register, staffLogin }

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
  final _phoneNumberController = TextEditingController();
  final _medicalLicenseNumberController = TextEditingController();
  final _licenseController =
      TextEditingController(); // Kept for consistency if needed, though unused in form
  final _usernameController = TextEditingController();
  final _pinController = TextEditingController();
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
    _phoneNumberController.dispose();
    _medicalLicenseNumberController.dispose();
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
            phoneNumber: _phoneNumberController.text,
            medicalLicenseNumber: _medicalLicenseNumberController.text,
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
          ref.invalidate(userProfileProvider);
        }
      } else if (_authMode == AuthMode.staffLogin) {
        // PIN-based authentication for managed users
        await _authenticateStaff();
      } else {
        // Email/password authentication for dentists
        await _firebaseService.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final userRole = _authMode == AuthMode.staffLogin
          ? UserRole.assistant
          : UserRole.dentist;
      await prefs.setString('userRole', userRole.toString());

      ref
          .read(auditServiceProvider)
          .logEvent(
            _authMode == AuthMode.login
                ? AuditAction.login
                : AuditAction.createPatient, // Placeholder
            details:
                '${_authMode == AuthMode.login ? 'User logged in' : 'User registered'}: ${_emailController.text}',
          );

      if (mounted) {
        context.go('/');
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
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

  Future<void> _authenticateStaff() async {
    // For staff login, we need to find a dentist first
    // In a real implementation, this would scan for available dentists on the LAN
    // For now, we'll show a dentist selection dialog

    // This is a simplified version - in production, this would discover dentists via LAN
    final dentistProfiles = await _showDentistSelectionDialog();

    if (dentistProfiles.isEmpty) {
      throw Exception(
        'No dentists found. Please ensure you are connected to the clinic network.',
      );
    }

    // Try to authenticate with each available dentist
    UserProfile? authenticatedUser;
    for (final dentist in dentistProfiles) {
      try {
        authenticatedUser = await _firebaseService.authenticateManagedUser(
          dentist.uid,
          _usernameController.text.trim(),
          _pinController.text.trim(),
        );
        if (authenticatedUser != null) break;
      } catch (e) {
        continue; // Try next dentist
      }
    }

    if (authenticatedUser == null) {
      throw Exception(
        'Invalid username or PIN. Please check your credentials.',
      );
    }

    // Store the authenticated managed user profile
    // In a real app, this would be stored securely and used throughout the session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'managedUserProfile',
      authenticatedUser.toJson().toString(),
    );
  }

  Future<List<UserProfile>> _showDentistSelectionDialog() async {
    final discoveryService = NetworkDiscoveryService();
    List<DiscoveredServer> discoveredServers = [];

    // Show loading dialog while discovering
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Discovering Dentists'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Scanning for dental clinic servers on your network...'),
          ],
        ),
      ),
    );

    try {
      // Start discovery
      await discoveryService.startDiscovery();

      // Wait for discovery results (listen for 10 seconds)
      final completer = Completer<List<DiscoveredServer>>();
      StreamSubscription? subscription;

      subscription = discoveryService.discoveredServers.listen((servers) {
        discoveredServers = servers;
        if (servers.isNotEmpty && !completer.isCompleted) {
          // Found at least one server, complete after a short delay to allow for more discoveries
          Future.delayed(const Duration(seconds: 3), () {
            if (!completer.isCompleted) {
              completer.complete(servers);
            }
          });
        }
      });

      // Timeout after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          completer.complete(discoveredServers);
        }
      });

      final finalServers = await completer.future;
      subscription.cancel();
      discoveryService.stopDiscovery();

      // Close loading dialog
      if (!mounted) return [];
      Navigator.of(context).pop();

      if (finalServers.isEmpty) {
        return [];
      }

      // Show selection dialog
      final selectedDentist = await showDialog<UserProfile>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Dental Clinic'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: finalServers.length,
              itemBuilder: (context, index) {
                final server = finalServers[index];
                return ListTile(
                  leading: const Icon(Icons.business, color: Colors.blue),
                  title: Text(server.clinicName),
                  subtitle: Text(
                    '${server.dentistName} - ${server.ipAddress}:${server.port}',
                  ),
                  onTap: () async {
                    // Create a UserProfile for the selected dentist
                    final dentistProfile = UserProfile(
                      uid: server.id,
                      email: '', // We don't have email for discovered dentists
                      licenseKey: '', // Will be set from Firebase
                      plan: SubscriptionPlan.free,
                      status: SubscriptionStatus.active,
                      licenseExpiry: DateTime.now().add(
                        const Duration(days: 365),
                      ),
                      createdAt: DateTime.now(),
                      lastLogin: DateTime.now(),
                      lastSync: DateTime.now(),
                      clinicName: server.clinicName,
                      dentistName: server.dentistName,
                      role: UserRole.dentist,
                    );

                    if (mounted) {
                      Navigator.of(context).pop(dentistProfile);
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      return selectedDentist != null ? [selectedDentist] : [];
    } catch (e) {
      discoveryService.stopDiscovery();

      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
      }

      return [];
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Contact Developer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dr. Tidjani Ahmed ZITOUNI',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _launchUrl('mailto:zitounitidjani@gmail.com'),
              child: Row(
                children: [
                  const Icon(Icons.email, color: Colors.blue),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'zitounitidjani@gmail.com',
                      style: GoogleFonts.poppins(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _launchUrl('tel:+213657293332'),
              child: Row(
                children: [
                  const Icon(Icons.phone, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    '+213 657 293 332',
                    style: GoogleFonts.poppins(
                      color: Colors.green,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.grey.shade900,
                        const Color(0xFF1E2746), // Deep Navy
                      ]
                    : [
                        const Color(0xFFE3F2FD), // Light Blue
                        const Color(0xFFBBDEFB), // Blue 100
                      ],
              ),
            ),
          ),

          // Background Pattern (Optional - subtle circles)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- Branding Section ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons
                            .medical_services_outlined, // More professional icon
                        size: 56,
                        color: Color(0xFF1976D2), // Professional Blue
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'DentalTid',
                      style: GoogleFonts.montserrat(
                        // Premium Font
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1565C0),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Professional Dental Management',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Mode Toggle - Hidden on Android (Dentist only)
                    if (!Platform.isAndroid)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed:
                                  _authMode == AuthMode.login ||
                                      _authMode == AuthMode.register
                                  ? null
                                  : () {
                                      setState(() {
                                        _authMode = AuthMode.login;
                                        _formKey.currentState?.reset();
                                      });
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    (_authMode == AuthMode.login ||
                                        _authMode == AuthMode.register)
                                    ? colorScheme.primary
                                    : colorScheme.surface,
                                foregroundColor:
                                    (_authMode == AuthMode.login ||
                                        _authMode == AuthMode.register)
                                    ? Colors.white
                                    : colorScheme.onSurface,
                              ),
                              child: const Text('Dentist'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _authMode == AuthMode.staffLogin
                                  ? null
                                  : () {
                                      setState(() {
                                        _authMode = AuthMode.staffLogin;
                                        _formKey.currentState!.reset();
                                      });
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _authMode == AuthMode.staffLogin
                                    ? colorScheme.primary
                                    : colorScheme.surface,
                                foregroundColor: _authMode == AuthMode.staffLogin
                                    ? Colors.white
                                    : colorScheme.onSurface,
                              ),
                              child: const Text('Client'),
                            ),
                          ],
                        ),
                      ),

                    // --- Auth Form Section ---
                    Container(
                      constraints: const BoxConstraints(maxWidth: 450),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _authMode == AuthMode.staffLogin
                                  ? 'Client Login'
                                  : _authMode == AuthMode.login
                                  ? 'Welcome Back'
                                  : 'Join DentalTid',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            if (_authMode == AuthMode.staffLogin) ...[
                              // Username Field for Staff
                              TextFormField(
                                controller: _usernameController,
                                style: GoogleFonts.poppins(),
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade50,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your username';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // PIN Field for Staff
                              TextFormField(
                                controller: _pinController,
                                style: GoogleFonts.poppins(),
                                decoration: InputDecoration(
                                  labelText: 'PIN (4 digits)',
                                  prefixIcon: const Icon(Icons.pin_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade50,
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your PIN';
                                  }
                                  if (value.length != 4) {
                                    return 'PIN must be 4 digits';
                                  }
                                  return null;
                                },
                              ),
                            ] else ...[
                              // Email Field for Dentists
                              TextFormField(
                                controller: _emailController,
                                style: GoogleFonts.poppins(),
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade50,
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
                              const SizedBox(height: 12),

                              // Password Field for Dentists
                              TextFormField(
                                controller: _passwordController,
                                style: GoogleFonts.poppins(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade50,
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
                            ],

                            if (_authMode == AuthMode.register) ...[
                              const SizedBox(height: 12),

                              // Clinic Name
                              TextFormField(
                                controller: _clinicNameController,
                                style: GoogleFonts.poppins(),
                                decoration: InputDecoration(
                                  labelText: 'Clinic Name',
                                  prefixIcon: const Icon(
                                    Icons.business_outlined,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade50,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your clinic name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Dentist Name
                              TextFormField(
                                controller: _dentistNameController,
                                style: GoogleFonts.poppins(),
                                decoration: InputDecoration(
                                  labelText: 'Your Name (e.g. Dr. Smith)',
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade50,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Phone Number
                              TextFormField(
                                controller: _phoneNumberController,
                                style: GoogleFonts.poppins(),
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade50,
                                ),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return null;
                                  }
                                  if (!RegExp(
                                    r'^\+?[0-9]{7,15}$',
                                  ).hasMatch(value)) {
                                    return 'Please enter a valid phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Medical License Number
                              TextFormField(
                                controller: _medicalLicenseNumberController,
                                style: GoogleFonts.poppins(),
                                decoration: InputDecoration(
                                  labelText: 'Medical License Number',
                                  prefixIcon: const Icon(Icons.badge_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade50,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your medical license number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Terms and Conditions
                              CheckboxListTile(
                                title: Text(
                                  'I accept the Terms and Conditions',
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                                value: _acceptTerms,
                                onChanged: (value) {
                                  setState(() => _acceptTerms = value ?? false);
                                },
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Auth Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _authenticate,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: colorScheme.primary,
                                elevation: 4,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _authMode == AuthMode.staffLogin
                                          ? 'STAFF LOGIN'
                                          : _authMode == AuthMode.login
                                          ? 'SIGN IN'
                                          : 'CREATE ACCOUNT',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                            ),

                            const SizedBox(height: 16),

                            // Switch Auth Mode
                            TextButton(
                              onPressed: _switchAuthMode,
                              child: Text(
                                _authMode == AuthMode.login
                                    ? "Don't have an account? Sign up"
                                    : 'Already have an account? Sign in',
                                style: GoogleFonts.poppins(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- Footer Branding ---
                    Column(
                      children: [
                        Text(
                          'Powered by',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Taedj Dev',
                          style: GoogleFonts.audiowide(
                            // Distinct tech/brand font
                            fontSize: 18,
                            color: isDark
                                ? Colors.blue.shade200
                                : Colors.blue.shade800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- Contact Us Floating Button ---
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: FloatingActionButton.extended(
                onPressed: _showContactDialog,
                backgroundColor: theme.cardColor.withValues(alpha: 0.9),
                elevation: 4,
                icon: const Icon(Icons.support_agent, color: Colors.blue),
                label: Text(
                  'Contact Us',
                  style: GoogleFonts.poppins(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
