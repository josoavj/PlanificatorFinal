import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:logger/logger.dart' as logger_pkg;

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

/// Service centralisé de logging
/// Capture les logs du package logger ET les logs personnalisés
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

  late final logger_pkg.Logger _loggerPackage;

  Stream<LogEntry> get logStream => _logController.stream;
  List<LogEntry> get allLogs => List.unmodifiable(_logs);

  int get maxLogs => 1000; // Augmenté pour capturer plus de logs

  void _initializeLoggerPackage() {
    _loggerPackage = logger_pkg.Logger(
      output: _CaptureLogOutput(this),
      level: logger_pkg.Level.debug,
    );
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
      // Déterminer le niveau du log à partir du contenu
      LogLevel level = LogLevel.info;
      if (line.contains('VERBOSE') || line.contains('💬')) {
        level = LogLevel.debug;
      } else if (line.contains('DEBUG') || line.contains('🐛')) {
        level = LogLevel.debug;
      } else if (line.contains('INFO') || line.contains('ℹ️')) {
        level = LogLevel.info;
      } else if (line.contains('WARNING') || line.contains('⚠️')) {
        level = LogLevel.warning;
      } else if (line.contains('ERROR') || line.contains('❌')) {
        level = LogLevel.error;
      } else if (line.contains('WTF') || line.contains('🔥')) {
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
    _logs.add(entry);
    _logController.add(entry);

    // Afficher dans la console en debug
    if (kDebugMode) {
      print(entry.formatted);
    }

    // Limiter la taille du buffer
    if (_logs.length > maxLogs) {
      _logs.removeRange(0, _logs.length - maxLogs);
    }
  }

  /// Exporter les logs en format texte
  String exportLogs({LogLevel? minLevel}) {
    final filtered = _logs
        .where((log) => minLevel == null || log.level.index >= minLevel.index)
        .toList();
    return filtered.map((e) => e.formatted).join('\n');
  }

  /// Obtenir les logs sous forme de liste pour affichage
  List<String> getLogsFormatted({LogLevel? minLevel}) {
    final filtered = _logs
        .where((log) => minLevel == null || log.level.index >= minLevel.index)
        .toList();
    return filtered.map((e) => e.formatted).toList();
  }

  /// Effacer tous les logs
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
}

// Singleton global pour accès partout dans l'app
final log = LoggingService();
