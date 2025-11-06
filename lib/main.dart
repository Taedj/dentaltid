import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/core/router.dart';
import 'package:dentaltid/src/core/theme_provider.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:dentaltid/src/core/language_provider.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dentaltid/src/features/security/application/audit_service.dart';
import 'package:dentaltid/src/features/security/domain/audit_event.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:dentaltid/firebase_options.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  Timer? _timer;
  final int _sessionTimeoutMinutes = 5; // 5 minutes of inactivity

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(Duration(minutes: _sessionTimeoutMinutes), _logout);
  }

  void _resetTimer() {
    _startTimer();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', false);
    ref
        .read(auditServiceProvider)
        .logEvent(
          AuditAction.logout,
          details: 'User logged out due to inactivity',
        ); // Log logout event
    // Navigate to login screen
    router.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(languageProvider);
    final theme = ref.watch(themeProvider);

    return Listener(
      onPointerDown: (_) =>
          _resetTimer(), // Reset timer on any pointer activity
      onPointerSignal: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      onPointerUp: (_) => _resetTimer(),
      onPointerCancel: (_) => _resetTimer(),
      child: MaterialApp.router(
        key: ValueKey(locale), // Force rebuild when locale changes
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        theme: appThemes[theme],
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
