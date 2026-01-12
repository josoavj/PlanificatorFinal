import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:workmanager/workmanager.dart';
import 'logging_service.dart';

/// Service centralisé de notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  late final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialiser le service de notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialiser timezone
      tzdata.initializeTimeZones();

      // Initialiser les notifications locales
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            defaultPresentAlert: true,
            defaultPresentBadge: true,
            defaultPresentSound: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      // Initialiser WorkManager pour les tâches planifiées
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      _isInitialized = true;
      log.info(
        'Service de notifications initialisé',
        source: 'NotificationService',
      );
    } catch (e) {
      log.error(
        'Erreur initialisation notifications: $e',
        source: 'NotificationService',
      );
    }
  }

  /// Envoyer une notification simple
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) return;

    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'planificator_channel',
            'Planificator Notifications',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      log.debug(
        '📢 Notification envoyée: $title',
        source: 'NotificationService',
      );
    } catch (e) {
      log.error('Erreur envoi notification: $e', source: 'NotificationService');
    }
  }

  /// Envoyer une notification journalière aux heures spécifiées
  Future<void> scheduleDailyNotification({
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!_isInitialized) return;

    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Si l'heure est passée, planifier pour demain
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'planificator_daily_channel',
            'Planificator Daily Notifications',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        title,
        body,
        scheduledDate,
        notificationDetails,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      log.info(
        'Notification journalière planifiée: $title à $hour:$minute',
        source: 'NotificationService',
      );
    } catch (e) {
      log.error(
        'Erreur planification notification: $e',
        source: 'NotificationService',
      );
    }
  }

  /// Gérer le clic sur une notification
  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      log.debug(
        'Notification cliquée: $payload',
        source: 'NotificationService',
      );
    }
  }

  /// Planifier la notification journalière pour les traitements du lendemain
  Future<void> scheduleNextTreatmentsNotification(
    int treatmentCount, {
    String subtitle = '',
    int hour = 8,
    int minute = 0,
  }) async {
    if (treatmentCount == 0) {
      log.debug('Aucun traitement pour demain', source: 'NotificationService');
      return;
    }

    final title = 'Prochains Traitements - Demain';
    final body = subtitle.isNotEmpty
        ? subtitle
        : '📅 $treatmentCount traitement${treatmentCount > 1 ? 's' : ''} programmé${treatmentCount > 1 ? 's' : ''}';

    await scheduleDailyNotification(
      title: title,
      body: body,
      hour: hour,
      minute: minute,
      payload: 'next_treatments',
    );
  }

  /// Annuler toutes les notifications
  Future<void> cancelAll() async {
    if (!_isInitialized) return;
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      log.info(
        'Toutes les notifications annulées',
        source: 'NotificationService',
      );
    } catch (e) {
      log.error(
        'Erreur annulation notifications: $e',
        source: 'NotificationService',
      );
    }
  }

  /// Annuler une notification spécifique
  Future<void> cancel(int id) async {
    if (!_isInitialized) return;
    try {
      await _flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      log.error(
        'Erreur annulation notification $id: $e',
        source: 'NotificationService',
      );
    }
  }
}

// Callback dispatcher pour les tâches en arrière-plan
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      log.info('Tâche planifiée exécutée: $taskName', source: 'Workmanager');
      return Future.value(true);
    } catch (e) {
      log.error('Erreur exécution tâche: $e', source: 'Workmanager');
      return Future.value(false);
    }
  });
}

// Singleton global pour accès partout dans l'app
final notifications = NotificationService();
