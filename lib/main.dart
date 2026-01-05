import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
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

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les données de locale pour intl
  await initializeDateFormatting('fr_FR', null);

  // Définir la locale par défaut pour intl (DateFormat)
  Intl.defaultLocale = 'fr_FR';

  // Initialiser la configuration de la base de données
  final config = DatabaseConfig();
  await config.initialize();

  // Mettre à jour les paramètres du DatabaseService
  if (config.isConfigured) {
    final db = DatabaseService();
    db.updateConnectionSettings(
      host: config.host ?? 'localhost',
      port: config.port ?? 3306,
      user: config.user ?? '',
      password: config.password ?? '',
      database: config.database ?? 'Planificator',
    );

    // Essayer de se connecter
    try {
      await db.connect();
      logger.i('✅ Base de données connectée');
    } catch (e) {
      logger.e('⚠️ Connexion impossible: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

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

    // ✅ Charger les types de traitement dès que la BD est prête
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<TypeTraitementRepository>().loadAllTraitements();
      } catch (e) {
        // Silencieusement ignorer si le contexte n'est pas disponible
      }
    });
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
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('fr', 'FR'),
        home: _isConfigured
            ? Consumer<AuthRepository>(
                builder: (context, authRepository, _) {
                  if (authRepository.isAuthenticated) {
                    return const HomeScreen();
                  }
                  return const LoginScreen();
                },
              )
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
      ),
    );
  }
}
