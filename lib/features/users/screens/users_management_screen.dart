import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../auth/repositories/auth_repository.dart';
import '../../../app/theme/theme.dart';
import '../../../core/utils/app_snackbars.dart';
import '../../../shared/widgets/app_dialogs.dart';

class UsersManagementScreen extends StatefulWidget {
  final bool embedded;

  const UsersManagementScreen({super.key, this.embedded = false});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  late Future<List<Map<String, dynamic>>> _accounts;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _accounts = context.read<AuthRepository>().getAllAccounts();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> _requestPassword({required bool deleting}) async {
    final controller = TextEditingController();
    try {
      return await AppDialogs.showBlurDialog<String>(
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
    final action = await AppDialogs.showBlurDialog<_AccountAction>(
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
      final accessDenied = const Center(
        child: Text('Accès réservé aux administrateurs.'),
      );
      return widget.embedded
          ? accessDenied
          : Scaffold(
              appBar: AppBar(title: const Text('Gestion des comptes')),
              body: accessDenied,
            );
    }

    final content = FutureBuilder<List<Map<String, dynamic>>>(
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _buildOverview(context, accounts),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  labelText: 'Rechercher un compte',
                  hintText: 'Nom, e-mail ou rôle',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.clear_rounded),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ..._filterAccounts(accounts).map((account) {
                final auth = context.read<AuthRepository>();
                final id = (account['id_compte'] as num).toInt();
                final isSelf = id == auth.currentUser?.userId;
                return _buildAccountCard(context, account, isSelf);
              }),
              if (_filterAccounts(accounts).isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Aucun compte correspondant.')),
                ),
            ],
          ),
        );
      },
    );
    return widget.embedded
        ? content
        : Scaffold(
            appBar: AppBar(title: const Text('Gestion des comptes')),
            body: content,
          );
  }

  List<Map<String, dynamic>> _filterAccounts(
    List<Map<String, dynamic>> accounts,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return accounts;
    return accounts.where((account) {
      final values = [
        account['nom'],
        account['prenom'],
        account['email'],
        account['type_compte'],
      ].map((value) => value?.toString().toLowerCase() ?? '');
      return values.any((value) => value.contains(query));
    }).toList();
  }

  Widget _buildOverview(
    BuildContext context,
    List<Map<String, dynamic>> accounts,
  ) {
    final admins = accounts
        .where((account) => account['type_compte'] == 'Administrateur')
        .length;
    final users = accounts.length - admins;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comptes de la plateforme',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Consultez les comptes et gérez leurs rôles depuis une vue centralisée.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildCountCard(
                context,
                Icons.people_alt_outlined,
                'Total',
                accounts.length.toString(),
                AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCountCard(
                context,
                Icons.admin_panel_settings_outlined,
                'Admins',
                '$admins / 3',
                Colors.deepPurple,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCountCard(
                context,
                Icons.person_outline,
                'Utilisateurs',
                users.toString(),
                Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.orange),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Il doit rester au moins un administrateur et la base accepte au maximum trois administrateurs.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCountCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    Map<String, dynamic> account,
    bool isSelf,
  ) {
    final isAdmin = account['type_compte'] == 'Administrateur';
    final name = '${account['prenom'] ?? ''} ${account['nom'] ?? ''}'.trim();
    final roleColor = isAdmin ? Colors.deepPurple : Colors.teal;
    final theme = Theme.of(context);
    final borderColor = theme.brightness == Brightness.dark
        ? AppTheme.glassBorder.withValues(alpha: 0.1)
        : AppTheme.mediumGrey.withValues(alpha: 0.2);
    return Card(
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.12),
          child: Icon(
            isAdmin
                ? Icons.admin_panel_settings_outlined
                : Icons.person_outline,
            color: roleColor,
          ),
        ),
        title: Text(
          name.isEmpty ? 'Compte sans nom' : name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(account['email']?.toString() ?? ''),
              Chip(
                label: Text(isAdmin ? 'Administrateur' : 'Utilisateur'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                backgroundColor: roleColor.withValues(alpha: 0.1),
                side: BorderSide.none,
              ),
              if (isSelf)
                const Chip(
                  label: Text('Vous'),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        trailing: isSelf
            ? const Tooltip(
                message: 'Votre compte ne peut pas être modifié ici',
                child: Icon(Icons.lock_outline, size: 20),
              )
            : const Icon(Icons.chevron_right_rounded),
        onTap: isSelf ? null : () => _manage(account),
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
