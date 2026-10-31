import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/auth_repository.dart';
import '../../utils/email_validator.dart';
import '../../utils/password_validator.dart';

class RecoverAccountScreen extends StatefulWidget {
  const RecoverAccountScreen({super.key});

  @override
  State<RecoverAccountScreen> createState() => _RecoverAccountScreenState();
}

class _RecoverAccountScreenState extends State<RecoverAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthRepository>();
    final success = await auth.resetPasswordWithRecoveryCode(
      _email.text,
      _code.text,
      _password.text,
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe réinitialisé')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'Échec de récupération')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Récupérer le compte')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'Utilisez le code remis lors de la création ou régénération '
                    'du compte administrateur.',
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email administrateur',
                    ),
                    validator: (value) =>
                        EmailValidator.isValidEmail(value ?? '')
                        ? null
                        : 'Email invalide',
                  ),
                  TextFormField(
                    controller: _code,
                    decoration: const InputDecoration(
                      labelText: 'Code de récupération',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Champ requis'
                        : null,
                  ),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nouveau mot de passe',
                    ),
                    validator: (value) {
                      final error = PasswordValidator.validatePassword(
                        value ?? '',
                        value ?? '',
                        '',
                        '',
                      );
                      return error.isEmpty ? null : error;
                    },
                  ),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmation',
                    ),
                    validator: (value) => value != _password.text
                        ? 'Les mots de passe diffèrent'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
