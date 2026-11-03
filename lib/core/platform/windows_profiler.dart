/// Windows Performance Profiler
///
/// Aide à identifier les goulots d'étranglement de performance
/// et mesure les temps de chargement sur Windows
library;

import 'dart:developer' show log;

class PerformanceMetrics {
  final String name;
  final DateTime startTime;
  DateTime? endTime;
  List<PerformanceMetrics> children = [];

  PerformanceMetrics(this.name) : startTime = DateTime.now();

  void end() => endTime = DateTime.now();

  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  double get durationMs => duration.inMilliseconds.toDouble();

  void addChild(PerformanceMetrics child) {
    children.add(child);
  }

  String get report {
    final buffer = StringBuffer();
    _buildReport(buffer, '', 0);
    return buffer.toString();
  }

  void _buildReport(StringBuffer buffer, String prefix, int depth) {
    final durationStr = '${durationMs.toStringAsFixed(1)}ms';
    final icon = endTime == null ? '[IN PROGRESS]' : '[DONE]';

    buffer.writeln('$prefix$icon $name: $durationStr');

    for (final child in children) {
      child._buildReport(buffer, '$prefix  ', depth + 1);
    }
  }

  /// Analyser et retourner les mettriques lentes (>100ms)
  List<PerformanceMetrics> getSlowMetrics({double thresholdMs = 100}) {
    final slow = <PerformanceMetrics>[];

    if (durationMs > thresholdMs) {
      slow.add(this);
    }

    for (final child in children) {
      slow.addAll(child.getSlowMetrics(thresholdMs: thresholdMs));
    }

    return slow;
  }
}

/// Global profiler pour tracked automatique
class WindowsProfiler {
  static final List<PerformanceMetrics> _metrics = [];
  static PerformanceMetrics? _current;

  /// Démarrer une mesure
  static PerformanceMetrics start(String name) {
    final metric = PerformanceMetrics(name);

    if (_current != null) {
      _current!.addChild(metric);
    } else {
      _metrics.add(metric);
    }

    _current = metric;

    return metric;
  }

  /// Terminer la mesure actuelle
  static void end() {
    if (_current == null) return;

    _current!.end();

    // Retourner au parent
    // Note: Implémentation simplifié, idealement on trackrait les parents
  }

  /// Enregistrer le rapport de performance
  static void logReport({bool showSlow = true, double thresholdMs = 100}) {
    log('====================================================================');
    log('PERFORMANCE REPORT (Windows)');
    log('====================================================================');

    for (final metric in _metrics) {
      log(metric.report);
    }

    if (showSlow) {
      final slowMetrics = _metrics
          .expand((m) => m.getSlowMetrics(thresholdMs: thresholdMs))
          .toList();

      if (slowMetrics.isNotEmpty) {
        log('SLOW OPERATIONS (>$thresholdMs ms):');
        for (final metric in slowMetrics) {
          log(
            '  SLOW: ${metric.name}: ${metric.durationMs.toStringAsFixed(1)}ms',
          );
        }
      }
    }

    log('====================================================================');
  }

  /// Vider les mesures
  static void clear() {
    _metrics.clear();
    _current = null;
  }

  /// Obtenir les stats agrégées
  static Map<String, double> getStats() {
    final allMetrics = _metrics.expand((m) => [m, ...m.children]).toList();

    if (allMetrics.isEmpty) return {};

    final durations = allMetrics.map((m) => m.durationMs).toList();
    durations.sort();

    return {
      'total': allMetrics.fold(0, (sum, m) => sum + m.durationMs),
      'average': allMetrics.isEmpty
          ? 0
          : (allMetrics.fold(0.0, (sum, m) => sum + m.durationMs) /
                allMetrics.length),
      'min': durations.first,
      'max': durations.last,
      'count': allMetrics.length.toDouble(),
    };
  }
}

/// Decorator pour mesurer automatiquement
T measurePerformance<T>(
  String name,
  T Function() fn, {
  bool logResult = false,
}) {
  final metric = WindowsProfiler.start(name);
  try {
    return fn();
  } finally {
    metric.end();
    if (logResult) {
      log('$name: ${metric.durationMs.toStringAsFixed(1)}ms');
    }
  }
}

/// Version async pour les Futures
Future<T> measureAsync<T>(
  String name,
  Future<T> Function() fn, {
  bool logResult = false,
}) async {
  final metric = WindowsProfiler.start(name);
  try {
    return await fn();
  } finally {
    metric.end();
    if (logResult) {
      log('$name: ${metric.durationMs.toStringAsFixed(1)}ms');
    }
  }
}
