import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_initializer.dart';
import 'services/index.dart';
import 'repositories/index.dart';
import 'config/database_config.dart';
import 'config/app_routes.dart';
import 'config/app_providers.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/setup/database_config_screen.dart';
import 'core/theme.dart';

void main() async {
  await AppInitializer.initialize();
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
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MultiProvider(
      providers: AppProviders.providers,
      child: Selector<ThemeProvider, ThemeMode>(
        selector: (_, themeProvider) => themeProvider.themeMode,
        builder: (context, themeMode, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            locale: const Locale('fr', 'FR'),
            home: _isConfigured
                ? const _AuthGate()
                : DatabaseConfigScreen(onConfigured: _onConfigured),
            routes: AppRoutes.routes,
          );
        },
      ));
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
    log.info('AuthGate initialized - data loading deferred to screens', source: 'main');
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
