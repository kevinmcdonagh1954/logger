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
  String get softwareName => 'Logger Software';

  @override
  String get developmentDate => 'Fecha de desarrollo';

  @override
  String get version => 'Versión';

  @override
  String get contact => 'Contacto';

  @override
  String get phone => 'Teléfono';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get email => 'Correo electrónico';

  @override
  String get location => 'Ubicación';

  @override
  String get slopeDistance => 'Distancia de pendiente';

  @override
  String get verticalAngle => 'Ángulo vertical';

  @override
  String get invalidSlopeDistance => 'Distancia de pendiente inválida';

  @override
  String get invalidVerticalAngle => 'Ángulo vertical inválido';

  @override
  String get calculationError => 'Error en el cálculo';

  @override
  String get swapPoints => 'Intercambiar puntos';

  @override
  String get settings => 'Configuraciones';

  @override
  String get setout => 'Replanteo';

  @override
  String get moveForward => 'Mover hacia adelante';

  @override
  String get moveBack => 'Mover hacia atrás';

  @override
  String get moveLeft => 'Mover a la izquierda';

  @override
  String get moveRight => 'Mover a la derecha';

  @override
  String get moveUp => 'Mover hacia arriba';

  @override
  String get moveDown => 'Mover hacia abajo';

  @override
  String get onLine => 'En línea';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String get homePage => 'Página principal';

  @override
  String get jobs => 'Trabajos';

  @override
  String get jobsHint => 'Seleccionar, Crear o Administrar';

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
  String get noCurrentJob => 'Sin trabajo actual';

  @override
  String currentJob(String jobName) {
    return 'Trabajo actual: $jobName';
  }

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get importPoints => 'Importar puntos';

  @override
  String get exportPoints => 'Exportar puntos';

  @override
  String get readyToImport => 'Listo para importar';

  @override
  String get importStatus => 'Estado de importación:';

  @override
  String get slopeDistanceWithUnit => 'Distancia de pendiente (m)';

  @override
  String get targetHeight => 'Altura objetivo (m)';

  @override
  String get horizontalAngle => 'Ángulo horizontal';

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
  String get distance => 'Distancia';

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
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get success => 'Éxito';

  @override
  String get singleJoin => 'Unión simple';

  @override
  String get polar => 'Polar';

  @override
  String get firstPoint => '1er Punto';

  @override
  String get secondPoint => '2do Punto';

  @override
  String get heightDiff => 'Diferencia de altura';

  @override
  String get slopeDistanceLabel => 'Distancia de pendiente';

  @override
  String get gradeSlope => 'Pendiente/Grado 1:';

  @override
  String get gradeSlopePercent => 'Pendiente/Grado %';

  @override
  String get slopeAngle => 'Ángulo de pendiente';

  @override
  String get area => 'Área';

  @override
  String get joins => 'Uniones';

  @override
  String get searchPoint => 'Buscar punto';

  @override
  String get addPoint => 'Agregar punto';

  @override
  String get targetHeightWithUnit => 'Altura objetivo (m)';

  @override
  String get useCurvatureAndRefraction => 'Usar curvatura y refracción';

  @override
  String get firstPointHint => 'Primer punto';

  @override
  String get nextPointHint => 'Siguiente punto';

  @override
  String get addPointTitle => 'Agregar punto';

  @override
  String get invalidComment => 'Comentario inválido';

  @override
  String get comment => 'Comentario';

  @override
  String get descriptor => 'Descriptor';

  @override
  String get coords => 'Coordenadas';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get sortByComment => 'Ordenar por comentario';

  @override
  String get sortByCoordinate => 'Ordenar por coordenada';

  @override
  String get viewOnGoogleMaps => 'Ver en Google Maps';

  @override
  String get addPointDialog => 'Agregar punto';

  @override
  String characterCount(int current, int max) {
    return '$current/$max';
  }

  @override
  String get searchPoints => 'Buscar puntos';

  @override
  String get editPoint => 'Editar punto';

  @override
  String get validComment => 'Comentario válido';

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
  String get dateModifiedNewest => 'Fecha de modificación (más reciente)';

  @override
  String get dateModifiedOldest => 'Fecha de modificación (más antigua)';

  @override
  String get createNewJob => 'Crear nuevo trabajo';

  @override
  String get info => 'Información';

  @override
  String get jobSettings => 'Configuración del trabajo';

  @override
  String get jobName => 'Nombre del trabajo';

  @override
  String get jobInformation => 'Información del trabajo';

  @override
  String get jobDescription => 'Descripción del trabajo';

  @override
  String get coordinateFormat => 'Formato de coordenadas';

  @override
  String get instrument => 'Instrumento';

  @override
  String get dualCapture => 'Captura dual';

  @override
  String get measurementUnits => 'Unidades de medida';

  @override
  String get angularMeasurement => 'Medición angular';

  @override
  String get commsBaudRate => 'Velocidad de baudios de comunicación';

  @override
  String get calculationSettings => 'Configuración de cálculo';

  @override
  String get scaleFactor => 'Factor de escala';

  @override
  String get heightAboveMSL => 'Altura sobre el nivel del mar';

  @override
  String get meanYValue => 'Valor medio Y';

  @override
  String get verticalAngleIndexError => 'Error de índice de ángulo vertical';

  @override
  String get toleranceSettings => 'Configuración de tolerancia';

  @override
  String get spotShotTolerance => 'Tolerancia de disparo puntual';

  @override
  String get horizontalAlignmentOffsetTolerance => 'Tolerancia de desplazamiento de alineación horizontal';

  @override
  String get maximumSearchDistanceFromCL => 'Distancia máxima de búsqueda desde CL';

  @override
  String get timingSettings => 'Configuración de tiempo';

  @override
  String get numberOfRetries => 'Número de reintentos';

  @override
  String get timeout => 'Tiempo de espera';

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
  String get horzAlignment => 'Alineación horizontal';

  @override
  String get dtmTot => 'DTM (TOT)';

  @override
  String get roadDesign => 'Diseño de carretera';

  @override
  String get strings => 'Cadenas';

  @override
  String get tacheRaw => 'Tache (crudo)';

  @override
  String get tacheReduced => 'Tache (reducido)';

  @override
  String get fieldbook => 'Libro de campo';

  @override
  String get importCoordinatesHint => 'Importar datos de coordenadas desde archivo. Formato delimitado por coma, espacio o tabulación. Formato CYXZ o CENZ. Restringido a 20 caracteres';

  @override
  String get importHorzAlignmentHint => 'Importar datos de alineación horizontal de archivos PID de Model y Road Maker';

  @override
  String get importDtmTotHint => 'Leer archivo TOT de Model Maker. Modelo TIN';

  @override
  String get importRoadDesignHint => 'Importar datos y especificaciones de diseño de carretera de Road Maker. Archivo PR3';

  @override
  String get importStringsHint => 'Importar cadenas de Model Maker.';

  @override
  String get exportTacheRawHint => 'Exportar datos de taquimetría crudos';

  @override
  String get exportTacheReducedHint => 'Exportar datos de taquimetría procesados Comentario YXZ/ENZ';

  @override
  String get exportFieldbookHint => 'Exportar datos del libro de campo';

  @override
  String get exportRoadDesignHint => 'Exportar datos de diseño de carretera';

  @override
  String get deletingYourJob => 'Eliminando su trabajo';

  @override
  String deleteJobConfirmation(String jobName) {
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

  @override
  String plotCoordinatesTitle(int count) {
    return 'Coordenadas de trama - $count';
  }

  @override
  String get showComments => 'Mostrar comentarios';

  @override
  String get showDescriptors => 'Mostrar descriptores';

  @override
  String get showZValues => 'Mostrar valores Z';

  @override
  String zDecimals(int count) {
    return 'Decimales Z: $count';
  }

  @override
  String get setGridInterval => 'Establecer intervalo de cuadrícula';

  @override
  String get pointUpdatedSuccess => 'Punto actualizado correctamente';

  @override
  String get pointMovedOutOfView => 'Punto movido fuera de vista';

  @override
  String get plotCoordinates => 'Plot Coordinates';
}
