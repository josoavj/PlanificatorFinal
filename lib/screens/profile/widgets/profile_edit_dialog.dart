import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../repositories/index.dart';
import '../../../utils/app_snackbars.dart';
import '../../../widgets/app_dialogs.dart';

class ProfileEditDialog extends StatefulWidget {
  final AuthRepository authRepo;
  final String currentUsername;

  const ProfileEditDialog({
    super.key,
    required this.authRepo,
    required this.currentUsername,
  });

  static void show(BuildContext context, AuthRepository authRepo, String currentUsername) {
    AppDialogs.showBlurDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ProfileEditDialog(
        authRepo: authRepo,
        currentUsername: currentUsername,
      ),
    );
  }

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  late TextEditingController prenomCtrl;
  late TextEditingController nomCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController usernameCtrl;
  
  int currentStep = 1;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    final user = widget.authRepo.currentUser!;
    prenomCtrl = TextEditingController(text: user.prenom);
    nomCtrl = TextEditingController(text: user.nom);
    emailCtrl = TextEditingController(text: user.email);
    usernameCtrl = TextEditingController(text: widget.currentUsername);
  }

  @override
  void dispose() {
    prenomCtrl.dispose();
    nomCtrl.dispose();
    emailCtrl.dispose();
    usernameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Column(
        children: [
          const Text('Mise à jour du profil', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepIndicator(1, currentStep, 'Identité', isDark),
              Container(
                width: 40, height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: currentStep >= 2 ? AppTheme.primaryBlue : Colors.grey.withValues(alpha: 0.2),
              ),
              _buildStepIndicator(2, currentStep, 'Coordonnées', isDark),
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
                    const Text('Commençons par vos informations d\'identité publique.', style: TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    TextField(controller: prenomCtrl, decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.person_outline))),
                    const SizedBox(height: 16),
                    TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(Icons.person_outline))),
                  ],
                )
              : Column(
                  key: const ValueKey(2),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Ces informations sont utilisées pour votre connexion et les notifications.', style: TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Identifiant (Username)', prefixIcon: Icon(Icons.badge_outlined))),
                    const SizedBox(height: 16),
                    TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Adresse Email', prefixIcon: Icon(Icons.alternate_email_rounded))),
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
              if (prenomCtrl.text.isEmpty || nomCtrl.text.isEmpty) {
                AppSnackBars.showError(context, 'Nom et Prénom sont requis');
                return;
              }
              setState(() => currentStep = 2);
            } else {
              if (usernameCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                AppSnackBars.showError(context, 'L\'identifiant et l\'email sont requis');
                return;
              }
              if (!emailCtrl.text.contains('@')) {
                AppSnackBars.showError(context, 'Veuillez saisir un email valide');
                return;
              }

              setState(() => isUpdating = true);
              final success = await widget.authRepo.updateProfile(
                nom: nomCtrl.text.trim(), prenom: prenomCtrl.text.trim(),
                email: emailCtrl.text.trim(), username: usernameCtrl.text.trim(),
              );
              
              if (mounted) {
                if (success) {
                  Navigator.pop(context);
                  AppSnackBars.showSuccess(context, 'Profil mis à jour avec succès');
                } else {
                  setState(() => isUpdating = false);
                  AppSnackBars.showError(context, widget.authRepo.errorMessage ?? 'Erreur lors de la mise à jour');
                }
              }
            }
          },
          child: isUpdating
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : Text(currentStep == 1 ? 'SUIVANT' : 'ENREGISTRER'),
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
