import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../repositories/index.dart';
import '../../../utils/app_snackbars.dart';
import '../../../widgets/app_dialogs.dart';

class ChangePasswordDialog extends StatefulWidget {
  final AuthRepository authRepo;

  const ChangePasswordDialog({super.key, required this.authRepo});

  static void show(BuildContext context, AuthRepository authRepo) {
    AppDialogs.showBlurDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ChangePasswordDialog(authRepo: authRepo),
    );
  }

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final oldPassword = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();
  int currentStep = 1;
  bool isUpdating = false;

  @override
  void dispose() {
    oldPassword.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Column(
        children: [
          const Text('Sécurité du compte', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepIndicator(1, currentStep, 'Actuel', isDark),
              Container(
                width: 40, height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: currentStep >= 2 ? AppTheme.primaryBlue : Colors.grey.withValues(alpha: 0.2),
              ),
              _buildStepIndicator(2, currentStep, 'Nouveau', isDark),
            ],
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: currentStep == 1
              ? Column(
                  key: const ValueKey(1),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Pour continuer, veuillez confirmer votre identité en saisissant votre mot de passe actuel.', style: TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    TextField(controller: oldPassword, obscureText: true, autofocus: true, decoration: const InputDecoration(labelText: 'Mot de passe actuel', prefixIcon: Icon(Icons.lock_person_outlined), hintText: '••••••••')),
                  ],
                )
              : Column(
                  key: const ValueKey(2),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Choisissez un nouveau mot de passe robuste pour votre compte.', style: TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    TextField(controller: newPassword, obscureText: true, autofocus: true, decoration: const InputDecoration(labelText: 'Nouveau mot de passe', prefixIcon: Icon(Icons.lock_reset_rounded))),
                    const SizedBox(height: 16),
                    TextField(controller: confirmPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Confirmation', prefixIcon: Icon(Icons.check_circle_outline_rounded))),
                  ],
                ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        if (currentStep == 1) TextButton(onPressed: () => Navigator.pop(context), child: const Text('ANNULER')),
        if (currentStep == 2) TextButton(onPressed: isUpdating ? null : () => setState(() => currentStep = 1), child: const Text('RETOUR')),
        FilledButton(
          onPressed: isUpdating ? null : () async {
            if (currentStep == 1) {
              if (oldPassword.text.isEmpty) {
                AppSnackBars.showError(context, 'Veuillez saisir votre mot de passe actuel');
                return;
              }
              setState(() => currentStep = 2);
            } else {
              if (newPassword.text.isEmpty || confirmPassword.text.isEmpty) {
                AppSnackBars.showError(context, 'Tous les champs sont requis');
                return;
              }
              if (newPassword.text != confirmPassword.text) {
                AppSnackBars.showError(context, 'Les mots de passe ne correspondent pas');
                return;
              }
              if (newPassword.text.length < 6) {
                AppSnackBars.showError(context, 'Minimum 6 caractères pour le nouveau mot de passe');
                return;
              }

              setState(() => isUpdating = true);
              final success = await widget.authRepo.changePassword(oldPassword.text, newPassword.text);
              
              if (mounted) {
                if (success) {
                  Navigator.pop(context);
                  AppSnackBars.showSuccess(context, 'Votre mot de passe a été mis à jour');
                } else {
                  setState(() => isUpdating = false);
                  AppSnackBars.showError(context, widget.authRepo.errorMessage ?? 'Erreur lors de la mise à jour');
                  if (widget.authRepo.errorMessage?.contains('actuel') ?? false) setState(() => currentStep = 1);
                }
              }
            }
          },
          child: isUpdating
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : Text(currentStep == 1 ? 'SUIVANT' : 'CONFIRMER'),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int step, int currentStep, String label, bool isDark) {
    bool isActive = currentStep == step;
    bool isCompleted = currentStep > step;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted ? AppTheme.primaryBlue : (isDark ? Colors.white10 : Colors.grey[200]),
            border: isActive ? Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3), width: 4) : null,
          ),
          child: Center(child: isCompleted ? const Icon(Icons.check, size: 16, color: Colors.white) : Text(step.toString(), style: TextStyle(color: isActive || isCompleted ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? AppTheme.primaryBlue : Colors.grey)),
      ],
    );
  }
}
