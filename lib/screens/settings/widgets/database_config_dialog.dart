import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../services/database_service.dart';
import '../../../config/database_config.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../utils/app_snackbars.dart';
import '../../../repositories/auth_repository.dart';

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
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Admin Password
  final _adminPwdController = TextEditingController();
  bool _showAdminPwd = false;

  // Step 2: DB Config
  late TextEditingController hostController;
  late TextEditingController portController;
  late TextEditingController userController;
  late TextEditingController databaseController;
  late TextEditingController passwordController;
  bool showDbPassword = false;

  @override
  void initState() {
    super.initState();
    final config = DatabaseConfig();
    hostController = TextEditingController(text: config.host ?? 'localhost');
    portController = TextEditingController(text: (config.port ?? 3306).toString());
    userController = TextEditingController(text: config.user ?? 'root');
    databaseController = TextEditingController(text: config.database ?? 'Planificator');
    passwordController = TextEditingController(text: config.password ?? '');
  }

  @override
  void dispose() {
    _adminPwdController.dispose();
    hostController.dispose();
    portController.dispose();
    userController.dispose();
    databaseController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _nextStep() async {
    if (_currentStep == 0) {
      setState(() => _isLoading = true);
      final auth = context.read<AuthRepository>();
      final isValid = await auth.verifyCurrentPassword(_adminPwdController.text);
      setState(() => _isLoading = false);

      if (isValid) {
        setState(() => _currentStep = 1);
      } else {
        if (mounted) AppSnackBars.showError(context, 'Mot de passe administrateur incorrect');
      }
    } else if (_currentStep == 1) {
      setState(() => _currentStep = 2);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseService();
      db.updateConnectionSettings(
        host: hostController.text, 
        port: int.parse(portController.text), 
        user: userController.text, 
        password: passwordController.text, 
        database: databaseController.text
      );
      
      final connected = await db.connect();
      if (connected) {
        await DatabaseConfig().saveConfig(
          host: hostController.text, 
          port: int.parse(portController.text), 
          user: userController.text, 
          password: passwordController.text, 
          database: databaseController.text
        );
        if (mounted) {
          Navigator.of(context).pop();
          AppSnackBars.showSuccess(context, 'Configuration de la base de données mise à jour');
        }
      } else {
        if (mounted) AppDialogs.error(context, message: 'La connexion a échoué avec ces paramètres. Vérifiez vos informations.');
      }
    } catch (e) {
      if (mounted) AppDialogs.error(context, message: 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildStepperProgress(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildCurrentStepView(),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: AppTheme.errorRed,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.gpp_maybe_rounded, color: Colors.white, size: 40),
            SizedBox(height: 8),
            Text(
              'ZONE CRITIQUE',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          bool active = _currentStep >= i;
          bool isLast = i == 2;
          
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? AppTheme.errorRed : Colors.grey.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Text('${i + 1}', style: TextStyle(color: active ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              if (!isLast)
                Container(
                  width: 60, // Largeur fixe pour les lignes entre les cercles
                  height: 2,
                  color: _currentStep > i ? AppTheme.errorRed : Colors.grey.withValues(alpha: 0.2),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0: return _buildStepVerification();
      case 1: return _buildStepConfiguration();
      case 2: return _buildStepConfirmation();
      default: return const SizedBox();
    }
  }

  Widget _buildStepVerification() {
    return Column(
      key: const ValueKey(0),
      children: [
        const Text(
          'Vérification de sécurité',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Veuillez entrer votre mot de passe administrateur pour déverrouiller ces réglages.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _adminPwdController,
          obscureText: !_showAdminPwd,
          decoration: InputDecoration(
            labelText: 'Mot de passe actuel',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(_showAdminPwd ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _showAdminPwd = !_showAdminPwd),
            ),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.errorRed, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepConfiguration() {
    return Column(
      key: const ValueKey(1),
      children: [
        const Text('Paramètres de Connexion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildDbField(hostController, 'Hôte', Icons.dns_outlined),
        const SizedBox(height: 16),
        _buildDbField(portController, 'Port', Icons.numbers, isNumeric: true),
        const SizedBox(height: 16),
        _buildDbField(userController, 'Utilisateur', Icons.person_outline),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          obscureText: !showDbPassword,
          decoration: InputDecoration(
            labelText: 'Mot de passe DB',
            prefixIcon: const Icon(Icons.password_rounded),
            suffixIcon: IconButton(
              icon: Icon(showDbPassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => showDbPassword = !showDbPassword),
            ),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.errorRed, width: 2)),
          ),
        ),
        const SizedBox(height: 16),
        _buildDbField(databaseController, 'Nom de la base', Icons.storage_rounded),
      ],
    );
  }

  Widget _buildStepConfirmation() {
    return Column(
      key: const ValueKey(2),
      children: [
        const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 48),
        const SizedBox(height: 16),
        const Text('Avertissement Important', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.errorRed)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.errorRed.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.1))),
          child: const Text(
            'Vous allez modifier les paramètres de connexion au serveur de données. Si ces informations sont incorrectes, l\'application ne pourra plus fonctionner jusqu\'à leur correction.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        const SizedBox(height: 24),
        _buildSummaryLine('Serveur', hostController.text),
        _buildSummaryLine('Utilisateur', userController.text),
        _buildSummaryLine('Base', databaseController.text),
      ],
    );
  }

  Widget _buildDbField(TextEditingController ctrl, String label, IconData icon, {bool isNumeric = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.errorRed, width: 2)),
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('ANNULER'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: _isLoading ? null : (_currentStep == 2 ? _saveConfig : _nextStep),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_currentStep == 2 ? 'CONFIRMER' : 'CONTINUER'),
            ),
          ),
        ],
      ),
    );
  }
}
