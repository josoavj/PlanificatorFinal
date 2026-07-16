import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../repositories/index.dart';
import '../../services/index.dart';
import '../../core/theme.dart';
import '../../utils/app_snackbars.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authRepo = context.watch<AuthRepository>();
    final user = authRepo.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, user, colorScheme, isDark),
            const SizedBox(height: 70), // Espace pour l'avatar qui dépasse
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    _buildSection(
                      title: 'Mes Informations',
                      children: [
                        _buildInfoTile(
                          icon: Icons.person_outline_rounded,
                          label: 'Nom complet',
                          value: user.fullName,
                        ),
                        _buildInfoTile(
                          icon: Icons.alternate_email_rounded,
                          label: 'Email',
                          value: user.email,
                        ),
                        _buildInfoTile(
                          icon: Icons.badge_outlined,
                          label: 'Identifiant',
                          value: 'Indisponible', // Sera mis à jour via DB si besoin
                          future: _fetchUsername(user.userId),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      title: 'Gestion du compte',
                      children: [
                        _buildActionTile(
                          icon: Icons.edit_outlined,
                          title: 'Modifier le profil',
                          subtitle: 'Mettre à jour vos informations personnelles',
                          onTap: () => _showEditProfileDialog(context, authRepo),
                        ),
                        _buildActionTile(
                          icon: Icons.lock_reset_rounded,
                          title: 'Changer le mot de passe',
                          subtitle: 'Assurer la sécurité de votre accès',
                          onTap: () => _showChangePasswordDialog(context, authRepo),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      title: 'Statut & Activité',
                      children: [
                        _buildInfoTile(
                          icon: Icons.event_available_rounded,
                          label: 'Membre depuis le',
                          value: user.createdAt != null 
                              ? DateFormat('dd MMMM yyyy', 'fr_FR').format(user.createdAt!)
                              : 'Date inconnue',
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user, ColorScheme colorScheme, bool isDark) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainer : AppTheme.primaryBlue,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(48),
            ),
          ),
        ),
        Positioned(
          top: 40,
          child: Column(
            children: [
              Text(
                user.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      user.isAdmin ? Icons.shield_rounded : Icons.person_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.isAdmin ? 'ADMINISTRATEUR' : 'UTILISATEUR',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -45,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBg : Colors.white,
              shape: BoxShape.circle,
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: AppTheme.primaryBlue,
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue,
            ),
          ),
        ),
        Container(
          decoration: AppTheme.cardDecoration(context, radius: 24),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: List.generate(children.length, (index) {
                return Column(
                  children: [
                    children[index],
                    if (index < children.length - 1)
                      Divider(
                        height: 1,
                        indent: 60,
                        endIndent: 16,
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.05) 
                            : Colors.grey.withValues(alpha: 0.1),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({required IconData icon, required String label, required String value, Future<String>? future}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Icon(icon, color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue, size: 22),
      hoverColor: Colors.transparent,
      mouseCursor: SystemMouseCursors.basic,
      title: Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600], fontWeight: FontWeight.bold)),
      subtitle: future != null 
        ? FutureBuilder<String>(
            future: future,
            builder: (context, snapshot) => Text(snapshot.data ?? '...', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          )
        : Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildActionTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.accentBlue.withValues(alpha: 0.1) : AppTheme.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue, size: 20),
      ),
      hoverColor: Colors.transparent,
      splashColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600])),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    );
  }

  Future<String> _fetchUsername(int userId) async {
    try {
      final db = DatabaseService();
      final result = await db.query('SELECT username FROM Account WHERE id_compte = ?', [userId]);
      return result.isNotEmpty ? result[0]['username'].toString() : 'Inconnu';
    } catch (e) {
      return 'Erreur';
    }
  }

  // Logique de modification (reprise de Settings et adaptée)
  void _showEditProfileDialog(BuildContext context, AuthRepository authRepo) async {
    final user = authRepo.currentUser!;
    final prenomCtrl = TextEditingController(text: user.prenom);
    final nomCtrl = TextEditingController(text: user.nom);
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier le profil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: prenomCtrl,
                decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(Icons.person_outline)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: isUpdating ? null : () async {
                setState(() => isUpdating = true);
                final success = await authRepo.updateProfile(nomCtrl.text, prenomCtrl.text);
                if (mounted) {
                  Navigator.pop(ctx);
                  if (success) {
                    AppSnackBars.showSuccess(context, 'Profil mis à jour');
                  } else {
                    AppSnackBars.showError(context, authRepo.errorMessage ?? 'Erreur');
                  }
                }
              },
              child: isUpdating ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthRepository authRepo) {
    final oldPassword = TextEditingController();
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Changer le mot de passe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: oldPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Ancien mot de passe', prefixIcon: Icon(Icons.lock_outline))),
              const SizedBox(height: 12),
              TextField(controller: newPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Nouveau mot de passe', prefixIcon: Icon(Icons.lock_reset_outlined))),
              const SizedBox(height: 12),
              TextField(controller: confirmPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Confirmer', prefixIcon: Icon(Icons.check_circle_outline))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: isUpdating ? null : () async {
                if (newPassword.text != confirmPassword.text) {
                  AppSnackBars.showError(context, 'Les mots de passe ne correspondent pas');
                  return;
                }
                setState(() => isUpdating = true);
                final success = await authRepo.changePassword(oldPassword.text, newPassword.text);
                if (mounted) {
                  Navigator.pop(ctx);
                  if (success) {
                    AppSnackBars.showSuccess(context, 'Mot de passe modifié');
                  } else {
                    AppSnackBars.showError(context, authRepo.errorMessage ?? 'Erreur');
                  }
                }
              },
              child: isUpdating ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Changer'),
            ),
          ],
        ),
      ),
    );
  }
}
