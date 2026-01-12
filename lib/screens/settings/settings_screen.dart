import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../services/index.dart';
import '../../config/database_config.dart';
import '../../core/theme.dart';
import '../../widgets/index.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
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
                // Section Profil
                _buildSection(
                  title: 'Profil',
                  children: [
                    _buildModernProfileCard(authRepository),
                    _buildModernCard(
                      icon: Icons.person_outline,
                      title: 'Détails du profil',
                      subtitle: 'Afficher mes informations',
                      onTap: () => _showProfileDialog(context, authRepository),
                    ),
                    _buildModernCard(
                      icon: Icons.lock_outline,
                      title: 'Changer le mot de passe',
                      subtitle: 'Mettre à jour votre mot de passe',
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                  ],
                ),

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
                    _buildModernSwitchCard(
                      icon: Icons.brightness_4_outlined,
                      title: 'Mode sombre',
                      subtitle: 'Utiliser le thème sombre',
                      value: _darkModeEnabled,
                      onChanged: (value) {
                        setState(() => _darkModeEnabled = value);
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

                // Section App
                _buildSection(
                  title: 'Application',
                  children: [
                    _buildModernCard(
                      icon: Icons.info_outline,
                      title: 'À propos',
                      subtitle: 'Informations sur l\'application',
                      onTap: () => _showAboutDialog(context),
                    ),
                    _buildModernCard(
                      icon: Icons.description_outlined,
                      title: 'Politique de confidentialité',
                      subtitle: 'Consultez nos conditions',
                      onTap: () => AppDialogs.info(
                        context,
                        title: 'Politique de confidentialité',
                        message: 'Votre politique de confidentialité ici.',
                      ),
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
                _buildSection(
                  title: 'Base de Données',
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Configuration critique - À manipuler avec prudence',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildModernCard(
                      icon: Icons.storage,
                      title: 'Configuration Base de Données',
                      subtitle: 'Modifier les informations de connexion',
                      onTap: () => _showDatabaseConfigDialog(context),
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
                        'Planificator 2.0.0',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(children: children),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        color: isDestructive ? Colors.red.shade50 : Colors.grey.shade100,
        child: ListTile(
          leading: Icon(
            icon,
            color: isDestructive ? Colors.red.shade600 : AppTheme.primaryBlue,
            size: 28,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDestructive ? Colors.red.shade700 : Colors.black87,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDestructive ? Colors.red.shade600 : Colors.grey.shade600,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isDestructive ? Colors.red.shade400 : Colors.grey.shade400,
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildModernSwitchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        color: Colors.grey.shade100,
        child: ListTile(
          leading: Icon(
            icon,
            color: value ? AppTheme.primaryBlue : Colors.grey.shade400,
            size: 28,
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          trailing: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryBlue,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildModernProfileCard(AuthRepository authRepository) {
    final user = authRepository.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        color: Colors.blue.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primaryBlue,
                    child: Text(
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: user.isAdmin
                          ? AppTheme.successGreen
                          : AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.isAdmin ? 'Admin' : 'Utilisateur',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, AuthRepository authRepository) {
    final user = authRepository.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Détails du profil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileDetailCard('Nom', user.fullName, Icons.person),
              const SizedBox(height: 12),
              _buildProfileDetailCard('Email', user.email, Icons.email),
              const SizedBox(height: 12),
              _buildProfileDetailCard(
                'Identifiant',
                user.userId.toString(),
                Icons.badge,
              ),
              const SizedBox(height: 12),
              _buildProfileDetailCard(
                'Rôle',
                user.isAdmin ? 'Administrateur' : 'Utilisateur',
                Icons.shield,
                backgroundColor: user.isAdmin
                    ? AppTheme.successGreen
                    : AppTheme.primaryBlue,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailCard(
    String label,
    String value,
    IconData icon, {
    Color? backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: backgroundColor ?? AppTheme.primaryBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPassword = TextEditingController();
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPassword,
                decoration: InputDecoration(
                  labelText: 'Ancien mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPassword,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: const Icon(Icons.check_circle_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (newPassword.text != confirmPassword.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Les mots de passe ne correspondent pas'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              context.read<AuthRepository>().changePassword(
                oldPassword.text,
                newPassword.text,
              );
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mot de passe changé avec succès'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Changer'),
          ),
        ],
      ),
    );
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

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Planificator',
      applicationVersion: '1.1.0',
      applicationIcon: const Icon(Icons.calendar_today, size: 64),
      children: const [
        SizedBox(height: 16),
        Text(
          'Application de gestion de clients et de factures.\n\n'
          'Développé avec Flutter et MySQL.\n\n'
          'Version 1.1.0 - 2024',
        ),
      ],
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
    final userController = TextEditingController(
      text: config.user ?? 'sudoted',
    );
    final databaseController = TextEditingController(
      text: config.database ?? 'Planificator',
    );
    final passwordController = TextEditingController(
      text: config.password ?? '',
    );

    bool showPassword = false;

    showDialog(
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
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Modification CRITIQUE - Soyez prudent',
                          style: TextStyle(
                            color: Colors.orange[900],
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
                    hintText: 'sudoted',
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
                        content: Text('✅ Configuration sauvegardée'),
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

  void _showCacheDialog(BuildContext context) {
    AppDialogs.confirm(
      context,
      title: 'Vider le cache',
      message:
          'Voulez-vous vraiment vider toutes les données en cache ? '
          'Cela n\'affectera pas vos données en ligne.',
      confirmText: 'Vider',
      cancelText: 'Annuler',
    ).then((confirmed) {
      if (confirmed == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cache vidé')));
      }
    });
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

  void _deleteAccount(BuildContext context) {
    AppDialogs.confirm(
      context,
      title: 'Supprimer le compte',
      message:
          'Cette action est irréversible. Tous vos données seront supprimées. '
          'Êtes-vous sûr ?',
      confirmText: 'Supprimer définitivement',
      cancelText: 'Annuler',
    ).then((confirmed) {
      if (confirmed == true) {
        AppDialogs.info(
          context,
          title: 'Compte supprimé',
          message: 'Votre compte a été supprimé.',
        ).then((_) {
          context.read<AuthRepository>().logout();
        });
      }
    });
  }

  // Logs & Débogage
  void _showLogViewer(BuildContext context) {
    showDialog(
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
      cancelText: 'Annuler',
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

  // Notifications
  void _showNotificationTimeDialog(BuildContext context) {
    final notifRepo = context.read<NotificationRepository>();
    int hour = notifRepo.notificationHour;
    int minute = notifRepo.notificationMinute;

    showDialog(
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
