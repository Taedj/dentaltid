import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/core/router.dart';
import 'package:dentaltid/src/core/theme_provider.dart';
import 'package:dentaltid/src/core/app_initializer.dart';
import 'package:dentaltid/l10n/app_localizations.dart';
import 'package:dentaltid/src/core/language_provider.dart';
import 'package:logging/logging.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:dentaltid/firebase_options.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:dentaltid/src/core/log_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup logging
  LogService.instance.init();

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  final log = Logger('Main');
  log.info('Application starting...');

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi; // Set the database factory
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
      key: ValueKey(locale), // Force rebuild when locale changes
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: appThemes[theme],
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
