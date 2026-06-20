import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/index.dart';
import '../core/sql_queries.dart';

/// Repository pour gérer les notifications de traitements
class NotificationRepository extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final logger = createLoggerWithFileOutput(name: 'notification_repository');

  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _treatments = [];
  int _notificationHour = 8;
  int _notificationMinute = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get treatments => _treatments;
  int get notificationHour => _notificationHour;
  int get notificationMinute => _notificationMinute;

  /// Charger l'heure de notification depuis SharedPreferences
  Future<void> loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationHour = prefs.getInt('notification_hour') ?? 8;
      _notificationMinute = prefs.getInt('notification_minute') ?? 0;
      notifyListeners();
    } catch (e) {
      log.error(
        'Erreur chargement paramètres notification: $e',
        source: 'NotificationRepository',
      );
    }
  }

  /// Charger les traitements du jour suivant avec détails et planifier la notification
  Future<List<Map<String, dynamic>>> loadAndNotifyNextDayTreatments() async {
    _isLoading = true;
    _errorMessage = null;
    _treatments = [];
    notifyListeners();

    try {
      // Vérifier et établir la connexion si nécessaire
      if (!_db.isConnected) {
        await _db.connect();
      }

      // Charger les paramètres de notification
      await loadNotificationSettings();

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final dateStr = tomorrow.toIso8601String().split('T')[0];

      final rows = await _db.query(SqlQueries.getNextDayTreatmentsDetailed, [dateStr]);
      _treatments = rows;
      final count = _treatments.length;

      if (count > 0) {
        // Construire le message avec détails
        final details = _treatments
            .take(3)
            .map((t) {
              final nom = '${t['prenom']} ${t['nom']}';
              final traitement = t['typeTraitement'] ?? 'Traitement';
              return '$nom ($traitement)';
            })
            .join(', ');

        final subtitle = count > 3
            ? '$details, et ${count - 3} autre${count > 4 ? 's' : ''}'
            : details;

        await notifications.scheduleNextTreatmentsNotification(
          count,
          subtitle: subtitle,
          hour: _notificationHour,
          minute: _notificationMinute,
        );
      }

      log.info(
        'Traitements trouvés pour demain: $count',
        source: 'NotificationRepository',
      );

      return _treatments;
    } catch (e) {
      _errorMessage = e.toString();
      log.error(
        'Erreur lors du chargement des traitements: $e',
        source: 'NotificationRepository',
      );
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Planifier une notification personnalisée et sauvegarder l'heure
  Future<void> scheduleCustomNotification({
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    try {
      // Sauvegarder l'heure et la minute
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_hour', hour);
      await prefs.setInt('notification_minute', minute);
      _notificationHour = hour;
      _notificationMinute = minute;
      notifyListeners();

      await notifications.scheduleDailyNotification(
        title: title,
        body: body,
        hour: hour,
        minute: minute,
      );
      log.info(
        'Notification planifiée à ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        source: 'NotificationRepository',
      );
    } catch (e) {
      _errorMessage = e.toString();
      log.error(
        'Erreur planification notification: $e',
        source: 'NotificationRepository',
      );
    }
  }

  /// Obtenir les traitements du jour suivant avec détails
  Future<List<Map<String, dynamic>>> getNextDayTreatmentsWithDetails() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Vérifier et établir la connexion si nécessaire
      if (!_db.isConnected) {
        await _db.connect();
      }

      // Charger les paramètres de notification
      await loadNotificationSettings();

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final dateStr = tomorrow.toIso8601String().split('T')[0];

      final rows = await _db.query(SqlQueries.getNextDayTreatmentsWithDetails, [dateStr]);
      _treatments = rows;

      log.info(
        '${_treatments.length} traitements trouvés pour demain',
        source: 'NotificationRepository',
      );
      return _treatments;
    } catch (e) {
      _errorMessage = e.toString();
      log.error(
        'Erreur lors du chargement des traitements: $e',
        source: 'NotificationRepository',
      );
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtenir le count des traitements du jour
  Future<int> getTodayTreatmentCount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Vérifier et établir la connexion si nécessaire
      if (!_db.isConnected) {
        await _db.connect();
      }

      final today = DateTime.now().toIso8601String().split('T')[0];

      final rows = await _db.query(SqlQueries.countTodayTreatments, [today]);
      final count = rows.isNotEmpty ? (rows[0]['count'] as int? ?? 0) : 0;

      log.info(
        '$count traitements pour aujourd\'hui',
        source: 'NotificationRepository',
      );
      return count;
    } catch (e) {
      _errorMessage = e.toString();
      log.error(
        'Erreur lors du chargement des traitements: $e',
        source: 'NotificationRepository',
      );
      return 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
