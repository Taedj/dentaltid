import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/core/router.dart';
import 'package:dentaltid/src/core/theme_provider.dart';
import 'package:dentaltid/src/core/app_initializer.dart';
import 'package:dentaltid/src/core/settings_service.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:dentaltid/src/core/language_provider.dart';
import 'package:logging/logging.dart';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:dentaltid/firebase_options.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:dentaltid/src/core/log_service.dart';
import 'package:dentaltid/src/core/remote_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup logging
  final logService = LogService.instance;
  await logService.init();
  
  final log = Logger('Main');

  // Catch Flutter Errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    log.severe('FLUTTER ERROR: ${details.exception}', details.exception, details.stack);
  };

  // Catch Platform/Dart Errors
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    log.severe('PLATFORM ERROR: $error', error, stack);
    return true;
  };

  Logger.root.level = Level.ALL;

  log.info('Application starting...');

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    log.info('Initializing native database factory...');
    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      log.info('Native database factory initialized successfully.');
    } catch (e, s) {
      log.severe('Failed to initialize native database factory', e, s);
    }
  }

  log.info('Initializing Firebase...');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log.info('Firebase initialized successfully.');
  } catch (e, s) {
    log.severe('Failed to initialize Firebase', e, s);
  }

  log.info('Initializing Settings...');
  try {
    await SettingsService.instance.init();
    log.info('Settings initialized successfully.');
  } catch (e, s) {
    log.severe('Failed to initialize Settings', e, s);
  }

  log.info('Initializing Remote Config...');
  try {
    final remoteConfigService = RemoteConfigService(); // Create an instance
    await remoteConfigService.fetchAndCacheConfig(); // Fetch and cache
    log.info('Remote Config initialized successfully.');
  } catch (e, s) {
    log.severe('Failed to initialize Remote Config', e, s);
  }

  log.info('Ready to runApp...');
  runApp(const ProviderScope(
    child: MyApp(),
  ));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize sync services in the background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appInitializerProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final log = Logger('MyApp');
    log.info('Building MyApp widget...');
    final locale = ref.watch(languageProvider);
    final theme = ref.watch(themeProvider);

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: appThemes[theme],
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
