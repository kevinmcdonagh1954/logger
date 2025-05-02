import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:logger/application_layer/core/logging_service.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../domain_layer/coordinates/point.dart';
import 'file_service.dart';
import '../../domain_layer/jobs/job_defaults.dart';

/// Service for managing SQLite database operations
class DatabaseService {
  // Singleton instance
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal() {
    // Initialize the logger and file service as early as possible
    _logger = GetIt.instance<LoggingService>();
    _fileService = GetIt.instance<FileService>();
  }

  // Currently opened database
  Database? _database;

  // Currently opened job name
  String? _currentJobName;

  // File service for safe file operations
  FileService? _fileService;

  // Logger
  LoggingService? _logger;
  final String _logName = 'DatabaseService';

  // Get the current job name
  String? get currentJobName => _currentJobName;

  Database? get database => _database;

  // Initialize the database service
  Future<void> init() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Initialize FFI for desktop platforms
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _logger?.info(_logName, 'Database service initialized');
  }

  // Get the Logger directory path
  Future<String> get loggerDirectoryPath async {
    // Get the application directory path directly (no need to create a separate Logger folder)
    final appDir = await _fileService!.getApplicationDirectory();

    // Return the application directory path which should be Logger_Jobs
    return appDir.path;
  }

  // Get the directory path for a job
  Future<String> getJobDirectoryPath(String jobName) async {
    try {
      // Get the application directory (Logger_Jobs) and create job subfolder inside it
      final appDir = await _fileService!.getApplicationDirectory();
      final jobDir = Directory(path.join(appDir.path, jobName));

      // Create the job directory if it doesn't exist
      if (!await jobDir.exists()) {
        await jobDir.create(recursive: true);
        _logger?.info(_logName, 'Created job directory: ${jobDir.path}');
      }

      return jobDir.path;
    } catch (e) {
      final errorMsg = 'Failed to get job directory path: ${e.toString()}';
      _logger?.error(_logName, errorMsg, e);
      throw Exception(errorMsg);
    }
  }

  // Create a new job database
  Future<Database> createJob(String jobName) async {
    _logger?.info(_logName, 'Creating new job: $jobName');
    final String jobPath = await getJobDirectoryPath(jobName);
    final String dbPath = path.join(jobPath, '$jobName.db');

    _currentJobName = jobName;

    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        // Create database schema
        await _createTables(db);
        _logger?.info(_logName, 'Created database schema for job: $jobName');

        // Create initial job defaults only during database creation
        final defaults = JobDefaults(
            databaseFileName: jobName,
            jobDescription: '',
            coordinateFormat: 'YXZ',
            instrument: 'MANUAL',
            dualCapture: 'N',
            scaleFactor: '1',
            heightAboveMSL: '0',
            meanYValue: '0',
            verticalAngleIndexError: '0',
            spotShotTolerance: '1.0',
            delayAndRetry: '4',
            timeout: '10',
            precision: 'Meters',
            commsBaudRate: '9600',
            horizontalAlignmentOffsetTolerance: '50',
            maximumSearchDistanceFromCL: '50',
            angularMeasurement: 'degrees');

        _logger?.debug(
            _logName, 'Setting initial job defaults: ${defaults.toMap()}');

        // Save initial defaults within the same transaction
        final Map<String, dynamic> map = defaults.toMap();
        for (var entry in map.entries) {
          if (entry.value != null && entry.key != 'databaseFileName') {
            await db.insert(
                'JobDefaults',
                {
                  'key': entry.key,
                  'value': entry.value.toString(),
                },
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      },
    );

    return _database!;
  }

  // Open an existing job database
  Future<Database> openJob(String jobName) async {
    _logger?.info(_logName, 'Opening job: $jobName');
    final String jobPath = await getJobDirectoryPath(jobName);
    final String dbPath = path.join(jobPath, '$jobName.db');

    // Check if database file exists
    final File dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      final errorMsg = 'Job database does not exist: $dbPath';
      _logger?.error(_logName, errorMsg);
      throw Exception(errorMsg);
    }

    _currentJobName = jobName;
    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        // This shouldn't be called since the database should already exist,
        // but we'll define it anyway as a fallback
        await _createTables(db);
      },
      onOpen: (Database db) async {
        // Validate tables exist, create them if they don't
        await _validateAndCreateTables(db);
      },
    );

    return _database!;
  }

  /// Create database tables
  Future<void> _createTables(Database db) async {
    _logger?.debug(_logName, 'Creating database tables');

    // Create JobDefaults table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS JobDefaults (
        id INTEGER PRIMARY KEY,
        key TEXT UNIQUE,
        value TEXT
      )
    ''');
    _logger?.debug(_logName, 'Created JobDefaults table');

    // Create Coords table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Coords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        comment TEXT,
        y REAL,
        x REAL,
        z REAL,
        descriptor TEXT,
        isDeleted INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    _logger?.debug(_logName, 'Created Coords table');
  }

  /// Validate tables exist and create them if they don't
  Future<void> _validateAndCreateTables(Database db) async {
    try {
      _logger?.debug(_logName, 'Validating database tables');

      // Check if JobDefaults table exists
      try {
        await db.query('JobDefaults', limit: 1);
        _logger?.debug(_logName, 'JobDefaults table exists');
      } catch (e) {
        _logger?.warning(
            _logName, 'JobDefaults table does not exist, creating it');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS JobDefaults (
            id INTEGER PRIMARY KEY,
            key TEXT UNIQUE,
            value TEXT
          )
        ''');
      }

      // Check if Coords table exists
      try {
        await db.query('Coords', limit: 1);
        _logger?.debug(_logName, 'Coords table exists');
      } catch (e) {
        _logger?.warning(_logName, 'Coords table does not exist, creating it');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS Coords (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            comment TEXT,
            y REAL,
            x REAL,
            z REAL,
            descriptor TEXT,
            isDeleted INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      }
    } catch (e) {
      _logger?.error(_logName, 'Error validating database tables: $e');
    }
  }

  // Close the current database
  Future<void> closeJob() async {
    _logger?.info(_logName, 'Closing job: $_currentJobName');

    try {
      if (_database != null) {
        if (_database!.isOpen) {
          await _database!.close();
          _logger?.info(_logName, 'Database closed for job: $_currentJobName');
        } else {
          _logger?.info(_logName, 'Database was already closed');
        }
        _database = null;
      }
    } catch (e) {
      _logger?.error(_logName, 'Error while closing database', e);
    } finally {
      _currentJobName = null;
    }
  }

  // Get all jobs
  Future<Map<String, dynamic>> getAllJobs() async {
    _logger?.info(_logName, 'Getting all jobs');
    final String loggerPath = await loggerDirectoryPath;
    final Directory loggerDir = Directory(loggerPath);

    if (!await loggerDir.exists()) {
      _logger?.warning(_logName,
          'Logger directory does not exist, returning empty job list');
      return {'jobs': []};
    }

    final List<FileSystemEntity> entities = await loggerDir.list().toList();
    final List<Map<String, dynamic>> jobsWithDates = [];

    for (var entity in entities) {
      if (entity is Directory) {
        final String jobName = path.basename(entity.path);

        // Skip folders that contain DELETED or BACKUPS in their name (case insensitive)
        if (jobName.toUpperCase().contains('DELETED') ||
            jobName.toUpperCase().contains('BACKUPS')) {
          _logger?.debug(_logName, 'Skipping special folder: ${entity.path}');
          continue;
        }

        // Check if the folder is empty
        final List<FileSystemEntity> folderContents =
            await entity.list().toList();
        if (folderContents.isEmpty) {
          _logger?.info(
              _logName, 'Found empty folder: ${entity.path}, deleting it');
          await entity.delete(recursive: true);
          continue;
        }

        // Check for corresponding .db file
        final String dbPath = path.join(entity.path, '$jobName.db');
        final File dbFile = File(dbPath);

        if (await dbFile.exists()) {
          // Valid job with database file
          final DateTime lastModified = await dbFile.lastModified();
          jobsWithDates.add({
            'name': jobName,
            'lastModified': lastModified,
          });
        } else {
          // This is a job folder without a database file - we'll delete it
          _logger?.warning(_logName,
              'Found job folder without database file: $jobName. Deleting invalid job folder.');
          await entity.delete(recursive: true);
        }
      }
    }

    // Sort the jobs by last modified date (most recent first)
    jobsWithDates
        .sort((a, b) => b['lastModified'].compareTo(a['lastModified']));

    // Extract just the job names in the sorted order
    final List<String> jobs =
        jobsWithDates.map((job) => job['name'] as String).toList();

    _logger?.debug(
        _logName, 'Found ${jobs.length} valid jobs: ${jobs.join(", ")}');
    return {
      'jobs': jobs,
    };
  }

  // Import points from CSV
  Future<int> insertPoints(List<Point> points) async {
    if (_database == null) {
      const errorMsg = 'No job database is open';
      _logger?.error(_logName, errorMsg);
      throw Exception(errorMsg);
    }

    _logger?.info(
        _logName, 'Importing ${points.length} points to job: $_currentJobName');
    int count = 0;

    try {
      // Ensure Coords table exists
      await _database!.execute('''
        CREATE TABLE IF NOT EXISTS Coords (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          comment TEXT,
          y REAL,
          x REAL,
          z REAL,
          descriptor TEXT,
          isDeleted INTEGER DEFAULT 0,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      _logger?.debug(_logName, 'Ensured Coords table exists before import');

      // Now perform the insert transaction
    await _database!.transaction((txn) async {
      for (var point in points) {
        await txn.insert(
          'Coords',
          point.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        count++;
      }
    });

    _logger?.info(_logName,
        'Successfully imported $count points to job: $_currentJobName');
    return count;
    } catch (e) {
      _logger?.error(_logName, 'Failed to import points: $e');
      throw Exception('Failed to import points: $e');
    }
  }

  // Get all points
  Future<List<Point>> getAllPoints() async {
    if (_database == null) {
      const errorMsg = 'No job database is open';
      _logger?.error(_logName, errorMsg);
      throw Exception(errorMsg);
    }

    _logger?.info(_logName, 'Getting all points for job: $_currentJobName');
    try {
      // Query all points from the Coords table (no job_name filter needed as each job has its own database)
      final List<Map<String, dynamic>> maps = await _database!.query('Coords');

    final points = List.generate(maps.length, (i) {
      return Point.fromMap(maps[i]);
    });

    _logger?.debug(_logName,
        'Retrieved ${points.length} points from job: $_currentJobName');
    return points;
    } catch (e) {
      // If table doesn't exist, try creating it
      _logger?.warning(_logName, 'Error querying Coords table: $e');
      _logger?.info(
          _logName, 'Attempting to create Coords table if it does not exist');

      try {
        // Create Coords table if it doesn't exist
        await _database!.execute('''
          CREATE TABLE IF NOT EXISTS Coords (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            comment TEXT,
            y REAL,
            x REAL,
            z REAL,
            descriptor TEXT,
            isDeleted INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        _logger?.info(
            _logName, 'Created Coords table schema or it already existed');
        // Try query again after creating table
        final List<Map<String, dynamic>> maps =
            await _database!.query('Coords');
        final points = List.generate(maps.length, (i) {
          return Point.fromMap(maps[i]);
        });

        return points;
      } catch (innerE) {
        _logger?.error(
            _logName, 'Failed to create or query Coords table: $innerE');
        throw Exception('Failed to get points: $innerE');
      }
    }
  }

  // Set job default value
  Future<void> setJobDefault(String key, String value) async {
    if (_database == null) {
      const errorMsg = 'No job database is open';
      _logger?.error(_logName, errorMsg);
      throw Exception(errorMsg);
    }

    _logger?.info(_logName,
        'Setting job default [$key=$value] for job: $_currentJobName');

    await _database!.insert(
      'JobDefaults',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get job default value
  Future<String?> getJobDefault(String key) async {
    if (_database == null) {
      const errorMsg = 'No job database is open';
      _logger?.error(_logName, errorMsg);
      throw Exception(errorMsg);
    }

    _logger?.debug(_logName,
        'Getting job default for key [$key] in job: $_currentJobName');

    final List<Map<String, dynamic>> maps = await _database!.query(
      'JobDefaults',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }

    return null;
  }

  // Dispose of resources when service is no longer needed
  Future<void> dispose() async {
    _logger?.info(_logName, 'Disposing DatabaseService');
    await closeJob();
    _currentJobName = null;
    _database = null;
  }

  /// Save job defaults to the database
  Future<void> saveJobDefaults(JobDefaults defaults) async {
    try {
      _logger?.info(_logName, 'Saving job defaults for job: $_currentJobName');

      if (_currentJobName == null) {
        throw Exception('No job is currently open');
      }

      if (_database == null || !_database!.isOpen) {
        throw Exception('Database is not open');
      }

      final Database db = _database!;

      // Convert the JobDefaults object to key-value pairs
      final Map<String, dynamic> map = defaults.toMap();
      _logger?.debug(_logName, 'Attempting to save job defaults map: $map');

      // Start transaction
      await db.transaction((txn) async {
        // Delete existing defaults
        final int deletedCount = await txn.delete('JobDefaults');
        _logger?.debug(_logName, 'Cleared $deletedCount existing job defaults');

        // Insert each field as a separate key-value row
        int insertedCount = 0;
        for (var entry in map.entries) {
          if (entry.value != null && entry.key != 'databaseFileName') {
            final String key = entry.key;
            final String value = entry.value.toString();

            _logger?.debug(_logName, 'Inserting default: $key = $value');

            // Insert new value
            await txn.insert(
                'JobDefaults',
                {
                  'key': key,
                  'value': value,
                },
                conflictAlgorithm: ConflictAlgorithm.replace);
            insertedCount++;
          }
        }
        _logger?.debug(_logName, 'Inserted $insertedCount job defaults');
      });

      // Verify the save by reading back
      final List<Map<String, dynamic>> saved = await db.query('JobDefaults');
      _logger?.debug(
          _logName, 'Retrieved ${saved.length} saved defaults: $saved');

      // Verify each key-value pair was saved correctly
      for (var entry in map.entries) {
        if (entry.value != null && entry.key != 'databaseFileName') {
          final savedRow = saved.firstWhere(
            (row) => row['key'] == entry.key,
            orElse: () => {'value': null},
          );

          final savedValue = savedRow['value'];
          final expectedValue = entry.value.toString();

          if (savedValue == null) {
            _logger?.error(
                _logName, 'Failed to save job default: ${entry.key}');
            throw Exception('Failed to save job default: ${entry.key}');
          }

          if (savedValue.toString() != expectedValue) {
            _logger?.error(
                _logName,
                'Job default ${entry.key} mismatch. '
                'Expected: $expectedValue, Got: $savedValue');
            throw Exception('Job default ${entry.key} was not saved correctly. '
                'Expected: $expectedValue, Got: $savedValue');
          }

          _logger?.debug(
              _logName, 'Verified default: ${entry.key} = $savedValue');
        }
      }

      _logger?.info(
          _logName, 'Successfully saved and verified all job defaults');
    } catch (e) {
      _logger?.error(_logName, 'Error saving job defaults: $e');
      throw Exception('Failed to save job defaults: $e');
    }
  }

  /// Get job defaults from the database
  Future<JobDefaults?> getJobDefaults() async {
    try {
      _logger?.info(_logName, 'Getting job defaults for job: $_currentJobName');

      if (_currentJobName == null) {
        _logger?.warning(_logName, 'No current job name set');
        return null;
      }

      if (_database == null || !_database!.isOpen) {
        throw Exception('Database is not open');
      }

      final Database db = _database!;

      // Query all defaults
      final List<Map<String, dynamic>> maps = await db.query('JobDefaults');
      _logger?.debug(_logName, 'Raw job defaults from database: $maps');

      if (maps.isEmpty) {
        _logger?.warning(_logName, 'No job defaults found in database');
        return JobDefaults(databaseFileName: _currentJobName!);
      }

      // Convert from key-value pairs to a single map
      Map<String, dynamic> defaultsMap = {'databaseFileName': _currentJobName!};

      for (var map in maps) {
        String key = map['key'] as String;
        String value = map['value'] as String;
        defaultsMap[key] = value;
        _logger?.debug(_logName, 'Loaded default: $key = $value');
      }

      _logger?.debug(_logName, 'Constructed defaults map: $defaultsMap');

      // Create JobDefaults object
      final defaults = JobDefaults.fromMap(defaultsMap);

      // Log all non-null values for verification
      defaults.toMap().forEach((key, value) {
        if (value != null) {
          _logger?.debug(_logName, 'JobDefaults.$key = $value');
        }
      });

      return defaults;
    } catch (e) {
      _logger?.error(_logName, 'Error retrieving job defaults: $e');
      throw Exception('Failed to retrieve job defaults: $e');
    }
  }

  // Delete a job (moves to Deleted folder first, then removes from Logger_Jobs)
  Future<void> deleteJob(String jobName) async {
    try {
      _logger?.info(_logName, 'Starting job deletion process: $jobName');

      // Close current job if it's the one being deleted
      if (_currentJobName == jobName) {
        await closeJob();
      }

      final String jobPath = await getJobDirectoryPath(jobName);
      final Directory jobDir = Directory(jobPath);

      if (await jobDir.exists()) {
        // First move to Deleted folder with timestamp
        final FileService fileService = GetIt.instance<FileService>();
        final Directory deletedDir = await fileService.getDeletedDirectory();

        // Create a unique folder name with timestamp
        final DateTime now = DateTime.now();
        final String timestamp =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
        final String deletedFolderName = '${jobName}_DELETED_$timestamp';
        final String deletedPath =
            path.join(deletedDir.path, deletedFolderName);

        // Copy to Deleted folder
        await fileService.copyDirectory(jobPath, deletedPath);
        _logger?.info(_logName, 'Job copied to deleted folder: $deletedPath');

        // Verify the copy was successful by checking if the deleted folder exists and has content
        final Directory deletedDir2 = Directory(deletedPath);
        if (!await deletedDir2.exists()) {
          throw Exception('Failed to copy job to deleted folder');
        }

        // Now delete from Logger_Jobs
        await jobDir.delete(recursive: true);

        // Verify the deletion
        if (await jobDir.exists()) {
          throw Exception('Failed to delete job from Logger_Jobs folder');
        }
        _logger?.info(_logName, 'Job removed from Logger_Jobs: $jobPath');
      } else {
        _logger?.warning(_logName, 'Job directory not found: $jobPath');
      }

      _logger?.info(_logName, 'Successfully completed job deletion: $jobName');
    } catch (e) {
      final String errorMsg = 'Failed to delete job: $jobName';
      _logger?.error(_logName, errorMsg, e);
      throw Exception('$errorMsg. ${e.toString()}');
    }
  }

  /// Rename a job
  Future<bool> renameJob(String oldJobName, String newJobName) async {
    try {
      _logger?.info(_logName, 'Renaming job from $oldJobName to $newJobName');

      // If this is the current job, close it first
      if (_currentJobName == oldJobName) {
        await closeJob();
      }

      final String oldJobPath = await getJobDirectoryPath(oldJobName);
      final String newJobPath = await getJobDirectoryPath(newJobName);

      // Check if the new job name already exists
      final Directory newJobDir = Directory(newJobPath);
      if (await newJobDir.exists()) {
        final errorMsg = 'Job name already exists: $newJobName';
        _logger?.error(_logName, errorMsg);
        throw Exception(errorMsg);
      }

      // Rename the job directory
      final Directory oldJobDir = Directory(oldJobPath);
      await oldJobDir.rename(newJobPath);
      _logger?.info(
          _logName, 'Job directory renamed: $oldJobPath to $newJobPath');

      _logger?.info(
          _logName, 'Successfully renamed job: $oldJobName to $newJobName');
      return true;
    } catch (e) {
      final errorMsg = 'Failed to rename job: ${e.toString()}';
      _logger?.error(_logName, errorMsg, e);
      return false;
    }
  }

  // Add a new point
  Future<Point> addPoint(Point point) async {
    if (_database == null) {
      const errorMsg = 'No job database is open';
      _logger?.error(_logName, errorMsg);
      throw Exception(errorMsg);
    }

    _logger?.info(_logName, 'Adding new point to job: $_currentJobName');
    try {
      final id = await _database!.insert(
        'Coords',
        point.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Return the point with the new ID
      return Point(
        id: id,
        comment: point.comment,
        y: point.y,
        x: point.x,
        z: point.z,
        descriptor: point.descriptor,
      );
    } catch (e) {
      _logger?.error(_logName, 'Failed to add point: $e');
      throw Exception('Failed to add point: $e');
    }
  }

  // Update an existing point
  Future<bool> updatePoint(Point point) async {
    if (_database == null) {
      const errorMsg = 'No job database is open';
      _logger?.error(_logName, errorMsg);
      throw Exception(errorMsg);
    }

    if (point.id == null) {
      const errorMsg = 'Cannot update point without ID';
      _logger?.error(_logName, errorMsg);
      throw Exception(errorMsg);
    }

    _logger?.info(
        _logName, 'Updating point ${point.id} in job: $_currentJobName');
    try {
      final rowsAffected = await _database!.update(
        'Coords',
        point.toMap(),
        where: 'id = ?',
        whereArgs: [point.id],
      );

      return rowsAffected > 0;
    } catch (e) {
      _logger?.error(_logName, 'Failed to update point: $e');
      throw Exception('Failed to update point: $e');
    }
  }

  // Delete a point
  Future<bool> deletePoint(int id) async {
    if (_database == null) {
      const errorMsg = 'No job database is open';
      _logger?.error(_logName, errorMsg);
      throw Exception(errorMsg);
    }

    _logger?.info(_logName, 'Deleting point $id from job: $_currentJobName');
    try {
      final rowsAffected = await _database!.delete(
        'Coords',
        where: 'id = ?',
        whereArgs: [id],
      );

      return rowsAffected > 0;
    } catch (e) {
      _logger?.error(_logName, 'Failed to delete point: $e');
      throw Exception('Failed to delete point: $e');
    }
  }
}
