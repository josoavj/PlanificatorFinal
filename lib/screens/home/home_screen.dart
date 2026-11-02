import 'package:flutter/material.dart';
import '../../widgets/sidebar_navigation.dart';
import '../client/client_list_screen.dart';
import '../facture/facture_screen.dart';
import '../contrat/contrat_screen.dart';
import '../planning/planning_screen.dart';
import '../historique/historique_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/users_management_screen.dart';
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
  int _navigationDirection = 1;

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
    'Gestion des comptes',
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
            if (index == _selectedIndex) return;
            setState(() {
              _navigationDirection = index > _selectedIndex ? 1 : -1;
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
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        reverseDuration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final offsetAnimation =
              Tween<Offset>(
                begin: Offset(0.06 * _navigationDirection, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );

          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
        child: KeyedSubtree(key: ValueKey<int>(index), child: _getPage(index)),
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const DashboardTab();
      case 1:
        return const ContratScreen();
      case 2:
        return const ClientListScreen();
      case 3:
        return const PlanningScreen();
      case 4:
        return const FactureScreen();
      case 5:
        return const HistoriqueScreen();
      case 6:
        return const ExportScreen();
      case 7:
        return const ProfileScreen();
      case 8:
        return const UsersManagementScreen(embedded: true);
      case 9:
        return const AboutScreen();
      case 10:
        return const SettingsScreen();
      default:
        return const DashboardTab();
    }
  }
}
