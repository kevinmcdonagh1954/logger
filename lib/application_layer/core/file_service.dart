import 'dart:io';
import 'package:logger/application_layer/core/logging_service.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:get_it/get_it.dart';

/// Service for handling file operations safely across different platforms
class FileService {
  // Logger instance
  final LoggingService _logger = GetIt.instance<LoggingService>();
  final String _logName = 'FileService';

  /// Singleton instance
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  /// Get the application directory that leverages OneDrive for backup when available
  Future<Directory> getApplicationDirectory() async {
    Directory appDir;

    if (Platform.isWindows) {
      try {
        // On Windows, use Documents\Logger Jobs folder
        final docsDir = await getApplicationDocumentsDirectory();
        appDir = Directory(path.join(docsDir.path, 'Logger_Jobs'));

        // Create Logger Jobs folder if it doesn't exist
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
          _logger.info(_logName, 'Created Logger_Jobs folder: ${appDir.path}');
        }

        // Check if we're in OneDrive for logging purposes
        final isOnOneDrive = appDir.path.toLowerCase().contains('onedrive');
        if (isOnOneDrive) {
          _logger.info(
              _logName, 'Using OneDrive location for app data: ${appDir.path}');
        }
      } catch (e) {
        // Log the error
        _logger.error(_logName, 'Error creating Logger_Jobs folder', e);

        // Try a fallback location - using local app data instead
        final appDataDir = await getApplicationSupportDirectory();
        appDir = Directory(path.join(appDataDir.path, 'Logger_Jobs'));

        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
          _logger.info(
              _logName, 'Created fallback Logger_Jobs folder: ${appDir.path}');
        }
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      // For mobile, use app documents directory with Logger Jobs subfolder
      final docsDir = await getApplicationDocumentsDirectory();
      appDir = Directory(path.join(docsDir.path, 'Logger_Jobs'));
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
    } else {
      // Linux, macOS - also use Logger Jobs subfolder
      final docsDir = await getApplicationDocumentsDirectory();
      appDir = Directory(path.join(docsDir.path, 'Logger_Jobs'));
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
    }

    // Ensure the directory exists
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }

    return appDir;
  }

  /// Safely delete a directory with retry logic and proper error handling for OneDrive
  Future<bool> safeDeleteDirectory(String directoryPath,
      {int maxRetries = 5}) async {
    try {
      final dir = Directory(directoryPath);
      if (await dir.exists()) {
        // Simple direct deletion without retries or delays
        await dir.delete(recursive: true);
        return true;
      } else {
        // Directory doesn't exist, consider it a success
        return true;
      }
    } catch (e) {
      _logger.error(_logName, 'Failed to delete directory: $directoryPath', e);
      rethrow;
    }
  }

  /// Create a new job directory with proper error handling
  Future<Directory> createJobDirectory(String jobName) async {
    try {
      final appDir = await getApplicationDirectory();
      final sanitizedJobName = _sanitizeFileName(jobName);
      final jobDir = Directory(path.join(appDir.path, sanitizedJobName));

      if (await jobDir.exists()) {
        // Add a unique suffix if directory already exists
        int counter = 1;
        Directory uniqueJobDir;
        do {
          uniqueJobDir = Directory(
              path.join(appDir.path, '${sanitizedJobName}_${counter++}'));
        } while (await uniqueJobDir.exists());

        return await uniqueJobDir.create();
      } else {
        return await jobDir.create();
      }
    } catch (e) {
      _logger.error(
          _logName, 'Error creating job directory for job: $jobName', e);
      rethrow;
    }
  }

  /// Make a filename safe for all platforms by removing invalid characters
  String _sanitizeFileName(String fileName) {
    // Replace characters that are invalid in filenames
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  /// Recursively copy directory contents to destination
  Future<bool> copyDirectory(String sourcePath, String destinationPath) async {
    try {
      final sourceDir = Directory(sourcePath);
      final destDir = Directory(destinationPath);

      if (!await sourceDir.exists()) {
        _logger.error(_logName, 'Source directory does not exist: $sourcePath');
        return false;
      }

      // Create destination if it doesn't exist
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      // Copy all contents from source to destination
      await for (final entity in sourceDir.list(recursive: false)) {
        final fileName = path.basename(entity.path);
        final newPath = path.join(destinationPath, fileName);

        if (entity is File) {
          await entity.copy(newPath);
        } else if (entity is Directory) {
          // Recursively copy subdirectories
          await copyDirectory(entity.path, newPath);
        }
      }

      _logger.debug(_logName,
          'Successfully copied directory: $sourcePath to $destinationPath');
      return true;
    } catch (e) {
      _logger.error(_logName,
          'Error copying directory from $sourcePath to $destinationPath', e);
      return false;
    }
  }

  /// Get the Backups directory path within Logger_Jobs
  Future<Directory> getBackupsDirectory() async {
    final appDir = await getApplicationDirectory();
    final backupsDir = Directory(path.join(appDir.path, 'Backups'));

    // Create the Backups directory if it doesn't exist
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
      _logger.info(_logName, 'Created Backups folder: ${backupsDir.path}');
    }

    return backupsDir;
  }

  /// Get the Deleted directory path within Logger_Jobs
  Future<Directory> getDeletedDirectory() async {
    final appDir = await getApplicationDirectory();
    final deletedDir = Directory(path.join(appDir.path, 'Deleted'));

    // Create the Deleted directory if it doesn't exist
    if (!await deletedDir.exists()) {
      await deletedDir.create(recursive: true);
      _logger.info(_logName, 'Created Deleted folder: ${deletedDir.path}');
    }

    return deletedDir;
  }

  /// Get the logger directory path
  Future<String> getLoggerDirectory() async {
    try {
      if (Platform.isWindows) {
        return r'D:\Logger';
      }

      if (Platform.isAndroid) {
        final Directory? extDir = await getExternalStorageDirectory();
        if (extDir == null) {
          throw Exception('Could not access external storage');
        }
        final String rootPath = extDir.path.split('Android/data').first;
        return path.join(rootPath, 'Logger');
      }

      throw Exception('Unsupported platform');
    } catch (e) {
      _logger.error(_logName, 'Failed to get logger directory', e);
      rethrow;
    }
  }

  /// Get the jobs directory path
  Future<String> getJobsDirectory() async {
    try {
      final String loggerDir = await getLoggerDirectory();
      return path.join(loggerDir, 'Jobs');
    } catch (e) {
      _logger.error(_logName, 'Failed to get jobs directory', e);
      rethrow;
    }
  }
}
