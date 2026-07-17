import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../services/index.dart';
import '../../config/database_config.dart';
import '../../core/theme.dart';
import '../../widgets/index.dart';
import '../../utils/app_snackbars.dart';
import '../../widgets/features_dialog.dart';

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
                // Section Préférences
                _buildSection(
                  title: 'Préférences',
                  children: [
                    _buildModernSwitchCard(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Recevoir les notifications',
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                      },
                    ),
                    if (_notificationsEnabled)
                      _buildModernCard(
                        icon: Icons.schedule,
                        title: 'Heure des notifications',
                        subtitle: 'Configurer l\'heure d\'affichage',
                        onTap: () => _showNotificationTimeDialog(context),
                      ),
                    Selector<ThemeProvider, bool>(
                      selector: (_, tp) => tp.isDarkMode,
                      builder: (context, isDarkMode, _) {
                        return _buildModernSwitchCard(
                          icon: Icons.brightness_4_outlined,
                          title: 'Mode sombre',
                          subtitle: 'Utiliser le thème sombre',
                          value: isDarkMode,
                          onChanged: (value) {
                            context.read<ThemeProvider>().toggleTheme();
                          },
                        );
                      },
                    ),
                    _buildModernSwitchCard(
                      icon: Icons.save_outlined,
                      title: 'Sauvegarde automatique',
                      subtitle: 'Sauvegarder automatiquement les données',
                      value: _autoSaveEnabled,
                      onChanged: (value) {
                        setState(() => _autoSaveEnabled = value);
                      },
                    ),
                    _buildModernCard(
                      icon: Icons.language,
                      title: 'Langue',
                      subtitle: _language == 'fr' ? 'Français' : 'English',
                      onTap: () => _showLanguageDialog(),
                    ),
                  ],
                ),

                // Section Plateforme
                _buildSection(
                  title: 'Plateforme',
                  children: [
                    _buildModernCard(
                      icon: Icons.info_outline,
                      title: 'À propos',
                      subtitle: 'Informations sur la plateforme',
                      onTap: () => FeaturesDialog.show(context),
                    ),
                    _buildModernCard(
                      icon: Icons.help_outline,
                      title: 'Aide',
                      subtitle: 'Obtenez de l\'assistance',
                      onTap: () => AppDialogs.info(
                        context,
                        title: 'Aide',
                        message:
                            'Bienvenue dans l\'aide de Planificator. '
                            'Pour toute question, veuillez nous contacter.',
                      ),
                    ),
                    _buildModernCard(
                      icon: Icons.storage_outlined,
                      title: 'Données locales',
                      subtitle: 'Gérer les données en cache',
                      onTap: () => _showCacheDialog(context),
                    ),
                  ],
                ),

                // Section Logs & Débogage
                _buildSection(
                  title: 'Logs et Débogage',
                  children: [
                    _buildModernCard(
                      icon: Icons.list_alt,
                      title: 'Visualiser les logs',
                      subtitle: 'Afficher tous les événements enregistrés',
                      onTap: () => _showLogViewer(context),
                    ),
                    _buildModernCard(
                      icon: Icons.cloud_download_outlined,
                      title: 'Exporter les logs',
                      subtitle: 'Télécharger les fichiers de logs',
                      onTap: () => _exportLogs(),
                    ),
                    _buildModernCard(
                      icon: Icons.delete_outline,
                      title: 'Effacer les logs',
                      subtitle: 'Supprimer tous les logs',
                      onTap: () => _clearLogs(context),
                      isDestructive: true,
                    ),
                  ],
                ),

                // Section Base de Données (CRITIQUE)
                if (authRepository.isAdmin)
                  _buildSection(
                    title: 'Base de Données',
                    children: [
                      // Notice d'avertissement intégrée
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.warningOrange.withValues(alpha: 0.15)
                              : Colors.orange.shade50,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppTheme.warningOrange,
                              size: 22,
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Configuration critique - À manipuler avec prudence',
                                style: TextStyle(
                                  color: AppTheme.warningOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildModernCard(
                        icon: Icons.storage_rounded,
                        title: 'Configuration Base de Données',
                        subtitle: 'Modifier les informations de connexion',
                        onTap: () => _showDatabaseConfigDialog(context),
                      ),
                    ],
                  ),

                // Section Administration
                if (authRepository.isAdmin)
                  _buildSection(
                    title: 'Administration',
                    children: [
                      _buildModernCard(
                        icon: Icons.group_outlined,
                        title: 'Liste des profils',
                        subtitle: 'Voir tous les profils et leurs types',
                        onTap: () => _showAllProfilesDialog(context),
                      ),
                    ],
                  ),

                // Section Sécurité
                _buildSection(
                  title: 'Sécurité',
                  children: [
                    _buildModernCard(
                      icon: Icons.logout,
                      title: 'Déconnexion',
                      subtitle: 'Terminer la session en cours',
                      onTap: () => _logout(context),
                      isDestructive: true,
                    ),
                    _buildModernCard(
                      icon: Icons.delete_forever,
                      title: 'Supprimer le compte',
                      subtitle: 'Supprimer définitivement mon compte',
                      onTap: () => _deleteAccount(context),
                      isDestructive: true,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Version
                Center(
                  child: Column(
                    children: const [
                      Text(
                        'Planificator 2.1.1',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
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
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? AppTheme.glassBorder.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.15),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Material(
            color: isDark ? AppTheme.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
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
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildModernCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppTheme.errorRed.withValues(alpha: 0.1)
              : (isDark
                  ? AppTheme.accentBlue.withValues(alpha: 0.1)
                  : AppTheme.primaryBlue.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDestructive
              ? AppTheme.errorRed
              : (isDark ? AppTheme.accentBlue : AppTheme.primaryBlue),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDestructive
              ? AppTheme.errorRed
              : (isDark ? Colors.white : Colors.black87),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white60 : Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: isDark ? Colors.white24 : Colors.grey.shade400,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildModernSwitchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.accentBlue.withValues(alpha: 0.1)
              : AppTheme.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white60 : Colors.grey.shade600,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppTheme.primaryBlue,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showDatabaseConfigDialog(BuildContext context) {
    final config = DatabaseConfig();
    final hostController = TextEditingController(
      text: config.host ?? 'localhost',
    );
    final portController = TextEditingController(
      text: (config.port ?? 3306).toString(),
    );
    final userController = TextEditingController(text: config.user ?? 'root');
    final databaseController = TextEditingController(
      text: config.database ?? 'Planificator',
    );
    final passwordController = TextEditingController(
      text: config.password ?? 'root',
    );

    bool showPassword = false;

    AppDialogs.showBlurDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Configuration Base de Données'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.warningOrange.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.warningOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Modification CRITIQUE - Soyez prudent',
                          style: TextStyle(
                            color: AppTheme.warningOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hostController,
                  decoration: const InputDecoration(
                    labelText: 'Host',
                    hintText: 'localhost',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: portController,
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    hintText: '3306',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: userController,
                  decoration: const InputDecoration(
                    labelText: 'Utilisateur',
                    hintText: 'root',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => showPassword = !showPassword);
                      },
                    ),
                  ),
                  obscureText: !showPassword,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: databaseController,
                  decoration: const InputDecoration(
                    labelText: 'Base de données',
                    hintText: 'Planificator',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final db = DatabaseService();
                  db.updateConnectionSettings(
                    host: hostController.text,
                    port: int.parse(portController.text),
                    user: userController.text,
                    password: passwordController.text,
                    database: databaseController.text,
                  );

                  final connected = await db.connect();
                  if (connected) {
                    await config.saveConfig(
                      host: hostController.text,
                      port: int.parse(portController.text),
                      user: userController.text,
                      password: passwordController.text,
                      database: databaseController.text,
                    );

                    if (!context.mounted) return;
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(' Configuration sauvegardée'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    if (!context.mounted) return;
                    AppDialogs.error(
                      context,
                      message:
                          'Impossible de se connecter à la base de données',
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  AppDialogs.error(context, message: 'Erreur: $e');
                }
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllProfilesDialog(BuildContext context) {
    AppDialogs.showBlurDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Liste des profils'),
        contentPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchAllProfiles(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 32,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Erreur: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final profiles = snapshot.data ?? [];

                if (profiles.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Aucun profil trouvé'),
                    ),
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(profiles.length, (index) {
                    final profile = profiles[index];
                    final userId = profile['id_compte'] ?? 'N/A';
                    final nom = profile['nom'] ?? 'N/A';
                    final prenom = profile['prenom'] ?? 'N/A';
                    final fullName = '$nom $prenom'.trim();
                    final email = profile['email'] ?? 'N/A';
                    final typeCom = profile['type_compte'] ?? 'Utilisateur';
                    final isAdmin = typeCom == 'Administrateur';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isAdmin ? Colors.blue[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isAdmin
                              ? Colors.blue[300]!
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  fullName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isAdmin
                                        ? Colors.blue[900]
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isAdmin
                                      ? AppTheme.successGreen
                                      : AppTheme.primaryBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isAdmin ? 'Admin' : 'Utilisateur',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Email: $email',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: $userId',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllProfiles() async {
    try {
      final db = DatabaseService();
      const sql = '''
        SELECT id_compte, nom, prenom, email, type_compte
        FROM Account
        ORDER BY nom, prenom ASC
      ''';
      final rows = await db.query(sql);
      return rows;
    } catch (e) {
      throw 'Erreur lors du chargement des profils: $e';
    }
  }

  void _showCacheDialog(BuildContext context) {
    AppDialogs.confirm(
      context,
      title: 'Vider le cache',
      message:
          'Voulez-vous vraiment vider toutes les données en cache ? '
          'Cela n\'affectera pas vos données en ligne.',
      confirmText: 'Vider',
    ).then((confirmed) {
      if (confirmed == true) {
        AppSnackBars.showSuccess(context, 'Cache vidé');
      }
    });
  }

  void _logout(BuildContext context) {
    AppDialogs.confirm(
      context,
      title: 'Déconnexion',
      message: 'Êtes-vous sûr de vouloir vous déconnecter ?',
      confirmText: 'Déconnexion',
    ).then((confirmed) {
      if (confirmed == true) {
        context.read<AuthRepository>().logout();
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    });
  }

  void _deleteAccount(BuildContext context) {
    AppDialogs.confirm(
      context,
      title: 'Supprimer le compte',
      message:
          'Cette action est irréversible. Tous vos données seront supprimées. '
          'Êtes-vous sûr ?',
      confirmText: 'Supprimer définitivement',
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          // Supprimer le compte de la base de données
          final authRepository = context.read<AuthRepository>();
          final userId = authRepository.currentUser?.userId;

          if (userId != null) {
            final db = DatabaseService();
            await db.execute('DELETE FROM Account WHERE id_compte = ?', [
              userId,
            ]);
          }

          if (!context.mounted) return;

          AppDialogs.info(
            context,
            title: 'Compte supprimé',
            message: 'Votre compte a été supprimé.',
          ).then((_) {
            context.read<AuthRepository>().logout();
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/register', (route) => false);
          });
        } catch (e) {
          if (!context.mounted) return;
          AppDialogs.error(
            context,
            message: 'Erreur lors de la suppression du compte: $e',
          );
        }
      }
    });
  }

  // Logs & Débogage
  void _showLogViewer(BuildContext context) {
    AppDialogs.showBlurDialog(
      context: context,
      builder: (context) => SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.95,
        child: const LogViewerDialog(),
      ),
    );
  }

  Future<void> _exportLogs() async {
    try {
      final logsDir = await log.getLogsDirectory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logs sauvegardés: $logsDir'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearLogs(BuildContext context) {
    AppDialogs.confirm(
      context,
      title: 'Effacer les logs',
      message: 'Supprimer tous les logs en mémoire et sur disque ?',
      confirmText: 'Effacer',
    ).then((confirmed) async {
      if (confirmed == true) {
        log.clear();
        await log.clearLogFiles();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logs effacés avec succès'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _showLanguageDialog() {
    AppDialogs.selection(
      context,
      title: 'Sélectionner une langue',
      items: const ['fr', 'en'],
      itemLabel: (item) => item == 'fr' ? 'Français' : 'English',
      selectedItem: _language,
    ).then((selected) {
      if (selected != null) {
        setState(() => _language = selected);
      }
    });
  }

  // Notifications
  void _showNotificationTimeDialog(BuildContext context) {
    final notifRepo = context.read<NotificationRepository>();
    int hour = notifRepo.notificationHour;
    int minute = notifRepo.notificationMinute;

    AppDialogs.showBlurDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Configurer les notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'À quelle heure voulez-vous être notifié des traitements du jour suivant ?',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            StatefulBuilder(
              builder: (context, setState) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Heure',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 70,
                            child: TextField(
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(
                                text: hour.toString().padLeft(2, '0'),
                              ),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              onChanged: (value) {
                                final h = int.tryParse(value);
                                if (h != null && h >= 0 && h < 24) {
                                  setState(() => hour = h);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        ':',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          const Text(
                            'Minute',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 70,
                            child: TextField(
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              controller: TextEditingController(
                                text: minute.toString().padLeft(2, '0'),
                              ),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              onChanged: (value) {
                                final m = int.tryParse(value);
                                if (m != null && m >= 0 && m < 60) {
                                  setState(() => minute = m);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final notifRepo = context.read<NotificationRepository>();
              await notifRepo.scheduleCustomNotification(
                title: 'Prochains Traitements',
                body: 'Rappel des traitements de demain',
                hour: hour,
                minute: minute,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Notification planifiée à ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
