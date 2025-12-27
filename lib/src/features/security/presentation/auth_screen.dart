import 'dart:async';
import 'dart:convert';
import 'package:dentaltid/src/shared/widgets/activation_dialog.dart';
import 'package:dentaltid/l10n/app_localizations.dart';

import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/core/firebase_service.dart';
import 'package:dentaltid/src/features/settings/application/staff_service.dart';
import 'package:dentaltid/src/features/settings/presentation/network_config_dialog.dart';
import 'package:dentaltid/src/core/network/sync_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dentaltid/src/core/settings_service.dart'; // Import SettingsService
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
  final _keyboardFocusNode = FocusNode();
  final _autocompleteFocusNode = FocusNode();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _dentistNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _medicalLicenseNumberController = TextEditingController();
  final _provinceController = TextEditingController();
  final _countryController = TextEditingController();
  final _clinicAddressController = TextEditingController();

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
  List<String> _savedEmails = [];

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _autocompleteFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _clinicNameController.dispose();
    _dentistNameController.dispose();
    _phoneNumberController.dispose();
    _medicalLicenseNumberController.dispose();
    _provinceController.dispose();
    _countryController.dispose();
    _clinicAddressController.dispose();
    _usernameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkAutoLogin() async {
    await SettingsService.instance.init(); // Initialize settings service
    final settings = SettingsService.instance;

    final rememberMe = settings.getBool('remember_me') ?? false;

    if (rememberMe) {
      if (mounted) setState(() => _rememberMe = true);

      // 1. Check for Managed User (Staff)
      final managedJson = settings.getString('managedUserProfile');
      if (managedJson != null) {
        if (mounted) context.go('/');
        return;
      }

      // 2. Check for Cached Profile (Dentist)
      final cachedProfileJson = settings.getString('cached_user_profile');
      if (cachedProfileJson != null) {
        try {
          final profileMap = Map<String, dynamic>.from(
            jsonDecode(cachedProfileJson),
          );
          final userProfile = UserProfile.fromJson(profileMap);

          if (!_isLicenseValid(userProfile)) return;

          if (mounted) context.go('/');
        } catch (e) {
          // invalid cache
        }
      }
    }

    // Load saved emails
    final emails = settings.getStringList('saved_emails');
    if (emails != null) {
      if (mounted) setState(() => _savedEmails = emails);
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.acceptTermsError),
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
            province: _provinceController.text,
            country: _countryController.text,
            clinicAddress: _clinicAddressController.text,
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

        // Save email to list if not present
        final email = _emailController.text;
        if (!_savedEmails.contains(email)) {
          _savedEmails.add(email);
          await SettingsService.instance.setStringList(
            'saved_emails',
            _savedEmails,
          );
        }

        final settings = SettingsService.instance;
        if (_rememberMe) {
          await settings.setBool('remember_me', true);
          await settings.setString(
            'cached_user_profile',
            jsonEncode(userProfile.toJson()),
          );
        } else {
          await settings.remove('remember_me');
          await settings.remove('cached_user_profile');
        }
        await settings.remove(
          'managedUserProfile',
        ); // Ensure staff session is cleared
      }

      final settings = SettingsService.instance;
      UserRole userRole = userProfile?.role ?? UserRole.dentist;
      await settings.setString('userRole', userRole.toString());
      final _ = await ref.refresh(userProfileProvider.future);

      ref
          .read(auditServiceProvider)
          .logEvent(
            _authMode == AuthMode.login
                ? AuditAction.login
                : AuditAction.createPatient,
            details:
                '${_authMode == AuthMode.login ? 'Dentist logged in' : 'Dentist registered'}: ${_emailController.text}',
          );

      if (mounted) context.go('/');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      String errorMessage = l10n.authError;
      if (e.code == 'weak-password') {
        errorMessage = l10n.weakPasswordError;
      } else if (e.code == 'email-already-in-use') {
        errorMessage = l10n.emailInUseError;
      } else if (e.code == 'user-not-found') {
        errorMessage = l10n.userNotFoundError;
      } else if (e.code == 'wrong-password') {
        errorMessage = l10n.wrongPasswordError;
      } else if (e.code == 'network-request-failed') {
        errorMessage = l10n.networkError;
      } else {
        errorMessage = l10n.authFailed(e.toString());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        _pinController.text.trim(),
      );

      if (staffUser != null) {
        // Create a session for Staff

        // Load Dentist Profile for License Inheritance
        await SettingsService.instance.init();
        final settings = SettingsService.instance;

        UserProfile? inheritedProfile;
        final dentistProfileJson = settings.getString(
          'dentist_profile',
        ); // From SyncClient.dart
        if (dentistProfileJson != null) {
          try {
            inheritedProfile = UserProfile.fromJson(
              jsonDecode(dentistProfileJson),
            );
          } catch (_) {}
        }

        final userProfile = UserProfile(
          uid: 'staff_${staffUser.id}',
          email: '${staffUser.username}@local.staff', // Dummy email
          licenseKey: inheritedProfile?.licenseKey ?? 'LOCAL_STAFF',
          plan: inheritedProfile?.plan ?? SubscriptionPlan.trial,
          status: inheritedProfile?.status ?? SubscriptionStatus.active,
          licenseExpiry: inheritedProfile?.licenseExpiry ?? DateTime.now(),
          createdAt: staffUser.createdAt,
          lastLogin: DateTime.now(),
          lastSync: DateTime.now(),
          isManagedUser: true,
          role: staffUser.role.toUserRole(),
          username: staffUser.username,
          fullName: staffUser.fullName,
          pin: staffUser.pin,
          dentistName: inheritedProfile?.dentistName ?? staffUser.fullName,
          isPremium: inheritedProfile?.isPremium ?? false,
          trialStartDate: inheritedProfile?.trialStartDate,
          premiumExpiryDate: inheritedProfile?.premiumExpiryDate,
        );

        if (_rememberMe) {
          await settings.setBool('remember_me', true);
        } else {
          await settings.remove('remember_me');
        }

        await settings.setString(
          'managedUserProfile',
          jsonEncode(userProfile.toJson()),
        );
        await settings.setString('userRole', userProfile.role.toString());

        // Clear dentist cache to avoid conflict
        await settings.remove('cached_user_profile');
        await FirebaseAuth.instance.signOut(); // Ensure no firebase session

        final _ = await ref.refresh(userProfileProvider.future);

        // IDENTIFY to server if already connected
        ref.read(syncClientProvider).sendIdentity();

        ref
            .read(auditServiceProvider)
            .logEvent(
              AuditAction.login,
              details: 'Staff logged in: ${staffUser.username}',
            );

        if (mounted) context.go('/');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.invalidStaffCredentials),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
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
      if (_authMode == AuthMode.login) {
        _authMode = AuthMode.register;
        _userType = UserType.dentist; // Registration is only for dentists
      } else {
        _authMode = AuthMode.login;
      }
      _formKey.currentState?.reset();
    });
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterEmailFirst),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.passwordResetSent),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.authFailed(e.message ?? 'An error occurred')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showContactDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          l10n.contactDeveloperLabel,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _launchUrl('mailto:zitounitidjani@gmail.com'),
              child: Row(
                children: [
                  const Icon(Icons.email, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'zitounitidjani@gmail.com',
                      style: GoogleFonts.poppins(
                        color: Colors.blueAccent,
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
                  const Icon(Icons.phone, color: Colors.greenAccent),
                  const SizedBox(width: 8),
                  Text(
                    '+213 657 293 332',
                    style: GoogleFonts.poppins(
                      color: Colors.greenAccent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _launchUrl('https://www.tidjanizitouni.com'),
              child: Row(
                children: [
                  const Icon(Icons.language, color: Colors.purpleAccent),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'www.tidjanizitouni.com',
                      style: GoogleFonts.poppins(
                        color: Colors.purpleAccent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 32, color: Colors.white12),
            Center(
              child: Column(
                children: [
                  Text(
                    'Powered by',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white38,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Taedj Dev',
                    style: GoogleFonts.audiowide(
                      fontSize: 14,
                      color: Colors.white54,
                      letterSpacing: 1.5,
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
            child: Text(
              l10n.close,
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  void _handleKeyEvents(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (HardwareKeyboard.instance.isControlPressed &&
          event.logicalKey == LogicalKeyboardKey.keyT) {
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
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvents,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Fallback base color
        body: Stack(
          children: [
            // 1. Space Background
            Positioned.fill(
              child: Image.asset(
                'assets/images/auth_bg.png',
                fit: BoxFit.cover,
              ),
            ),

            // 2. Main Content Centerer
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 24,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // --- The Glassmorphic Card ---
                      Container(
                        constraints: const BoxConstraints(maxWidth: 850),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // LEFT SIDE: Form
                            Expanded(
                              flex: 5,
                              child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    40,
                                    125, // Increased to clear branding
                                    40,
                                    25,  // Slightly reduced bottom padding
                                  ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Tab Switcher (ONLY show in Login mode)
                                      if (_authMode == AuthMode.login) ...[
                                        _buildTabSwitcher(colorScheme),
                                        const SizedBox(height: 24),
                                      ],

                                      // Title
                                      // Title
                                      Text(
                                        _userType == UserType.dentist
                                            ? (_authMode == AuthMode.login
                                                  ? l10n.dentistLogin
                                                  : l10n.dentistRegistration)
                                            : l10n.staffPortal,
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ), // Minimal gap to save space
                                      // Stable height container for forms
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        height: _authMode == AuthMode.login
                                            ? 160
                                            : 400, // Slightly more compact
                                        child: SingleChildScrollView(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            child: _userType == UserType.dentist
                                                ? _buildDentistForm(theme)
                                                : _buildStaffForm(theme),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 8), // Reduced gap
                                      // Sign In Button
                                      _buildActionButton(colorScheme),

                                    const SizedBox(
                                      height: 8,
                                    ), // Tightened gap
                                      // Remember Me & Forgot Password
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (_authMode == AuthMode.login ||
                                              _userType == UserType.staff)
                                            _buildRememberMeSection(),
                                          if (_userType == UserType.dentist &&
                                              _authMode == AuthMode.login)
                                            TextButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _resetPassword,
                                              child: Text(
                                                AppLocalizations.of(context)!.forgotPassword,
                                                style: GoogleFonts.poppins(
                                                  color: const Color(
                                                    0xFFA78BFA,
                                                  ),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      // Footer Action Link
                                      if (_userType == UserType.dentist)
                                        _buildFooterLink(colorScheme),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // RIGHT SIDE: Illustration (Hidden on small screens if needed, but here we assume desktop/tablet)
                            if (size.width > 700)
                              Expanded(
                                flex: 4,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: 20,
                                    top: 20,
                                    bottom: 20,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(24),
                                      bottomRight: Radius.circular(24),
                                    ),
                                    child: Image.asset(
                                      'assets/images/dentists_illustration.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // --- Overlapping Logo & Branding ---
                      Positioned(
                        top: -35, // Shunted slightly lower
                        left: 20,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                                child: Image.asset(
                                  'assets/images/DT!d.png',
                                  width: 120, // Reduced from 140
                                  height: 120, // Reduced from 140
                                  fit: BoxFit.contain,
                                ),
                            ),
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 25.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.montserrat(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                      children: [
                                        const TextSpan(text: 'Dental'),
                                        TextSpan(
                                          text: 'T!D',
                                          style: TextStyle(
                                            color: Colors.greenAccent.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'Professional Dental Management',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white70,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Top Right Contact Button
            Positioned(
              top: 24,
              right: 24,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: InkWell(
                    onTap: _showContactDialog,
                    borderRadius: BorderRadius.circular(30),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.support_agent,
                            color: Colors.blueAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.contactUs,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTabSwitcher(ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabItem(l10n.dentist, UserType.dentist)),
          Expanded(child: _buildTabItem(l10n.staff, UserType.staff)),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, UserType type) {
    final isSelected = _userType == type;
    return GestureDetector(
      onTap: () => setState(() => _userType = type),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDentistForm(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        RawAutocomplete<String>(
          textEditingController: _emailController,
          focusNode: _autocompleteFocusNode,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') {
              return _savedEmails;
            }
            return _savedEmails.where((String option) {
              return option
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
            }).toList();
          },
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted,
          ) {
            return _buildTextField(
              controller: textEditingController,
              label: l10n.emailAddress,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              focusNode: fieldFocusNode,
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<String> onSelected,
            Iterable<String> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return ListTile(
                        title: Text(
                          option,
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                          onPressed: () async {
                            setState(() {
                              _savedEmails.remove(option);
                            });
                             await SettingsService.instance.setStringList('saved_emails', _savedEmails);
                          },
                        ),
                        onTap: () {
                          onSelected(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12), // Reduced from 16
        _buildTextField(
          controller: _passwordController,
          label: l10n.password,
          icon: Icons.lock_outline,
          obscureText: true,
        ),
        if (_authMode == AuthMode.register) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _clinicNameController,
                  label: l10n.clinicNameLabel,
                  icon: Icons.business_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _dentistNameController,
                  label: l10n.yourName,
                  icon: Icons.person_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _phoneNumberController,
                  label: l10n.phoneNumber,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _medicalLicenseNumberController,
                  label: l10n.licenseNumber,
                  icon: Icons.badge_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _clinicAddressController,
            label: l10n.clinicAddress,
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _provinceController,
                  label: l10n.province,
                  icon: Icons.map_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _countryController,
                  label: l10n.country,
                  icon: Icons.public_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Theme(
            data: theme.copyWith(unselectedWidgetColor: Colors.white54),
            child: CheckboxListTile(
              title: Text(
                l10n.acceptTermsAndConditions,
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
              ),
              value: _acceptTerms,
              onChanged: (value) =>
                  setState(() => _acceptTerms = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFF8B5CF6),
              checkColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStaffForm(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _buildTextField(
          controller: _usernameController,
          label: l10n.username,
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _pinController,
          label: l10n.pin4Digits,
          icon: Icons.lock_outline,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        counterText: '',
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildActionButton(ColorScheme colorScheme) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _authenticate,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                _userType == UserType.dentist
                    ? (_authMode == AuthMode.login
                        ? AppLocalizations.of(context)!.signIn
                        : AppLocalizations.of(context)!.register)
                    : AppLocalizations.of(context)!.loginLabel,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    );
  }

  Widget _buildRememberMeSection() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.white54, size: 16),
        const SizedBox(width: 4),
        Text(
          AppLocalizations.of(context)!.rememberLabel,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(width: 4),
        Transform.scale(
          scale: 0.6,
          child: Switch(
            value: _rememberMe,
            activeThumbColor: const Color(0xFF8B5CF6),
            activeTrackColor: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            onChanged: (v) => setState(() => _rememberMe = v),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLink(ColorScheme colorScheme) {
    return Center(
      child: TextButton(
        onPressed: _switchAuthMode,
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
            children: [
              TextSpan(
                text: _authMode == AuthMode.login
                    ? AppLocalizations.of(context)!.dontHaveAccount
                    : AppLocalizations.of(context)!.alreadyHaveAccount,
              ),
              TextSpan(
                text: _authMode == AuthMode.login
                    ? AppLocalizations.of(context)!.signUpSmall
                    : AppLocalizations.of(context)!.signInSmall,
                style: const TextStyle(
                  color: Color(0xFFA78BFA),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
