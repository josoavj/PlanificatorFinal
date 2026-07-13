import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart' as logger_pkg;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io';
import 'services/index.dart';
import 'repositories/index.dart';
import 'config/database_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/setup/database_config_screen.dart';
import 'screens/client/client_list_screen.dart';
import 'screens/contrat/contrat_screen.dart';
import 'screens/facture/facture_screen.dart';
import 'screens/planning/planning_screen.dart';
import 'screens/historique/historique_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/about/about_screen.dart';
import 'core/theme.dart';

/// Logger global qui envoie tous les logs au fichier
final logger = logger_pkg.Logger(level: logger_pkg.Level.debug);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le service de logging
  await log.initialize();

  // Configurer le logger global pour envoyer tous les logs au fichier
  log.configureGlobalLogger(logger);

  log.info('Plateforme démarrée', source: 'main');

  // Initialiser le provider de thème
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();
  log.info('Provider de thème initialisé', source: 'main');

  // Initialiser le service de notifications
  await notifications.initialize();
  log.info('Service de notifications initialisé', source: 'main');

  // Initialiser les données de locale pour intl
  await initializeDateFormatting('fr_FR');

  // Définir la locale par défaut pour intl (DateFormat)
  Intl.defaultLocale = 'fr_FR';

  // Initialiser la configuration de la base de données
  final config = DatabaseConfig();
  await config.initialize();

  // Mettre à jour les paramètres du DatabaseService si configuré
  if (config.isConfigured) {
    final db = DatabaseService();
    db.updateConnectionSettings(
      host: config.host ?? 'localhost',
      port: config.port ?? 3306,
      user: config.user ?? '',
      password: config.password ?? '',
      database: config.database ?? 'Planificator',
    );

    // Sur Windows, désactiver les isolates (bug avec compute() sur Windows)
    // Utiliser la connexion directe à la DB à la place
    if (Platform.isWindows) {
      db.setUseIsolates(false);
      logger.i(
        'Isolates désactivés (Windows détecté - utiliser connexion directe)',
      );
    } else {
      db.setUseIsolates(true);
      logger.i('Isolates activés pour les requêtes');
    }

    // Essayer de se connecter d'abord
    try {
      await db.connect();
      logger.i('Base de données connectée');
    } catch (e) {
      logger.e('Connexion impossible: $e');
    }

    // Charger les traitements du lendemain et planifier les notifications
    try {
      final notifRepo = NotificationRepository();
      await notifRepo.loadAndNotifyNextDayTreatments();
    } catch (e) {
      log.warning('Erreur chargement traitements: $e', source: 'main');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isConfigured = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkConfiguration();
  }

  Future<void> _checkConfiguration() async {
    final config = DatabaseConfig();
    setState(() {
      _isConfigured = config.isConfigured;
      _isInitialized = true;
    });
  }

  void _onConfigured() {
    setState(() {
      _isConfigured = true;
    });
    // Recharger la base de données
    final db = DatabaseService();
    final config = DatabaseConfig();
    db.updateConnectionSettings(
      host: config.host ?? 'localhost',
      port: config.port ?? 3306,
      user: config.user ?? '',
      password: config.password ?? '',
      database: config.database ?? 'Planificator',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MultiProvider(
      providers: [
        // Provider du thème (doit être en premier pour être disponible partout)
        ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),

        // Repositories
        ChangeNotifierProvider(create: (_) => AuthRepository()),
        ChangeNotifierProvider(create: (_) => ClientRepository()),
        ChangeNotifierProvider(create: (_) => FactureRepository()),
        ChangeNotifierProvider(create: (_) => ContratRepository()),
        ChangeNotifierProvider(create: (_) => PlanningRepository()),
        ChangeNotifierProvider(create: (_) => PlanningDetailsRepository()),
        ChangeNotifierProvider(create: (_) => HistoriqueRepository()),
        ChangeNotifierProvider(create: (_) => TypeTraitementRepository()),
        ChangeNotifierProvider(create: (_) => RemarqueRepository()),
        ChangeNotifierProvider(create: (_) => SignalementRepository()),
        ChangeNotifierProvider(create: (_) => NotificationRepository()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            locale: const Locale('fr', 'FR'),
            home: _isConfigured
                ? _AuthGate()
                : DatabaseConfigScreen(onConfigured: _onConfigured),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const HomeScreen(),
              '/clients': (context) => const ClientListScreen(),
              '/contrats': (context) => const ContratScreen(),
              '/factures': (context) => const FactureScreen(),
              '/planning': (context) => const PlanningScreen(),
              '/historique': (context) => const HistoriqueScreen(),
              '/about': (context) => const AboutScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}

// Widget séparé pour éviter les rebuilds de l'arbre entier
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    logger.i('AuthGate initialized - data loading deferred to screens');
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AuthRepository, bool>(
      selector: (_, auth) => auth.isAuthenticated,
      builder: (_, isAuthenticated, _) {
        if (isAuthenticated) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
