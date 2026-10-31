import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../core/theme.dart';
import '../../utils/password_validator.dart';
import '../../utils/email_validator.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_of_service_screen.dart';
import 'login_screen.dart';
import 'auth_page_shell.dart';
import '../../utils/app_snackbars.dart';

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
    final nom = _nomController.text;
    final prenom = _prenomController.text;

    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasDigits = password.contains(RegExp(r'[0-9]'));
      _hasNoPersonalInfo = !PasswordValidator.isPasswordPersonalInfo(
        password,
        nom,
        prenom,
      );
      _passwordsMatch = password.isNotEmpty && password == confirm;
      _strengthScore = PasswordValidator.getPasswordStrength(password);
    });
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
    if (!_formKey.currentState!.validate()) return;

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
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Code de récupération administrateur'),
            content: SelectableText(
              'Conservez ce code hors de l’application :\n\n$recoveryCode',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('J’ai sauvegardé le code'),
              ),
            ],
          ),
        );
      }
      AppSnackBars.showSuccess(
        context,
        widget.isBootstrap
            ? 'Compte administrateur créé avec succès.'
            : 'Compte créé avec succès.',
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } else {
      _showErrorSnackBar(
        authRepository.errorMessage ?? 'Erreur d\'inscription',
      );
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
      form: _buildRegisterForm(context),
    );
  }

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
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const LoginScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                  ),
                );
              },
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
      child: Row(
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
                            builder: (context) => const TermsOfServiceScreen(),
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
                            builder: (context) => const PrivacyPolicyScreen(),
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
    );
  }
}
