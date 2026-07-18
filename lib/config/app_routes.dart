import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/client/client_list_screen.dart';
import '../screens/contrat/contrat_screen.dart';
import '../screens/facture/facture_screen.dart';
import '../screens/planning/planning_screen.dart';
import '../screens/historique/historique_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/about/about_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String clients = '/clients';
  static const String contrats = '/contrats';
  static const String factures = '/factures';
  static const String planning = '/planning';
  static const String historique = '/historique';
  static const String about = '/about';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    home: (context) => const HomeScreen(),
    clients: (context) => const ClientListScreen(),
    contrats: (context) => const ContratScreen(),
    factures: (context) => const FactureScreen(),
    planning: (context) => const PlanningScreen(),
    historique: (context) => const HistoriqueScreen(),
    about: (context) => const AboutScreen(),
    settings: (context) => const SettingsScreen(),
  };
}
