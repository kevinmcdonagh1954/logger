import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Base ViewModel class that all ViewModels should inherit from
abstract class BaseViewModel {
  // ValueNotifier for busy state (when asynchronous operations are running)
  final ValueNotifier<bool> _isBusy = ValueNotifier<bool>(false);

  // ValueNotifier for error state
  final ValueNotifier<bool> _hasError = ValueNotifier<bool>(false);

  // ValueNotifier for error message
  final ValueNotifier<String?> _errorMessage = ValueNotifier<String?>(null);

  // Getters for the ValueNotifiers so views can listen to them
  ValueNotifier<bool> get isBusy => _isBusy;
  ValueNotifier<bool> get hasError => _hasError;
  ValueNotifier<String?> get errorMessage => _errorMessage;

  /// Execute a future and set busy state while it's running
  Future<T> runBusyFuture<T>(Future<T> future) async {
    try {
      _isBusy.value = true;
      _hasError.value = false;
      _errorMessage.value = null;
      return await future;
    } catch (e) {
      setError(e.toString());
      rethrow;
    } finally {
      _isBusy.value = false;
    }
  }

  /// Set an error message
  void setError(String message) {
    _hasError.value = true;
    _errorMessage.value = message;
  }

  /// Clear the error state
  void clearError() {
    _hasError.value = false;
    _errorMessage.value = null;
  }

  /// Safely delete a directory with retry logic and proper error handling
  /// Returns true if successful, false otherwise
  Future<bool> safeDeleteDirectory(String directoryPath,
      {int maxRetries = 3, int delayMs = 500}) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        final dir = Directory(directoryPath);
        if (await dir.exists()) {
          // Force close any open handles before deletion
          await _closeOpenHandles(dir);

          // Delete the directory recursively
          await dir.delete(recursive: true);
          return true;
        } else {
          // Directory doesn't exist, consider it a success
          return true;
        }
      } catch (e) {
        attempts++;

        if (attempts >= maxRetries) {
          // All retries failed, report the error
          setError('Failed to delete directory: ${e.toString()}');
          return false;
        }

        // Wait before retrying
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    return false;
  }

  /// Helper method to try to close any open file handles in a directory
  Future<void> _closeOpenHandles(Directory directory) async {
    try {
      // Get all files in the directory
      List<FileSystemEntity> entities =
          await directory.list(recursive: true).toList();

      // Loop through all files and attempt to open and close them to release handles
      for (var entity in entities) {
        if (entity is File) {
          try {
            final file = File(entity.path);
            // Try to open and immediately close the file to ensure no handles are left open
            final randomAccessFile = await file.open(mode: FileMode.read);
            await randomAccessFile.close();
          } catch (e) {
            // Ignore errors, just try to close as many files as possible
          }
        }
      }
    } catch (e) {
      // Ignore errors in the cleanup process
    }
  }

  /// Safely move a directory with proper error handling for Windows and OneDrive
  Future<bool> safeMoveDirectory(
      String sourcePath, String destinationPath) async {
    try {
      final sourceDir = Directory(sourcePath);
      final destDir = Directory(destinationPath);

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
          await safeMoveDirectory(entity.path, newPath);
        }
      }

      // Then try to delete the source
      return await safeDeleteDirectory(sourcePath);
    } catch (e) {
      setError('Failed to move directory: ${e.toString()}');
      return false;
    }
  }

  /// Dispose all ValueNotifiers
  void dispose() {
    // Ensure all potentially pending futures are handled gracefully
    _isBusy.value = false;

    // Clear any error states
    _hasError.value = false;
    _errorMessage.value = null;

    // Dispose ValueNotifiers
    _isBusy.dispose();
    _hasError.dispose();
    _errorMessage.dispose();
  }
}
