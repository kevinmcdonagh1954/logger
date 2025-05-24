import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('zh'),
    Locale('pt')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Logger'**
  String get appTitle;

  /// Name of the software
  ///
  /// In en, this message translates to:
  /// **'Logger Software'**
  String get softwareName;

  /// Label for development date
  ///
  /// In en, this message translates to:
  /// **'Development Date'**
  String get developmentDate;

  /// Label for version
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Label for contact section
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// Label for phone
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Label for WhatsApp
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// Label for email
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Label for location
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Label for slope distance input
  ///
  /// In en, this message translates to:
  /// **'Slope Distance'**
  String get slopeDistance;

  /// Label for vertical angle input
  ///
  /// In en, this message translates to:
  /// **'Vertical Angle'**
  String get verticalAngle;

  /// Error message for invalid slope distance
  ///
  /// In en, this message translates to:
  /// **'Invalid slope distance'**
  String get invalidSlopeDistance;

  /// Error message for invalid vertical angle
  ///
  /// In en, this message translates to:
  /// **'Invalid vertical angle'**
  String get invalidVerticalAngle;

  /// Error message for calculation failure
  ///
  /// In en, this message translates to:
  /// **'Error in calculation'**
  String get calculationError;

  /// Label for swap points button
  ///
  /// In en, this message translates to:
  /// **'Swap Points'**
  String get swapPoints;

  /// Label for settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label for setout
  ///
  /// In en, this message translates to:
  /// **'Set Out'**
  String get setout;

  /// Direction instruction
  ///
  /// In en, this message translates to:
  /// **'Move Forward'**
  String get moveForward;

  /// Direction instruction
  ///
  /// In en, this message translates to:
  /// **'Move Back'**
  String get moveBack;

  /// Direction instruction
  ///
  /// In en, this message translates to:
  /// **'Move Left'**
  String get moveLeft;

  /// Direction instruction
  ///
  /// In en, this message translates to:
  /// **'Move Right'**
  String get moveRight;

  /// Direction instruction
  ///
  /// In en, this message translates to:
  /// **'Move Up'**
  String get moveUp;

  /// Direction instruction
  ///
  /// In en, this message translates to:
  /// **'Move Down'**
  String get moveDown;

  /// Position indicator
  ///
  /// In en, this message translates to:
  /// **'On Line'**
  String get onLine;

  /// Label for language selection
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Title for language selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Label for home page
  ///
  /// In en, this message translates to:
  /// **'Home Page'**
  String get homePage;

  /// Label for jobs section
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// Hint text for jobs section in navigator drawer
  ///
  /// In en, this message translates to:
  /// **'Select, Create, or Manage'**
  String get jobsHint;

  /// Label for coordinates section
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates;

  /// Hint text for coordinates section in navigator drawer
  ///
  /// In en, this message translates to:
  /// **'View, Add, Edit, Delete'**
  String get coordinatesHint;

  /// Label for calculations section
  ///
  /// In en, this message translates to:
  /// **'Calculations'**
  String get calculations;

  /// Hint text for calculations section in navigator drawer
  ///
  /// In en, this message translates to:
  /// **'Join, Polar'**
  String get calculationsHint;

  /// Label for fixes section
  ///
  /// In en, this message translates to:
  /// **'Fixes'**
  String get fixes;

  /// Label for roads section
  ///
  /// In en, this message translates to:
  /// **'Roads'**
  String get roads;

  /// Label for quit option
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get quit;

  /// Text shown when no job is selected
  ///
  /// In en, this message translates to:
  /// **'No Current Job'**
  String get noCurrentJob;

  /// Text shown with current job name
  ///
  /// In en, this message translates to:
  /// **'Current Job: {jobName}'**
  String currentJob(String jobName);

  /// Text shown for features in development
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// Label for import points action
  ///
  /// In en, this message translates to:
  /// **'Import Points'**
  String get importPoints;

  /// Label for export points action
  ///
  /// In en, this message translates to:
  /// **'Export Points'**
  String get exportPoints;

  /// Status message for import
  ///
  /// In en, this message translates to:
  /// **'Ready to import'**
  String get readyToImport;

  /// Label for import status
  ///
  /// In en, this message translates to:
  /// **'Import Status:'**
  String get importStatus;

  /// Label for slope distance input with unit
  ///
  /// In en, this message translates to:
  /// **'Slope Distance (m)'**
  String get slopeDistanceWithUnit;

  /// Label for target height input with unit
  ///
  /// In en, this message translates to:
  /// **'Target Height (m)'**
  String get targetHeight;

  /// Label for horizontal angle input
  ///
  /// In en, this message translates to:
  /// **'Horizontal Angle'**
  String get horizontalAngle;

  /// Label for setup point location
  ///
  /// In en, this message translates to:
  /// **'Setup at'**
  String get setupAt;

  /// Label for point name input
  ///
  /// In en, this message translates to:
  /// **'Point Name'**
  String get pointName;

  /// Label for search action
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Label for add button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Label for calculated position result
  ///
  /// In en, this message translates to:
  /// **'Calculated Position'**
  String get calculatedPosition;

  /// Label for distance measurement
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// Label for direction in the joins dialog and similar contexts.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get direction;

  /// Label for cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Label for save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Label for delete action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Label for update action
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Error message with details
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error(String message);

  /// Label for success message
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Label for single join calculation
  ///
  /// In en, this message translates to:
  /// **'Single Join'**
  String get singleJoin;

  /// Label for polar calculation
  ///
  /// In en, this message translates to:
  /// **'Polar'**
  String get polar;

  /// Label for first point input
  ///
  /// In en, this message translates to:
  /// **'1st Point'**
  String get firstPoint;

  /// Label for second point input
  ///
  /// In en, this message translates to:
  /// **'2nd Point'**
  String get secondPoint;

  /// Label for height difference
  ///
  /// In en, this message translates to:
  /// **'Height Diff'**
  String get heightDiff;

  /// Label for slope distance
  ///
  /// In en, this message translates to:
  /// **'Slope Distance'**
  String get slopeDistanceLabel;

  /// Label for grade/slope ratio
  ///
  /// In en, this message translates to:
  /// **'Grade/Slope 1:'**
  String get gradeSlope;

  /// Label for grade/slope percentage
  ///
  /// In en, this message translates to:
  /// **'Grade/Slope %'**
  String get gradeSlopePercent;

  /// Label for slope angle
  ///
  /// In en, this message translates to:
  /// **'Slope Angle'**
  String get slopeAngle;

  /// Label for area calculation view
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// Title for joins view
  ///
  /// In en, this message translates to:
  /// **'Joins'**
  String get joins;

  /// Label for search point action
  ///
  /// In en, this message translates to:
  /// **'Search Point'**
  String get searchPoint;

  /// Label for add point action
  ///
  /// In en, this message translates to:
  /// **'Add Point'**
  String get addPoint;

  /// Label for target height with unit
  ///
  /// In en, this message translates to:
  /// **'Target Height (m)'**
  String get targetHeightWithUnit;

  /// Label for curvature and refraction checkbox
  ///
  /// In en, this message translates to:
  /// **'Use Curvature and Refraction'**
  String get useCurvatureAndRefraction;

  /// Hint text for first point input
  ///
  /// In en, this message translates to:
  /// **'First Point'**
  String get firstPointHint;

  /// Hint text for next point input
  ///
  /// In en, this message translates to:
  /// **'Next Point'**
  String get nextPointHint;

  /// Title for add point dialog
  ///
  /// In en, this message translates to:
  /// **'Add Point'**
  String get addPointTitle;

  /// Error message for invalid comment
  ///
  /// In en, this message translates to:
  /// **'Invalid Comment'**
  String get invalidComment;

  /// Label for comment field
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// Label for descriptor field
  ///
  /// In en, this message translates to:
  /// **'Descriptor'**
  String get descriptor;

  /// Label for coordinates section
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coords;

  /// Label for sort options
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// Sort option for comment
  ///
  /// In en, this message translates to:
  /// **'Sort by Comment'**
  String get sortByComment;

  /// Sort option for coordinate
  ///
  /// In en, this message translates to:
  /// **'Sort by Coordinate'**
  String get sortByCoordinate;

  /// Option to view point on Google Maps
  ///
  /// In en, this message translates to:
  /// **'View on Google Maps'**
  String get viewOnGoogleMaps;

  /// Title for add point dialog
  ///
  /// In en, this message translates to:
  /// **'Add Point'**
  String get addPointDialog;

  /// Character count display
  ///
  /// In en, this message translates to:
  /// **'{current}/{max}'**
  String characterCount(int current, int max);

  /// Label for search points action
  ///
  /// In en, this message translates to:
  /// **'Search Points'**
  String get searchPoints;

  /// Title for edit point dialog
  ///
  /// In en, this message translates to:
  /// **'Edit Point'**
  String get editPoint;

  /// Validation message for valid comment
  ///
  /// In en, this message translates to:
  /// **'Valid Comment'**
  String get validComment;

  /// Error message when comment is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a comment'**
  String get pleaseEnterComment;

  /// Error message when comment already exists
  ///
  /// In en, this message translates to:
  /// **'Comment already exists'**
  String get commentExists;

  /// Label for backup button
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// Label for search job button
  ///
  /// In en, this message translates to:
  /// **'Search For Job'**
  String get searchJob;

  /// Title for job sort dialog
  ///
  /// In en, this message translates to:
  /// **'Sort Jobs By'**
  String get sortJobsBy;

  /// Sort option for alphabetical order A to Z
  ///
  /// In en, this message translates to:
  /// **'Name (A to Z)'**
  String get nameAtoZ;

  /// Sort option for alphabetical order Z to A
  ///
  /// In en, this message translates to:
  /// **'Name (Z to A)'**
  String get nameZtoA;

  /// Sort option for date modified newest first
  ///
  /// In en, this message translates to:
  /// **'Date Modified (Newest)'**
  String get dateModifiedNewest;

  /// Sort option for date modified oldest first
  ///
  /// In en, this message translates to:
  /// **'Date Modified (Oldest)'**
  String get dateModifiedOldest;

  /// Label for create new job button
  ///
  /// In en, this message translates to:
  /// **'Create New Job'**
  String get createNewJob;

  /// Label for info button
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// Title for job settings view
  ///
  /// In en, this message translates to:
  /// **'Job Settings'**
  String get jobSettings;

  /// Label for job name field
  ///
  /// In en, this message translates to:
  /// **'Job Name'**
  String get jobName;

  /// Label for job information section
  ///
  /// In en, this message translates to:
  /// **'Job Information'**
  String get jobInformation;

  /// Label for job description in job info dialog
  ///
  /// In en, this message translates to:
  /// **'Job Description'**
  String get jobDescription;

  /// Label for coordinate format field
  ///
  /// In en, this message translates to:
  /// **'Coordinate Format'**
  String get coordinateFormat;

  /// Label for instrument field
  ///
  /// In en, this message translates to:
  /// **'Instrument'**
  String get instrument;

  /// Label for dual capture field
  ///
  /// In en, this message translates to:
  /// **'Dual Capture'**
  String get dualCapture;

  /// Label for measurement units field
  ///
  /// In en, this message translates to:
  /// **'Measurement Units'**
  String get measurementUnits;

  /// Label for angular measurement field
  ///
  /// In en, this message translates to:
  /// **'Angular Measurement'**
  String get angularMeasurement;

  /// Label for communications baud rate field
  ///
  /// In en, this message translates to:
  /// **'Comms Baud Rate'**
  String get commsBaudRate;

  /// Title for calculation settings section
  ///
  /// In en, this message translates to:
  /// **'Calculation Settings'**
  String get calculationSettings;

  /// Label for scale factor field
  ///
  /// In en, this message translates to:
  /// **'Scale Factor'**
  String get scaleFactor;

  /// Label for height above mean sea level field
  ///
  /// In en, this message translates to:
  /// **'Height Above MSL'**
  String get heightAboveMSL;

  /// Label for mean Y value field
  ///
  /// In en, this message translates to:
  /// **'Mean Y Value'**
  String get meanYValue;

  /// Label for vertical angle index error field
  ///
  /// In en, this message translates to:
  /// **'Vertical Angle Index Error'**
  String get verticalAngleIndexError;

  /// Title for tolerance settings section
  ///
  /// In en, this message translates to:
  /// **'Tolerance Settings'**
  String get toleranceSettings;

  /// Label for spot shot tolerance field
  ///
  /// In en, this message translates to:
  /// **'Spot Shot Tolerance'**
  String get spotShotTolerance;

  /// Label for horizontal alignment offset tolerance field
  ///
  /// In en, this message translates to:
  /// **'Horizontal Alignment Offset Tolerance'**
  String get horizontalAlignmentOffsetTolerance;

  /// Label for maximum search distance from center line field
  ///
  /// In en, this message translates to:
  /// **'Maximum Search Distance From CL'**
  String get maximumSearchDistanceFromCL;

  /// Title for timing settings section
  ///
  /// In en, this message translates to:
  /// **'Timing Settings'**
  String get timingSettings;

  /// Label for number of retries field
  ///
  /// In en, this message translates to:
  /// **'Number of Retries'**
  String get numberOfRetries;

  /// Label for timeout field
  ///
  /// In en, this message translates to:
  /// **'Timeout'**
  String get timeout;

  /// Label for instrument settings section
  ///
  /// In en, this message translates to:
  /// **'Instrument Settings'**
  String get instrumentSettings;

  /// Label for manual instrument option
  ///
  /// In en, this message translates to:
  /// **'MANUAL'**
  String get manualInstrument;

  /// Label for import/export section or button.
  ///
  /// In en, this message translates to:
  /// **'Import/Export'**
  String get importExport;

  /// Hint or tooltip for exporting coordinate data to a file.
  ///
  /// In en, this message translates to:
  /// **'Export coordinate data to file'**
  String get exportCoordinatesHint;

  /// Label for import action
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// Label for export action
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// Label for horizontal alignment section
  ///
  /// In en, this message translates to:
  /// **'Horz Alignment'**
  String get horzAlignment;

  /// Label for DTM TOT section
  ///
  /// In en, this message translates to:
  /// **'DTM (TOT)'**
  String get dtmTot;

  /// Label for road design section
  ///
  /// In en, this message translates to:
  /// **'Road Design'**
  String get roadDesign;

  /// Label for strings section
  ///
  /// In en, this message translates to:
  /// **'Strings'**
  String get strings;

  /// Label for raw tacheometry data
  ///
  /// In en, this message translates to:
  /// **'Tache (Raw)'**
  String get tacheRaw;

  /// Label for reduced tacheometry data
  ///
  /// In en, this message translates to:
  /// **'Tache (Reduced)'**
  String get tacheReduced;

  /// Label for fieldbook section
  ///
  /// In en, this message translates to:
  /// **'Fieldbook'**
  String get fieldbook;

  /// Hint text for importing coordinate data
  ///
  /// In en, this message translates to:
  /// **'Import coordinate data from file. Format comma,space,tab delimited. Format CYXZ or CENZ. Restricted to 20 Charaters'**
  String get importCoordinatesHint;

  /// Hint text for importing horizontal alignment data
  ///
  /// In en, this message translates to:
  /// **'Import horizontal alignment data from Model and Road Maker PID files'**
  String get importHorzAlignmentHint;

  /// Hint text for importing DTM TOT data
  ///
  /// In en, this message translates to:
  /// **'Read Model Maker TOT file. TIN model'**
  String get importDtmTotHint;

  /// Hint text for importing road design data
  ///
  /// In en, this message translates to:
  /// **'Import road design data and specifications from Road Maker. PR3 file'**
  String get importRoadDesignHint;

  /// Hint text for importing strings
  ///
  /// In en, this message translates to:
  /// **'Import strings from Model Maker.'**
  String get importStringsHint;

  /// Hint text for exporting raw tacheometry data
  ///
  /// In en, this message translates to:
  /// **'Export raw tacheometry data'**
  String get exportTacheRawHint;

  /// Hint text for exporting reduced tacheometry data
  ///
  /// In en, this message translates to:
  /// **'Export processed tacheometry data Comment YXZ/ENZ'**
  String get exportTacheReducedHint;

  /// Hint text for exporting fieldbook data
  ///
  /// In en, this message translates to:
  /// **'Export fieldbook data'**
  String get exportFieldbookHint;

  /// Hint text for exporting road design data
  ///
  /// In en, this message translates to:
  /// **'Export road design data'**
  String get exportRoadDesignHint;

  /// Title for job deletion dialog
  ///
  /// In en, this message translates to:
  /// **'Deleting Your Job'**
  String get deletingYourJob;

  /// Confirmation message for job deletion
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{jobName}\" and all its contents?'**
  String deleteJobConfirmation(String jobName);

  /// Hint text for job search field
  ///
  /// In en, this message translates to:
  /// **'Search jobs...'**
  String get searchJobsHint;

  /// Label for exit action
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// Label for last modified date in job info dialog
  ///
  /// In en, this message translates to:
  /// **'Last Modified'**
  String get lastModified;

  /// Label for creation date in job info dialog
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// Label for file size in job info dialog
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// Title for job info dialog with job name
  ///
  /// In en, this message translates to:
  /// **'Job Information - {jobName}'**
  String jobInfoDialogTitle(String jobName);

  /// Title of the usage timer dialog
  ///
  /// In en, this message translates to:
  /// **'Usage Timer'**
  String get usageTimer;

  /// Current session duration text
  ///
  /// In en, this message translates to:
  /// **'Current session: {duration}'**
  String currentSession(String duration);

  /// Total time for a job
  ///
  /// In en, this message translates to:
  /// **'Total time for {jobName}: {duration}'**
  String totalJobTime(String jobName, String duration);

  /// Message shown when location is not available
  ///
  /// In en, this message translates to:
  /// **'Location not available'**
  String get locationNotAvailable;

  /// Latitude coordinate
  ///
  /// In en, this message translates to:
  /// **'Latitude: {latitude}'**
  String latitude(String latitude);

  /// Longitude coordinate
  ///
  /// In en, this message translates to:
  /// **'Longitude: {longitude}'**
  String longitude(String longitude);

  /// Title for plot coordinates view with point count
  ///
  /// In en, this message translates to:
  /// **'Plot Coordinates - {count}'**
  String plotCoordinatesTitle(int count);

  /// Option to toggle visibility of comments in plot coordinates
  ///
  /// In en, this message translates to:
  /// **'Show Comments'**
  String get showComments;

  /// Option to toggle visibility of descriptors in plot coordinates
  ///
  /// In en, this message translates to:
  /// **'Show Descriptors'**
  String get showDescriptors;

  /// Option to toggle visibility of Z values in plot coordinates
  ///
  /// In en, this message translates to:
  /// **'Show Z Values'**
  String get showZValues;

  /// Label for Z decimal places setting
  ///
  /// In en, this message translates to:
  /// **'Z Decimals: {count}'**
  String zDecimals(int count);

  /// Label for setting grid interval option
  ///
  /// In en, this message translates to:
  /// **'Set Grid Interval'**
  String get setGridInterval;

  /// Success message when point is updated
  ///
  /// In en, this message translates to:
  /// **'Point updated successfully'**
  String get pointUpdatedSuccess;

  /// Message when point is moved outside visible area
  ///
  /// In en, this message translates to:
  /// **'Point moved out of view'**
  String get pointMovedOutOfView;

  /// Option to plot coordinates from the popup menu
  ///
  /// In en, this message translates to:
  /// **'Plot Coordinates'**
  String get plotCoordinates;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'pt', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'pt': return AppLocalizationsPt();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
