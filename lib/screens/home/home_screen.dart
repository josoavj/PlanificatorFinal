import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../widgets/index.dart';
import '../../core/theme.dart';
import '../client/client_list_screen.dart';
import '../facture/facture_list_screen.dart';
import '../contrat/contrat_screen.dart';
import '../planning/planning_screen.dart';
import '../historique/historique_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load initial data
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Additional initialization can be added here
    // });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Planificator 1.1.0'),
          elevation: 0,
          centerTitle: true,
        ),
        body: Row(
          children: [
            // Navigation Rail Latérale
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.blue.shade50,
              selectedIconTheme: IconThemeData(
                color: AppTheme.primaryBlue,
                size: 24,
              ),
              unselectedIconTheme: const IconThemeData(
                color: Colors.grey,
                size: 24,
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Accueil'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people),
                  label: Text('Clients'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt),
                  label: Text('Factures'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.description),
                  label: Text('Contrats'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.event),
                  label: Text('Planning'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history),
                  label: Text('Historique'),
                ),
              ],
            ),
            // Contenu principal
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: const [
                  _DashboardTab(),
                  ClientListScreen(),
                  FactureListScreen(),
                  ContratScreen(),
                  PlanningScreen(),
                  HistoriqueScreen(),
                  SettingsScreen(),
                ],
              ),
            ),
          ],
        ),
        drawer: _buildDrawer(context),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Consumer<AuthRepository>(
      builder: (context, authRepository, _) {
        final user = authRepository.currentUser;
        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                accountName: Text(user?.fullName ?? 'Utilisateur'),
                accountEmail: Text(user?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    user?.fullName.isNotEmpty == true
                        ? user!.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _buildDrawerItem(
                icon: Icons.home,
                title: 'Accueil',
                onTap: () {
                  setState(() => _selectedIndex = 0);
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.people,
                title: 'Clients',
                onTap: () {
                  setState(() => _selectedIndex = 1);
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.receipt,
                title: 'Factures',
                onTap: () {
                  setState(() => _selectedIndex = 2);
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.description,
                title: 'Contrats',
                onTap: () {
                  setState(() => _selectedIndex = 3);
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.event,
                title: 'Planning',
                onTap: () {
                  setState(() => _selectedIndex = 4);
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.history,
                title: 'Historique',
                onTap: () {
                  setState(() => _selectedIndex = 5);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              _buildDrawerItem(
                icon: Icons.settings,
                title: 'Paramètres',
                onTap: () {
                  setState(() => _selectedIndex = 6);
                  Navigator.pop(context);
                },
              ),
              _buildDrawerItem(
                icon: Icons.logout,
                title: 'Déconnexion',
                textColor: AppTheme.errorRed,
                onTap: () {
                  Navigator.pop(context);
                  _logout(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  ListTile _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = Colors.black,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(color: textColor)),
      onTap: onTap,
    );
  }

  void _logout(BuildContext context) {
    AppDialogs.confirm(
      context,
      title: 'Déconnexion',
      message: 'Êtes-vous sûr de vouloir vous déconnecter ?',
      confirmText: 'Déconnexion',
      cancelText: 'Annuler',
    ).then((confirmed) {
      if (confirmed == true) {
        context.read<AuthRepository>().logout();
      }
    });
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthRepository>(
      builder: (context, authRepository, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              _WelcomeCard(
                userName: authRepository.currentUser?.fullName ?? 'Utilisateur',
                isAdmin: authRepository.currentUser?.isAdmin ?? false,
              ),
              const SizedBox(height: 24),

              // Statistics Section
              Text(
                'Statistiques',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _buildStatisticsCards(),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Actions rapides',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _buildQuickActions(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCards() {
    return Row(
      children: [
        Expanded(
          child: _StatisticCard(
            title: 'Clients',
            value: '0',
            icon: Icons.people,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatisticCard(
            title: 'Factures',
            value: '0',
            icon: Icons.receipt,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/clients');
            },
            icon: const Icon(Icons.people),
            label: const Text('Voir tous les clients'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/contrats');
            },
            icon: const Icon(Icons.description),
            label: const Text('Gérer les contrats'),
          ),
        ),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String userName;
  final bool isAdmin;

  const _WelcomeCard({Key? key, required this.userName, required this.isAdmin})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenue, $userName!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin ? 'Administrateur' : 'Utilisateur standard',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatisticCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

// End of HomeScreen
