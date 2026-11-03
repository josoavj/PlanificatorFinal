import 'package:flutter/material.dart';
import 'package:planificator/app/app_providers.dart';
import 'package:planificator/app/app_routes.dart';
import 'package:planificator/app/auth_gate.dart';
import 'package:planificator/app/theme/theme.dart';
import 'package:planificator/app/theme/theme_provider.dart';
import 'package:planificator/core/database/database_config.dart';
import 'package:planificator/features/settings/screens/database_config_screen.dart';
import 'package:planificator/core/database/database_service.dart';
import 'package:provider/provider.dart';

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
                ? const AuthGate()
                : DatabaseConfigScreen(onConfigured: _onConfigured),
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}