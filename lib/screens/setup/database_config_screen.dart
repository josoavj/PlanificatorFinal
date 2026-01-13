import 'package:flutter/material.dart';
import '../../config/database_config.dart';
import '../../core/theme.dart';
import '../../widgets/index.dart';
import '../../services/index.dart';
import '../../services/logging_service.dart';

class DatabaseConfigScreen extends StatefulWidget {
  final VoidCallback onConfigured;

  const DatabaseConfigScreen({Key? key, required this.onConfigured})
    : super(key: key);

  @override
  State<DatabaseConfigScreen> createState() => _DatabaseConfigScreenState();
}

class _DatabaseConfigScreenState extends State<DatabaseConfigScreen> {
  final _hostController = TextEditingController(text: 'localhost');
  final _portController = TextEditingController(text: '3306');
  final _userController = TextEditingController(text: 'sudoted');
  final _passwordController = TextEditingController(text: '100805Josh');
  final _databaseController = TextEditingController(text: 'Planificator');
  final logger = createLoggerWithFileOutput(name: 'database_config_screen');

  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  void _loadExistingConfig() {
    final config = DatabaseConfig();
    if (config.host != null) {
      _hostController.text = config.host!;
    }
    if (config.port != null) {
      _portController.text = config.port!.toString();
    }
    if (config.user != null) {
      _userController.text = config.user!;
    }
    if (config.password != null) {
      _passwordController.text = config.password!;
    }
    if (config.database != null) {
      _databaseController.text = config.database!;
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isLoading = true);

    try {
      final db = DatabaseService();

      // Mettre à jour les paramètres du DatabaseService
      db.updateConnectionSettings(
        host: _hostController.text,
        port: int.parse(_portController.text),
        user: _userController.text,
        password: _passwordController.text,
        database: _databaseController.text,
      );

      final connected = await db.connect();

      if (!mounted) return;

      if (connected) {
        // Sauvegarder la configuration
        await DatabaseConfig().saveConfig(
          host: _hostController.text,
          port: int.parse(_portController.text),
          user: _userController.text,
          password: _passwordController.text,
          database: _databaseController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Connexion réussie! Configuration sauvegardée.'),
            backgroundColor: Colors.green,
          ),
        );

        logger.i('✅ Base de données configurée avec succès');

        // Fermer la page et continuer
        widget.onConfigured();
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        AppDialogs.error(
          context,
          message: 'Impossible de se connecter à la base de données.',
        );
      }
    } catch (e) {
      logger.e('❌ Erreur de connexion: $e');
      if (!mounted) return;
      AppDialogs.error(context, message: 'Erreur: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Empêcher de fermer avant la config
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Center(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: const Icon(
                          Icons.storage,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Configuration Base de Données',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Configurez votre connexion MySQL/MariaDB',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Formulaire
                Text(
                  'Informations de connexion',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Host
                TextField(
                  controller: _hostController,
                  decoration: InputDecoration(
                    labelText: 'Host',
                    hintText: 'localhost',
                    prefixIcon: const Icon(Icons.storage),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // Port
                TextField(
                  controller: _portController,
                  decoration: InputDecoration(
                    labelText: 'Port',
                    hintText: '3306',
                    prefixIcon: const Icon(Icons.numbers),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // User
                TextField(
                  controller: _userController,
                  decoration: InputDecoration(
                    labelText: 'Utilisateur',
                    hintText: 'root',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    hintText: 'Votre mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: !_showPassword,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // Database
                TextField(
                  controller: _databaseController,
                  decoration: InputDecoration(
                    labelText: 'Base de données',
                    hintText: 'Planificator',
                    prefixIcon: const Icon(Icons.dataset),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 32),

                // Bouton de test
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testConnection,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.link),
                    label: Text(
                      _isLoading
                          ? 'Connexion en cours...'
                          : 'Tester la connexion',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.infoBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.infoBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info, color: AppTheme.infoBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Cette configuration ne s\'affiche qu\'une seule fois. Vous pourrez la modifier dans les paramètres de l\'application.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.infoBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _databaseController.dispose();
    super.dispose();
  }
}
