import 'dart:async';
import 'dart:convert';
import 'package:dentaltid/src/shared/widgets/activation_dialog.dart';

import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/core/firebase_service.dart';
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
  final _phoneNumberController = TextEditingController();
  final _medicalLicenseNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final FirebaseService _firebaseService = FirebaseService();

  AuthMode _authMode = AuthMode.login;
  bool _isLoading = false;
  bool _acceptTerms = false;

  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _clinicNameController.dispose();
    _dentistNameController.dispose();
    _phoneNumberController.dispose();
    _medicalLicenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe) {
      if (mounted) setState(() => _rememberMe = true);

      // Check if we have a cached profile for offline access
      final cachedProfileJson = prefs.getString('cached_user_profile');
      if (cachedProfileJson != null) {
        try {
          final profileMap = Map<String, dynamic>.from(
              // Using a simplified parsing approach assuming standard json decode
              // In production we imported dart:convert at file top
              // but here I'll rely on the existing imports or add it if needed.
              // Actually dart:convert is imported in firebase_service.dart but not here.
              // I should add import 'dart:convert'; to the top of file or use another way.
              // Safe bet: add the import in a separate tool call if it's missing, 
              // or assume standard jsonDecode is available if I add the import.
              // Wait, I can't add import easily with replace_file_content unless I replace top.
              // I'll assume current context allows it or the replacement includes it?
              // No, I must be careful. I'll read the file imports first? 
              // I've seen them: dart:async, dart:io, etc. No dart:convert.
              // I will use a separate specific replace for imports later or now.
              // For now, let's implement the logic assuming I'll fix imports.
               jsonDecode(cachedProfileJson)
          );
          final userProfile = UserProfile.fromJson(profileMap);

          // Check License/Trial Status
          if (!_isLicenseValid(userProfile)) {
             // If invalid, we don't auto-login. User sees login screen.
             // Maybe show a dialog saying "Session Expired"?
             // For now, just don't auto-login.
             return;
          }
          
          // Proceed to home if valid
          // Logic: If offline, go to home. If online, we might want to refresh auth.
          // But strict "Remember Me" usually skips login.
          if (mounted) {
             context.go('/');
          }
        } catch (e) {
          // invalid cache, ignore
        }
      }
    }
  }

  bool _isLicenseValid(UserProfile profile) {
    if (profile.isPremium) return true;

    final trialStart = profile.trialStartDate ?? profile.createdAt;
    final trialEnd = trialStart.add(const Duration(days: 30));
    final now = DateTime.now();

    if (now.isAfter(trialEnd)) {
      _showDeploymentDialog(); // Or Activation Dialog
      return false;
    }
    return true;
  }

  void _showDeploymentDialog() {
    // This will be implemented fully later or reusing contact dialog
    // For now, we rely on the logic in _authenticate to show the proper activation dialog
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
      UserProfile? userProfile;

      if (_authMode == AuthMode.register) {
        final User? user = await _firebaseService.signUpWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );

        if (user != null) {
          final licenseKey = const Uuid().v4();
          userProfile = UserProfile(
            uid: user.uid,
            email: user.email!,
            clinicName: _clinicNameController.text,
            dentistName: _dentistNameController.text,
            phoneNumber: _phoneNumberController.text,
            medicalLicenseNumber: _medicalLicenseNumberController.text,
            plan: SubscriptionPlan.trial, // Start with Trial
            licenseKey: licenseKey,
            status: SubscriptionStatus.active,
            licenseExpiry: DateTime.now().add(
              const Duration(days: 36500),
            ),
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
            lastSync: DateTime.now(),
            trialStartDate: DateTime.now(), // Set Trial Start
            isPremium: false,
          );

          await _firebaseService.createUserProfile(userProfile, licenseKey);
          ref.invalidate(userProfileProvider);
        }
      } else {
        // Login
        await _firebaseService.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
        // Fetch Profile to check status
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
           userProfile = await _firebaseService.getUserProfile(user.uid);
        }
      }
      
      // If we have a profile, Validation Check
      if (userProfile != null) {
          if (!_isLicenseValid(userProfile)) {
             await FirebaseAuth.instance.signOut(); // Logout
             if (mounted) {
                 _showActivationDialog(userProfile.uid); // Show Activation Input
             }
             return; // Stop execution
          }

          // Save for offline/remember me
          final prefs = await SharedPreferences.getInstance();
          
          if (_rememberMe) {
             await prefs.setBool('remember_me', true);
             await prefs.setString('cached_user_profile', jsonEncode(userProfile.toJson()));
          } else {
             await prefs.remove('remember_me');
             await prefs.remove('cached_user_profile');
          }
      }

      final prefs = await SharedPreferences.getInstance();
      UserRole userRole = userProfile?.role ?? UserRole.dentist;
      
      await prefs.setString('userRole', userRole.toString());
      final _ = await ref.refresh(userProfileProvider.future);

      ref
          .read(auditServiceProvider)
          .logEvent(
            _authMode == AuthMode.login
                ? AuditAction.login
                : AuditAction.createPatient,
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
      } else if (e.code == 'network-request-failed') { 
         // Handle Offline Login fallback manually here if needed, 
         // but _checkAutoLogin handles app start. 
         // If user explicitly clicks "Login" while offline, we could try local auth if "remember me" was set?
         // For now let's keep it simple.
         message = 'Network error. check your connection.';
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

  void _showActivationDialog(String uid) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ActivationDialog(uid: uid),
      );
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

    return Focus(
      autofocus: true,
      child: Scaffold(
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
                              _authMode == AuthMode.login
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
                              if (_authMode == AuthMode.register)
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
                              
                            ], // Close register block

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
                                      _authMode == AuthMode.login
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
                            
                            // Remember Me (Moved Here)
                            if (_authMode == AuthMode.login)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_outline, 
                                        size: 20, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Remember Me',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Transform.scale(
                                        scale: 0.8,
                                        child: Switch(
                                          value: _rememberMe,
                                          // activeColor: colorScheme.primary, // Deprecated
                                          onChanged: (value) {
                                              setState(() => _rememberMe = value);
                                          },
                                        ),
                                    ),
                                  ],
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
    ),
  );
}
}
