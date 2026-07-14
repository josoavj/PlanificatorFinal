import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../core/theme.dart';
import '../../utils/password_validator.dart';
import 'login_screen.dart';
import '../../utils/app_snackbars.dart';

/// Écran d'inscription moderne et intuitif
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

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
      _hasNoPersonalInfo = !PasswordValidator.isPasswordPersonalInfo(password, nom, prenom);
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

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Les mots de passe ne correspondent pas');
      return;
    }

    final authRepository = context.read<AuthRepository>();
    final success = await authRepository.register(
      _usernameController.text.trim(),
      _emailController.text.trim(),
      _nomController.text.trim(),
      _prenomController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      AppSnackBars.showSuccess(context, 'Compte créé avec succès ! Connectez-vous.');
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      _showErrorSnackBar(authRepository.errorMessage ?? 'Erreur d\'inscription');
    }
  }

  void _showErrorSnackBar(String message) {
    AppSnackBars.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return Row(
              children: [
                // Panneau de gauche : Formulaire
                Expanded(
                  flex: 3,
                  child: Container(
                    color: isDark ? AppTheme.darkBg : Colors.white,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 450),
                          child: _buildRegisterForm(context),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Panneau de droite : Branding
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -50,
                          right: -50,
                          child: _buildCircle(250, Colors.white.withValues(alpha: 0.1)),
                        ),
                        Positioned(
                          bottom: 100,
                          left: 100,
                          child: _buildCircle(150, Colors.white.withValues(alpha: 0.1)),
                        ),
                        
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Hero(
                                  tag: 'app_logo',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        )
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(15),
                                    child: Image.asset(
                                      'assets/Pictures/Logo Planificator.png',
                                      height: 100,
                                      width: 100,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                Text(
                                  'Rejoignez-nous',
                                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    color: Colors.white,
                                    fontSize: 40,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  'Créez votre compte en quelques instants et commencez à gérer vos plannings clients efficacement.',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w300,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Vue mobile
            return Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: _buildRegisterForm(context),
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
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
            'Inscription',
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
                child: _buildFieldLabel(context, 'Nom', 
                  TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(hintText: 'Votre nom'),
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFieldLabel(context, 'Prénom', 
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
          
          _buildFieldLabel(context, 'Email', 
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'exemple@mail.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) => v!.contains('@') ? null : 'Email invalide',
            ),
          ),
          const SizedBox(height: 20),
          
          _buildFieldLabel(context, 'Nom d\'utilisateur', 
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
          
          _buildFieldLabel(context, 'Mot de passe', 
            Focus(
              onFocusChange: (hasFocus) => setState(() => _showCriteria = hasFocus),
              child: TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  if (!_hasMinLength || !_hasUppercase || !_hasLowercase || !_hasDigits) {
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
          
          _buildFieldLabel(context, 'Confirmer le mot de passe', 
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (v) => v != _passwordController.text ? 'Les mots de passe ne correspondent pas' : null,
            ),
          ),
          _buildMatchIndicator(context),
          
          const SizedBox(height: 40),
          
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
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Text('CRÉER MON COMPTE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
              child: const Text('Déjà inscrit ? Se connecter', style: TextStyle(fontWeight: FontWeight.bold)),
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
        Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
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
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
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
            color: _passwordsMatch ? AppTheme.successGreen : AppTheme.warningOrange,
          ),
          const SizedBox(width: 8),
          Text(
            _passwordsMatch ? 'Les mots de passe correspondent' : 'Les mots de passe sont différents',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _passwordsMatch ? AppTheme.successGreen : AppTheme.warningOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}
