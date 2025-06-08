import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'application_layer/core/service_locator.dart';
import 'presentation_layer/pages/startup/home_page_view.dart';
import 'application_layer/jobs/job_service.dart';
import 'application_layer/core/database_service.dart';
import 'application_layer/core/logging_service.dart';
import 'application_layer/core/localization_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize SQLite FFI for Windows
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory for desktop
      databaseFactory = databaseFactoryFfi;
    }

    // Initialize service locator first, before any service usage
    await setupLocator();

    // Get services after they're registered
    final logger = locator<LoggingService>();
    final databaseService = locator<DatabaseService>();
    final jobService = locator<JobService>();

    logger.debug('Main', 'Starting app initialization');

    // Initialize services
    await databaseService.init();
    logger.debug('Main', 'Database service initialized');

    await jobService.init();
    logger.debug('Main', 'Job service initialized');

    // Set up lifecycle observer
    WidgetsBinding.instance.addObserver(AppLifecycleObserver());
    logger.debug('Main', 'Lifecycle observer added');

    // Run the app
    runApp(const LoggerApp());
    logger.debug('Main', 'App started');
  } catch (e, stackTrace) {
    // Basic error logging since we might not have the logger service yet
    debugPrint('Error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow; // Rethrow to ensure the error is not silently swallowed
  }
}

/// Observer to handle app lifecycle events
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _cleanupResources();
    }
  }

  Future<void> _cleanupResources() async {
    try {
      final jobService = locator<JobService>();
      final databaseService = locator<DatabaseService>();
      final logger = locator<LoggingService>();

      await jobService.dispose();
      await databaseService.dispose();
      logger.info('System', 'Resources cleaned up successfully');
    } catch (e) {
      debugPrint('Error cleaning up resources: $e');
    }
  }
}

class LoggerApp extends StatelessWidget {
  const LoggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get logger after we know services are initialized
    final logger = locator<LoggingService>();
    logger.debug('LoggerApp', 'Building app with localization support');

    return ChangeNotifierProvider<LocalizationProvider>(
      create: (context) {
        final provider = LocalizationProvider();
        logger.debug('LoggerApp', 'Created LocalizationProvider');
        return provider;
      },
      child: Consumer<LocalizationProvider>(
        builder: (context, provider, _) {
          logger.debug(
              'LoggerApp', 'Current locale: ${provider.locale.languageCode}');
          return MaterialApp(
            title: 'Logger',
            locale: provider.locale,
            supportedLocales: LocalizationProvider.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              logger.debug(
                  'LoggerApp', 'Resolving locale: ${locale?.languageCode}');
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale?.languageCode) {
                  logger.debug('LoggerApp',
                      'Found matching supported locale: ${supportedLocale.languageCode}');
                  return supportedLocale;
                }
              }
              logger.debug('LoggerApp', 'Using fallback locale: en');
              return const Locale('en');
            },
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
