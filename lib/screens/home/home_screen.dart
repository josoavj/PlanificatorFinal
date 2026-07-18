import 'package:flutter/material.dart';
import '../../widgets/sidebar_navigation.dart';
import '../client/client_list_screen.dart';
import '../facture/facture_screen.dart';
import '../contrat/contrat_screen.dart';
import '../planning/planning_screen.dart';
import '../historique/historique_screen.dart';
import '../settings/settings_screen.dart';
import '../about/about_screen.dart';
import '../profile/profile_screen.dart';
import '../export/export_screen.dart';
import 'widgets/dashboard_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Liste des titres centralisée
  static const List<String> _pageTitles = [
    'Accueil',
    'Contrats',
    'Clients',
    'Planning',
    'Factures',
    'Historique',
    'Export',
    'Mon Profil',
    'À propos',
    'Paramètres',
  ];

  @override
  Widget build(BuildContext context) {
    // Sécurité : éviter le dépassement d'index lors des transitions de version
    final safeIndex = _selectedIndex >= _pageTitles.length ? 0 : _selectedIndex;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_pageTitles[safeIndex]),
          centerTitle: false,
          elevation: 2,
        ),
        drawer: SidebarNavigation(
          selectedIndex: safeIndex,
          onItemSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
        body: _buildPage(safeIndex),
      ),
    );
  }

  Widget _buildPage(int index) {
    return RepaintBoundary(
      child: _getPage(index),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0: return const DashboardTab();
      case 1: return const ContratScreen();
      case 2: return const ClientListScreen();
      case 3: return const PlanningScreen();
      case 4: return const FactureScreen();
      case 5: return const HistoriqueScreen();
      case 6: return const ExportScreen();
      case 7: return const ProfileScreen();
      case 8: return const AboutScreen();
      case 9: return const SettingsScreen();
      default: return const DashboardTab();
    }
  }
}
