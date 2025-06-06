import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain_layer/coordinates/point.dart';
import 'package:logger/application_layer/core/logging_service.dart';
import 'package:get_it/get_it.dart';
import '../core/file_service.dart';

/// Service for handling CSV file operations
class CSVService {
  // Singleton instance
  static final CSVService _instance = CSVService._internal();
  factory CSVService() => _instance;
  CSVService._internal() {
    _logger = GetIt.instance<LoggingService>();
  }

  String? _currentJobName;
  LoggingService? _logger;
  final String _logName = 'CSVService';

  /// Initialize the service with a job name
  Future<void> init(String jobName) async {
    _currentJobName = jobName;
  }

  /// Dispose of resources
  Future<void> dispose() async {
    _currentJobName = null;
  }

  /// Pick and parse CSV file to points
  Future<Map<String, dynamic>> pickAndParseCSVToPoints() async {
    try {
      if (_currentJobName == null) {
        _logger?.error(_logName, 'CSVService not initialized with job name');
        return {'points': [], 'errorCount': 0};
      }

      // Use file picker to get the CSV file
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        _logger?.info(_logName, 'No file selected');
        return {'points': [], 'errorCount': 0};
      }

      // Get the file path
      final String path = result.files.first.path!;
      _logger?.info(_logName, 'Selected file: $path');

      // Read the file contents
      final File file = File(path);
      final String contents = await file.readAsString();

      // Parse the CSV
      final List<Point> points = [];
      final List<String> errorLines = [];
      int errorCount = 0;

      // Split the contents by line and skip the header
      final List<String> lines = contents.split('\n');
      if (lines.isEmpty) {
        _logger?.warning(_logName, 'CSV file is empty');
        return {'points': [], 'errorCount': 0};
      }

      // Skip the header line
      for (int i = 1; i < lines.length; i++) {
        final String line = lines[i].trim();
        if (line.isEmpty) continue;

        try {
          // Split the line by comma (or detect delimiter)
          final List<String> fields = line.split(',');

          // Validate that we have at least 4 fields
          if (fields.length < 4) {
            const errorMsg = 'Insufficient columns';
            _logger?.error(_logName, 'Error parsing row $i: $errorMsg');
            errorLines.add('Row $i: $errorMsg - Line: "$line"');
            errorCount++;
            continue;
          }

          // Parse the fields
          final String comment = fields[0].trim();
          final double? y = double.tryParse(fields[1].trim());
          final double? x = double.tryParse(fields[2].trim());
          final double? z = double.tryParse(fields[3].trim());

          if (y == null || x == null || z == null) {
            final errorMsg =
                'Invalid coordinates (Y=${fields[1]}, X=${fields[2]}, Z=${fields[3]})';
            _logger?.error(_logName, 'Error parsing row $i: $errorMsg');
            errorLines.add('Row $i: $errorMsg - Line: "$line"');
            errorCount++;
            continue;
          }

          // Create the point
          final Point point = Point(
            comment: comment,
            y: y,
            x: x,
            z: z,
          );

          points.add(point);
        } catch (e) {
          _logger?.error(_logName, 'Error parsing row $i: $e');
          errorLines.add('Row $i: $e - Line: "$line"');
          errorCount++;
        }
      }

      // Write errors to a log file if there are any
      String? errorLogPath;
      if (errorLines.isNotEmpty) {
        try {
          errorLogPath = await _writeErrorLogFile(errorLines);
          _logger?.info(_logName,
              'Parsed ${points.length} points with $errorCount errors. Error log at $errorLogPath');
        } catch (e) {
          // Do not fail the entire import if we can't write the error log
          _logger?.error(_logName, 'Failed to write error log: $e');
        }
      } else {
        _logger?.info(
            _logName, 'Parsed ${points.length} points with no errors');
      }

      return {
        'points': points,
        'errorCount': errorCount,
        'errorLogPath': errorLogPath
      };
    } catch (e) {
      _logger?.error(_logName, 'Error parsing CSV file: $e');
      // Return empty list as fallback
      return {'points': [], 'errorCount': 1};
    }
  }

  /// Write error log file
  Future<String> _writeErrorLogFile(List<String> errorLines) async {
    try {
      // Get the Logger_Jobs directory
      final String loggerJobsPath = await _getLoggerJobsPath();

      // Create the error log file
      final String errorLogPath = '$loggerJobsPath/Coordinate Import Error.log';
      final File errorLogFile = File(errorLogPath);

      // Add timestamp header
      final DateTime now = DateTime.now();
      final String timestamp =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      final String header = '=== Coordinate Import Errors ($timestamp) ===\n';

      // Write the errors to the file
      final String content = header + errorLines.join('\n');
      await errorLogFile.writeAsString(content);

      _logger?.info(_logName, 'Wrote error log to: $errorLogPath');
      return errorLogPath;
    } catch (e) {
      _logger?.error(_logName, 'Failed to write error log: $e');
      throw Exception('Failed to write error log: $e');
    }
  }

  /// Get the proper Logger_Jobs directory path
  Future<String> _getLoggerJobsPath() async {
    try {
      // Use FileService to get the application directory consistently
      final FileService fileService = GetIt.instance<FileService>();
      final Directory appDir = await fileService.getApplicationDirectory();

      // Create directory if it doesn't exist
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
        _logger?.info(
            _logName, 'Created Logger_Jobs directory at: ${appDir.path}');
      }

      return appDir.path;
    } catch (e) {
      _logger?.error(_logName, 'Failed to get Logger_Jobs directory: $e');
      rethrow;
    }
  }

  /// Export Points to a CSV file
  Future<String?> exportPointsToCSV(
      List<Point> points, String jobName, String directory) async {
    if (_currentJobName == null) {
      throw Exception('CSVService not initialized with a job name');
    }

    if (points.isEmpty) return null;

    final List<List<dynamic>> rows = [
      ['comment', 'y', 'x', 'z', 'descriptor'],
      ...points.map((point) =>
          [point.comment, point.y, point.x, point.z, point.descriptor ?? ''])
    ];

    final String csv = const ListToCsvConverter().convert(rows);
    final String filePath = '$directory/${jobName}_points.csv';
    await File(filePath).writeAsString(csv);
    return filePath;
  }
}
