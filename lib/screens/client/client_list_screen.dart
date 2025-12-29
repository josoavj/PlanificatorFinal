import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/client.dart';
import '../../repositories/index.dart';
import '../../widgets/index.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({Key? key}) : super(key: key);

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Charger les clients
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientRepository>().loadClients();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des clients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un client',
            onPressed: () => _showAddClientDialog(context),
          ),
        ],
      ),
      body: Consumer<ClientRepository>(
        builder: (context, repository, _) {
          // État de chargement
          if (repository.isLoading) {
            return const LoadingWidget(message: 'Chargement des clients...');
          }

          // État d'erreur
          if (repository.errorMessage != null) {
            return ErrorDisplayWidget(
              message: repository.errorMessage!,
              onRetry: () => repository.loadClients(),
            );
          }

          // État vide
          if (repository.clients.isEmpty) {
            return const EmptyStateWidget(
              title: 'Aucun client',
              message: 'Aucun client trouvé. Commencez par créer un client.',
              icon: Icons.people_outline,
              actionLabel: 'Ajouter un client',
            );
          }

          return Column(
            children: [
              // Barre de recherche
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un client...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              repository.loadClients();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (query) {
                    setState(() {}); // Mettre à jour le suffixIcon
                    if (query.isEmpty) {
                      repository.loadClients();
                    } else {
                      repository.searchClients(query);
                    }
                  },
                ),
              ),

              // Nombre de résultats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${repository.clients.length} client(s) trouvé(s)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),

              // Liste des clients
              Expanded(
                child: ListView.builder(
                  itemCount: repository.clients.length,
                  itemBuilder: (context, index) {
                    final client = repository.clients[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // En-tête avec nom et avatar
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.blue[100],
                                  child: Text(
                                    client.fullName.isNotEmpty
                                        ? client.fullName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        client.fullName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (client.email.isNotEmpty)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.email_outlined,
                                              size: 14,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                client.email,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: Colors.grey[600],
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.event_available,
                                              size: 14,
                                              color: Colors.blue[700],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${client.treatmentCount} traitement(s)',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors.blue[700],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Informations de contact
                            if (client.telephone.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      client.telephone,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                            // Boutons d'action
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.visibility, size: 18),
                                  label: const Text('Voir'),
                                  onPressed: () {
                                    _showClientDetails(context, client);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Éditer'),
                                  onPressed: () {
                                    _showEditClientDialog(context, client);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Supprimer',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () {
                                    _showDeleteConfirmation(
                                      context,
                                      repository,
                                      client.clientId,
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddClientDialog(BuildContext context) {
    final nomController = TextEditingController();
    final prenomController = TextEditingController();
    final emailController = TextEditingController();
    final telephoneController = TextEditingController();
    final adresseController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Ajouter un client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: prenomController,
                decoration: const InputDecoration(labelText: 'Prénom'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: telephoneController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
              ),
              TextField(
                controller: adresseController,
                decoration: const InputDecoration(labelText: 'Adresse'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomController.text.isNotEmpty &&
                  prenomController.text.isNotEmpty) {
                final newClient = Client(
                  clientId: 0,
                  nom: nomController.text,
                  prenom: prenomController.text,
                  email: emailController.text,
                  telephone: telephoneController.text,
                  adresse: adresseController.text,
                  categorie: '',
                  nif: '',
                  stat: '',
                  axe: '',
                );

                await context.read<ClientRepository>().createClient(newClient);
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showEditClientDialog(BuildContext context, client) {
    final nomController = TextEditingController(text: client.nom);
    final prenomController = TextEditingController(text: client.prenom);
    final emailController = TextEditingController(text: client.email);
    final telephoneController = TextEditingController(text: client.telephone);
    final adresseController = TextEditingController(text: client.adresse);

    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Éditer un client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: prenomController,
                decoration: const InputDecoration(labelText: 'Prénom'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: telephoneController,
                decoration: const InputDecoration(labelText: 'Téléphone'),
              ),
              TextField(
                controller: adresseController,
                decoration: const InputDecoration(labelText: 'Adresse'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomController.text.isNotEmpty &&
                  prenomController.text.isNotEmpty) {
                final updatedClient = Client(
                  clientId: client.clientId,
                  nom: nomController.text,
                  prenom: prenomController.text,
                  email: emailController.text,
                  telephone: telephoneController.text,
                  adresse: adresseController.text,
                  categorie: client.categorie,
                  nif: client.nif,
                  stat: client.stat,
                  axe: client.axe,
                );

                await context.read<ClientRepository>().updateClient(
                  updatedClient,
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showClientDetails(BuildContext context, client) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Détails du client',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Nom', client.fullName),
              _buildDetailRow('Email', client.email),
              _buildDetailRow('Téléphone', client.telephone),
              _buildDetailRow('Adresse', client.adresse),
              _buildDetailRow('Catégorie', client.categorie),
              _buildDetailRow('NIF', client.nif),
              _buildDetailRow('STAT', client.stat),
              _buildDetailRow('Axe', client.axe),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value.isNotEmpty ? value : '-')),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    ClientRepository repository,
    int clientId,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce client ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              repository.deleteClient(clientId);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Client supprimé')));
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
