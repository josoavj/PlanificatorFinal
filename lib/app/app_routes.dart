import 'package:material_ui/material_ui.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/recover_account_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/clients/screens/client_list_screen.dart';
import '../features/contrats/screens/contrat_screen.dart';
import '../features/factures/screens/facture_screen.dart';
import '../features/planning/screens/planning_screen.dart';
import '../features/historique/screens/historique_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/about/screens/about_screen.dart';
import '../features/legal/screens/legal_documents_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String recoverAccount = '/recover-account';
  static const String home = '/home';
  static const String clients = '/clients';
  static const String contrats = '/contrats';
  static const String factures = '/factures';
  static const String planning = '/planning';
  static const String historique = '/historique';
  static const String about = '/about';
  static const String settings = '/settings';
  static const String legalDocuments = '/legal-documents';

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    recoverAccount: (context) => const RecoverAccountScreen(),
    home: (context) => const HomeScreen(),
    clients: (context) => const ClientListScreen(),
    contrats: (context) => const ContratScreen(),
    factures: (context) => const FactureScreen(),
    planning: (context) => const PlanningScreen(),
    historique: (context) => const HistoriqueScreen(),
    about: (context) => const AboutScreen(),
    settings: (context) => const SettingsScreen(),
    legalDocuments: (context) => const LegalDocumentsScreen(),
  };
}
