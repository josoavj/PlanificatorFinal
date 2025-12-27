import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/index.dart';
import '../../repositories/index.dart';
import '../../widgets/index.dart';
import '../../core/theme.dart';

class ClientDetailScreen extends StatefulWidget {
  final int clientId;

  const ClientDetailScreen({Key? key, required this.clientId})
    : super(key: key);

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
    return WillPopScope(
      onWillPop: () async {
        if (_isEditing) {
          final confirmed = await AppDialogs.confirm(
            context,
            title: 'Abandon des modifications',
            message: 'Êtes-vous sûr de vouloir abandonner vos modifications ?',
            confirmText: 'Oui, quitter',
            cancelText: 'Non, continuer',
          );
          return confirmed ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Détails du client'),
          actions: [
            if (!_isEditing)
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Éditer'),
                      ],
                    ),
                    onTap: () {
                      setState(() => _isEditing = true);
                    },
                  ),
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: AppTheme.errorRed),
                        SizedBox(width: 8),
                        Text(
                          'Supprimer',
                          style: TextStyle(color: AppTheme.errorRed),
                        ),
                      ],
                    ),
                    onTap: () => _deleteClient(),
                  ),
                ],
              ),
          ],
        ),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isEditing)
                    _buildViewMode(context, _client!)
                  else
                    _buildEditMode(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildViewMode(BuildContext context, Client client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header avec avatar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Text(
                  client.fullName.isNotEmpty
                      ? client.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      client.email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Informations de contact
        _buildSection(
          title: 'Contact',
          children: [
            _buildInfoRow(Icons.email, 'Email', client.email),
            _buildInfoRow(Icons.phone, 'Téléphone', client.telephone),
            _buildInfoRow(Icons.location_on, 'Adresse', client.adresse),
          ],
        ),
        const SizedBox(height: 20),

        // Informations professionnelles
        _buildSection(
          title: 'Informations professionnelles',
          children: [
            _buildInfoRow(Icons.category, 'Catégorie', client.categorie),
            _buildInfoRow(Icons.card_membership, 'NIF', client.nif),
            _buildInfoRow(Icons.badge, 'STAT', client.stat),
            _buildInfoRow(Icons.trending_up, 'Axe', client.axe),
          ],
        ),
        const SizedBox(height: 20),

        // Actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToFactures(context, client.clientId),
                icon: const Icon(Icons.receipt),
                label: const Text('Voir factures'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToContrats(context, client.clientId),
                icon: const Icon(Icons.description),
                label: const Text('Voir contrats'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                value.isNotEmpty ? value : '-',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Text(
            'Éditer le client',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nomController,
            decoration: const InputDecoration(labelText: 'Nom'),
            validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _prenomController,
            decoration: const InputDecoration(labelText: 'Prénom'),
            validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
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
            decoration: const InputDecoration(labelText: 'Téléphone'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _adresseController,
            decoration: const InputDecoration(labelText: 'Adresse'),
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _categorieController,
            decoration: const InputDecoration(labelText: 'Catégorie'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nifController,
            decoration: const InputDecoration(labelText: 'NIF'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _statController,
            decoration: const InputDecoration(labelText: 'STAT'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _axeController,
            decoration: const InputDecoration(labelText: 'Axe'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveClient,
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
            setState(() => _isEditing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Client modifié avec succès')),
            );
          })
          .catchError((error) {
            AppDialogs.error(context, message: error.toString());
          });
    }
  }

  void _deleteClient() async {
    final confirmed = await AppDialogs.confirmDelete(context);
    if (confirmed == true) {
      context
          .read<ClientRepository>()
          .deleteClient(_client!.clientId)
          .then((_) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Client supprimé')));
          })
          .catchError((error) {
            AppDialogs.error(context, message: error.toString());
          });
    }
  }

  void _navigateToFactures(BuildContext context, int clientId) {
    context.read<FactureRepository>().loadFacturesForClient(clientId);
    Navigator.of(context).pushNamed('/factures');
  }

  void _navigateToContrats(BuildContext context, int clientId) {
    context.read<ContratRepository>().loadContratsForClient(clientId);
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
