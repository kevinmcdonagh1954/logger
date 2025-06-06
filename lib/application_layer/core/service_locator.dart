import 'package:get_it/get_it.dart';
import '../../presentation_layer/pages/jobs/jobs_viewmodel.dart';
import '../../presentation_layer/pages/jobs/create_job_viewmodel.dart';
import '../../presentation_layer/pages/jobs/job_details_viewmodel.dart';
import '../../presentation_layer/pages/import_export/import_points_viewmodel.dart';
import '../../presentation_layer/pages/coordinates/coordinates_viewmodel.dart';
import '../../presentation_layer/viewmodels/usage_viewmodel.dart';
import 'database_service.dart';
import '../import_export/csv_service.dart';
import '../jobs/job_service.dart';
import '../fixing/fixing_service.dart';
import 'file_service.dart';
import 'logging_service.dart';

// Create a global instance of GetIt
final locator = GetIt.instance;

/// Setup function to register all services and ViewModels
Future<void> setupLocator() async {
  // Register services
  locator.registerSingleton<LoggingService>(LoggingService());
  locator.registerSingleton<FileService>(FileService());
  locator.registerSingleton<DatabaseService>(DatabaseService());
  locator.registerSingleton<CSVService>(CSVService());
  locator.registerSingleton<JobService>(JobService());
  locator.registerSingleton<FixingService>(FixingService());

  // Register ViewModels as factories (new instance each time)
  locator.registerFactory<JobsViewModel>(
      () => JobsViewModel(locator<JobService>()));
  locator.registerFactory<CreateJobViewModel>(
      () => CreateJobViewModel(locator<JobService>()));
  locator.registerFactory<JobDetailsViewModel>(
      () => JobDetailsViewModel(locator<JobService>()));
  locator.registerFactory<ImportPointsViewModel>(
      () => ImportPointsViewModel(jobService: locator<JobService>()));
  locator.registerFactory<CoordinatesViewModel>(
      () => CoordinatesViewModel(locator<JobService>()));

  // Register UsageViewModel as a lazy singleton
  locator.registerLazySingleton(() => UsageViewModel());
}
