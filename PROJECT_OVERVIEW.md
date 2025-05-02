# Surveying App Project Overview

## Project Description

This is a Flutter-based surveying and logging application designed for land surveyors and civil engineers. The app provides functionality for managing surveying jobs, coordinates, calculations, and instrument integrations. It supports various survey instruments and coordinate systems, with features for data import/export and job management.

## Tech Stack

- **Framework**: Flutter
- **State Management**: Custom ValueNotifier-based approach
- **Database**: SQLite for local storage (job-specific databases)
- **Architecture**: Feature-based modular architecture
- **Platforms**: Windows, potentially cross-platform

## Project Architecture

The application follows a feature-based architecture with the following organization:

```
lib/
├── features/           # Feature modules
│   ├── jobs/           # Job management features
│   │   ├── models/     # Data models (Job, JobDefaults)
│   │   ├── services/   # Business logic (JobService)
│   │   ├── viewmodels/ # State management
│   │   └── views/      # UI components
│   ├── job_details/    # Job-specific features
│   │   ├── models/     # Data models (Point)
│   │   ├── services/
│   │   ├── viewmodels/
│   │   └── views/
│   └── shared/         # Shared functionality
│       ├── services/   # Core services (DatabaseService, LoggerService)
│       ├── utils/      # Helper utilities
│       └── views/      # Common UI components
└── main.dart           # App entry point
```

## Core Features

### Job Management
- Create, edit, delete, and organize surveying jobs
- Import and export job data
- Job-specific settings and defaults
- Sorting and searching capabilities

### Coordinate Management
- Store and manage survey points with coordinates (Y/X/Z)
- Tagging and commenting on points
- Import/export points via CSV
- Support for different coordinate formats (YXZ, ENZ, MPC)

### Instrument Integration
- Support for various surveying instruments (Sokkia, Leica, Topcon, etc.)
- Manual data entry option
- Instrument-specific settings and configurations

### Calculations
- Scale factor calculations
- Height adjustments
- Tolerance calculations
- Angular measurements (degrees, grads)

### Settings and Defaults
- Per-job default settings
- Instrument-specific configurations
- Measurement precision options
- Interface customization

## Key Components

### Models

- **Job**: Represents a surveying job with metadata
- **JobDefaults**: Contains default settings for a specific job
- **Point**: Represents a survey point with coordinates (Y/X/Z), comment, and tag

### Services

- **DatabaseService**: Handles SQLite database operations
- **JobService**: Manages job-related operations
- **CSVService**: Handles import/export of points data
- **LoggerService**: Application logging functionality

### ViewModels

- **JobsViewModel**: Manages state for the jobs list
- **JobDetailsViewModel**: Manages state for job details screen

### Views

- **HomePageView**: Main navigation interface
- **JobsView**: List of available jobs
- **JobDetailsView**: Detail view for a specific job
- **JobDefaultsView**: Interface for viewing/editing job defaults
- **CreateJobView**: Interface for creating new jobs

## Database Structure

The app uses SQLite with a job-based database approach:
- Each job has its own database file
- Key tables include:
  - Points: Stores coordinate data
  - JobDefaults: Stores job-specific default settings (key-value pairs)

## Workflows

### Job Creation Workflow
1. User creates a new job with a name
2. System creates a new SQLite database for the job
3. System initializes default settings for the job
4. Job appears in the jobs list

### Point Management Workflow
1. User selects a job
2. System displays job details including points
3. User can add, edit, import or export points
4. Changes are saved to the job-specific database

### Job Defaults Workflow
1. User selects job defaults from job options
2. System displays current defaults in a form
3. User can edit default values
4. System saves updated defaults to database

## Future Enhancements

- GPS integration
- Cloud synchronization
- Advanced calculations
- Road design features
- Setting out functionality
- Report generation

---

*This document provides an overview of the project architecture and key components. Refer to specific code files for implementation details.* 