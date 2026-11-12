import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:planificator/features/auth/repositories/auth_repository.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/theme.dart';
import '../../../core/utils/password_validator.dart';
import '../../../core/security/email_validator.dart';
import '../../legal/screens/legal_documents_screen.dart';
import '../../legal/screens/privacy_policy_screen.dart';
import '../../legal/screens/terms_of_service_screen.dart';
import 'login_screen.dart';
import 'auth_page_shell.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../shared/widgets/app_dialogs.dart';

/// Écran d'inscription moderne et intuitif
class RegisterScreen extends StatefulWidget {
  final bool embedded;
  final bool isBootstrap;

  const RegisterScreen({
    super.key,
    this.embedded = false,
    this.isBootstrap = false,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with AutomaticKeepAliveClientMixin {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Password criteria states
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigits = false;
  bool _hasNoPersonalInfo = true;
  bool _showCriteria = false;
  bool _passwordsMatch = false;
  int _strengthScore = 0;
  bool _acceptedPrivacyPolicy = false;
  int _currentStep = 0;
  static const _stepCount = 4;

  Route<void> _loginRoute() {
    return PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => const LoginScreen(),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordCriteria);
    _confirmPasswordController.addListener(_updatePasswordCriteria);
    _nomController.addListener(_updatePasswordCriteria);
    _prenomController.addListener(_updatePasswordCriteria);
  }

  void _updatePasswordCriteria() {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.isEmpty && confirm.isEmpty && !_showCriteria) {
      return;
    }

    final nom = _nomController.text;
    final prenom = _prenomController.text;

    final newMinLength = password.length >= 8;
    final newUppercase = password.contains(RegExp(r'[A-Z]'));
    final newLowercase = password.contains(RegExp(r'[a-z]'));
    final newDigits = password.contains(RegExp(r'[0-9]'));
    final newNoPersonalInfo = !PasswordValidator.isPasswordPersonalInfo(
      password,
      nom,
      prenom,
    );
    final newMatch = password.isNotEmpty && password == confirm;
    final newStrength = PasswordValidator.getPasswordStrength(password);

    if (_hasMinLength != newMinLength ||
        _hasUppercase != newUppercase ||
        _hasLowercase != newLowercase ||
        _hasDigits != newDigits ||
        _hasNoPersonalInfo != newNoPersonalInfo ||
        _passwordsMatch != newMatch ||
        _strengthScore != newStrength) {
      setState(() {
        _hasMinLength = newMinLength;
        _hasUppercase = newUppercase;
        _hasLowercase = newLowercase;
        _hasDigits = newDigits;
        _hasNoPersonalInfo = newNoPersonalInfo;
        _passwordsMatch = newMatch;
        _strengthScore = newStrength;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_validateIdentityValues() || !_validateCredentialValues()) return;

    if (!_acceptedPrivacyPolicy) {
      _showErrorSnackBar(
        'Vous devez accepter les conditions d\'utilisation et la politique de confidentialité',
      );
      return;
    }

    final authRepository = context.read<AuthRepository>();

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Les mots de passe ne correspondent pas');
      return;
    }

    final recoveryCode = widget.isBootstrap
        ? await authRepository.createFirstAdmin(
            _usernameController.text.trim(),
            _emailController.text.trim(),
            _nomController.text.trim(),
            _prenomController.text.trim(),
            _passwordController.text,
          )
        : (await authRepository.register(
                _usernameController.text.trim(),
                _emailController.text.trim(),
                _nomController.text.trim(),
                _prenomController.text.trim(),
                _passwordController.text,
              )
              ? ''
              : null);

    if (!mounted) return;

    if (recoveryCode != null) {
      if (widget.isBootstrap) {
        await AppDialogs.showBlurDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Code de récupération administrateur'),
            content: SingleChildScrollView(
              child: SelectableText(
                'Conservez ce code hors de l’application :\n\n$recoveryCode',
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => _saveRecoveryCodeToFile(recoveryCode),
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('Enregistrer en .txt'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('J’ai sauvegardé le code'),
              ),
            ],
          ),
        );
        if (!mounted) return;
      }
      if (!mounted) return;
      AppSnackBars.showSuccess(
        context,
        widget.isBootstrap
            ? 'Compte administrateur créé avec succès.'
            : 'Compte créé avec succès.',
      );
      Navigator.of(context).pushAndRemoveUntil(_loginRoute(), (_) => false);
    } else {
      _showErrorSnackBar(
        authRepository.errorMessage ?? 'Erreur d\'inscription',
      );
    }
  }

  Future<void> _saveRecoveryCodeToFile(String recoveryCode) async {
    final directory = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choisir le dossier du code de récupération',
    );
    if (directory == null || !mounted) return;

    final filenameController = TextEditingController(
      text: 'code-recuperation-administrateur.txt',
    );
    final filename = await AppDialogs.showBlurDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nom du fichier'),
        content: TextField(
          controller: filenameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nom du fichier',
            suffixText: '.txt',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, filenameController.text),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    filenameController.dispose();
    if (filename == null || !mounted) return;

    final normalizedFilename = filename.trim();
    if (normalizedFilename.isEmpty) {
      _showErrorSnackBar('Le nom du fichier est obligatoire.');
      return;
    }

    final safeFilename = normalizedFilename.toLowerCase().endsWith('.txt')
        ? normalizedFilename
        : '$normalizedFilename.txt';
    try {
      final file = File(path.join(directory, safeFilename));
      await file.writeAsString(
        'Code de récupération administrateur Planificator\n'
        'Compte : ${_usernameController.text.trim()}\n'
        'Date de création : ${DateTime.now().toIso8601String()}\n\n'
        '$recoveryCode\n',
      );
      if (mounted) {
        AppSnackBars.showSuccess(context, 'Code enregistré dans ${file.path}');
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Impossible d’enregistrer le code : $error');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    AppSnackBars.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AuthPageShell(
      showBrandPanel: !widget.embedded,
      form: _buildWizardForm(context),
    );
  }

  Widget _buildWizardForm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isBootstrap
                ? 'Créer le compte administrateur'
                : 'Inscription',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.darkGrey,
            ),
          ),
          const SizedBox(height: 30),
          _buildWizardProgress(),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildWizardStep(context),
          ),
          const SizedBox(height: 30),
          _buildWizardNavigation(context),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () =>
                  Navigator.of(context).pushReplacement(_loginRoute()),
              child: const Text(
                'Déjà inscrit ? Se connecter',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWizardProgress() {
    const labels = ['Profil', 'Connexion', 'Validation', 'Résumé'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Étape ${_currentStep + 1} sur $_stepCount · ${labels[_currentStep]}',
          style: const TextStyle(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(
            _stepCount,
            (index) => Expanded(
              child: Container(
                height: 5,
                margin: EdgeInsets.only(right: index == _stepCount - 1 ? 0 : 6),
                decoration: BoxDecoration(
                  color: index <= _currentStep
                      ? AppTheme.primaryBlue
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWizardStep(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildProfileStep(context);
      case 1:
        return _buildCredentialsStep(context);
      case 2:
        return _buildConsentStep(context);
      default:
        return _buildSummaryStep(context);
    }
  }

  Widget _buildProfileStep(BuildContext context) {
    return Column(
      key: const ValueKey('register-profile'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWizardTitle(
          'Vos informations',
          'Commençons par faire connaissance.',
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _buildFieldLabel(
                context,
                'Nom',
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(hintText: 'Votre nom'),
                  validator: (v) => v!.trim().isEmpty ? 'Requis' : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFieldLabel(
                context,
                'Prénom',
                TextFormField(
                  controller: _prenomController,
                  decoration: const InputDecoration(hintText: 'Votre prénom'),
                  validator: (v) => v!.trim().isEmpty ? 'Requis' : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildFieldLabel(
          context,
          'Email',
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'exemple@mail.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) =>
                v == null || !EmailValidator.isValidEmail(v.trim())
                ? 'Format d\'email invalide'
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCredentialsStep(BuildContext context) {
    return Column(
      key: const ValueKey('register-credentials'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWizardTitle(
          'Sécurisez votre compte',
          'Choisissez un identifiant et un mot de passe robuste.',
        ),
        const SizedBox(height: 22),
        _buildFieldLabel(
          context,
          'Nom d\'utilisateur',
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              hintText: 'Identifiant de connexion',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) =>
                v!.trim().length < 3 ? 'Minimum 3 caractères' : null,
          ),
        ),
        const SizedBox(height: 20),
        _buildFieldLabel(
          context,
          'Mot de passe',
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (_) => _passwordValidationError,
          ),
        ),
        const SizedBox(height: 12),
        _buildPasswordLiveCriteria(context),
        const SizedBox(height: 20),
        _buildFieldLabel(
          context,
          'Confirmer le mot de passe',
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
            ),
            validator: (v) => v != _passwordController.text
                ? 'Les mots de passe ne correspondent pas'
                : null,
          ),
        ),
        _buildMatchIndicator(context),
      ],
    );
  }

  Widget _buildConsentStep(BuildContext context) {
    return Column(
      key: const ValueKey('register-consent'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWizardTitle(
          'Validation finale',
          'Prenez connaissance des documents avant de continuer.',
        ),
        const SizedBox(height: 22),
        if (widget.isBootstrap)
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'Ce compte sera le premier administrateur. Un code de récupération '
              'sera généré après confirmation.',
            ),
          ),
        _buildPrivacyPolicyCheckbox(context),
      ],
    );
  }

  Widget _buildSummaryStep(BuildContext context) {
    return Column(
      key: const ValueKey('register-summary'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWizardTitle(
          'Vérifiez vos informations',
          'Tout est prêt. Confirmez pour créer votre compte.',
        ),
        const SizedBox(height: 22),
        _buildSummaryRow(
          'Nom complet',
          '${_prenomController.text} ${_nomController.text}',
        ),
        _buildSummaryRow('Email', _emailController.text),
        _buildSummaryRow('Identifiant', _usernameController.text),
        _buildSummaryRow(
          'Type de compte',
          widget.isBootstrap ? 'Administrateur' : 'Utilisateur',
        ),
        const SizedBox(height: 18),
        Text(
          widget.isBootstrap
              ? 'Après confirmation, le code de récupération sera affiché une seule fois.'
              : 'Après confirmation, vous pourrez vous connecter avec ces identifiants.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildWizardTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? 'Non renseigné' : value)),
        ],
      ),
    );
  }

  Widget _buildWizardNavigation(BuildContext context) {
    return Selector<AuthRepository, bool>(
      selector: (_, auth) => auth.isLoading,
      builder: (context, isLoading, _) {
        final isLastStep = _currentStep == _stepCount - 1;
        return Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => setState(() => _currentStep--),
                  child: const Text('PRÉCÉDENT'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : isLastStep
                    ? _handleRegister
                    : _goToNextStep,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isLastStep ? 'CONFIRMER LA CRÉATION' : 'CONTINUER'),
              ),
            ),
          ],
        );
      },
    );
  }

  String? get _passwordValidationError {
    if (_passwordController.text.isEmpty) return 'Requis';
    if (!_hasMinLength || !_hasUppercase || !_hasLowercase || !_hasDigits) {
      return 'Le mot de passe est trop faible';
    }
    if (!_hasNoPersonalInfo) {
      return 'Le mot de passe contient vos informations personnelles';
    }
    return null;
  }

  bool _validateIdentityValues() {
    if (_nomController.text.trim().isEmpty ||
        _prenomController.text.trim().isEmpty) {
      _showErrorSnackBar('Le nom et le prénom sont requis.');
      return false;
    }
    if (!EmailValidator.isValidEmail(_emailController.text.trim())) {
      _showErrorSnackBar('Format d\'email invalide.');
      return false;
    }
    return true;
  }

  bool _validateCredentialValues() {
    if (_usernameController.text.trim().length < 3 ||
        _passwordValidationError != null ||
        _confirmPasswordController.text != _passwordController.text) {
      _showErrorSnackBar('Vérifiez vos identifiants et votre mot de passe.');
      return false;
    }
    return true;
  }

  void _goToNextStep() {
    final valid = switch (_currentStep) {
      0 => _validateIdentityValues(),
      1 => _validateCredentialValues(),
      2 => _acceptedPrivacyPolicy,
      _ => true,
    };
    if (!valid) {
      if (_currentStep == 2) {
        _showErrorSnackBar('Vous devez accepter les documents légaux.');
      }
      return;
    }
    setState(() => _currentStep++);
  }

  // Kept as a fallback for embedded integrations that may still reference
  // the previous single-screen layout.
  // ignore: unused_element
  Widget _buildRegisterForm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isBootstrap
                ? 'Créer le compte administrateur'
                : 'Inscription',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.darkGrey,
            ),
          ),
          const SizedBox(height: 30),

          // Nom & Prénom en ligne sur Desktop
          Row(
            children: [
              Expanded(
                child: _buildFieldLabel(
                  context,
                  'Nom',
                  TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(hintText: 'Votre nom'),
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFieldLabel(
                  context,
                  'Prénom',
                  TextFormField(
                    controller: _prenomController,
                    decoration: const InputDecoration(hintText: 'Votre prénom'),
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildFieldLabel(
            context,
            'Email',
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'exemple@mail.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email requis';
                if (!EmailValidator.isValidEmail(v.trim())) {
                  return 'Format d\'email invalide';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 20),

          _buildFieldLabel(
            context,
            'Nom d\'utilisateur',
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                hintText: 'Identifiant de connexion',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => v!.length < 3 ? 'Minimum 3 caractères' : null,
            ),
          ),
          const SizedBox(height: 20),

          _buildFieldLabel(
            context,
            'Mot de passe',
            Focus(
              onFocusChange: (hasFocus) =>
                  setState(() => _showCriteria = hasFocus),
              child: TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  if (!_hasMinLength ||
                      !_hasUppercase ||
                      !_hasLowercase ||
                      !_hasDigits) {
                    return 'Le mot de passe est trop faible';
                  }
                  if (!_hasNoPersonalInfo) {
                    return 'Le mot de passe contient vos informations personnelles';
                  }
                  return null;
                },
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showCriteria
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildPasswordLiveCriteria(context),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),

          _buildFieldLabel(
            context,
            'Confirmer le mot de passe',
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
              ),
              validator: (v) => v != _passwordController.text
                  ? 'Les mots de passe ne correspondent pas'
                  : null,
            ),
          ),
          _buildMatchIndicator(context),

          const SizedBox(height: 24),

          if (widget.isBootstrap)
            const Text(
              'Ce compte sera le premier administrateur de cette base de données.',
            ),

          const SizedBox(height: 30),

          _buildPrivacyPolicyCheckbox(context),

          const SizedBox(height: 30),

          Selector<AuthRepository, bool>(
            selector: (_, auth) => auth.isLoading,
            builder: (context, isLoading, _) {
              return SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(elevation: 4),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'CRÉER MON COMPTE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          Center(
            child: TextButton(
              onPressed: () =>
                  Navigator.of(context).pushReplacement(_loginRoute()),
              child: const Text(
                'Déjà inscrit ? Se connecter',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _buildPasswordLiveCriteria(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _strengthScore / 100,
                    backgroundColor: isDark ? Colors.white10 : Colors.grey[300],
                    color: _getStrengthColor(),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                PasswordValidator.getPasswordStrengthLabel(_strengthScore),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getStrengthColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCriteriaItem('8 caractères minimum', _hasMinLength),
          _buildCriteriaItem('Une majuscule (A-Z)', _hasUppercase),
          _buildCriteriaItem('Une minuscule (a-z)', _hasLowercase),
          _buildCriteriaItem('Un chiffre (0-9)', _hasDigits),
          _buildCriteriaItem('Pas de nom ou prénom', _hasNoPersonalInfo),
        ],
      ),
    );
  }

  Color _getStrengthColor() {
    if (_strengthScore < 30) return AppTheme.errorRed;
    if (_strengthScore < 50) return AppTheme.warningOrange;
    if (_strengthScore < 70) return Colors.blue;
    if (_strengthScore < 85) return Colors.green;
    return AppTheme.successGreen;
  }

  Widget _buildCriteriaItem(String label, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: isMet ? AppTheme.successGreen : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? (AppTheme.successGreen) : Colors.grey[600],
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchIndicator(BuildContext context) {
    if (_confirmPasswordController.text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Row(
        children: [
          Icon(
            _passwordsMatch ? Icons.check_circle_outline : Icons.error_outline,
            size: 14,
            color: _passwordsMatch
                ? AppTheme.successGreen
                : AppTheme.warningOrange,
          ),
          const SizedBox(width: 8),
          Text(
            _passwordsMatch
                ? 'Les mots de passe correspondent'
                : 'Les mots de passe sont différents',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _passwordsMatch
                  ? AppTheme.successGreen
                  : AppTheme.warningOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicyCheckbox(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _acceptedPrivacyPolicy
            ? AppTheme.primaryBlue.withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _acceptedPrivacyPolicy
              ? AppTheme.primaryBlue.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _acceptedPrivacyPolicy,
                  onChanged: (value) =>
                      setState(() => _acceptedPrivacyPolicy = value ?? false),
                  activeColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                      height: 1.4,
                      fontFamily: 'Poppins',
                    ),
                    children: [
                      const TextSpan(text: 'J\'ai lu et j\'accepte les '),
                      TextSpan(
                        text: 'conditions d\'utilisation',
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TermsOfServiceScreen(),
                              ),
                            );
                          },
                      ),
                      const TextSpan(text: ' et la '),
                      TextSpan(
                        text: 'politique de confidentialité',
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PrivacyPolicyScreen(),
                              ),
                            );
                          },
                      ),
                      const TextSpan(text: ' de Planificator.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LegalDocumentsScreen()),
              ),
              icon: const Icon(Icons.gavel_outlined, size: 16),
              label: const Text('Voir toutes les informations légales'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
