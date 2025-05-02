// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Logger';

  @override
  String get softwareName => 'Software Logger';

  @override
  String get developmentDate => 'Fecha de Desarrollo';

  @override
  String get version => 'Versión';

  @override
  String get contact => 'Contacto';

  @override
  String get phone => 'Teléfono';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get email => 'Correo';

  @override
  String get location => 'Ubicación';

  @override
  String get slopeDistance => 'Distancia Inclinada';

  @override
  String get verticalAngle => 'Ángulo Vertical';

  @override
  String get invalidSlopeDistance => 'Distancia inclinada inválida';

  @override
  String get invalidVerticalAngle => 'Ángulo vertical inválido';

  @override
  String get calculationError => 'Error en el cálculo';

  @override
  String get swapPoints => 'Intercambiar Puntos';

  @override
  String get settings => 'Configuración';

  @override
  String get setout => 'Replanteo';

  @override
  String get moveForward => 'Avanzar';

  @override
  String get moveBack => 'Retroceder';

  @override
  String get moveLeft => 'Mover a la Izquierda';

  @override
  String get moveRight => 'Mover a la Derecha';

  @override
  String get moveUp => 'Mover Arriba';

  @override
  String get moveDown => 'Bajar';

  @override
  String get onLine => 'En Línea';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Seleccionar Idioma';

  @override
  String get homePage => 'Página Principal';

  @override
  String get jobs => 'Trabajos';

  @override
  String get jobsHint => 'Seleccionar, Crear o Gestionar';

  @override
  String get coordinates => 'Coordenadas';

  @override
  String get coordinatesHint => 'Ver, Agregar, Editar, Eliminar';

  @override
  String get calculations => 'Cálculos';

  @override
  String get calculationsHint => 'Unir, Polar';

  @override
  String get fixes => 'Fijaciones';

  @override
  String get roads => 'Carreteras';

  @override
  String get quit => 'Salir';

  @override
  String get noCurrentJob => 'Sin Trabajo Actual';

  @override
  String currentJob(String jobName) {
    return 'Trabajo Actual: $jobName';
  }

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get importPoints => 'Importar Puntos';

  @override
  String get exportPoints => 'Exportar Puntos';

  @override
  String get readyToImport => 'Listo para importar';

  @override
  String get importStatus => 'Estado de importación:';

  @override
  String get slopeDistanceWithUnit => 'Distancia de Pendiente (m)';

  @override
  String get targetHeight => 'Altura del objetivo (m)';

  @override
  String get horizontalAngle => 'Ángulo Horizontal';

  @override
  String get setupAt => 'Configurar en';

  @override
  String get pointName => 'Nombre del punto';

  @override
  String get search => 'Buscar';

  @override
  String get add => 'Agregar';

  @override
  String get calculatedPosition => 'Posición calculada';

  @override
  String get distance => 'Distancia (m)';

  @override
  String get direction => 'Dirección';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get update => 'Actualizar';

  @override
  String get error => 'Error';

  @override
  String get success => 'Éxito';

  @override
  String get singleJoin => 'Unión Simple';

  @override
  String get polar => 'Polar';

  @override
  String get firstPoint => '1er Punto';

  @override
  String get secondPoint => '2do Punto';

  @override
  String get heightDiff => 'Dif. Altura';

  @override
  String get slopeDistanceLabel => 'Distancia Inclinada';

  @override
  String get gradeSlope => 'Pendiente 1:';

  @override
  String get gradeSlopePercent => 'Pendiente %';

  @override
  String get slopeAngle => 'Ángulo de Pendiente';

  @override
  String get area => 'Área';

  @override
  String get joins => 'Uniones';

  @override
  String get searchPoint => 'Buscar Punto';

  @override
  String get addPoint => 'Agregar Punto';

  @override
  String get targetHeightWithUnit => 'Altura del Objetivo (m)';

  @override
  String get useCurvatureAndRefraction => 'Usar Curvatura y Refracción';

  @override
  String get firstPointHint => 'Primer Punto';

  @override
  String get nextPointHint => 'Siguiente Punto';

  @override
  String get addPointTitle => 'Agregar Punto';

  @override
  String get invalidComment => 'Comentario Inválido';

  @override
  String get comment => 'Comentario';

  @override
  String get descriptor => 'Descriptor';

  @override
  String get coords => 'Coords';

  @override
  String get sortBy => 'Ordenar Por';

  @override
  String get sortByComment => 'Ordenar por Comentario';

  @override
  String get sortByCoordinate => 'Ordenar por Coordenada';

  @override
  String get viewOnGoogleMaps => 'Ver en Google Maps';

  @override
  String get addPointDialog => 'Add Point';

  @override
  String characterCount(int current, int max) {
    return '$current/$max';
  }

  @override
  String get searchPoints => 'Search Points';

  @override
  String get editPoint => 'Editar Punto';

  @override
  String get validComment => 'Comentario Válido';

  @override
  String get pleaseEnterComment => 'Por favor ingrese un comentario';

  @override
  String get commentExists => 'El comentario ya existe';

  @override
  String get backup => 'Copia de seguridad';

  @override
  String get searchJob => 'Buscar trabajo';

  @override
  String get sortJobsBy => 'Ordenar trabajos por';

  @override
  String get nameAtoZ => 'Nombre (A a Z)';

  @override
  String get nameZtoA => 'Nombre (Z a A)';

  @override
  String get dateModifiedNewest => 'Fecha de modificación (Más reciente)';

  @override
  String get dateModifiedOldest => 'Fecha de modificación (Más antiguo)';

  @override
  String get createNewJob => 'Crear nuevo trabajo';

  @override
  String get info => 'Información';

  @override
  String get jobSettings => 'Configuración del Trabajo';

  @override
  String get jobName => 'Nombre del Trabajo';

  @override
  String get jobInformation => 'Información del trabajo';

  @override
  String get jobDescription => 'Descripción del trabajo';

  @override
  String get coordinateFormat => 'Formato de Coordenadas';

  @override
  String get instrument => 'Instrumento';

  @override
  String get dualCapture => 'Captura Dual';

  @override
  String get measurementUnits => 'Unidades de Medida';

  @override
  String get angularMeasurement => 'Medición Angular';

  @override
  String get commsBaudRate => 'Velocidad de Baudios';

  @override
  String get calculationSettings => 'Configuración de Cálculos';

  @override
  String get scaleFactor => 'Factor de Escala';

  @override
  String get heightAboveMSL => 'Altura sobre el Nivel del Mar';

  @override
  String get meanYValue => 'Valor Medio Y';

  @override
  String get verticalAngleIndexError => 'Error de Índice de Ángulo Vertical';

  @override
  String get toleranceSettings => 'Configuración de Tolerancias';

  @override
  String get spotShotTolerance => 'Tolerancia de Punto';

  @override
  String get horizontalAlignmentOffsetTolerance => 'Tolerancia de Desplazamiento de Alineación Horizontal';

  @override
  String get maximumSearchDistanceFromCL => 'Distancia Máxima de Búsqueda desde CL';

  @override
  String get timingSettings => 'Configuración de Tiempo';

  @override
  String get numberOfRetries => 'Número de Reintentos';

  @override
  String get timeout => 'Tiempo de Espera';

  @override
  String get instrumentSettings => 'Configuración del instrumento';

  @override
  String get manualInstrument => 'MANUAL';

  @override
  String get importExport => 'Importar/Exportar';

  @override
  String get exportCoordinatesHint => 'Exportar datos de coordenadas a archivo';

  @override
  String get import => 'Importar';

  @override
  String get export => 'Exportar';

  @override
  String get horzAlignment => 'Alineación Horizontal';

  @override
  String get dtmTot => 'DTM (TOT)';

  @override
  String get roadDesign => 'Diseño de Carretera';

  @override
  String get strings => 'Cuerdas';

  @override
  String get tacheRaw => 'Taqueo (Bruto)';

  @override
  String get tacheReduced => 'Taqueo (Reducido)';

  @override
  String get fieldbook => 'Libreta de Campo';

  @override
  String get importCoordinatesHint => 'Importar datos de coordenadas desde archivo. Formato delimitado por coma, espacio o tabulación. Formato CYXZ o CENZ. Restringido a 20 caracteres';

  @override
  String get importHorzAlignmentHint => 'Importar datos de alineación horizontal desde archivos PID de Model y Road Maker';

  @override
  String get importDtmTotHint => 'Leer archivo TOT de Model Maker. Modelo TIN';

  @override
  String get importRoadDesignHint => 'Importar datos y especificaciones de diseño de carretera desde Road Maker. Archivo PR3';

  @override
  String get importStringsHint => 'Importar cuerdas desde Model Maker';

  @override
  String get exportTacheRawHint => 'Exportar datos brutos de taqueometría';

  @override
  String get exportTacheReducedHint => 'Exportar datos procesados de taqueometría Comentario YXZ/ENZ';

  @override
  String get exportFieldbookHint => 'Exportar datos de libreta de campo';

  @override
  String get exportRoadDesignHint => 'Exportar datos de diseño de carretera';

  @override
  String get deletingYourJob => 'Eliminando su trabajo';

  @override
  String deleteJobConfirmation(Object jobName) {
    return '¿Está seguro de que desea eliminar \"$jobName\" y todo su contenido?';
  }

  @override
  String get searchJobsHint => 'Buscar trabajos...';

  @override
  String get exit => 'Salir';

  @override
  String get lastModified => 'Última modificación';

  @override
  String get created => 'Creado';

  @override
  String get size => 'Tamaño';

  @override
  String jobInfoDialogTitle(String jobName) {
    return 'Información del trabajo - $jobName';
  }

  @override
  String get usageTimer => 'Temporizador de uso';

  @override
  String currentSession(String duration) {
    return 'Sesión actual: $duration';
  }

  @override
  String totalJobTime(String jobName, String duration) {
    return 'Tiempo total para $jobName: $duration';
  }

  @override
  String get locationNotAvailable => 'Ubicación no disponible';

  @override
  String latitude(String latitude) {
    return 'Latitud: $latitude';
  }

  @override
  String longitude(String longitude) {
    return 'Longitud: $longitude';
  }
}
