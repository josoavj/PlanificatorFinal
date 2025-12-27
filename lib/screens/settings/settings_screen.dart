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
      appBar: AppBar(title: const Text('Paramètres')),
      body: Consumer<AuthRepository>(
        builder: (context, authRepository, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Section Profil
                _buildSection(
                  title: 'Profil',
                  children: [
                    _buildProfileHeader(authRepository),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Voir mon profil'),
                      onTap: () => _showProfileDialog(context, authRepository),
                    ),
                    ListTile(
                      leading: const Icon(Icons.vpn_key),
                      title: const Text('Changer le mot de passe'),
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                  ],
                ),

                // Section Préférences
                _buildSection(
                  title: 'Préférences',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Notifications'),
                      subtitle: const Text('Recevoir les notifications'),
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() => _notificationsEnabled = value);
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.brightness_4),
                      title: const Text('Mode sombre'),
                      subtitle: const Text('Utiliser le thème sombre'),
                      trailing: Switch(
                        value: _darkModeEnabled,
                        onChanged: (value) {
                          setState(() => _darkModeEnabled = value);
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.save),
                      title: const Text('Sauvegarde automatique'),
                      subtitle: const Text(
                        'Sauvegarder automatiquement les données',
                      ),
                      trailing: Switch(
                        value: _autoSaveEnabled,
                        onChanged: (value) {
                          setState(() => _autoSaveEnabled = value);
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: const Text('Langue'),
                      subtitle: Text(
                        _language == 'fr' ? 'Français' : 'English',
                      ),
                      onTap: () => _showLanguageDialog(),
                    ),
                  ],
                ),

                // Section App
                _buildSection(
                  title: 'Application',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('À propos'),
                      onTap: () => _showAboutDialog(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('Politique de confidentialité'),
                      onTap: () => AppDialogs.info(
                        context,
                        title: 'Politique de confidentialité',
                        message: 'Votre politique de confidentialité ici.',
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: const Text('Aide'),
                      onTap: () => AppDialogs.info(
                        context,
                        title: 'Aide',
                        message:
                            'Bienvenue dans l\'aide de Planificator. '
                            'Pour toute question, veuillez nous contacter.',
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.storage),
                      title: const Text('Données locales'),
                      subtitle: const Text('Gérer les données en cache'),
                      onTap: () => _showCacheDialog(context),
                    ),
                  ],
                ),

                // Section Base de Données (CRITIQUE)
                _buildSection(
                  title: 'Base de Données',
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'CRITIQUE - Ne modifiez que si nécessaire',
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.storage),
                      title: const Text('Configuration Base de Données'),
                      subtitle: const Text(
                        'Modifier les informations de connexion',
                      ),
                      trailing: const Icon(Icons.edit),
                      onTap: () => _showDatabaseConfigDialog(context),
                    ),
                  ],
                ),

                // Section Sécurité
                _buildSection(
                  title: 'Sécurité',
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: AppTheme.errorRed,
                      ),
                      title: const Text(
                        'Déconnexion',
                        style: TextStyle(color: AppTheme.errorRed),
                      ),
                      onTap: () => _logout(context),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.delete,
                        color: AppTheme.errorRed,
                      ),
                      title: const Text(
                        'Supprimer le compte',
                        style: TextStyle(color: AppTheme.errorRed),
                      ),
                      onTap: () => _deleteAccount(context),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Version
                Center(
                  child: Column(
                    children: const [
                      Text(
                        'Planificator 1.1.0',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Build 1',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
        Column(children: children),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildProfileHeader(AuthRepository authRepository) {
    final user = authRepository.currentUser;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryBlue,
        child: Text(
          user?.fullName.isNotEmpty == true
              ? user!.fullName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(user?.fullName ?? 'Utilisateur'),
      subtitle: Text(user?.email ?? ''),
      trailing: Chip(
        label: Text(user?.isAdmin == true ? 'Admin' : 'User'),
        backgroundColor: user?.isAdmin == true
            ? AppTheme.successGreen
            : AppTheme.primaryBlue,
        labelStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, AuthRepository authRepository) {
    final user = authRepository.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Mon profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileRow('Nom', user.fullName),
            _buildProfileRow('Email', user.email),
            _buildProfileRow('ID', user.userId.toString()),
            _buildProfileRow(
              'Rôle',
              user.isAdmin ? 'Administrateur' : 'Utilisateur',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                decoration: const InputDecoration(
                  labelText: 'Ancien mot de passe',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPassword,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassword,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe',
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
          ElevatedButton(
            onPressed: () {
              if (newPassword.text != confirmPassword.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Les mots de passe ne correspondent pas'),
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
                const SnackBar(content: Text('Mot de passe changé')),
              );
            },
            child: const Text('Enregistrer'),
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
}
