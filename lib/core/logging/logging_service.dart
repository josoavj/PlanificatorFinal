import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'package:logger/logger.dart' as logger_pkg;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// Vérifier si on est sur Windows
bool isWindows = Platform.isWindows;

final _ansiEscapePattern = RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]');
final _emojiPattern = RegExp(
  r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0E}\u{FE0F}]',
  unicode: true,
);
final _nonAsciiPattern = RegExp(r'[^\x20-\x7E]');

enum LogLevel { debug, info, warning, error, critical }

class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogLevel level;
  final String? source;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.message,
    required this.level,
    this.source,
    this.stackTrace,
  });

  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')}';

  String get levelName => level.name.toUpperCase();

  String get colorCode {
    switch (level) {
      case LogLevel.debug:
        return '\x1B[36m'; // Cyan
      case LogLevel.info:
        return '\x1B[32m'; // Green
      case LogLevel.warning:
        return '\x1B[33m'; // Yellow
      case LogLevel.error:
        return '\x1B[31m'; // Red
      case LogLevel.critical:
        return '\x1B[35m'; // Magenta
    }
  }

  String get formatted =>
      '$colorCode[$formattedTime] [$levelName]${source != null ? ' [$source]' : ''}: $message\x1B[0m';

  String get plainText {
    // Sur Windows, éviter les codes ANSI qui rendent le fichier illisible
    // Utiliser un format structuré et lisible à la place
    final sourceStr = source != null ? ' [$source]' : '';
    final baseLog = '[$formattedTime] [$levelName]$sourceStr: $message';

    // Ajouter séparateurs pour meilleure lisibilité sur Windows
    if (isWindows && level == LogLevel.error || level == LogLevel.critical) {
      return '\n${'=' * 80}\n$baseLog\n${'=' * 80}';
    }
    return baseLog;
  }

  @override
  String toString() => formatted;
}

/// Custom Output pour rediriger les logs du package logger
class _CaptureLogOutput extends logger_pkg.LogOutput {
  final LoggingService _loggingService;

  _CaptureLogOutput(this._loggingService);

  @override
  void output(logger_pkg.OutputEvent event) {
    // Rediriger les logs du package logger vers notre système
    for (var line in event.lines) {
      _loggingService._captureLogLine(line);
    }
  }
}

/// Configuration du service de logging
class LoggingConfig {
  /// Activer la sauvegarde des logs sur disque
  final bool enableFileLogging;

  /// Nombre maximum de logs en mémoire
  final int maxLogsInMemory;

  /// Taille maximale d'un fichier log (en MB)
  final int maxFileSize;

  /// Nombre de fichiers archives à conserver
  final int maxLogFiles;

  /// Niveau minimum de log à persister
  final LogLevel minPersistLevel;

  const LoggingConfig({
    this.enableFileLogging = true,
    this.maxLogsInMemory = 1000,
    this.maxFileSize = 5, // 5 MB
    this.maxLogFiles = 10,
    this.minPersistLevel = LogLevel.debug,
  });
}

