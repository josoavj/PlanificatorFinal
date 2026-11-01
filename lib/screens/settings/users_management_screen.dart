import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/auth_repository.dart';
import '../../utils/app_snackbars.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  late Future<List<Map<String, dynamic>>> _accounts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _accounts = context.read<AuthRepository>().getAllAccounts();

  Future<String?> _requestPassword({required bool deleting}) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            deleting ? 'Confirmer la suppression' : 'Confirmer la modification',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deleting
                    ? 'Saisissez votre mot de passe pour supprimer définitivement ce compte.'
                    : 'Saisissez votre mot de passe pour appliquer le nouveau rôle.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe administrateur',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                onSubmitted: (value) => Navigator.pop(context, value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _manage(Map<String, dynamic> account) async {
    final auth = context.read<AuthRepository>();
    final id = (account['id_compte'] as num).toInt();
    final action = await showDialog<_AccountAction>(
      context: context,
      builder: (context) => _AccountActionDialog(
        account: account,
        isCurrentUser: id == auth.currentUser?.userId,
      ),
    );
    if (action == null || !mounted) return;
    final password = await _requestPassword(deleting: action.delete);
    if (password == null || password.isEmpty || !mounted) return;
    final ok = action.delete
        ? await auth.adminDeleteAccount(id, password)
        : await auth.updateAccountRole(id, action.role!, password);
    if (!mounted) return;
    if (ok) {
      setState(_load);
      AppSnackBars.showSuccess(
        context,
        action.delete ? 'Compte supprimé.' : 'Rôle du compte mis à jour.',
      );
    } else {
      AppSnackBars.showError(
        context,
        auth.errorMessage ?? 'Action impossible.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthRepository>().isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestion des comptes')),
        body: const Center(child: Text('Accès réservé aux administrateurs.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des comptes')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _accounts,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final accounts = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => setState(_load),
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Il doit rester au moins un administrateur. La base accepte au maximum trois administrateurs.',
                  ),
                ),
                ...accounts.map((account) {
                  final auth = context.read<AuthRepository>();
                  final id = (account['id_compte'] as num).toInt();
                  final isSelf = id == auth.currentUser?.userId;
                  return ListTile(
                    leading: Icon(
                      account['type_compte'] == 'Administrateur'
                          ? Icons.admin_panel_settings
                          : Icons.person_outline,
                    ),
                    title: Text(
                      '${account['prenom'] ?? ''} ${account['nom'] ?? ''}'
                          .trim(),
                    ),
                    subtitle: Text(
                      '${account['email']} · ${account['type_compte']}${isSelf ? ' · Vous' : ''}',
                    ),
                    trailing: isSelf ? null : const Icon(Icons.chevron_right),
                    onTap: isSelf ? null : () => _manage(account),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AccountAction {
  final String? role;
  final bool delete;

  const _AccountAction({this.role, this.delete = false});
}

class _AccountActionDialog extends StatefulWidget {
  final Map<String, dynamic> account;
  final bool isCurrentUser;

  const _AccountActionDialog({
    required this.account,
    required this.isCurrentUser,
  });

  @override
  State<_AccountActionDialog> createState() => _AccountActionDialogState();
}

class _AccountActionDialogState extends State<_AccountActionDialog> {
  late String _role;

  @override
  void initState() {
    super.initState();
    _role = widget.account['type_compte'] as String? ?? 'Utilisateur';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fullName =
        '${widget.account['prenom'] ?? ''} ${widget.account['nom'] ?? ''}'
            .trim();
    return AlertDialog(
      title: Text(fullName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.account['email'] as String? ?? ''),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: const InputDecoration(
              labelText: 'Rôle du compte',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Administrateur',
                child: Text('Administrateur'),
              ),
              DropdownMenuItem(
                value: 'Utilisateur',
                child: Text('Utilisateur'),
              ),
            ],
            onChanged: widget.isCurrentUser
                ? null
                : (value) {
                    if (value != null) setState(() => _role = value);
                  },
          ),
          if (widget.isCurrentUser)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Votre propre rôle et votre compte ne peuvent pas être modifiés ici.',
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.isCurrentUser
              ? null
              : () =>
                    Navigator.pop(context, const _AccountAction(delete: true)),
          style: TextButton.styleFrom(foregroundColor: colors.error),
          child: const Text('Supprimer le compte'),
        ),
        TextButton(
          onPressed:
              widget.isCurrentUser || _role == widget.account['type_compte']
              ? null
              : () => Navigator.pop(context, _AccountAction(role: _role)),
          child: const Text('Modifier le rôle'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}
