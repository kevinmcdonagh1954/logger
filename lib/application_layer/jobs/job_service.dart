import 'package:flutter/foundation.dart';
import '../../domain_layer/coordinates/point.dart';
import '../core/database_service.dart';
import '../import_export/csv_service.dart';
import '../core/file_service.dart';
import '../core/logging_service.dart';
import 'package:get_it/get_it.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../domain_layer/jobs/job_defaults.dart';
import '../../../domain_layer/calculations/angle_converter.dart';

/// Service for managing job-related operations
class JobService {
  // Flag to track if a job is currently open
  bool _isJobOpen = false;
  bool _isInitialized = false;
  bool _isOpeningJob = false;

  // File service for safe file operations
  // Remove the 'late' keyword and initialize with null
  FileService? _fileService;

  // Database service
  // Remove the 'late' keyword and initialize with null
  DatabaseService? _databaseService;

  // CSV service
  CSVService? _csvService;

  // Logger
  // Remove the 'late' keyword and initialize with null
  LoggingService? _logger;
  final String _logName = 'JobService';

  // Value notifiers to expose job data to the UI
  final ValueNotifier<List<Point>> points = ValueNotifier<List<Point>>([]);
  final ValueNotifier<Map<String, String>> jobDefaults =
      ValueNotifier<Map<String, String>>({});

  // ValueNotifier for the current job name
  final ValueNotifier<String?> _currentJobName = ValueNotifier<String?>(null);

  // ValueNotifier for the list of all jobs
  final ValueNotifier<List<String>> _allJobs = ValueNotifier<List<String>>([]);

  // ValueNotifier for error messages
  final ValueNotifier<String?> _errorMessage = ValueNotifier<String?>(null);

  // Singleton instance
  static final JobService _instance = JobService._internal();
  factory JobService() => _instance;
  JobService._internal() {
    _fileService = GetIt.instance<FileService>();
    _databaseService = GetIt.instance<DatabaseService>();
    _csvService = GetIt.instance<CSVService>();
    _logger = GetIt.instance<LoggingService>();
    _init();
  }

  Future<void> _init() async {
    // This private init is now handled by the public init() method
    await init();
  }

  /// Getters for the value notifiers
  ValueNotifier<String?> get currentJobName => _currentJobName;
  ValueNotifier<List<String>> get allJobs => _allJobs;
  ValueNotifier<String?> get errorMessage => _errorMessage;

  /// Initialize the service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _logger?.info(_logName, 'Initializing JobService');

      // Initialize services if they're null
      _fileService ??= GetIt.instance<FileService>();
      _databaseService ??= GetIt.instance<DatabaseService>();
      _csvService ??= GetIt.instance<CSVService>();
      _logger ??= GetIt.instance<LoggingService>();

      // Initialize database service
      await _databaseService!.init();

      // Load all jobs first
      await loadAllJobs();

      // Only open the most recent job if no job is currently open
      if (_allJobs.value.isNotEmpty && !_isJobOpen) {
        // Get the most recent job (first in the list since it's sorted by last modified)
        final String mostRecentJob = _allJobs.value.first;
        _logger?.info(_logName, 'Opening most recent job: $mostRecentJob');
        await openJob(mostRecentJob);
      }

