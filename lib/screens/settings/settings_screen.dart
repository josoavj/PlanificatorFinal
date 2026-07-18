import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../services/database_service.dart';
import '../../services/logging_service.dart';
import '../../core/theme.dart';
import '../../services/theme_provider.dart';
import '../../widgets/index.dart';
import '../../utils/app_snackbars.dart';
import '../../widgets/features_dialog.dart';
import 'widgets/database_config_dialog.dart';
import 'widgets/profile_list_dialog.dart';
import 'widgets/notification_time_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoSaveEnabled = true;
  String _language = 'fr';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthRepository>(
        builder: (context, authRepository, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildSection(title: 'Préférences', children: [
                  _buildModernSwitchCard(icon: Icons.notifications_outlined, title: 'Notifications', subtitle: 'Recevoir les notifications', value: _notificationsEnabled, onChanged: (v) => setState(() => _notificationsEnabled = v)),
                  if (_notificationsEnabled) _buildModernCard(icon: Icons.schedule, title: 'Heure des notifications', subtitle: 'Configurer l\'heure d\'affichage', onTap: () => NotificationTimeDialog.show(context)),
                  Selector<ThemeProvider, bool>(selector: (_, tp) => tp.isDarkMode, builder: (context, isDark, _) => _buildModernSwitchCard(icon: Icons.brightness_4_outlined, title: 'Mode sombre', subtitle: 'Utiliser le thème sombre', value: isDark, onChanged: (v) => context.read<ThemeProvider>().toggleTheme())),
                  _buildModernSwitchCard(icon: Icons.save_outlined, title: 'Sauvegarde automatique', subtitle: 'Sauvegarder automatiquement les données', value: _autoSaveEnabled, onChanged: (v) => setState(() => _autoSaveEnabled = v)),
                  _buildModernCard(icon: Icons.language, title: 'Langue', subtitle: _language == 'fr' ? 'Français' : 'English', onTap: () => _showLanguageDialog()),
                ]),
                _buildSection(title: 'Plateforme', children: [
                  _buildModernCard(icon: Icons.info_outline, title: 'À propos', subtitle: 'Informations sur la plateforme', onTap: () => FeaturesDialog.show(context)),
                  _buildModernCard(icon: Icons.help_outline, title: 'Aide', subtitle: 'Obtenez de l\'assistance', onTap: () => AppDialogs.info(context, title: 'Aide', message: 'Bienvenue dans l\'aide de Planificator. Pour toute question, veuillez nous contacter.')),
                  _buildModernCard(icon: Icons.storage_outlined, title: 'Données locales', subtitle: 'Gérer les données en cache', onTap: () => _showCacheDialog(context)),
                ]),
                _buildSection(title: 'Logs & Débogage', children: [
                  _buildModernCard(icon: Icons.list_alt, title: 'Visualiser les logs', subtitle: 'Afficher tous les événements enregistrés', onTap: () => _showLogViewer(context)),
                  _buildModernCard(icon: Icons.cloud_download_outlined, title: 'Exporter les logs', subtitle: 'Télécharger les fichiers de logs', onTap: () => _exportLogs()),
                  _buildModernCard(icon: Icons.delete_outline, title: 'Effacer les logs', subtitle: 'Supprimer tous les logs', onTap: () => _clearLogs(context), isDestructive: true),
                ]),
                if (authRepository.isAdmin) _buildSection(title: 'Base de Données', children: [
                  Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.warningOrange.withValues(alpha: 0.15) : Colors.orange.shade50), child: const Row(children: [Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange, size: 22), SizedBox(width: 16), Expanded(child: Text('Configuration critique - À manipuler avec prudence', style: TextStyle(color: AppTheme.warningOrange, fontWeight: FontWeight.bold, fontSize: 12)))])),
                  _buildModernCard(icon: Icons.storage_rounded, title: 'Configuration Base de Données', subtitle: 'Modifier les informations de connexion', onTap: () => DatabaseConfigDialog.show(context)),
                ]),
                if (authRepository.isAdmin) _buildSection(title: 'Administration', children: [
                  _buildModernCard(icon: Icons.group_outlined, title: 'Liste des profils', subtitle: 'Voir tous les profils et leurs types', onTap: () => ProfileListDialog.show(context)),
                ]),
                _buildSection(title: 'Sécurité', children: [
                  _buildModernCard(icon: Icons.logout, title: 'Déconnexion', subtitle: 'Terminer la session en cours', onTap: () => _logout(context), isDestructive: true),
                  _buildModernCard(icon: Icons.delete_forever, title: 'Supprimer le compte', subtitle: 'Supprimer définitivement mon compte', onTap: () => _deleteAccount(context), isDestructive: true),
                ]),
                const SizedBox(height: 24),
                const Center(child: Text('Planificator 2.1.1', style: TextStyle(color: Colors.grey))),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 12), child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue))),
        Container(margin: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: isDark ? AppTheme.glassBorder.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15)), boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))]), child: Material(color: isDark ? AppTheme.darkCardBg : Colors.white, borderRadius: BorderRadius.circular(24), clipBehavior: Clip.antiAlias, child: Column(children: List.generate(children.length, (index) => Column(children: [children[index], if (index < children.length - 1) Divider(height: 1, indent: 60, endIndent: 16, color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1))]))))),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildModernCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, bool isDestructive = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isDestructive ? AppTheme.errorRed.withValues(alpha: 0.1) : (isDark ? AppTheme.accentBlue.withValues(alpha: 0.1) : AppTheme.primaryBlue.withValues(alpha: 0.1)), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: isDestructive ? AppTheme.errorRed : (isDark ? AppTheme.accentBlue : AppTheme.primaryBlue), size: 20)), title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDestructive ? AppTheme.errorRed : (isDark ? Colors.white : Colors.black87))), subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600)), trailing: Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? Colors.white24 : Colors.grey.shade400), onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4));
  }

  Widget _buildModernSwitchCard({required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isDark ? AppTheme.accentBlue.withValues(alpha: 0.1) : AppTheme.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue, size: 20)), title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)), subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600)), trailing: Switch.adaptive(value: value, onChanged: onChanged, activeTrackColor: AppTheme.primaryBlue), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4));
  }

  void _showCacheDialog(BuildContext context) {
    AppDialogs.confirm(context, title: 'Vider le cache', message: 'Voulez-vous vraiment vider toutes les données en cache ? Cela n\'affectera pas vos données en ligne.', confirmText: 'Vider').then((c) { if (c == true) AppSnackBars.showSuccess(context, 'Cache vidé'); });
  }

  void _logout(BuildContext context) {
    AppDialogs.confirm(context, title: 'Déconnexion', message: 'Êtes-vous sûr de vouloir vous déconnecter ?', confirmText: 'Déconnexion').then((c) { if (c == true) { context.read<AuthRepository>().logout(); Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false); } });
  }

  void _deleteAccount(BuildContext context) {
    AppDialogs.confirm(context, title: 'Supprimer le compte', message: 'Cette action est irréversible. Tous vos données seront supprimées. Êtes-vous sûr ?', confirmText: 'Supprimer définitivement').then((c) async {
      if (c == true) {
        try {
          final auth = context.read<AuthRepository>();
          if (auth.currentUser != null) await DatabaseService().execute('DELETE FROM Account WHERE id_compte = ?', [auth.currentUser!.userId]);
          if (!mounted) return;
          AppDialogs.info(context, title: 'Compte supprimé', message: 'Votre compte a été supprimé.').then((_) { auth.logout(); Navigator.of(context).pushNamedAndRemoveUntil('/register', (route) => false); });
        } catch (e) { if (mounted) AppDialogs.error(context, message: 'Erreur: $e'); }
      }
    });
  }

  void _showLogViewer(BuildContext context) {
    AppDialogs.showBlurDialog(context: context, builder: (context) => SizedBox(width: MediaQuery.of(context).size.width * 0.95, height: MediaQuery.of(context).size.height * 0.95, child: const LogViewerDialog()));
  }

  Future<void> _exportLogs() async {
    try { final dir = await log.getLogsDirectory(); if (mounted) AppSnackBars.showSuccess(context, 'Logs sauvegardés: $dir'); }
    catch (e) { if (mounted) AppSnackBars.showError(context, 'Erreur: $e'); }
  }

  void _clearLogs(BuildContext context) {
    AppDialogs.confirm(context, title: 'Effacer les logs', message: 'Supprimer tous les logs en mémoire et sur disque ?', confirmText: 'Effacer').then((c) async {
      if (c == true) { log.clear(); await log.clearLogFiles(); if (mounted) AppSnackBars.showSuccess(context, 'Logs effacés avec succès'); }
    });
  }

  void _showLanguageDialog() {
    AppDialogs.selection(context, title: 'Sélectionner une langue', items: const ['fr', 'en'], itemLabel: (i) => i == 'fr' ? 'Français' : 'English', selectedItem: _language).then((s) { if (s != null) setState(() => _language = s); });
  }
}