/// Service centralisé de logging
/// Capture les logs du package logger ET les logs personnalisés
/// Supporte la persistance fichier avec rotation automatique
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();

  factory LoggingService() {
    return _instance;
  }

  LoggingService._internal() {
    // Initialiser le logger package avec notre output personnalisé
    _initializeLoggerPackage();
  }

  final List<LogEntry> _logs = [];
  final StreamController<LogEntry> _logController =
      StreamController<LogEntry>.broadcast();

  late LoggingConfig _config;

  File? _currentLogFile;
  bool _isInitialized = false;
  Future<void> _fileWriteQueue = Future<void>.value();

  Stream<LogEntry> get logStream => _logController.stream;
  List<LogEntry> get allLogs => List.unmodifiable(_logs);
  int get maxLogs => _config.maxLogsInMemory;
  LoggingConfig get config => _config;

  void _initializeLoggerPackage() {
    // Initialiser le logger package avec notre output personnalisé
    logger_pkg.Logger(
      output: _CaptureLogOutput(this),
      level: logger_pkg.Level.debug,
    );
  }

  /// Configurer le Logger global pour qu'il envoie tous les logs au fichier
  void configureGlobalLogger(logger_pkg.Logger globalLogger) {
    // Le Logger utilise déjà notre _CaptureLogOutput en interne
    // Cette méthode est ici pour la documentation
  }

  /// Initialiser le service de logging avec configuration
  Future<void> initialize({LoggingConfig? config}) async {
    if (_isInitialized) return;

    _config = config ?? const LoggingConfig();

    if (_config.enableFileLogging) {
      try {
        await _initializeFileLogging();
      } catch (e) {
        // Fallback en cas d'erreur - log en mémoire uniquement
        _config = LoggingConfig(
          enableFileLogging: false,
          maxLogsInMemory: _config.maxLogsInMemory,
        );
        debug(' File logging disabled: $e', source: 'LoggingService');
      }
    }

    _isInitialized = true;
    info(' Logging service initialized', source: 'LoggingService');
  }

  /// Initialiser le dossier de logs et vérifier la rotation
  Future<void> _initializeFileLogging() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory(path.join(appDocDir.path, 'Planificator/logs'));

      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      // Créer le fichier log du jour
      final dateStr = DateTime.now().toString().split(
        ' ',
      )[0]; // Format: YYYY-MM-DD
      _currentLogFile = File(
        path.join(logsDir.path, 'planificator_$dateStr.log'),
      );

      // Ajouter un en-tête au fichier si c'est un nouveau fichier
      if (!await _currentLogFile!.exists()) {
        await _currentLogFile!.writeAsString(_getLogFileHeader());
      }

      // Vérifier la rotation des fichiers
      await _rotateLogsIfNeeded();
    } catch (e) {
      rethrow;
    }
  }

  /// Générer un en-tête formaté pour le fichier log
  String _getLogFileHeader() {
    final now = DateTime.now();
    final separator = '=' * 100;
    return _sanitizeLogText('''$separator
PLANIFICATOR LOG FILE
Démarré: ${now.toString()}
Plateforme: ${Platform.operatingSystem.toUpperCase()}
$separator

FORMAT: [HH:MM:SS.mmm] [LEVEL] [SOURCE] [MESSAGE]

''');
  }

  /// Vérifier et archiver les fichiers logs si nécessaire
  Future<void> _rotateLogsIfNeeded() async {
    try {
      if (_currentLogFile == null || !await _currentLogFile!.exists()) {
        return;
      }

      final fileSize = await _currentLogFile!.length();
      final maxSizeBytes = _config.maxFileSize * 1024 * 1024;

      if (fileSize > maxSizeBytes) {
        // Créer un backup avec timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final backupPath = _currentLogFile!.path.replaceAll(
          '.log',
          '_$timestamp.bak',
        );
        await _currentLogFile!.rename(backupPath);

        // Nettoyer les anciens fichiers
        await _cleanupOldLogFiles();

        // Créer un nouveau fichier
        final dateStr = DateTime.now().toString().split(' ')[0];
        _currentLogFile = File(
          path.join(_currentLogFile!.parent.path, 'planificator_$dateStr.log'),
        );
      }
    } catch (e) {
      // Ignorer les erreurs de rotation
    }
  }

  /// Supprimer les fichiers logs les plus anciens
  Future<void> _cleanupOldLogFiles() async {
    try {
      final logsDir = _currentLogFile?.parent;
      if (logsDir == null || !await logsDir.exists()) return;

      final files = logsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('planificator'))
          .toList();

      // Garder seulement les N derniers fichiers
      if (files.length > _config.maxLogFiles) {
        files.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
        );
        for (var i = _config.maxLogFiles; i < files.length; i++) {
          try {
            await files[i].delete();
          } catch (e) {
            // Ignorer les erreurs de suppression
          }
        }
      }
    } catch (e) {
      // Ignorer les erreurs de nettoyage
    }
  }

  /// Persister un log dans un fichier
  void _persistLog(LogEntry entry) {
    _fileWriteQueue = _fileWriteQueue
        .then((_) => _writeLogEntry(entry))
        .catchError((_) {});
  }

  Future<void> _writeLogEntry(LogEntry entry) async {
    if (!_config.enableFileLogging || _currentLogFile == null) return;
    if (entry.level.index < _config.minPersistLevel.index) return;

    try {
      await _rotateLogsIfNeeded();

      // Format structuré et lisible pour le fichier, sans codes ANSI
      String logLine = _formatLogForFile(entry);

      await _currentLogFile!.writeAsString('$logLine\n', mode: FileMode.append);
    } catch (e) {
      // Ignorer silencieusement les erreurs d'écriture fichier
    }
  }

  /// Formater un log pour le fichier en fonction de la plateforme
  String _formatLogForFile(LogEntry entry) {
    final prefix =
        '${entry.formattedTime} | ${entry.levelName.padRight(8)} | '
        '${entry.source?.padRight(20) ?? 'general'.padRight(20)} | ';
    final messageLines = _formatMessageLines(entry.message);
    final baseLog = messageLines.indexed
        .map(
          (line) => line.$1 == 0
              ? '$prefix${line.$2.trim()}'
              : '${' ' * prefix.length}${line.$2.trim()}',
        )
        .join('\n');

    // Sur Windows: ajouter des séparateurs visuels pour les erreurs
    if (isWindows &&
        (entry.level == LogLevel.error || entry.level == LogLevel.critical)) {
      return '\n${'-' * 100}\n$baseLog\n${'-' * 100}';
    }

    return baseLog;
  }

  List<String> _formatMessageLines(String message) {
    final queryMatch = RegExp(
      r'^(?:\[[A-Z]\]\s*)?Query:\s*(.*)$',
      dotAll: true,
    ).firstMatch(message.trim());
    if (queryMatch == null) {
      return message.split('\n');
    }

    final sql = queryMatch.group(1)!.replaceAll(RegExp(r'\s+'), ' ').trim();
    final formattedSql = sql
        .replaceAllMapped(
          RegExp(
            r'\s+(FROM|INNER JOIN|LEFT JOIN|RIGHT JOIN|JOIN|WHERE|GROUP BY|HAVING|ORDER BY|LIMIT)\s+',
            caseSensitive: false,
          ),
          (match) => '\n${match.group(1)!.toUpperCase()} ',
        )
        .replaceAllMapped(
          RegExp(r'\s+(AND|OR)\s+', caseSensitive: false),
          (match) => '\n  ${match.group(1)!.toUpperCase()} ',
        );
    return ['Query:', ...formattedSql.split('\n').map((line) => '  $line')];
  }

  /// Ajouter un log au système de journalisation
  void debug(String message, {String? source, StackTrace? stackTrace}) {
    _addLog(
      LogEntry(
        timestamp: DateTime.now(),
        message: message,
        level: LogLevel.debug,
        source: source,
        stackTrace: stackTrace,
      ),
    );
  }

  void info(String message, {String? source, StackTrace? stackTrace}) {
    _addLog(
      LogEntry(
        timestamp: DateTime.now(),
        message: message,
        level: LogLevel.info,
        source: source,
        stackTrace: stackTrace,
      ),
    );
  }

  void warning(String message, {String? source, StackTrace? stackTrace}) {
    _addLog(
      LogEntry(
        timestamp: DateTime.now(),
        message: message,
        level: LogLevel.warning,
        source: source,
        stackTrace: stackTrace,
      ),
    );
  }

  void error(String message, {String? source, StackTrace? stackTrace}) {
    _addLog(
      LogEntry(
        timestamp: DateTime.now(),
        message: message,
        level: LogLevel.error,
        source: source,
        stackTrace: stackTrace,
      ),
    );
  }

  void critical(String message, {String? source, StackTrace? stackTrace}) {
    _addLog(
      LogEntry(
        timestamp: DateTime.now(),
        message: message,
        level: LogLevel.critical,
        source: source,
        stackTrace: stackTrace,
      ),
    );
  }

  /// Capturer une ligne de log du package logger
  void _captureLogLine(String line) {
    try {
      line = _sanitizeLogText(line);
      if (line.trim().isEmpty || RegExp(r'^[\s\-=]+$').hasMatch(line)) {
        return;
      }

      // Déterminer le niveau du log à partir du contenu
      LogLevel level = LogLevel.info;
      if (line.contains('VERBOSE') || line.contains('verbose')) {
        level = LogLevel.debug;
      } else if (line.contains('DEBUG') || line.contains('debug')) {
        level = LogLevel.debug;
      } else if (line.contains('INFO') || line.contains('ℹnfo')) {
        level = LogLevel.info;
      } else if (line.contains('WARNING') || line.contains('warning')) {
        level = LogLevel.warning;
      } else if (line.contains('ERROR') || line.contains('error')) {
        level = LogLevel.error;
      } else if (line.contains('WTF')) {
        level = LogLevel.critical;
      }

      _addLog(
        LogEntry(
          timestamp: DateTime.now(),
          message: line,
          level: level,
          source: 'logger',
        ),
      );
    } catch (e) {
      // Éviter les erreurs infinies de logging
    }
  }

  void _addLog(LogEntry entry) {
    final sanitizedEntry = LogEntry(
      timestamp: entry.timestamp,
      message: _sanitizeLogText(entry.message),
      level: entry.level,
      source: entry.source,
      stackTrace: entry.stackTrace,
    );
    _logs.add(sanitizedEntry);
    _logController.add(sanitizedEntry);

    // Persister le log en fichier (async)
    _persistLog(sanitizedEntry);

    // Afficher dans la console en debug
    if (kDebugMode) {
      print(sanitizedEntry.formatted);
    }

    // Limiter la taille du buffer
    if (_logs.length > _config.maxLogsInMemory) {
      _logs.removeRange(0, _logs.length - _config.maxLogsInMemory);
    }
  }

  String _sanitizeLogText(String text) {
    const replacements = {
      'À': 'A',
      'Â': 'A',
      'Ä': 'A',
      'Ç': 'C',
      'È': 'E',
      'É': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'Î': 'I',
      'Ï': 'I',
      'Ô': 'O',
      'Ö': 'O',
      'Ù': 'U',
      'Û': 'U',
      'Ü': 'U',
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'ç': 'c',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'î': 'i',
      'ï': 'i',
      'ô': 'o',
      'ö': 'o',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'œ': 'oe',
      'Œ': 'OE',
      '’': "'",
      '→': '->',
    };
    var sanitized = text;
    for (final replacement in replacements.entries) {
      sanitized = sanitized.replaceAll(replacement.key, replacement.value);
    }
    return sanitized
        .replaceAll(_ansiEscapePattern, '')
        .replaceAll(_emojiPattern, '')
        .replaceAll(_nonAsciiPattern, '');
  }

  /// Exporter les logs en format texte
  String exportLogs({LogLevel? minLevel}) {
    final filtered = _logs
        .where((log) => minLevel == null || log.level.index >= minLevel.index)
        .toList();
    return filtered
        .map((e) {
          final baseLog =
              '${e.formattedTime} | ${e.levelName.padRight(8)} | '
              '${e.source?.padRight(20) ?? 'general'.padRight(20)} | ${e.message}';
          return baseLog;
        })
        .join('\n');
  }

  /// Obtenir les logs sous forme de liste pour affichage console
  List<String> getLogsFormatted({LogLevel? minLevel}) {
    final filtered = _logs
        .where((log) => minLevel == null || log.level.index >= minLevel.index)
        .toList();
    // Sur Windows, utiliser plainText sans codes ANSI; sur autres OS, utiliser formatted avec couleurs
    return filtered.map((e) => isWindows ? e.plainText : e.formatted).toList();
  }

  /// Effacer tous les logs en mémoire
  void clear() {
    _logs.clear();
  }

  /// Filtrer les logs par niveau
  List<LogEntry> getLogsAtLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  /// Filtrer les logs par source
  List<LogEntry> getLogsBySource(String source) {
    return _logs.where((log) => log.source?.contains(source) ?? false).toList();
  }

  /// Recherche full-text dans les logs
  List<LogEntry> searchLogs(String query) {
    final q = query.toLowerCase();
    return _logs
        .where(
          (log) =>
              log.message.toLowerCase().contains(q) ||
              (log.source?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  /// Obtenir un résumé des logs
  String getSummary() {
    final errors = getLogsAtLevel(LogLevel.error).length;
    final warnings = getLogsAtLevel(LogLevel.warning).length;
    final infos = getLogsAtLevel(LogLevel.info).length;
    final debugs = getLogsAtLevel(LogLevel.debug).length;
    final criticals = getLogsAtLevel(LogLevel.critical).length;

    return '''
Résumé des Logs:
- Critical: $criticals
- Erreurs: $errors
- Avertissements: $warnings
- Infos: $infos
- Debug: $debugs
- Total: ${_logs.length}
''';
  }

  /// Récupérer le chemin du dossier logs
  Future<String?> getLogsDirectory() async {
    if (!_config.enableFileLogging) return null;
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      return path.join(appDocDir.path, 'Planificator/logs');
    } catch (e) {
      return null;
    }
  }

  /// Exporter tous les logs du jour depuis le fichier
  Future<String?> exportTodayLogs() async {
    if (_currentLogFile == null || !await _currentLogFile!.exists()) {
      return null;
    }
    try {
      // Lire avec UTF-8 pour Windows (évite les problèmes d'encodage)
      return await _currentLogFile!.readAsString();
    } catch (e) {
      return null;
    }
  }

  /// Nettoyer tous les fichiers logs
  Future<void> clearLogFiles() async {
    if (!_config.enableFileLogging) return;
    try {
      final logsDir = _currentLogFile?.parent;
      if (logsDir != null && await logsDir.exists()) {
        logsDir.deleteSync(recursive: true);
        await _initializeFileLogging();
      }
    } catch (e) {
      // Ignorer les erreurs
    }
  }
}

// Singleton global pour accès partout dans l'app
final log = LoggingService();

/// Crée un Logger qui envoie tous ses logs au LoggingService
/// Utiliser cette fonction dans vos fichiers pour créer un logger local
/// qui persiste automatiquement dans les fichiers
logger_pkg.Logger createLoggerWithFileOutput({String? name}) {
  return logger_pkg.Logger(
    output: _CaptureLogOutput(log),
    printer: logger_pkg.SimplePrinter(),
    level: logger_pkg.Level.debug,
    filter: logger_pkg.ProductionFilter(),
  );
}
