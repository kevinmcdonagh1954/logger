// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Logger';

  @override
  String get softwareName => 'Software Logger';

  @override
  String get developmentDate => 'Data de desenvolvimento';

  @override
  String get version => 'Versão';

  @override
  String get contact => 'Contato';

  @override
  String get phone => 'Telefone';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get email => 'E-mail';

  @override
  String get location => 'Localização';

  @override
  String get slopeDistance => 'Distância inclinada';

  @override
  String get verticalAngle => 'Ângulo vertical';

  @override
  String get invalidSlopeDistance => 'Distância inclinada inválida';

  @override
  String get invalidVerticalAngle => 'Ângulo vertical inválido';

  @override
  String get calculationError => 'Erro no cálculo';

  @override
  String get swapPoints => 'Trocar pontos';

  @override
  String get settings => 'Configurações';

  @override
  String get setout => 'Implantar';

  @override
  String get moveForward => 'Mover para frente';

  @override
  String get moveBack => 'Mover para trás';

  @override
  String get moveLeft => 'Mover para a esquerda';

  @override
  String get moveRight => 'Mover para a direita';

  @override
  String get moveUp => 'Mover para cima';

  @override
  String get moveDown => 'Mover para baixo';

  @override
  String get onLine => 'Na linha';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Selecionar idioma';

  @override
  String get homePage => 'Página inicial';

  @override
  String get jobs => 'Trabalhos';

  @override
  String get jobsHint => 'Selecionar, Criar ou Gerenciar';

  @override
  String get coordinates => 'Coordenadas';

  @override
  String get coordinatesHint => 'Visualizar, Adicionar, Editar, Excluir';

  @override
  String get calculations => 'Cálculos';

  @override
  String get calculationsHint => 'Juntar, Polar';

  @override
  String get fixes => 'Correções';

  @override
  String get roads => 'Estradas';

  @override
  String get quit => 'Sair';

  @override
  String get noCurrentJob => 'Nenhum trabalho atual';

  @override
  String currentJob(String jobName) {
    return 'Current Job: $jobName';
  }

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get importPoints => 'Import Points';

  @override
  String get exportPoints => 'Export Points';

  @override
  String get readyToImport => 'Ready to import';

  @override
  String get importStatus => 'Import Status:';

  @override
  String get slopeDistanceWithUnit => 'Slope Distance (m)';

  @override
  String get targetHeight => 'Target Height (m)';

  @override
  String get horizontalAngle => 'Horizontal Angle';

  @override
  String get setupAt => 'Setup at';

  @override
  String get pointName => 'Point Name';

  @override
  String get search => 'Search';

  @override
  String get add => 'Add';

  @override
  String get calculatedPosition => 'Calculated Position';

  @override
  String get distance => 'Distance';

  @override
  String get direction => 'Direction';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get update => 'Update';

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get success => 'Success';

  @override
  String get singleJoin => 'Single Join';

  @override
  String get polar => 'Polar';

  @override
  String get firstPoint => '1st Point';

  @override
  String get secondPoint => '2nd Point';

  @override
  String get heightDiff => 'Height Diff';

  @override
  String get slopeDistanceLabel => 'Slope Distance';

  @override
  String get gradeSlope => 'Grade/Slope 1:';

  @override
  String get gradeSlopePercent => 'Grade/Slope %';

  @override
  String get slopeAngle => 'Slope Angle';

  @override
  String get area => 'Area';

  @override
  String get joins => 'Joins';

  @override
  String get searchPoint => 'Search Point';

  @override
  String get addPoint => 'Add Point';

  @override
  String get targetHeightWithUnit => 'Target Height (m)';

  @override
  String get useCurvatureAndRefraction => 'Use Curvature and Refraction';

  @override
  String get firstPointHint => 'First Point';

  @override
  String get nextPointHint => 'Next Point';

  @override
  String get addPointTitle => 'Add Point';

  @override
  String get invalidComment => 'Invalid Comment';

  @override
  String get comment => 'Comment';

  @override
  String get descriptor => 'Descriptor';

  @override
  String get coords => 'Coordinates';

  @override
  String get sortBy => 'Sort By';

  @override
  String get sortByComment => 'Sort by Comment';

  @override
  String get sortByCoordinate => 'Sort by Coordinate';

  @override
  String get viewOnGoogleMaps => 'View on Google Maps';

  @override
  String get addPointDialog => 'Add Point';

  @override
  String characterCount(int current, int max) {
    return '$current/$max';
  }

  @override
  String get searchPoints => 'Search Points';

  @override
  String get editPoint => 'Edit Point';

  @override
  String get validComment => 'Valid Comment';

  @override
  String get pleaseEnterComment => 'Please enter a comment';

  @override
  String get commentExists => 'Comment already exists';

  @override
  String get backup => 'Backup';

  @override
  String get searchJob => 'Search For Job';

  @override
  String get sortJobsBy => 'Sort Jobs By';

  @override
  String get nameAtoZ => 'Name (A to Z)';

  @override
  String get nameZtoA => 'Name (Z to A)';

  @override
  String get dateModifiedNewest => 'Date Modified (Newest)';

  @override
  String get dateModifiedOldest => 'Date Modified (Oldest)';

  @override
  String get createNewJob => 'Create New Job';

  @override
  String get info => 'Info';

  @override
  String get jobSettings => 'Job Settings';

  @override
  String get jobName => 'Job Name';

  @override
  String get jobInformation => 'Job Information';

  @override
  String get jobDescription => 'Job Description';

  @override
  String get coordinateFormat => 'Coordinate Format';

  @override
  String get instrument => 'Instrument';

  @override
  String get dualCapture => 'Dual Capture';

  @override
  String get measurementUnits => 'Measurement Units';

  @override
  String get angularMeasurement => 'Angular Measurement';

  @override
  String get commsBaudRate => 'Comms Baud Rate';

  @override
  String get calculationSettings => 'Calculation Settings';

  @override
  String get scaleFactor => 'Scale Factor';

  @override
  String get heightAboveMSL => 'Height Above MSL';

  @override
  String get meanYValue => 'Mean Y Value';

  @override
  String get verticalAngleIndexError => 'Vertical Angle Index Error';

  @override
  String get toleranceSettings => 'Tolerance Settings';

  @override
  String get spotShotTolerance => 'Spot Shot Tolerance';

  @override
  String get horizontalAlignmentOffsetTolerance => 'Horizontal Alignment Offset Tolerance';

  @override
  String get maximumSearchDistanceFromCL => 'Maximum Search Distance From CL';

  @override
  String get timingSettings => 'Timing Settings';

  @override
  String get numberOfRetries => 'Number of Retries';

  @override
  String get timeout => 'Timeout';

  @override
  String get instrumentSettings => 'Instrument Settings';

  @override
  String get manualInstrument => 'MANUAL';

  @override
  String get importExport => 'Import/Export';

  @override
  String get exportCoordinatesHint => 'Export coordinate data to file';

  @override
  String get import => 'Import';

  @override
  String get export => 'Export';

  @override
  String get horzAlignment => 'Horz Alignment';

  @override
  String get dtmTot => 'DTM (TOT)';

  @override
  String get roadDesign => 'Road Design';

  @override
  String get strings => 'Strings';

  @override
  String get tacheRaw => 'Tache (Raw)';

  @override
  String get tacheReduced => 'Tache (Reduced)';

  @override
  String get fieldbook => 'Fieldbook';

  @override
  String get importCoordinatesHint => 'Import coordinate data from file. Format comma,space,tab delimited. Format CYXZ or CENZ. Restricted to 20 Charaters';

  @override
  String get importHorzAlignmentHint => 'Import horizontal alignment data from Model and Road Maker PID files';

  @override
  String get importDtmTotHint => 'Read Model Maker TOT file. TIN model';

  @override
  String get importRoadDesignHint => 'Import road design data and specifications from Road Maker. PR3 file';

  @override
  String get importStringsHint => 'Import strings from Model Maker.';

  @override
  String get exportTacheRawHint => 'Export raw tacheometry data';

  @override
  String get exportTacheReducedHint => 'Export processed tacheometry data Comment YXZ/ENZ';

  @override
  String get exportFieldbookHint => 'Export fieldbook data';

  @override
  String get exportRoadDesignHint => 'Export road design data';

  @override
  String get deletingYourJob => 'Deleting Your Job';

  @override
  String deleteJobConfirmation(String jobName) {
    return 'Are you sure you want to delete \"$jobName\" and all its contents?';
  }

  @override
  String get searchJobsHint => 'Search jobs...';

  @override
  String get exit => 'Exit';

  @override
  String get lastModified => 'Last Modified';

  @override
  String get created => 'Created';

  @override
  String get size => 'Size';

  @override
  String jobInfoDialogTitle(String jobName) {
    return 'Job Information - $jobName';
  }

  @override
  String get usageTimer => 'Usage Timer';

  @override
  String currentSession(String duration) {
    return 'Current session: $duration';
  }

  @override
  String totalJobTime(String jobName, String duration) {
    return 'Total time for $jobName: $duration';
  }

  @override
  String get locationNotAvailable => 'Location not available';

  @override
  String latitude(String latitude) {
    return 'Latitude: $latitude';
  }

  @override
  String longitude(String longitude) {
    return 'Longitude: $longitude';
  }

  @override
  String plotCoordinatesTitle(int count) {
    return 'Plot Coordinates - $count';
  }

  @override
  String get showComments => 'Show Comments';

  @override
  String get showDescriptors => 'Show Descriptors';

  @override
  String get showZValues => 'Show Z Values';

  @override
  String zDecimals(int count) {
    return 'Z Decimals: $count';
  }

  @override
  String get setGridInterval => 'Set Grid Interval';

  @override
  String get pointUpdatedSuccess => 'Point updated successfully';

  @override
  String get pointMovedOutOfView => 'Point moved out of view';

  @override
  String get plotCoordinates => 'Plot Coordinates';
}
