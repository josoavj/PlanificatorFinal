import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../../shared/widgets/sidebar_navigation.dart';
import '../../clients/screens/client_list_screen.dart';
import '../../factures/screens/facture_screen.dart';
import '../../contrats/screens/contrat_screen.dart';
import '../../planning/screens/planning_screen.dart';
import '../../historique/screens/historique_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../users/screens/users_management_screen.dart';
import '../../about/screens/about_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../export/screens/export_screen.dart';
import '../widgets/dashboard_tab.dart';

class _NavigateTabIntent extends Intent {
  final int index;
  const _NavigateTabIntent(this.index);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _navigationDirection = 1;
  bool _isNavigationVisible = false;

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

  void _onSelectTab(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _navigationDirection = index > _selectedIndex ? 1 : -1;
      _selectedIndex = index;
    });
  }

  void _onSelectDesktopTab(int index) {
    setState(() {
      if (index != _selectedIndex) {
        _navigationDirection = index > _selectedIndex ? 1 : -1;
        _selectedIndex = index;
      }
      _isNavigationVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sécurité : éviter le dépassement d'index lors des transitions de version
    final safeIndex = _selectedIndex >= _pageTitles.length ? 0 : _selectedIndex;

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.digit1, control: true):
            const _NavigateTabIntent(0),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true):
            const _NavigateTabIntent(1),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true):
            const _NavigateTabIntent(2),
        const SingleActivator(LogicalKeyboardKey.digit4, control: true):
            const _NavigateTabIntent(3),
        const SingleActivator(LogicalKeyboardKey.digit5, control: true):
            const _NavigateTabIntent(4),
        const SingleActivator(LogicalKeyboardKey.digit6, control: true):
            const _NavigateTabIntent(5),
        const SingleActivator(LogicalKeyboardKey.digit7, control: true):
            const _NavigateTabIntent(6),
        const SingleActivator(LogicalKeyboardKey.digit8, control: true):
            const _NavigateTabIntent(7),
        const SingleActivator(LogicalKeyboardKey.digit9, control: true):
            const _NavigateTabIntent(10),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NavigateTabIntent: CallbackAction<_NavigateTabIntent>(
            onInvoke: (intent) => _onSelectTab(intent.index),
          ),
        },
        child: Focus(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 960;

              return PopScope(
                canPop: false,
                child: Scaffold(
                  appBar: AppBar(
                    title: isDesktop && _isNavigationVisible
                        ? const SizedBox.shrink()
                        : Text(_pageTitles[safeIndex]),
                    centerTitle: false,
                    elevation: 1,
                    automaticallyImplyLeading: !isDesktop,
                    leading: isDesktop
                        ? IconButton(
                            tooltip: _isNavigationVisible
                                ? 'Masquer la navigation'
                                : 'Afficher la navigation',
                            icon: Icon(
                              _isNavigationVisible
                                  ? Icons.menu_open_rounded
                                  : Icons.menu_rounded,
                            ),
                            onPressed: () => setState(
                              () =>
                                  _isNavigationVisible = !_isNavigationVisible,
                            ),
                          )
                        : null,
                  ),
                  drawer: isDesktop
                      ? null
                      : SidebarNavigation(
                          selectedIndex: safeIndex,
                          onItemSelected: _onSelectTab,
                        ),
                  body: isDesktop
                      ? Stack(
                          children: [
                            Positioned.fill(child: _buildPage(safeIndex)),
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeInOutCubic,
                              left: _isNavigationVisible ? 0 : -260,
                              top: 0,
                              bottom: 0,
                              width: 260,
                              child: Material(
                                elevation: _isNavigationVisible ? 12 : 0,
                                child: SidebarNavigation(
                                  selectedIndex: safeIndex,
                                  onItemSelected: _onSelectDesktopTab,
                                  isDrawer: false,
                                ),
                              ),
                            ),
                          ],
                        )
                      : _buildPage(safeIndex),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        reverseDuration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        transitionBuilder: (child, animation) {
          final offsetAnimation =
              Tween<Offset>(
                begin: Offset(0.02 * _navigationDirection, 0),
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
