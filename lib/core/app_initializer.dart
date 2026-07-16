import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logger/logger.dart' as logger_pkg;
import '../services/index.dart';
import '../repositories/index.dart';
import '../config/database_config.dart';

/// Classe responsable de l'initialisation de l'application.
/// Centralise toute la logique de démarrage pour garder le main.dart propre.
class AppInitializer {
  static final logger = logger_pkg.Logger(level: logger_pkg.Level.debug);

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Initialiser le service de logging (PRIORITÉ)
    await log.initialize();
    log.configureGlobalLogger(logger);
    log.info('Démarrage de l\'initialisation applicative', source: 'AppInitializer');

    try {
      // 2. Optimisation des performances des polices
      // Désactiver le chargement à l'exécution pour éviter les micro-latences lors des changements de thème
      GoogleFonts.config.allowRuntimeFetching = false;
      log.info('Optimisation GoogleFonts activée', source: 'AppInitializer');

      // 3. Initialiser le provider de thème
      final themeProvider = ThemeProvider();
      await themeProvider.initialize();
      log.info('Provider de thème initialisé', source: 'AppInitializer');

      // 4. Initialiser le service de notifications
      await notifications.initialize();
      log.info('Service de notifications initialisé', source: 'AppInitializer');

      // 5. Internationalisation et Locales
      await initializeDateFormatting('fr_FR');
      Intl.defaultLocale = 'fr_FR';
      log.info('Locales initialisées (fr_FR)', source: 'AppInitializer');

      // 5. Configuration de la base de données
      final config = DatabaseConfig();
      await config.initialize();
      log.info('Configuration base de données chargée', source: 'AppInitializer');

      if (config.isConfigured) {
        await _setupDatabase(config);
      } else {
        log.warning('Base de données non configurée au démarrage', source: 'AppInitializer');
      }

      log.info('Initialisation terminée avec succès', source: 'AppInitializer');
    } catch (e, stack) {
      log.critical('Erreur fatale lors de l\'initialisation: $e', source: 'AppInitializer', stackTrace: stack);
      // On laisse l'erreur remonter si elle est critique, ou on gère un mode dégradé
    }
  }

  static Future<void> _setupDatabase(DatabaseConfig config) async {
    final db = DatabaseService();
    db.updateConnectionSettings(
      host: config.host ?? 'localhost',
      port: config.port ?? 3306,
      user: config.user ?? '',
      password: config.password ?? '',
      database: config.database ?? 'Planificator',
    );

    // Optimisation spécifique à la plateforme
    if (Platform.isWindows) {
      db.setUseIsolates(false);
      log.info('Windows détecté : Isolates désactivés pour la stabilité DB', source: 'AppInitializer');
    } else {
      db.setUseIsolates(true);
      log.info('Isolates activés pour les requêtes DB', source: 'AppInitializer');
    }

    try {
      await db.connect();
      log.info('Connexion à la base de données établie', source: 'AppInitializer');
      
      // Charger les traitements du lendemain
      final notifRepo = NotificationRepository();
      await notifRepo.loadAndNotifyNextDayTreatments();
      log.info('Notifications planifiées pour les traitements de demain', source: 'AppInitializer');
    } catch (e) {
      log.error('Échec de la connexion à la base de données: $e', source: 'AppInitializer');
    }
  }
}
