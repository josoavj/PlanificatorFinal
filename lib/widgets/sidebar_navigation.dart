import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../core/theme.dart';

class SidebarNavigation extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const SidebarNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends State<SidebarNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Drawer(
      elevation: 0,
      child: RepaintBoundary(
        child: Container(
          color: isDark ? AppTheme.darkBgSecondary : Colors.white,
        child: Column(
          children: [
            // Header Moderne (Optimisé performance)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                border: isDark ? const Border(bottom: BorderSide(color: AppTheme.glassBorder, width: 0.5)) : null,
              ),
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo avec icône calendrier
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Planificator',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'GESTION DE PLANNING',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  // Section Principale
                  _buildSectionLabel('NAVIGATION'),
                  _buildNavItem(
                    context,
                    icon: Icons.home_rounded,
                    label: 'Accueil',
                    index: 0,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.assignment_rounded,
                    label: 'Contrats',
                    index: 1,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.people_rounded,
                    label: 'Clients',
                    index: 2,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.calendar_today_rounded,
                    label: 'Planning',
                    index: 3,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.receipt_rounded,
                    label: 'Factures',
                    index: 4,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.history_rounded,
                    label: 'Historique',
                    index: 5,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.download_rounded,
                    label: 'Export',
                    index: 6,
                  ),
                  // Section Autres
                  const SizedBox(height: 8),
                  _buildSectionLabel('AUTRES'),
                  _buildNavItem(
                    context,
                    icon: Icons.account_circle_rounded,
                    label: 'Mon Profil',
                    index: 7,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.info_rounded,
                    label: 'À propos',
                    index: 8,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.settings_rounded,
                    label: 'Paramètres',
                    index: 9,
                  ),
                ],
              ),
            ),

            // Footer (Optimisé performance)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppTheme.glassBorder.withValues(alpha: 0.1) : Colors.grey[200]!,
                  ),
                ),
                color: isDark ? AppTheme.darkBgSecondary : Colors.grey[50],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showLogoutConfirm(context),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'DÉCONNEXION',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 0.8,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = widget.selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            widget.onItemSelected(index);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? (isDark ? AppTheme.accentBlue.withValues(alpha: 0.15) : AppTheme.primaryBlue.withValues(alpha: 0.08))
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected 
                      ? (isDark ? AppTheme.accentBlue : AppTheme.primaryBlue) 
                      : (isDark ? Colors.white54 : Colors.grey[600]),
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected 
                          ? (isDark ? AppTheme.accentBlue : AppTheme.primaryBlue) 
                          : (isDark ? Colors.white70 : Colors.grey[800]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Déconnexion',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                // Effectuer la déconnexion via le repository
                context.read<AuthRepository>().logout();
                Navigator.pop(context);
                Navigator.of(context).pushReplacementNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );
  }
}
