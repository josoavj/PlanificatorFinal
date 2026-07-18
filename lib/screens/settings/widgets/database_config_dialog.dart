import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../services/database_service.dart';
import '../../../config/database_config.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../utils/app_snackbars.dart';

class DatabaseConfigDialog extends StatefulWidget {
  const DatabaseConfigDialog({super.key});

  static void show(BuildContext context) {
    AppDialogs.showBlurDialog(
      context: context,
      builder: (ctx) => const DatabaseConfigDialog(),
    );
  }

  @override
  State<DatabaseConfigDialog> createState() => _DatabaseConfigDialogState();
}

class _DatabaseConfigDialogState extends State<DatabaseConfigDialog> {
  late TextEditingController hostController;
  late TextEditingController portController;
  late TextEditingController userController;
  late TextEditingController databaseController;
  late TextEditingController passwordController;
  bool showPassword = false;

  @override
  void initState() {
    super.initState();
    final config = DatabaseConfig();
    hostController = TextEditingController(text: config.host ?? 'localhost');
    portController = TextEditingController(text: (config.port ?? 3306).toString());
    userController = TextEditingController(text: config.user ?? 'root');
    databaseController = TextEditingController(text: config.database ?? 'Planificator');
    passwordController = TextEditingController(text: config.password ?? 'root');
  }

  @override
  void dispose() {
    hostController.dispose();
    portController.dispose();
    userController.dispose();
    databaseController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configuration Base de Données'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.warningOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.warningOrange.withValues(alpha: 0.2))),
              child: const Row(children: [Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange, size: 20), SizedBox(width: 12), Expanded(child: Text('Modification CRITIQUE - Soyez prudent', style: TextStyle(color: AppTheme.warningOrange, fontSize: 12, fontWeight: FontWeight.bold)))]),
            ),
            const SizedBox(height: 16),
            TextField(controller: hostController, decoration: const InputDecoration(labelText: 'Host', hintText: 'localhost')),
            const SizedBox(height: 12),
            TextField(controller: portController, decoration: const InputDecoration(labelText: 'Port', hintText: '3306'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: userController, decoration: const InputDecoration(labelText: 'Utilisateur', hintText: 'root')),
            const SizedBox(height: 12),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Mot de passe', suffixIcon: IconButton(icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => showPassword = !showPassword))), obscureText: !showPassword),
            const SizedBox(height: 12),
            TextField(controller: databaseController, decoration: const InputDecoration(labelText: 'Base de données', hintText: 'Planificator')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            try {
              final db = DatabaseService();
              db.updateConnectionSettings(host: hostController.text, port: int.parse(portController.text), user: userController.text, password: passwordController.text, database: databaseController.text);
              final connected = await db.connect();
              if (connected) {
                await DatabaseConfig().saveConfig(host: hostController.text, port: int.parse(portController.text), user: userController.text, password: passwordController.text, database: databaseController.text);
                if (mounted) {
                  Navigator.of(context).pop();
                  AppSnackBars.showSuccess(context, ' Configuration sauvegardée');
                }
              } else {
                if (mounted) AppDialogs.error(context, message: 'Impossible de se connecter à la base de données');
              }
            } catch (e) {
              if (mounted) AppDialogs.error(context, message: 'Erreur: $e');
            }
          },
          child: const Text('Sauvegarder'),
        ),
      ],
    );
  }
}
