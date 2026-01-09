import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../core/theme.dart';

class SidebarNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const SidebarNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header
            Container(
              color: AppTheme.primaryBlue,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Planificator',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Gestion de Planning et de Traitements',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildNavItem(
                    context,
                    icon: Icons.home,
                    label: 'Accueil',
                    index: 0,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.description,
                    label: 'Contrats',
                    index: 1,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.people,
                    label: 'Clients',
                    index: 2,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Planning',
                    index: 3,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.receipt,
                    label: 'Factures',
                    index: 4,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.history,
                    label: 'Historique',
                    index: 5,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.download,
                    label: 'Export',
                    index: 6,
                  ),
                  const Divider(height: 16),
                  _buildNavItem(
                    context,
                    icon: Icons.info,
                    label: 'À propos',
                    index: 7,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.settings,
                    label: 'Paramètres',
                    index: 8,
                  ),
                ],
              ),
            ),

            // Footer avec bouton déconnexion
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Consumer<AuthRepository>(
                builder: (context, authRepository, _) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showLogoutConfirm(context, authRepository);
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Déconnexion'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorRed,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[50] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? const Border(left: BorderSide(color: Colors.blue, width: 4))
            : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          onItemSelected(index);
        },
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context, AuthRepository authRepository) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text(
                'Déconnexion',
                style: TextStyle(color: AppTheme.errorRed),
              ),
            ),
          ],
        );
      },
    );
  }
}
