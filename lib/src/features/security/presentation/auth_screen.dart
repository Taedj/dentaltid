import 'dart:async';
import 'dart:convert';
import 'package:dentaltid/src/shared/widgets/activation_dialog.dart';

import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/core/firebase_service.dart';
import 'package:dentaltid/src/features/settings/application/staff_service.dart';
import 'package:dentaltid/src/features/settings/presentation/network_config_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
enum UserType { dentist, staff }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _focusNode = FocusNode();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _dentistNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _medicalLicenseNumberController = TextEditingController();
  
  // Staff Controllers
  final _usernameController = TextEditingController();
  final _pinController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final FirebaseService _firebaseService = FirebaseService();

  AuthMode _authMode = AuthMode.login;
  UserType _userType = UserType.dentist;
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
    _focusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _clinicNameController.dispose();
    _dentistNameController.dispose();
    _phoneNumberController.dispose();
    _medicalLicenseNumberController.dispose();
    _usernameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe) {
      if (mounted) setState(() => _rememberMe = true);

      // 1. Check for Managed User (Staff)
      final managedJson = prefs.getString('managedUserProfile');
      if (managedJson != null) {
          if (mounted) context.go('/');
          return;
      }

      // 2. Check for Cached Profile (Dentist)
      final cachedProfileJson = prefs.getString('cached_user_profile');
      if (cachedProfileJson != null) {
        try {
          final profileMap = Map<String, dynamic>.from(jsonDecode(cachedProfileJson));
          final userProfile = UserProfile.fromJson(profileMap);

          if (!_isLicenseValid(userProfile)) return;
          
          if (mounted) context.go('/');
        } catch (e) {
          // invalid cache
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
      _showDeploymentDialog(); 
      return false;
    }
    return true;
  }

  void _showDeploymentDialog() {
    // Implemented via activation dialog in authenticate flow
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_userType == UserType.staff) {
        await _authenticateStaff();
        return;
    }

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
            plan: SubscriptionPlan.trial,
            licenseKey: licenseKey,
            status: SubscriptionStatus.active,
            licenseExpiry: DateTime.now().add(const Duration(days: 36500)),
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
            lastSync: DateTime.now(),
            trialStartDate: DateTime.now(),
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
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
           userProfile = await _firebaseService.getUserProfile(user.uid);
        }
      }
      
      if (userProfile != null) {
          if (!_isLicenseValid(userProfile)) {
             await FirebaseAuth.instance.signOut();
             if (mounted) _showActivationDialog(userProfile.uid);
             return;
          }

          final prefs = await SharedPreferences.getInstance();
          if (_rememberMe) {
             await prefs.setBool('remember_me', true);
             await prefs.setString('cached_user_profile', jsonEncode(userProfile.toJson()));
          } else {
             await prefs.remove('remember_me');
             await prefs.remove('cached_user_profile');
          }
          await prefs.remove('managedUserProfile'); // Ensure staff session is cleared
      }

      final prefs = await SharedPreferences.getInstance();
      UserRole userRole = userProfile?.role ?? UserRole.dentist;
      await prefs.setString('userRole', userRole.toString());
      final _ = await ref.refresh(userProfileProvider.future);

      ref.read(auditServiceProvider).logEvent(
            _authMode == AuthMode.login ? AuditAction.login : AuditAction.createPatient,
            details: '${_authMode == AuthMode.login ? 'Dentist logged in' : 'Dentist registered'}: ${_emailController.text}',
      );

      if (mounted) context.go('/');
      
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
        message = 'Network error. check your connection.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Authentication failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _authenticateStaff() async {
      setState(() => _isLoading = true);
      try {
          final staffService = ref.read(staffServiceProvider);
          final staffUser = await staffService.authenticateStaff(
              _usernameController.text.trim(), 
              _pinController.text.trim()
          );

          if (staffUser != null) {
              // Create a session for Staff
              
              // Load Dentist Profile for License Inheritance
              final prefs = await SharedPreferences.getInstance();
              UserProfile? inheritedProfile;
              final dentistProfileJson = prefs.getString('dentist_profile');
              if (dentistProfileJson != null) {
                  try {
                      inheritedProfile = UserProfile.fromJson(jsonDecode(dentistProfileJson));
                  } catch (_) {}
              }

              final userProfile = UserProfile(
                  uid: 'staff_${staffUser.id}',
                  email: '${staffUser.username}@local.staff', // Dummy email
                  licenseKey: 'LOCAL_STAFF',
                  plan: inheritedProfile?.plan ?? SubscriptionPlan.trial,
                  status: SubscriptionStatus.active,
                  licenseExpiry: inheritedProfile?.licenseExpiry ?? DateTime.now(),
                  createdAt: staffUser.createdAt,
                  lastLogin: DateTime.now(),
                  lastSync: DateTime.now(),
                  isManagedUser: true,
                  role: staffUser.role.toUserRole(),
                  username: staffUser.username,
                  pin: staffUser.pin,
                  dentistName: inheritedProfile?.dentistName ?? staffUser.fullName, 
                  isPremium: inheritedProfile?.isPremium ?? false,
                  trialStartDate: inheritedProfile?.trialStartDate,
                  premiumExpiryDate: inheritedProfile?.premiumExpiryDate,
              );

              if (_rememberMe) {
                 await prefs.setBool('remember_me', true);
              } else {
                 await prefs.remove('remember_me');
              }
              
              await prefs.setString('managedUserProfile', jsonEncode(userProfile.toJson()));
              await prefs.setString('userRole', userProfile.role.toString());
              
              // Clear dentist cache to avoid conflict
              await prefs.remove('cached_user_profile');
              await FirebaseAuth.instance.signOut(); // Ensure no firebase session

              final _ = await ref.refresh(userProfileProvider.future);

              ref.read(auditServiceProvider).logEvent(
                  AuditAction.login,
                  details: 'Staff logged in: ${staffUser.username}',
              );

              if (mounted) context.go('/');
          } else {
              if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid Username or PIN'), backgroundColor: Colors.red)
                  );
              }
          }
      } catch (e) {
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
          }
      } finally {
          if (mounted) setState(() => _isLoading = false);
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
      _authMode = _authMode == AuthMode.login ? AuthMode.register : AuthMode.login;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Developer', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dr. Tidjani Ahmed ZITOUNI', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _launchUrl('mailto:zitounitidjani@gmail.com'),
              child: Row(
                children: [
                  const Icon(Icons.email, color: Colors.blue),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text('zitounitidjani@gmail.com', style: GoogleFonts.poppins(color: Colors.blue, decoration: TextDecoration.underline)),
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
                  Text('+213 657 293 332', style: GoogleFonts.poppins(color: Colors.green, decoration: TextDecoration.underline)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
  
  void _handleKeyEvents(KeyEvent event) {
      if (event is KeyDownEvent) {
          if (HardwareKeyboard.instance.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyT) {
              showDialog(
                  context: context,
                  builder: (context) => NetworkConfigDialog(userType: _userType),
              );
          }
      }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvents,
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
                        ? [Colors.grey.shade900, const Color(0xFF1E2746)]
                        : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
                  ),
                ),
              ),

              // Background Pattern
              Positioned(
                top: -50, right: -50,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -50, left: -50,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
              ),

              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
                              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: const Icon(Icons.medical_services_outlined, size: 56, color: Color(0xFF1976D2)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'DentalTid',
                          style: GoogleFonts.montserrat(fontSize: 38, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1565C0), letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Professional Dental Management',
                          style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 24),

                        // --- Auth Form Section ---
                        Container(
                          constraints: const BoxConstraints(maxWidth: 450),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 15)),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // --- User Type Switcher ---
                                Container(
                                    height: 45,
                                    decoration: BoxDecoration(
                                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                        children: [
                                            Expanded(
                                                child: GestureDetector(
                                                    onTap: () => setState(() => _userType = UserType.dentist),
                                                    child: Container(
                                                        decoration: BoxDecoration(
                                                            color: _userType == UserType.dentist ? colorScheme.primary : Colors.transparent,
                                                            borderRadius: BorderRadius.circular(12),
                                                            boxShadow: _userType == UserType.dentist ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)] : [],
                                                        ),
                                                        alignment: Alignment.center,
                                                        child: Text('Dentist', style: TextStyle(fontWeight: FontWeight.bold, color: _userType == UserType.dentist ? Colors.white : Colors.grey)),
                                                    ),
                                                ),
                                            ),
                                            Expanded(
                                                child: GestureDetector(
                                                    onTap: () => setState(() => _userType = UserType.staff),
                                                    child: Container(
                                                        decoration: BoxDecoration(
                                                            color: _userType == UserType.staff ? colorScheme.primary : Colors.transparent,
                                                            borderRadius: BorderRadius.circular(12),
                                                            boxShadow: _userType == UserType.staff ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)] : [],
                                                        ),
                                                        alignment: Alignment.center,
                                                        child: Text('Staff', style: TextStyle(fontWeight: FontWeight.bold, color: _userType == UserType.staff ? Colors.white : Colors.grey)),
                                                    ),
                                                ),
                                            ),
                                        ],
                                    ),
                                ),
                                const SizedBox(height: 24),
                                
                                Text(
                                  _userType == UserType.dentist
                                      ? (_authMode == AuthMode.login ? 'Dentist Login' : 'Join as Dentist')
                                      : 'Staff Portal',
                                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: theme.textTheme.titleLarge?.color),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                
                                // --- DENTIST FORM ---
                                if (_userType == UserType.dentist) ...[
                                    TextFormField(
                                        controller: _emailController,
                                        style: GoogleFonts.poppins(),
                                        decoration: InputDecoration(
                                            labelText: 'Email Address',
                                            prefixIcon: const Icon(Icons.email_outlined),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            filled: true,
                                            fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                        ),
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (value) {
                                            if (value == null || value.isEmpty) return 'Required';
                                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Invalid email';
                                            return null;
                                        },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                        controller: _passwordController,
                                        style: GoogleFonts.poppins(),
                                        decoration: InputDecoration(
                                            labelText: 'Password',
                                            prefixIcon: const Icon(Icons.lock_outline),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            filled: true,
                                            fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                        ),
                                        obscureText: true,
                                        validator: (value) {
                                            if (value == null || value.isEmpty) return 'Required';
                                            if (_authMode == AuthMode.register && value.length < 8) return 'Min 8 chars';
                                            return null;
                                        },
                                    ),
                                    
                                    if (_authMode == AuthMode.register) ...[
                                        const SizedBox(height: 12),
                                        TextFormField(
                                            controller: _clinicNameController,
                                            decoration: InputDecoration(labelText: 'Clinic Name', prefixIcon: const Icon(Icons.business_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50),
                                            validator: (v) => v!.isEmpty ? 'Required' : null,
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                            controller: _dentistNameController,
                                            decoration: InputDecoration(labelText: 'Your Name', prefixIcon: const Icon(Icons.person_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50),
                                            validator: (v) => v!.isEmpty ? 'Required' : null,
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                            controller: _phoneNumberController,
                                            decoration: InputDecoration(labelText: 'Phone', prefixIcon: const Icon(Icons.phone_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50),
                                            keyboardType: TextInputType.phone,
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                            controller: _medicalLicenseNumberController,
                                            decoration: InputDecoration(labelText: 'License Number', prefixIcon: const Icon(Icons.badge_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50),
                                            validator: (v) => v!.isEmpty ? 'Required' : null,
                                        ),
                                        const SizedBox(height: 16),
                                        CheckboxListTile(
                                            title: Text('I accept the Terms and Conditions', style: GoogleFonts.poppins(fontSize: 12)),
                                            value: _acceptTerms,
                                            onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                                            controlAffinity: ListTileControlAffinity.leading,
                                            contentPadding: EdgeInsets.zero,
                                        ),
                                    ],
                                ] 
                                // --- STAFF FORM ---
                                else ...[
                                    TextFormField(
                                        controller: _usernameController,
                                        decoration: InputDecoration(
                                            labelText: 'Username',
                                            prefixIcon: const Icon(Icons.person),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            filled: true,
                                            fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                        ),
                                        validator: (v) => v!.isEmpty ? 'Required' : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                        controller: _pinController,
                                        decoration: InputDecoration(
                                            labelText: 'PIN (4 Digits)',
                                            prefixIcon: const Icon(Icons.pin),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            filled: true,
                                            fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                        ),
                                        obscureText: true,
                                        maxLength: 4,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        validator: (v) => (v!.isEmpty || v.length != 4) ? 'Enter 4 digits' : null,
                                    ),
                                ],

                                const SizedBox(height: 24),

                                // Auth Button
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _authenticate,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    backgroundColor: colorScheme.primary,
                                    elevation: 4,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : Text(
                                          _userType == UserType.dentist
                                              ? (_authMode == AuthMode.login ? 'SIGN IN' : 'CREATE ACCOUNT')
                                              : 'LOGIN',
                                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0),
                                        ),
                                ),

                                const SizedBox(height: 16),
                                
                                // Remember Me
                                if (_authMode == AuthMode.login || _userType == UserType.staff)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.check_circle_outline, size: 20, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Remember Me',
                                          style: GoogleFonts.poppins(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(width: 8),
                                        Transform.scale(
                                            scale: 0.8,
                                            child: Switch(
                                              value: _rememberMe,
                                              onChanged: (value) => setState(() => _rememberMe = value),
                                            ),
                                        ),
                                      ],
                                    ),
                                  ),

                                const SizedBox(height: 16),

                                // Switch Auth Mode (Dentist only)
                                if (_userType == UserType.dentist)
                                    TextButton(
                                      onPressed: _switchAuthMode,
                                      child: Text(
                                        _authMode == AuthMode.login
                                            ? "Don't have an account? Sign up"
                                            : 'Already have an account? Sign in',
                                        style: GoogleFonts.poppins(color: colorScheme.primary, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                        Column(
                          children: [
                            Text('Powered by', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('Taedj Dev', style: GoogleFonts.audiowide(fontSize: 18, color: isDark ? Colors.blue.shade200 : Colors.blue.shade800, letterSpacing: 1.5)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16, right: 16,
                child: SafeArea(
                  child: FloatingActionButton.extended(
                    onPressed: _showContactDialog,
                    backgroundColor: theme.cardColor.withValues(alpha: 0.9),
                    elevation: 4,
                    icon: const Icon(Icons.support_agent, color: Colors.blue),
                    label: Text('Contact Us', style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }
}