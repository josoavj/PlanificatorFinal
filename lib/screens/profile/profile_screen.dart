import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../repositories/index.dart';
import '../../services/index.dart';
import '../../core/theme.dart';
import '../../widgets/index.dart';
import 'widgets/profile_edit_dialog.dart';
import 'widgets/change_password_dialog.dart';

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
            const SizedBox(height: 70), 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    AppSection(
                      title: 'Mes Informations',
                      children: [
                        AppInfoTile(icon: Icons.person_outline_rounded, label: 'Nom complet', value: user.fullName),
                        AppInfoTile(icon: Icons.alternate_email_rounded, label: 'Email', value: user.email),
                        _buildUsernameTile(user.userId),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppSection(
                      title: 'Gestion du compte',
                      children: [
                        AppActionCard(
                          icon: Icons.edit_outlined,
                          title: 'Modifier le profil',
                          subtitle: 'Mettre à jour vos informations personnelles',
                          onTap: () async {
                            final currentUsername = await _fetchUsername(user.userId);
                            if (mounted) ProfileEditDialog.show(context, authRepo, currentUsername);
                          },
                        ),
                        AppActionCard(
                          icon: Icons.lock_reset_rounded,
                          title: 'Changer le mot de passe',
                          subtitle: 'Assurer la sécurité de votre accès',
                          onTap: () => ChangePasswordDialog.show(context, authRepo),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppSection(
                      title: 'Statut & Activité',
                      children: [
                        AppInfoTile(
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
        Container(height: 210, width: double.infinity, decoration: BoxDecoration(color: isDark ? colorScheme.surfaceContainer : AppTheme.primaryBlue, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(48)))),
        Positioned(top: 50, child: Column(children: [
          Text(user.fullName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)), child: Row(children: [Icon(user.isAdmin ? Icons.shield_rounded : Icons.person_rounded, color: Colors.white, size: 14), const SizedBox(width: 8), Text(user.isAdmin ? 'ADMINISTRATEUR' : 'UTILISATEUR', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2))])),
        ])),
        Positioned(bottom: -45, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: isDark ? AppTheme.darkCardBg : Colors.white, shape: BoxShape.circle, boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))]), child: CircleAvatar(radius: 55, backgroundColor: AppTheme.primaryBlue, child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold))))),
      ],
    );
  }

  Widget _buildUsernameTile(int userId) {
    return FutureBuilder<String>(
      future: _fetchUsername(userId),
      builder: (context, snapshot) {
        return AppInfoTile(
          icon: Icons.badge_outlined,
          label: 'Identifiant',
          value: snapshot.data ?? '...',
        );
      },
    );
  }

  Future<String> _fetchUsername(int userId) async {
    try {
      final db = DatabaseService();
      final result = await db.query('SELECT username FROM Account WHERE id_compte = ?', [userId]);
      return result.isNotEmpty ? result[0]['username'].toString() : 'Inconnu';
    } catch (e) { return 'Erreur'; }
  }
}
