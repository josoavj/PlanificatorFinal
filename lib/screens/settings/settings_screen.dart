import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../services/database_service.dart';
import '../../services/logging_service.dart';
import '../../core/theme.dart';
import '../../services/theme_provider.dart';
import '../../widgets/index.dart';
import '../../utils/app_snackbars.dart';
import '../../utils/excel_utils.dart';
import '../../widgets/features_dialog.dart';
import 'package:file_picker/file_picker.dart';
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
  String _exportPath = 'Chargement...';

  @override
  void initState() {
    super.initState();
    _loadExportPath();
  }

  Future<void> _loadExportPath() async {
    final dir = await FolderManager.getExportBasePath();
    if (mounted) setState(() => _exportPath = dir.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthRepository>(
        builder: (context, authRepository, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                AppSection(
                  title: 'Préférences',
                  children: [
                    AppSwitchCard(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Recevoir les notifications',
                      value: _notificationsEnabled,
                      onChanged: (v) => setState(() => _notificationsEnabled = v),
                    ),
                    if (_notificationsEnabled)
                      AppActionCard(
                        icon: Icons.schedule,
                        title: 'Heure des notifications',
                        subtitle: 'Configurer l\'heure d\'affichage',
                        onTap: () => NotificationTimeDialog.show(context),
                      ),
                    Selector<ThemeProvider, bool>(
                      selector: (_, tp) => tp.isDarkMode,
                      builder: (context, isDark, _) => AppSwitchCard(
                        icon: isDark ? Icons.wb_sunny_outlined : Icons.mode_night_outlined,
                        title: isDark ? 'Mode clair' : 'Mode sombre',
                        subtitle: isDark ? 'Utiliser le thème clair' : 'Utiliser le thème sombre',
                        value: isDark,
                        onChanged: (v) => context.read<ThemeProvider>().toggleTheme(),
                      ),
                    ),
                    AppSwitchCard(
                      icon: Icons.save_outlined,
                      title: 'Sauvegarde automatique',
                      subtitle: 'Sauvegarder automatiquement les données',
                      value: _autoSaveEnabled,
                      onChanged: (v) => setState(() => _autoSaveEnabled = v),
                    ),
                    AppActionCard(
                      icon: Icons.language,
                      title: 'Langue',
                      subtitle: _language == 'fr' ? 'Français' : 'English',
                      onTap: () => _showLanguageDialog(),
                    ),
                  ],
                ),
                AppSection(
                  title: 'Plateforme',
                  children: [
                    AppActionCard(
                      icon: Icons.info_outline,
                      title: 'À propos',
                      subtitle: 'Informations sur la plateforme',
                      onTap: () => FeaturesDialog.show(context),
                    ),
                    AppActionCard(
                      icon: Icons.help_outline,
                      title: 'Aide',
                      subtitle: 'Obtenez de l\'assistance',
                      onTap: () => AppDialogs.info(
                        context,
                        title: 'Aide',
                        message: 'Bienvenue dans l\'aide de Planificator. Pour toute question, veuillez nous contacter.',
                      ),
                    ),
                    AppActionCard(
                      icon: Icons.storage_outlined,
                      title: 'Données locales',
                      subtitle: 'Gérer les données en cache',
                      onTap: () => _showCacheDialog(context),
                      isDestructive: true,
                    ),
                  ],
                ),
                AppSection(
                  title: 'Export & Fichiers',
                  children: [
                    AppActionCard(
                      icon: Icons.folder_open_outlined,
                      title: 'Emplacement des exports',
                      subtitle: _exportPath,
                      onTap: () => _pickExportDirectory(),
                    ),
                    AppActionCard(
                      icon: Icons.restart_alt_rounded,
                      title: 'Réinitialiser l\'emplacement',
                      subtitle: 'Revenir au dossier Bureau par défaut',
                      onTap: () => _resetExportPath(),
                    ),
                  ],
                ),
                AppSection(
                  title: 'Logs & Débogage',
                  children: [
                    AppActionCard(
                      icon: Icons.list_alt,
                      title: 'Visualiser les logs',
                      subtitle: 'Afficher tous les événements enregistrés',
                      onTap: () => _showLogViewer(context),
                    ),
                    AppActionCard(
                      icon: Icons.cloud_download_outlined,
                      title: 'Exporter les logs',
                      subtitle: 'Télécharger les fichiers de logs',
                      onTap: () => _exportLogs(),
                    ),
                    AppActionCard(
                      icon: Icons.delete_outline,
                      title: 'Effacer les logs',
                      subtitle: 'Supprimer tous les logs',
                      onTap: () => _clearLogs(context),
                      isDestructive: true,
                    ),
                  ],
                ),
                if (authRepository.isAdmin)
                  AppSection(
                    title: 'Base de Données',
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.warningOrange.withValues(alpha: 0.15)
                              : Colors.orange.shade50,
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange, size: 22),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Configuration critique - À manipuler avec prudence',
                                style: TextStyle(color: AppTheme.warningOrange, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppActionCard(
                        icon: Icons.storage_rounded,
                        title: 'Configuration Base de Données',
                        subtitle: 'Modifier les informations de connexion',
                        onTap: () => DatabaseConfigDialog.show(context),
                      ),
                    ],
                  ),
                if (authRepository.isAdmin)
                  AppSection(
                    title: 'Administration',
                    children: [
                      AppActionCard(
                        icon: Icons.group_outlined,
                        title: 'Liste des profils',
                        subtitle: 'Voir tous les profils et leurs types',
                        onTap: () => ProfileListDialog.show(context),
                      ),
                    ],
                  ),
                AppSection(
                  title: 'Sécurité',
                  children: [
                    AppActionCard(
                      icon: Icons.logout,
                      title: 'Déconnexion',
                      subtitle: 'Terminer la session en cours',
                      onTap: () => _logout(context),
                      isDestructive: true,
                    ),
                    AppActionCard(
                      icon: Icons.delete_forever,
                      title: 'Supprimer le compte',
                      subtitle: 'Supprimer définitivement mon compte',
                      onTap: () => _deleteAccount(context),
                      isDestructive: true,
                    ),
                  ],
                ),
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

  void _showCacheDialog(BuildContext context) {
    AppDialogs.confirm(context, title: 'Vider le cache', message: 'Voulez-vous vraiment vider toutes les données en cache ? Cela n\'affectera pas vos données en ligne.', confirmText: 'Vider la cache', isDestructive: true).then((c) { if (c == true) AppSnackBars.showSuccess(context, 'Cache vidé'); });
  }

  void _logout(BuildContext context) {
    AppDialogs.confirm(context, title: 'Déconnexion', message: 'Êtes-vous sûr de vouloir vous déconnecter ?', confirmText: 'Se déconnecter', isDestructive: true).then((c) { if (c == true) { context.read<AuthRepository>().logout(); Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false); } });
  }

  void _deleteAccount(BuildContext context) {
    AppDialogs.confirm(context, title: 'Supprimer le compte', message: 'Cette action est irréversible. Tous vos données seront supprimées. Êtes-vous sûr ?', confirmText: 'Supprimer définitivement', isDestructive: true).then((c) async {
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
    AppDialogs.confirm(context, title: 'Effacer les logs', message: 'Supprimer tous les logs en mémoire et sur disque ?', confirmText: 'Effacer les logs', isDestructive: true).then((c) async {
      if (c == true) { log.clear(); await log.clearLogFiles(); if (mounted) AppSnackBars.showSuccess(context, 'Logs effacés avec succès'); }
    });
  }

  void _showLanguageDialog() {
    AppDialogs.selection(context, title: 'Sélectionner une langue', items: const ['fr', 'en'], itemLabel: (i) => i == 'fr' ? 'Français' : 'English', selectedItem: _language).then((s) { if (s != null) setState(() => _language = s); });
  }

  Future<void> _pickExportDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      await FolderManager.setCustomPath(selectedDirectory);
      await _loadExportPath();
      if (mounted) AppSnackBars.showSuccess(context, 'Nouvel emplacement enregistré');
    }
  }

  Future<void> _resetExportPath() async {
    await FolderManager.resetToDefault();
    await _loadExportPath();
    if (mounted) AppSnackBars.showSuccess(context, 'Emplacement réinitialisé sur le Bureau');
  }
}
