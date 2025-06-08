import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

/// A service to handle application logging using the logging package
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  // Map of loggers by name
  final Map<String, Logger> _loggers = {};
  bool _initialized = false;

  /// Initialize the logging system
  void init() {
    if (_initialized) return;

    // Set up logging configuration
    Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
    Logger.root.onRecord.listen((record) {
      // Format the log message
      final message =
          '${record.time}: ${record.loggerName}: ${record.level.name}: ${record.message}';

      // Add stack trace if present
      final logMessage = record.error != null
          ? '$message\nError: ${record.error}\nStack Trace: ${record.stackTrace}'
          : message;

      // In debug mode, print to console
      if (kDebugMode) {
        debugPrint(logMessage);
      }

      // In production, additional log handling could be added here
      // e.g., sending logs to a remote service, writing to a file, etc.
    });

    _initialized = true;
  }

  /// Get a logger for a specific class or component
  Logger getLogger(String name) {
    if (!_initialized) {
      init();
    }

    if (!_loggers.containsKey(name)) {
      _loggers[name] = Logger(name);
    }
    return _loggers[name]!;
  }

  /// Log at info level
  void info(String name, String message,
      [Object? error, StackTrace? stackTrace]) {
    getLogger(name).info(message, error, stackTrace);
  }

  /// Log at warning level
  void warning(String name, String message,
      [Object? error, StackTrace? stackTrace]) {
    getLogger(name).warning(message, error, stackTrace);
  }

  /// Log at severe/error level
  void error(String name, String message,
      [Object? error, StackTrace? stackTrace]) {
    getLogger(name).severe(message, error, stackTrace);
  }

  /// Log at fine/debug level (only output in debug mode)
  void debug(String name, String message,
      [Object? error, StackTrace? stackTrace]) {
    getLogger(name).fine(message, error, stackTrace);
  }
}
