import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/index.dart';
import '../../core/theme.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/type_traitement_repository.dart';
import '../../utils/app_snackbars.dart';
import '../../widgets/app_dialogs.dart';

class TreatmentCatalogManagementScreen extends StatefulWidget {
  const TreatmentCatalogManagementScreen({super.key});

  @override
  State<TreatmentCatalogManagementScreen> createState() =>
      _TreatmentCatalogManagementScreenState();
}

class _TreatmentCatalogManagementScreenState
    extends State<TreatmentCatalogManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TypeTraitementRepository>().loadCatalogForAdmin();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthRepository>().isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Catalogue des traitements')),
        body: const Center(child: Text('Accès réservé aux administrateurs.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Catalogue des traitements')),
      body: Consumer<TypeTraitementRepository>(
        builder: (context, repository, _) {
          if (repository.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: repository.loadCatalogForAdmin,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Catégories',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Les catégories regroupent les traitements disponibles dans les contrats.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ...repository.categories.map(
                  (category) =>
                      _buildCategoryCard(context, repository, category),
                ),
                _buildAddButton(
                  onPressed: () => _addCategory(context),
                  icon: Icons.create_new_folder_outlined,
                  label: 'Ajouter une catégorie',
                ),
                const SizedBox(height: 28),
                Text(
                  'Traitements',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900
                        ? 3
                        : constraints.maxWidth >= 560
                        ? 2
                        : 1;
                    final gap = 12.0;
                    final width =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: repository.traitements
                          .map(
                            (treatment) => SizedBox(
                              width: width,
                              child: _buildTreatmentCard(
                                context,
                                repository,
                                treatment,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                _buildAddButton(
                  onPressed: repository.categories.isEmpty
                      ? null
                      : () => _addTreatment(context),
                  icon: Icons.add,
                  label: 'Ajouter un traitement',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: SizedBox(
          width: 280,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTreatmentCard(
    BuildContext context,
    TypeTraitementRepository repository,
    TypeTraitement treatment,
  ) {
    final theme = Theme.of(context);
    final borderColor = theme.brightness == Brightness.dark
        ? AppTheme.glassBorder.withValues(alpha: 0.1)
        : AppTheme.mediumGrey.withValues(alpha: 0.2);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    return Card(
      elevation: 0,
      shadowColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Icon(
          treatment.actif
              ? Icons.cleaning_services_outlined
              : Icons.visibility_off_outlined,
          color: treatment.actif ? null : mutedColor,
        ),
        title: Text(
          treatment.type,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: treatment.actif ? null : mutedColor,
            decoration: treatment.actif ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text(
          treatment.categorie,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Switch.adaptive(
          value: treatment.actif,
          onChanged: (visible) =>
              _setTreatmentVisibility(context, repository, treatment, visible),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    TypeTraitementRepository repository,
    TypeTraitementCategory category,
  ) {
    final theme = Theme.of(context);
    final borderColor = theme.brightness == Brightness.dark
        ? AppTheme.glassBorder.withValues(alpha: 0.1)
        : AppTheme.mediumGrey.withValues(alpha: 0.2);
    final mutedColor = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    return Card(
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: ListTile(
        leading: Icon(
          category.actif ? Icons.folder_outlined : Icons.folder_off_outlined,
          color: category.actif ? null : mutedColor,
        ),
        title: Text(category.name),
        subtitle: Text(category.actif ? 'Visible partout' : 'Masquée partout'),
        trailing: Switch.adaptive(
          value: category.actif,
          onChanged: (visible) =>
              _setCategoryVisibility(context, repository, category, visible),
        ),
      ),
    );
  }

  Future<void> _setCategoryVisibility(
    BuildContext context,
    TypeTraitementRepository repository,
    TypeTraitementCategory category,
    bool visible,
  ) async {
    try {
      await repository.setCategoryVisibility(category, visible);
      if (context.mounted) {
        AppSnackBars.showSuccess(
          context,
          visible
              ? 'Catégorie et traitements affichés.'
              : 'Catégorie et traitements masqués.',
        );
      }
    } catch (error) {
      if (context.mounted) {
        AppSnackBars.showError(
          context,
          'Impossible de modifier l’affichage : $error',
        );
      }
    }
  }

  Future<void> _setTreatmentVisibility(
    BuildContext context,
    TypeTraitementRepository repository,
    TypeTraitement treatment,
    bool visible,
  ) async {
    try {
      await repository.setTreatmentVisibility(treatment, visible);
      if (context.mounted) {
        AppSnackBars.showSuccess(
          context,
          visible ? 'Traitement affiché.' : 'Traitement masqué.',
        );
      }
    } catch (error) {
      if (context.mounted) {
        AppSnackBars.showError(
          context,
          'Impossible de modifier l’affichage : $error',
        );
      }
    }
  }

  Future<void> _addCategory(BuildContext context) async {
    final controller = TextEditingController();
    final name = await AppDialogs.showBlurDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !context.mounted) return;

    try {
      await context.read<TypeTraitementRepository>().createCategory(name);
      if (context.mounted) {
        AppSnackBars.showSuccess(context, 'Catégorie ajoutée.');
      }
    } catch (error) {
      if (context.mounted) {
        AppSnackBars.showError(
          context,
          'Impossible d’ajouter la catégorie : $error',
        );
      }
    }
  }

  Future<void> _addTreatment(BuildContext context) async {
    final repository = context.read<TypeTraitementRepository>();
    final controller = TextEditingController();
    var category = repository.categories.first.name;
    final result = await AppDialogs.showBlurDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouveau traitement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: repository.categories
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.name,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => category = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nom du traitement',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, (category, controller.text)),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (result == null || !context.mounted) return;

    try {
      await repository.createTreatment(category: result.$1, name: result.$2);
      if (context.mounted) {
        AppSnackBars.showSuccess(context, 'Traitement ajouté.');
      }
    } catch (error) {
      if (context.mounted) {
        AppSnackBars.showError(
          context,
          'Impossible d’ajouter le traitement : $error',
        );
      }
    }
  }
}
