import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/index.dart';
import '../../repositories/index.dart';
import '../../utils/app_snackbars.dart';
import '../../widgets/index.dart';
import '../../core/theme.dart';

class ClientDetailScreen extends StatefulWidget {
  final int clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  late Client? _client;
  bool _isEditing = false;

  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _telephoneController;
  late TextEditingController _adresseController;
  late TextEditingController _categorieController;
  late TextEditingController _nifController;
  late TextEditingController _statController;
  late TextEditingController _axeController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadClient();
  }

  void _initializeControllers() {
    _nomController = TextEditingController();
    _prenomController = TextEditingController();
    _emailController = TextEditingController();
    _telephoneController = TextEditingController();
    _adresseController = TextEditingController();
    _categorieController = TextEditingController();
    _nifController = TextEditingController();
    _statController = TextEditingController();
    _axeController = TextEditingController();
  }

  void _loadClient() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientRepository>().loadClient(widget.clientId);
    });
  }

  void _updateControllers(Client client) {
    _nomController.text = client.nom;
    _prenomController.text = client.prenom;
    _emailController.text = client.email;
    _telephoneController.text = client.telephone;
    _adresseController.text = client.adresse;
    _categorieController.text = client.categorie;
    _nifController.text = client.nif;
    _statController.text = client.stat;
    _axeController.text = client.axe;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_isEditing,
      onPopInvokedWithResult: (didPop, result) async {
        if (_isEditing && !didPop) {
          final confirmed = await AppDialogs.confirm(
            context,
            title: 'Abandon des modifications',
            message: 'Êtes-vous sûr de vouloir abandonner vos modifications ?',
            confirmText: 'Oui, quitter',
            cancelText: 'Non, continuer',
          );
          if (confirmed == true && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        body: Consumer<ClientRepository>(
          builder: (context, repository, _) {
            _client = repository.currentClient;

            if (repository.isLoading) {
              return const LoadingWidget();
            }

            if (repository.errorMessage != null) {
              return ErrorDisplayWidget(
                message: repository.errorMessage!,
                onRetry: _loadClient,
              );
            }

            if (_client == null) {
              return const EmptyStateWidget(
                title: 'Client non trouvé',
                message: 'Le client demandé n\'existe pas',
              );
            }

            if (!_isEditing) {
              _updateControllers(_client!);
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  if (!_isEditing) ...[
                    _buildHeader(context, _client!, isDark),
                    const SizedBox(height: 70),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: _buildViewMode(context, _client!),
                      ),
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildEditMode(),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Client client, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 230,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainer : AppTheme.primaryBlue,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(48)),
          ),
        ),
        // Bouton Retour en haut à gauche (Simplifié)
        Positioned(
          top: 40,
          left: 8,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
          ),
        ),
        // Menu Actions en haut à droite
        Positioned(
          top: 40,
          right: 8,
          child: Consumer<AuthRepository>(
            builder: (context, auth, _) {
              return Theme(
                data: Theme.of(context).copyWith(
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                child: PopupMenuButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Éditer le profil'),
                        ],
                      ),
                      onTap: () {
                        setState(() => _isEditing = true);
                      },
                    ),
                    if (auth.isAdmin)
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.delete_rounded, size: 18, color: AppTheme.errorRed),
                            SizedBox(width: 8),
                            Text(
                              'Supprimer le client',
                              style: TextStyle(color: AppTheme.errorRed),
                            ),
                          ],
                        ),
                        onTap: () => _deleteClient(),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 60,
          child: Column(
            children: [
              Text(
                client.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.category_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      client.categorie.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -45,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBg : Colors.white,
              shape: BoxShape.circle,
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: AppTheme.primaryBlue,
              child: Text(
                client.fullName.isNotEmpty ? client.fullName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewMode(BuildContext context, Client client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informations de contact
        _buildSection(
          title: 'Coordonnées de contact',
          children: [
            _buildInfoRow(Icons.email_outlined, 'Adresse Email', client.email),
            _buildInfoRow(Icons.phone_outlined, 'Téléphone', client.telephone),
            _buildInfoRow(Icons.location_on_outlined, 'Adresse physique', client.adresse),
          ],
        ),
        const SizedBox(height: 24),

        // Informations professionnelles
        _buildSection(
          title: 'Détails Professionnels',
          children: [
            _buildInfoRow(Icons.business_center_outlined, 'Catégorie', client.categorie),
            _buildInfoRow(Icons.description_outlined, 'NIF', client.nif),
            _buildInfoRow(Icons.badge_outlined, 'STAT', client.stat),
            _buildInfoRow(Icons.map_outlined, 'Axe / Secteur', client.axe),
          ],
        ),
        const SizedBox(height: 32),

        // Actions rapides
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToFactures(context, client.clientId),
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('Voir factures', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToContrats(context, client.clientId),
                icon: const Icon(Icons.assignment_rounded),
                label: const Text('Voir contrats', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue,
            ),
          ),
        ),
        Container(
          decoration: AppTheme.cardDecoration(context, radius: 24),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: List.generate(children.length, (index) {
                return Column(
                  children: [
                    children[index],
                    if (index < children.length - 1)
                      Divider(
                        height: 1,
                        indent: 60,
                        endIndent: 16,
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Icon(icon, color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue, size: 22),
      title: Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600], fontWeight: FontWeight.bold)),
      subtitle: Text(
        value.isNotEmpty ? value : '-',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildEditMode() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _isEditing = false),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              const SizedBox(width: 8),
              Text(
                'Éditer le client',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nomController,
            decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(Icons.person_outline)),
            validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _prenomController,
            decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.person_outline)),
            validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Requis';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value!)) {
                return 'Email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _telephoneController,
            decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Icons.phone_outlined)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _adresseController,
            decoration: const InputDecoration(labelText: 'Adresse', prefixIcon: Icon(Icons.location_on_outlined)),
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _categorieController,
            decoration: const InputDecoration(labelText: 'Catégorie', prefixIcon: Icon(Icons.category_outlined)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nifController,
            decoration: const InputDecoration(labelText: 'NIF', prefixIcon: Icon(Icons.description_outlined)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _statController,
            decoration: const InputDecoration(labelText: 'STAT', prefixIcon: Icon(Icons.badge_outlined)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _axeController,
            decoration: const InputDecoration(labelText: 'Axe', prefixIcon: Icon(Icons.map_outlined)),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isEditing = false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveClient,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveClient() {
    if (_formKey.currentState!.validate()) {
      final updated = _client!.copyWith(
        nom: _nomController.text,
        prenom: _prenomController.text,
        email: _emailController.text,
        telephone: _telephoneController.text,
        adresse: _adresseController.text,
        categorie: _categorieController.text,
        nif: _nifController.text,
        stat: _statController.text,
        axe: _axeController.text,
      );

      context
          .read<ClientRepository>()
          .updateClient(updated)
          .then((_) {
            if (mounted) {
              setState(() => _isEditing = false);
              AppSnackBars.showSuccess(context, 'Client modifié avec succès');
            }
          })
          .catchError((error) {
            if (mounted) {
              AppSnackBars.showError(context, error.toString());
            }
          });
    }
  }

  void _deleteClient() async {
    final authRepo = context.read<AuthRepository>();
    if (!authRepo.isAdmin) {
      AppSnackBars.showError(context, 'Droits administrateur requis');
      return;
    }

    final confirmed = await AppDialogs.confirmDelete(context);
    if (confirmed == true && mounted) {
      final nav = Navigator.of(context);
      context
          .read<ClientRepository>()
          .deleteClient(_client!.clientId, isAdmin: authRepo.isAdmin)
          .then((success) {
            if (mounted && success) {
              nav.pop(true);
              AppSnackBars.showSuccess(context, 'Client supprimé');
            }
          })
          .catchError((error) {
            if (mounted) {
              AppSnackBars.showError(context, error.toString());
            }
          });
    }
  }

  void _navigateToFactures(BuildContext context, int clientId) {
    context.read<FactureRepository>().loadFacturesForClient(clientId);
    Navigator.of(context).pushNamed('/factures');
  }

  void _navigateToContrats(BuildContext context, int clientId) {
    Navigator.of(context).pushNamed('/contrats');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _categorieController.dispose();
    _nifController.dispose();
    _statController.dispose();
    _axeController.dispose();
    super.dispose();
  }
}
