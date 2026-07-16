import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' show log;

/// Provider pour gérer le thème de la plateforme (light/dark)
///
/// Persiste le choix utilisateur dans SharedPreferences et
/// notifie les écouteurs lors du changement de thème
class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.light;
  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode;

  /// Vérifier si le mode dark est activé
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Initialiser le provider
  /// Charge la préférence de thème depuis SharedPreferences
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedTheme = _prefs?.getString(_prefKey);

      if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
        log('Thème chargé depuis préférences: DARK');
      } else if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
        log('Thème chargé depuis préférences: LIGHT');
      } else {
        // Utiliser le mode clair par défaut
        _themeMode = ThemeMode.light;
        log('Mode clair utilisé par défaut');
      }
    } catch (e) {
      log('Erreur lors du chargement des préférences de thème: $e');
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  /// Changer le mode de thème
  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners(); // Notifier immédiatement pour une UI fluide

    // Sauvegarder en arrière-plan sans bloquer le thread UI
    _saveThemePreference(mode);
  }

  Future<void> _saveThemePreference(ThemeMode mode) async {
    try {
      final modeString = mode == ThemeMode.dark
          ? 'dark'
          : mode == ThemeMode.light
          ? 'light'
          : 'system';
      await _prefs?.setString(_prefKey, modeString);
      log('Préférences de thème sauvegardées en arrière-plan: $modeString');
    } catch (e) {
      log('Erreur lors de la sauvegarde asynchrone du thème: $e');
    }
  }

  /// Activer le mode sombre
  void enableDarkMode() => setThemeMode(ThemeMode.dark);

  /// Désactiver le mode sombre (light mode)
  void enableLightMode() => setThemeMode(ThemeMode.light);

  /// Utiliser le thème système
  void useSystemTheme() => setThemeMode(ThemeMode.system);

  /// Basculer entre clair et sombre
  void toggleTheme() {
    final newMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    setThemeMode(newMode);
  }
}
