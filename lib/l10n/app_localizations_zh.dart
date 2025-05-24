// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '测量软件';

  @override
  String get softwareName => '测量软件';

  @override
  String get developmentDate => '开发日期';

  @override
  String get version => '版本';

  @override
  String get contact => '联系方式';

  @override
  String get phone => '电话';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get email => '电子邮件';

  @override
  String get location => '位置';

  @override
  String get slopeDistance => '斜距';

  @override
  String get verticalAngle => '垂直角';

  @override
  String get invalidSlopeDistance => '无效的斜距';

  @override
  String get invalidVerticalAngle => '无效的垂直角';

  @override
  String get calculationError => '计算错误';

  @override
  String get swapPoints => '交换点';

  @override
  String get settings => '设置';

  @override
  String get setout => '放样';

  @override
  String get moveForward => '向前移动';

  @override
  String get moveBack => '向后移动';

  @override
  String get moveLeft => '向左移动';

  @override
  String get moveRight => '向右移动';

  @override
  String get moveUp => '向上移动';

  @override
  String get moveDown => '向下移动';

  @override
  String get onLine => '在线上';

  @override
  String get language => '语言';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get homePage => '主页';

  @override
  String get jobs => '工作';

  @override
  String get jobsHint => '选择、创建或管理';

  @override
  String get coordinates => '坐标';

  @override
  String get coordinatesHint => '查看、添加、编辑、删除';

  @override
  String get calculations => '计算';

  @override
  String get calculationsHint => '连接、极坐标';

  @override
  String get fixes => '固定点';

  @override
  String get roads => '道路';

  @override
  String get quit => '退出';

  @override
  String get noCurrentJob => '无当前工作';

  @override
  String currentJob(String jobName) {
    return '当前工作：$jobName';
  }

  @override
  String get comingSoon => '即将推出';

  @override
  String get importPoints => '导入点';

  @override
  String get exportPoints => '导出点';

  @override
  String get readyToImport => '准备导入';

  @override
  String get importStatus => '导入状态：';

  @override
  String get slopeDistanceWithUnit => '斜距 (m)';

  @override
  String get targetHeight => '目标高度 (m)';

  @override
  String get horizontalAngle => '水平角';

  @override
  String get setupAt => '设置于';

  @override
  String get pointName => '点名';

  @override
  String get search => '搜索';

  @override
  String get add => '添加';

  @override
  String get calculatedPosition => '计算位置';

  @override
  String get distance => '距离';

  @override
  String get direction => '方向';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get update => '更新';

  @override
  String error(String message) {
    return '错误：$message';
  }

  @override
  String get success => '成功';

  @override
  String get singleJoin => '单点连接';

  @override
  String get polar => '极坐标';

  @override
  String get firstPoint => '第一点';

  @override
  String get secondPoint => '第二点';

  @override
  String get heightDiff => '高度差';

  @override
  String get slopeDistanceLabel => '斜距';

  @override
  String get gradeSlope => '坡度 1:';

  @override
  String get gradeSlopePercent => '坡度百分比';

  @override
  String get slopeAngle => '坡度角';

  @override
  String get area => 'Area';

  @override
  String get joins => '连接';

  @override
  String get searchPoint => '搜索点';

  @override
  String get addPoint => '添加点';

  @override
  String get targetHeightWithUnit => '目标高度 (m)';

  @override
  String get useCurvatureAndRefraction => '使用曲率和折射';

  @override
  String get firstPointHint => '第一点';

  @override
  String get nextPointHint => '下一点';

  @override
  String get addPointTitle => '添加点';

  @override
  String get invalidComment => '无效注释';

  @override
  String get comment => '注释';

  @override
  String get descriptor => '描述符';

  @override
  String get coords => '坐标';

  @override
  String get sortBy => '排序方式';

  @override
  String get sortByComment => '按注释排序';

  @override
  String get sortByCoordinate => '按坐标排序';

  @override
  String get viewOnGoogleMaps => '在谷歌地图中查看';

  @override
  String get addPointDialog => '添加点';

  @override
  String characterCount(int current, int max) {
    return '$current/$max';
  }

  @override
  String get searchPoints => '搜索点';

  @override
  String get editPoint => '编辑点';

  @override
  String get validComment => '有效注释';

  @override
  String get pleaseEnterComment => '请输入注释';

  @override
  String get commentExists => '注释已存在';

  @override
  String get backup => '备份';

  @override
  String get searchJob => '搜索工作';

  @override
  String get sortJobsBy => '工作排序方式';

  @override
  String get nameAtoZ => '名称 (A 到 Z)';

  @override
  String get nameZtoA => '名称 (Z 到 A)';

  @override
  String get dateModifiedNewest => '修改日期 (最新)';

  @override
  String get dateModifiedOldest => '修改日期 (最早)';

  @override
  String get createNewJob => '创建新工作';

  @override
  String get info => '信息';

  @override
  String get jobSettings => '工作设置';

  @override
  String get jobName => '工作名称';

  @override
  String get jobInformation => '工作信息';

  @override
  String get jobDescription => '工作描述';

  @override
  String get coordinateFormat => '坐标格式';

  @override
  String get instrument => '仪器';

  @override
  String get dualCapture => '双重采集';

  @override
  String get measurementUnits => '测量单位';

  @override
  String get angularMeasurement => '角度测量';

  @override
  String get commsBaudRate => '通信波特率';

  @override
  String get calculationSettings => '计算设置';

  @override
  String get scaleFactor => '比例因子';

  @override
  String get heightAboveMSL => '平均海平面以上高度';

  @override
  String get meanYValue => 'Y值平均值';

  @override
  String get verticalAngleIndexError => '垂直角指数误差';

  @override
  String get toleranceSettings => '误差设置';

  @override
  String get spotShotTolerance => '点测量误差 (m)';

  @override
  String get horizontalAlignmentOffsetTolerance => '水平对齐偏移误差 (m)';

  @override
  String get maximumSearchDistanceFromCL => '中心线最大搜索距离 (m)';

  @override
  String get timingSettings => '时间设置';

  @override
  String get numberOfRetries => '重试次数';

  @override
  String get timeout => '超时时间（秒）';

  @override
  String get instrumentSettings => '仪器设置';

  @override
  String get manualInstrument => '手动';

  @override
  String get importExport => '导入/导出';

  @override
  String get exportCoordinatesHint => '导出坐标数据到文件';

  @override
  String get import => '导入';

  @override
  String get export => '导出';

  @override
  String get horzAlignment => '水平线形';

  @override
  String get dtmTot => 'DTM (TOT)';

  @override
  String get roadDesign => '道路设计';

  @override
  String get strings => '线路';

  @override
  String get tacheRaw => 'Tache (Raw)';

  @override
  String get tacheReduced => 'Tache (Reduced)';

  @override
  String get fieldbook => '现场手册';

  @override
  String get importCoordinatesHint => '从文件导入坐标数据。格式：逗号、空格、制表符分隔。格式：CYXZ 或 CENZ。限制 20 个字符';

  @override
  String get importHorzAlignmentHint => '从Model和Road Maker PID文件导入水平线形数据';

  @override
  String get importDtmTotHint => 'Read Model Maker TOT file. TIN model';

  @override
  String get importRoadDesignHint => '从Road Maker导入道路设计数据和规范。PR3文件';

  @override
  String get importStringsHint => '从Model Maker导入线路';

  @override
  String get exportTacheRawHint => 'Export raw tacheometry data';

  @override
  String get exportTacheReducedHint => 'Export processed tacheometry data Comment YXZ/ENZ';

  @override
  String get exportFieldbookHint => '导出现场手册数据';

  @override
  String get exportRoadDesignHint => 'Export road design data';

  @override
  String get deletingYourJob => '删除您的工作';

  @override
  String deleteJobConfirmation(String jobName) {
    return '您确定要删除\"$jobName\"及其所有内容吗？';
  }

  @override
  String get searchJobsHint => '搜索工作...';

  @override
  String get exit => '退出';

  @override
  String get lastModified => '最后修改时间';

  @override
  String get created => '创建时间';

  @override
  String get size => '大小';

  @override
  String jobInfoDialogTitle(String jobName) {
    return '作业信息 - $jobName';
  }

  @override
  String get usageTimer => '使用计时器';

  @override
  String currentSession(String duration) {
    return '本次会话：$duration';
  }

  @override
  String totalJobTime(String jobName, String duration) {
    return '$jobName总用时：$duration';
  }

  @override
  String get locationNotAvailable => '位置不可用';

  @override
  String latitude(String latitude) {
    return '纬度：$latitude';
  }

  @override
  String longitude(String longitude) {
    return '经度：$longitude';
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
