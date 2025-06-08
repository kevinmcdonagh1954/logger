# Logger App

A Flutter logging application using the MVVM (Model-View-ViewModel) architecture.

## Architecture Overview

This project follows the MVVM architectural pattern to ensure:

1. **Separation of concerns** - Business logic is separated from UI code
2. **Testability** - ViewModels and Services are fully testable
3. **Unidirectional data flow** - State flows from higher classes down to the view

### Key Components

- **Models** - Data classes representing the core entities (e.g., LogEntry)
- **Views** - UI components that depend on ViewModels for their data and actions
- **ViewModels** - Classes that handle business logic, state, and interactions with services
- **Services** - App-wide classes that provide functionality to multiple ViewModels

### Design Decisions

- Each view has exactly one ViewModel
- All state in ViewModels is exposed as ValueNotifiers
- Services are injected into ViewModels via constructor injection
- The service locator pattern (get_it) is used for dependency injection

## State Management

The application uses Flutter's `ValueListenableBuilder` widget to reactively update the UI when state changes. This allows for:

- Fine-grained control over what gets rebuilt
- Clear traceability of state changes
- Simplified testing

## Project Structure

```
lib/
  ├── models/            # Data models
  ├── services/          # App-wide services
  ├── viewmodels/        # ViewModels for each view
  ├── views/             # UI components
  ├── utils/             # Utility functions and constants
  └── main.dart          # Application entry point
```

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

## Dependencies

- flutter: The Flutter SDK
- provider: For dependency injection and widget rebuilding
- get_it: For service locator pattern
- shared_preferences: For persistent storage
- http: For network requests (future use)
