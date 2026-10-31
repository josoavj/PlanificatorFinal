import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/auth_repository.dart';
import '../../core/theme.dart';
import '../../utils/email_validator.dart';
import '../../utils/password_validator.dart';
import 'login_screen.dart';
import 'auth_page_shell.dart';

class RecoverAccountScreen extends StatefulWidget {
  final bool embedded;

  const RecoverAccountScreen({super.key, this.embedded = false});

  @override
  State<RecoverAccountScreen> createState() => _RecoverAccountScreenState();
}

class _RecoverAccountScreenState extends State<RecoverAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRecover() async {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_passwordController.text != _confirmController.text) {
      setState(() {
        _errorMessage = 'Les mots de passe ne correspondent pas';
      });
      return;
    }

    final authRepo = context.read<AuthRepository>();
    final success = await authRepo.resetPasswordWithRecoveryCode(
      _emailController.text.trim(),
      _codeController.text.trim().toUpperCase(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppTheme.successGreen),
              SizedBox(width: 10),
              Text('Mot de passe réinitialisé'),
            ],
          ),
          content: const Text(
            'Votre mot de passe a été réinitialisé avec succès. Vous pouvez maintenant vous connecter avec votre nouveau mot de passe.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
              ),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const LoginScreen(),
            transitionsBuilder: (_, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
          (_) => false,
        );
      }
    } else {
      setState(() {
        _errorMessage =
            authRepo.errorMessage ??
            'Échec de la réinitialisation du mot de passe';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      showBrandPanel: !widget.embedded,
      form: _buildRecoverForm(context),
    );
  }

  Widget _buildRecoverForm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RÉCUPÉRATION SÉCURISÉE',
            style: TextStyle(
              color: AppTheme.primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Récupérer votre compte',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.darkGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Utilisez le code remis lors de la création ou de la régénération du compte administrateur.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Carte d'information explicative
          _buildInfoCard(context, isDark),

          const SizedBox(height: 24),

          // Email
          _buildFieldLabel(
            context,
            'Adresse e-mail administrateur',
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'admin@exemple.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email requis';
                if (!EmailValidator.isValidEmail(v.trim())) {
                  return 'Email invalide';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 16),

          // Code de récupération
          _buildFieldLabel(
            context,
            'Code de récupération',
            TextFormField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Code à 16 caractères',
                prefixIcon: Icon(Icons.key_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Code requis' : null,
            ),
          ),

          const SizedBox(height: 16),

          // Nouveau mot de passe
          _buildFieldLabel(
            context,
            'Nouveau mot de passe',
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
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                final err = PasswordValidator.validatePassword(v, v, '', '');
                return err.isEmpty ? null : err;
              },
            ),
          ),

          const SizedBox(height: 16),

          // Confirmation mot de passe
          _buildFieldLabel(
            context,
            'Confirmer le nouveau mot de passe',
            TextFormField(
              controller: _confirmController,
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
                  ? 'Les mots de passe diffèrent'
                  : null,
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Bouton Réinitialiser
          Selector<AuthRepository, bool>(
            selector: (_, auth) => auth.isLoading,
            builder: (context, isLoading, _) {
              return SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleRecover,
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
                          'RÉINITIALISER LE MOT DE PASSE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Lien Retour à la connexion
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text(
                'Retour à la connexion',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.accentBlue.withValues(alpha: 0.1)
            : AppTheme.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppTheme.accentBlue.withValues(alpha: 0.3)
              : AppTheme.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comment fonctionne la récupération ?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppTheme.darkGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Le code de récupération est remis uniquement lors de la création du compte administrateur. Il permet de réinitialiser le mot de passe de manière sécurisée.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
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
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}