      _logger?.info(_logName, 'Job service initialized successfully');
      _isInitialized = true;
    } catch (e) {
      _logger?.error(_logName, 'Failed to initialize JobService', e);
      throw Exception('Failed to initialize JobService: $e');
    }
  }

  /// Load all jobs
  Future<void> loadAllJobs() async {
    try {
      _logger?.info(_logName, 'Loading all jobs');
      final Map<String, dynamic> result = await _databaseService!.getAllJobs();
      final List<String> jobs = result['jobs'] as List<String>;

      _allJobs.value = jobs;

      // Set appropriate message based on results
      if (jobs.isEmpty) {
        // No jobs at all
        _errorMessage.value =
            'No jobs found. Please create a new job to get started.';
      } else {
        // Normal case - jobs found
        _errorMessage.value = null;
      }

      _logger?.debug(_logName, 'Loaded ${jobs.length} jobs');
    } catch (e) {
      final errorMsg = 'Failed to load jobs: ${e.toString()}';
      _errorMessage.value = errorMsg;
      _logger?.error(_logName, errorMsg, e);
    }
  }

  /// Create a new job
  Future<bool> createJob(String jobName) async {
    try {
      _logger?.info(_logName, 'Creating new job: $jobName');

      // Create job database
      await _databaseService!.createJob(jobName);

      // Set as current job
      _currentJobName.value = jobName;
      _isJobOpen = true;

      _logger?.info(_logName, 'Set current job to: $jobName');

      // Load the initial defaults that were created with the database
      final defaults = await _databaseService!.getJobDefaults();
      if (defaults != null) {
        // Convert the map values to strings
        final Map<String, String> stringMap = {};
        defaults.toMap().forEach((key, value) {
          if (value != null) {
            stringMap[key] = value.toString();
          }
        });
        jobDefaults.value = stringMap;
        _logger?.debug(
            _logName, 'Loaded initial job defaults: ${jobDefaults.value}');
      }

      // Refresh job list
      await loadAllJobs();

      // Initialize empty points list
      points.value = [];

      _errorMessage.value = null;
      _logger?.info(_logName, 'Successfully created job: $jobName');
      return true;
    } catch (e) {
      // If there was an error, make sure we reset the job state
      _currentJobName.value = null;
      _isJobOpen = false;

      final errorMsg = 'Failed to create job: ${e.toString()}';
      _errorMessage.value = errorMsg;
      _logger?.error(_logName, errorMsg, e);
      return false;
    }
  }

  /// Open a job
  Future<bool> openJob(String jobName) async {
    if (_isOpeningJob) return false;
    _isOpeningJob = true;

    try {
      _logger?.info(_logName, 'Opening job: $jobName');

      // Initialize CSV service with job name
      await _csvService!.init(jobName);

      // Open job database
      await _databaseService!.openJob(jobName);

      // Set as current job
      _currentJobName.value = jobName;
      _isJobOpen = true;

      // Load points
      await loadPoints();

      // Load job defaults
      final defaults = await _databaseService!.getJobDefaults();
      if (defaults != null) {
        // Convert the map values to strings
        final Map<String, String> stringMap = {};
        defaults.toMap().forEach((key, value) {
          if (value != null) {
            stringMap[key] = value.toString();
          }
        });
        jobDefaults.value = stringMap;
        _logger?.debug(_logName, 'Loaded job defaults: ${jobDefaults.value}');
      } else {
        _logger?.warning(_logName, 'No job defaults found for job: $jobName');
      }

      _errorMessage.value = null;
      _logger?.info(_logName, 'Successfully opened job: $jobName');
      return true;
    } catch (e) {
      final errorMsg = 'Failed to open job: ${e.toString()}';
      _errorMessage.value = errorMsg;
      _logger?.error(_logName, errorMsg, e);
      return false;
    } finally {
      _isOpeningJob = false;
    }
  }

  /// Close the current job
  Future<bool> closeJob() async {
    try {
      _logger?.info(_logName, 'Closing current job: ${_currentJobName.value}');

      // Clear points data
      points.value = [];

      // Clear job defaults
      jobDefaults.value = {};

      // Close database connection
      await _databaseService!.closeJob();

      // Update state
      _currentJobName.value = null;
      _isJobOpen = false;

      _errorMessage.value = null;
      _logger?.info(_logName, 'Successfully closed job');
      return true;
    } catch (e) {
      final errorMsg = 'Failed to close job: ${e.toString()}';
      _errorMessage.value = errorMsg;
      _logger?.error(_logName, errorMsg);
      return false;
    }
  }

  /// Delete a job
  Future<bool> deleteJob(String jobName) async {
    try {
      _logger?.info(_logName, 'Deleting job: $jobName');

      // If this is the current job, close it first
      if (_currentJobName.value == jobName) {
        await closeJob();
      }

      // Use the DatabaseService's delete method
      await _databaseService!.deleteJob(jobName);

      // Refresh job list
      await loadAllJobs();

      _errorMessage.value = null;
      _logger?.info(_logName, 'Successfully deleted job: $jobName');
      return true;
    } catch (e) {
      final errorMsg = 'Failed to delete job: ${e.toString()}';
      _errorMessage.value = errorMsg;
      _logger?.error(_logName, errorMsg, e);
      return false;
    }
  }

  /// Rename a job
  Future<bool> renameJob(String oldJobName, String newJobName) async {
    try {
      _logger?.info(_logName, 'Renaming job from $oldJobName to $newJobName');

      // Validate the new job name
      if (newJobName.isEmpty) {
        throw Exception('New job name cannot be empty');
      }

      // Check if newJobName already exists
      if (_allJobs.value.contains(newJobName)) {
        throw Exception('A job with the name "$newJobName" already exists');
      }

      // If this is the current job, close it first
      final bool wasOpen = _currentJobName.value == oldJobName;
      if (wasOpen) {
        await closeJob();
      }

      // Get the paths
      final loggerDir = await _databaseService!.loggerDirectoryPath;
      final String oldPath = path.join(loggerDir, oldJobName);
      final String newPath = path.join(loggerDir, newJobName);

      // Verify old directory exists
      final oldDir = Directory(oldPath);
      if (!await oldDir.exists()) {
        throw Exception('Job directory does not exist: $oldPath');
      }

      // Check if new directory already exists to avoid conflicts
      final newDir = Directory(newPath);
      if (await newDir.exists()) {
        throw Exception('Directory for new job name already exists: $newPath');
      }

      // Get the old database file path
      final String oldDbPath = path.join(oldPath, '$oldJobName.db');
      final File oldDbFile = File(oldDbPath);
      if (!await oldDbFile.exists()) {
        throw Exception('Database file not found: $oldDbPath');
      }

      // Rename the directory
      await oldDir.rename(newPath);

      // Rename the database file inside the newly renamed directory
      final String newDbPath = path.join(newPath, '$oldJobName.db');
      final String finalDbPath = path.join(newPath, '$newJobName.db');
      final File newDbFile = File(newDbPath);
      await newDbFile.rename(finalDbPath);

      // Refresh job list
      await loadAllJobs();

      // Reopen the job if it was open
      if (wasOpen) {
        await openJob(newJobName);
      }

      _errorMessage.value = null;
      _logger?.info(
          _logName, 'Successfully renamed job from $oldJobName to $newJobName');
      return true;
    } catch (e) {
      final errorMsg = 'Failed to rename job: ${e.toString()}';
      _errorMessage.value = errorMsg;
      _logger?.error(_logName, errorMsg, e);
      return false;
    }
  }

  /// Backup a job to a specified destination path
  Future<String?> backupJob(String jobName, String destinationPath) async {
    try {
      _logger?.info(_logName, 'Backing up job: $jobName to $destinationPath');

      // Get the job directory path
      final String jobPath =
          await _databaseService!.getJobDirectoryPath(jobName);

      // Create the destination directory if it doesn't exist
      final destDir = Directory(destinationPath);
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      // Create backup folder name with timestamp
      final DateTime now = DateTime.now();
      final String timestamp =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
      final String backupFolderName = '${jobName}_backup_$timestamp';
      final String backupPath = path.join(destinationPath, backupFolderName);

      // Create the backup directory
      final backupDir = Directory(backupPath);
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Copy the job directory to the backup location
      await _fileService!.copyDirectory(jobPath, backupPath);

      _errorMessage.value = null;
      _logger?.info(
          _logName, 'Successfully backed up job: $jobName to $backupPath');
      return backupPath;
    } catch (e) {
      final errorMsg = 'Failed to backup job: $e';
      _errorMessage.value = errorMsg;
      _logger?.error(_logName, errorMsg, e);
      return null;
    }
  }

  /// Backup job to the default Backups directory
  Future<String?> backupJobToDefaultLocation(String jobName) async {
    try {
      // Get the default backups directory
      final backupsDir = await _fileService!.getBackupsDirectory();
      return await backupJob(jobName, backupsDir.path);
    } catch (e) {
      final errorMsg =
          'Failed to backup job to default location: ${e.toString()}';
      _errorMessage.value = errorMsg;
      _logger?.error(_logName, errorMsg, e);
      return null;
    }
  }

  /// Import points from CSV file
  Future<Map<String, dynamic>> importPointsFromCSV() async {
    try {
      _logger?.info(_logName,
          'Importing points from CSV for job: ${_currentJobName.value}');

      // Get CSV file path from user and parse points
      final Map<String, dynamic> importResult =
          await _csvService!.pickAndParseCSVToPoints();

      // Safely extract points, ensuring it's a List<Point>
      List<Point> newPoints = [];
      final pointsData = importResult['points'];
      if (pointsData is List<Point>) {
        newPoints = pointsData;
      } else if (pointsData is List) {
        // Attempt to convert the dynamic list to List<Point>
        _logger?.debug(_logName, 'Converting dynamic list to List<Point>');
        try {
          newPoints = pointsData.map((item) => item as Point).toList();
        } catch (e) {
          _logger?.error(_logName, 'Failed to convert points: $e');
          return {
            'count': 0,
            'errorCount': importResult['errorCount'] as int? ?? 1,
            'errorLogPath': importResult['errorLogPath'],
            'success': false,
            'message': 'Failed to process points: $e'
          };
        }
      }

      final int errorCount = importResult['errorCount'] as int? ?? 0;
      final String? errorLogPath = importResult['errorLogPath'];

      if (newPoints.isEmpty) {
        _logger?.info(_logName, 'No points found in CSV file');
        return {
          'count': 0,
          'errorCount': errorCount,
          'errorLogPath': errorLogPath,
          'success': false,
          'message': errorCount > 0
              ? 'Import failed: $errorCount errors found'
              : 'No points found in CSV file'
        };
      }

      try {
        // Import points to database
        _logger?.debug(
            _logName, 'Attempting to insert ${newPoints.length} points');
        final count = await _databaseService!.insertPoints(newPoints);
        _logger?.debug(_logName, 'Successfully inserted $count points');

        // Reload points to update UI
        await loadPoints();

        _errorMessage.value = null;
        _logger?.info(_logName,
            'Successfully imported $count points from CSV${errorCount > 0 ? ' with $errorCount errors' : ''}');

        return {
          'count': count,
          'errorCount': errorCount,
          'errorLogPath': errorLogPath,
          'success': true,
          'message':
              'Successfully imported $count points${errorCount > 0 ? ' with $errorCount errors' : ''}'
        };
      } catch (dbError) {
        _logger?.error(
            _logName, 'Database error during import: $dbError', dbError);
        _errorMessage.value = 'Database error during import: $dbError';

        return {
          'count': 0, // Reset count to 0 on database error
          'errorCount': errorCount,
          'errorLogPath': errorLogPath,
          'success': false,
          'message': 'Database error during import: $dbError'
        };
      }
    } catch (e) {
      final errorMsg = 'Failed to import points: $e';
      _errorMessage.value = errorMsg;
      _logger?.error(_logName, errorMsg, e);
      return {
        'count': 0,
        'errorCount': 0,
        'errorLogPath': null,
        'success': false,
        'message': errorMsg
      };
    }
  }

  /// Load points from database
  Future<void> loadPoints() async {
    try {
      _logger?.debug(
          _logName, 'Loading points for job: ${_currentJobName.value}');

      final loadedPoints = await _databaseService!.getAllPoints();
      points.value = loadedPoints;

      _errorMessage.value = null;
      _logger?.debug(_logName, 'Loaded ${loadedPoints.length} points');
    } catch (e) {
      final errorMsg = 'Failed to load points: ${e.toString()}';
      _errorMessage.value = errorMsg;
      _logger?.error(_logName, errorMsg, e);
    }
  }

  /// Export points to CSV file
  Future<String?> exportPointsToCSV() async {
    try {
      _logger?.info(_logName,
          'Exporting points to CSV for job: ${_currentJobName.value}');

      // Check if there are points to export
      if (points.value.isEmpty) {
        _logger?.warning(
            _logName, 'No points to export for job: ${_currentJobName.value}');
        return null;
      }

      // Get job directory path
      final jobPath =
          await _databaseService!.getJobDirectoryPath(_currentJobName.value!);

      // Export points to CSV
      final result = await _csvService!.exportPointsToCSV(
        points.value,
        _currentJobName.value!,
        jobPath,
      );

      _errorMessage.value = null;
      _logger?.info(_logName, 'Successfully exported points to CSV: $result');
      return result;
    } catch (e) {
      final errorMsg = 'Failed to export points: ${e.toString()}';
      _errorMessage.value = errorMsg;
      _logger?.error(_logName, errorMsg, e);
      return null;
    }
  }

  /// Set a job default value
  Future<bool> setJobDefault(String key, String value) async {
    try {
      _logger?.debug(_logName,
          'Setting job default: $key=$value for job: ${_currentJobName.value}');

      // Set job default
      await _databaseService!.setJobDefault(key, value);

      return true;
    } catch (e) {
      final errorMsg = 'Failed to set job default: ${e.toString()}';
      _errorMessage.value = errorMsg;
      _logger?.error(_logName, errorMsg, e);
      return false;
    }
  }

  /// Get a job default value
  Future<String?> getJobDefault(String key) async {
    try {
      _logger?.debug(_logName,
          'Getting job default: $key for job: ${_currentJobName.value}');

      // Get job default
      final value = await _databaseService!.getJobDefault(key);

      return value;
    } catch (e) {
      final errorMsg = 'Failed to get job default: ${e.toString()}';
      _errorMessage.value = errorMsg;
      _logger?.error(_logName, errorMsg, e);
      return null;
    }
  }

  /// Get job defaults for the current job
  Future<JobDefaults?> getJobDefaults() async {
    try {
      if (_currentJobName.value == null) {
        _logger?.warning(_logName, 'No job is currently open');
        return null;
      }

      return await _databaseService!.getJobDefaults();
      // return await _databaseService!.getJobDefaults();
    } catch (e) {
      _logger?.error(_logName, 'Error getting job defaults', e);
      throw Exception('Failed to get job defaults: ${e.toString()}');
    }
  }

  /// Save job defaults for the current job
  Future<bool> saveJobDefaults(JobDefaults defaults) async {
    try {
      _logger?.info(_logName, 'Saving job defaults');

      if (!_isJobOpen) {
        throw Exception('No job is currently open');
      }

      await _databaseService!.saveJobDefaults(defaults);

      // Convert the map values to strings
      final Map<String, String> stringMap = {};
      defaults.toMap().forEach((key, value) {
        if (value != null) {
          stringMap[key] = value.toString();
        }
      });
      jobDefaults.value = stringMap;
      _logger?.debug(_logName, 'Updated job defaults: ${jobDefaults.value}');

      _errorMessage.value = null;
      _logger?.info(_logName, 'Successfully saved job defaults');
      return true;
    } catch (e) {
      final errorMsg = 'Failed to save job defaults: ${e.toString()}';
      _errorMessage.value = errorMsg;
      _logger?.error(_logName, errorMsg, e);
      return false;
    }
  }

  /// Update job defaults from a map of values
  Future<bool> updateJobDefaults(
      String jobName, Map<String, dynamic> defaultsMap) async {
    try {
      _logger?.info(_logName, 'Updating job defaults for job: $jobName');
      _logger?.debug(_logName, 'Received defaults map: $defaultsMap');

      // Open the job if it's not already open
      final bool wasJobAlreadyOpen =
          _isJobOpen && _currentJobName.value == jobName;
      if (!wasJobAlreadyOpen) {
        await openJob(jobName);
      }

      // Get existing defaults first
      final existingDefaults = await _databaseService!.getJobDefaults();
      final Map<String, dynamic> currentMap = existingDefaults?.toMap() ?? {};
      _logger?.debug(_logName, 'Existing defaults: $currentMap');

      // Update only the fields that are provided in defaultsMap
      defaultsMap.forEach((key, value) {
        if (value != null) {
          // Convert values to strings and handle special cases
          switch (key) {
            case 'dualCapture':
              currentMap[key] = value == 'Yes' ? 'Y' : 'N';
              break;
            case 'scaleFactor':
            case 'heightAboveMSL':
            case 'meanYValue':
            case 'verticalAngleIndexError':
            case 'spotShotTolerance':
            case 'horizontalAlignmentOffsetTolerance':
            case 'maximumSearchDistanceFromCL':
              // Ensure numeric values are valid
              final num = double.tryParse(value.toString()) ?? 0.0;
              currentMap[key] = num.toString();
              break;
            case 'delayAndRetry':
            case 'timeout':
              // Ensure integer values are valid
              final num = int.tryParse(value.toString()) ?? 0;
              currentMap[key] = num.toString();
              break;
            default:
              currentMap[key] = value.toString();
          }
        }
      });

      // Ensure databaseFileName is set
      currentMap['databaseFileName'] = jobName;

      _logger?.debug(_logName, 'Updated defaults map: $currentMap');

      // Convert map to JobDefaults object
      final jobDefaults = JobDefaults.fromMap(currentMap);

      // Save the job defaults
      await saveJobDefaults(jobDefaults);

      // Close the job if we opened it just for this update
      if (!wasJobAlreadyOpen) {
        await closeJob();
      }

      _errorMessage.value = null;
      _logger?.info(
          _logName, 'Successfully updated job defaults for: $jobName');
      return true;
    } catch (e) {
      final errorMsg = 'Failed to update job defaults: ${e.toString()}';
      _errorMessage.value = errorMsg;
      _logger?.error(_logName, errorMsg, e);
      return false;
    }
  }

  /// Backup and delete a job
  Future<Map<String, dynamic>> backupAndDeleteJob(String jobName) async {
    try {
      _logger?.info(_logName, 'Backing up and deleting job: $jobName');

      // First backup the job to default location
      final backupPath = await backupJobToDefaultLocation(jobName);

      if (backupPath == null) {
        throw Exception('Failed to backup job before deletion');
      }

      // Then delete the job
      await _databaseService!.deleteJob(jobName);

      // Reload the jobs list
      await loadAllJobs();

      return {
        'success': true,
        'backupPath': backupPath,
        'message': 'Job "$jobName" backed up to $backupPath and deleted',
      };
    } catch (e) {
      final errorMsg = 'Failed to backup and delete job: ${e.toString()}';
      _errorMessage.value = errorMsg;
      _logger?.error(_logName, errorMsg, e);

      return {
        'success': false,
        'message': errorMsg,
      };
    }
  }

  /// Get job information
  Future<Map<String, dynamic>> getJobInfo(String jobName) async {
    try {
      _logger?.debug(_logName, 'Getting job info for: $jobName');

      // Get job directory path
      final String jobPath =
          await _databaseService!.getJobDirectoryPath(jobName);
      final String dbPath = path.join(jobPath, '$jobName.db');
      final File dbFile = File(dbPath);

      // Get file stats
      final FileStat stats = await dbFile.stat();
      final double sizeKB = stats.size / 1024;

      return {
        'date': stats.modified,
        'creationDate': stats.changed,
        'sizeKB': sizeKB.toStringAsFixed(1),
        'location': jobPath,
      };
    } catch (e) {
      _logger?.error(_logName, 'Failed to get job info: ${e.toString()}', e);
      return {
        'date': DateTime.now(),
        'creationDate': DateTime.now(),
        'sizeKB': '0.0',
        'location': 'Error retrieving location',
      };
    }
  }

  /// Dispose method to clean up all resources
  Future<void> dispose() async {
    try {
      _logger?.info(_logName, 'Disposing JobService');

      // Close any open job
      if (_isJobOpen) {
        await closeJob();
      }

      // Explicitly dispose database service
      await _databaseService?.dispose();

      // Clear all data
      points.value = [];
      jobDefaults.value = {};
      _allJobs.value = [];
      _currentJobName.value = null;
      _errorMessage.value = null;

      _logger?.info(_logName, 'JobService successfully disposed');
    } catch (e) {
      _logger?.error(_logName, 'Error disposing JobService', e);
    }
  }

  /// Add a new point
  Future<Point> addPoint(Point point) async {
    try {
      _logger?.info(
          _logName, 'Adding new point to job: ${_currentJobName.value}');

      // Add point to database
      final newPoint = await _databaseService!.addPoint(point);

      // Update points list
      final List<Point> updatedPoints = List.from(points.value)..add(newPoint);
      points.value = updatedPoints;

      _errorMessage.value = null;
      _logger?.info(
          _logName, 'Successfully added point with ID: ${newPoint.id}');
      return newPoint;
    } catch (e) {
      final errorMsg = 'Failed to add point: ${e.toString()}';
      _errorMessage.value = errorMsg;
      _logger?.error(_logName, errorMsg, e);
      throw Exception(errorMsg);
    }
  }

  /// Update an existing point
  Future<bool> updatePoint(Point point) async {
    try {
      _logger?.info(_logName,
          'Updating point ${point.id} in job: ${_currentJobName.value}');

      // Update point in database
      final success = await _databaseService!.updatePoint(point);

      if (success) {
        // Update points list
        final List<Point> updatedPoints = List.from(points.value);
        final index = updatedPoints.indexWhere((p) => p.id == point.id);
        if (index != -1) {
          updatedPoints[index] = point;
          points.value = updatedPoints;
        }
      }

      _errorMessage.value = null;
      _logger?.info(_logName, 'Successfully updated point ${point.id}');
      return success;
    } catch (e) {
      final errorMsg = 'Failed to update point: ${e.toString()}';
      _errorMessage.value = errorMsg;
      _logger?.error(_logName, errorMsg, e);
      throw Exception(errorMsg);
    }
  }

  /// Delete a point
  Future<bool> deletePoint(int id) async {
    try {
      _logger?.info(
          _logName, 'Deleting point $id from job: ${_currentJobName.value}');

      // Delete point from database
      final success = await _databaseService!.deletePoint(id);

      if (success) {
        // Update points list
        final List<Point> updatedPoints = List.from(points.value)
          ..removeWhere((p) => p.id == id);
        points.value = updatedPoints;
      }

      _errorMessage.value = null;
      _logger?.info(_logName, 'Successfully deleted point $id');
      return success;
    } catch (e) {
      final errorMsg = 'Failed to delete point: ${e.toString()}';
      _errorMessage.value = errorMsg;
      _logger?.error(_logName, errorMsg, e);
      throw Exception(errorMsg);
    }
  }

  /// Mark a point as deleted (soft delete)
  Future<void> markPointAsDeleted(int pointId) async {
    try {
      final point = points.value.firstWhere((p) => p.id == pointId);
      final updatedPoint = point.copyWith(isDeleted: true);
      await updatePoint(updatedPoint);
      _logger?.info(_logName, 'Point marked as deleted: $pointId');
    } catch (e) {
      _logger?.error(_logName, 'Error marking point as deleted: $e');
      throw Exception('Failed to mark point as deleted: $e');
    }
  }

  /// Unmark a point as deleted (restore)
  Future<void> unmarkPointAsDeleted(int pointId) async {
    try {
      final point = points.value.firstWhere((p) => p.id == pointId);
      final updatedPoint = point.copyWith(isDeleted: false);
      await updatePoint(updatedPoint);
      _logger?.info(_logName, 'Point restored: $pointId');
    } catch (e) {
      _logger?.error(_logName, 'Error restoring point: $e');
      throw Exception('Failed to restore point: $e');
    }
  }

  /// Get count of deleted points
  int getDeletedPointsCount() {
    return points.value.where((p) => p.isDeleted).length;
  }

  Future<String> getAngularMeasurement() async {
    final defaults = await getJobDefaults();
    final angularMeasurement = defaults?.angularMeasurement ?? 'DEGREES';

    // Update the angle converter with the current setting
    AngleConverter.setAngularMode(angularMeasurement);

    return angularMeasurement;
  }
}
