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
              // En-tête avec gradient bleu et barre de recherche
              _buildHeader(context, repository),

              // Liste des clients
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: repository.clients.length,
                  itemBuilder: (context, index) {
                    final client = repository.clients[index];
                    return _buildClientCard(context, repository, client);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Construit l'en-tête avec gradient et barre de recherche
  Widget _buildHeader(BuildContext context, ClientRepository repository) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, email...',
              hintStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        _searchController.clear();
                        repository.loadClients();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (query) {
              setState(() {});
              if (query.isEmpty) {
                repository.loadClients();
              } else {
                repository.searchClients(query);
              }
            },
          ),
          const SizedBox(height: 12),
          // Badge nombre de clients
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${repository.clients.length} client(s)',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une carte client moderne
  Widget _buildClientCard(
    BuildContext context,
    ClientRepository repository,
    Client client,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showClientDetails(context, client),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!, width: 1),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec avatar, nom et catégorie
                Row(
                  children: [
                    // Avatar avec gradient
                    _buildAvatar(client),
                    const SizedBox(width: 16),
                    // Informations client
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  client.fullName,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Badge catégorie
                              _buildCategoryBadge(client.categorie),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Email
                          if (client.email.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 16,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    client.email,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Chips axe et traitements
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.location_on_outlined,
                        label: client.axe,
                        color: Colors.orange[100],
                        textColor: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.description_outlined,
                        label: '${client.treatmentCount} traitement(s)',
                        color: Colors.green[100],
                        textColor: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                if (client.telephone.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        client.telephone,
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // Boutons d'action
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Voir'),
                      onPressed: () => _showClientDetails(context, client),
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
                      onPressed: () => _showEditClientDialog(context, client),
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
                      onPressed: () => _showDeleteConfirmation(
                        context,
                        context.read<ClientRepository>(),
                        client.clientId,
                        client.fullName,
                      ),
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
        ),
      ),
    );
  }

  /// Construit l'avatar avec gradient
  Widget _buildAvatar(Client client) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.blue[600]!],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          client.fullName.isNotEmpty ? client.fullName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  /// Construit le badge de catégorie
  Widget _buildCategoryBadge(String categorie) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor(categorie),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        categorie,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Construit un chip d'information
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color? color,
    required Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Retourne la couleur selon la catégorie
  Color _getCategoryColor(String categorie) {
    switch (categorie.toLowerCase()) {
      case 'particulier':
        return Colors.blue[600]!;
      case 'organisation':
        return Colors.purple[600]!;
      case 'société':
        return Colors.teal[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  /// Affiche la boîte de dialogue d'édition

  /// Affiche les détails du client dans un AlertDialog avec sections
  void _showClientDetails(BuildContext context, Client client) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Détails du Client'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═════════════════════════════════════════
                // SECTION: INFORMATIONS PERSONNELLES
                // ═════════════════════════════════════════
                _buildSectionHeader('👤 INFORMATIONS PERSONNELLES'),
                _buildDetailRow('Nom', client.nom),
                _buildDetailRow('Prénom', client.prenom),
                _buildDetailRow('Email', client.email),
                _buildDetailRow('Téléphone', client.telephone),
                const SizedBox(height: 16),

                // ═════════════════════════════════════════
                // SECTION: ADRESSE & LOCALISATION
                // ═════════════════════════════════════════
                _buildSectionHeader('📍 ADRESSE & LOCALISATION'),
                _buildDetailRow('Adresse', client.adresse),
                _buildDetailRow('Axe', client.axe),
                const SizedBox(height: 16),

                // ═════════════════════════════════════════
                // SECTION: CATÉGORIE & INFOS FISCALES
                // ═════════════════════════════════════════
                _buildSectionHeader('📋 CATÉGORIE & INFOS'),
                _buildDetailRow('Catégorie', client.categorie),
                if (client.categorie == 'Société') ...[
                  _buildDetailRow('NIF', client.nif),
                  _buildDetailRow('STAT', client.stat),
                ],
                const SizedBox(height: 16),

                // ═════════════════════════════════════════
                // SECTION: TRAITEMENTS ASSOCIÉS
                // ═════════════════════════════════════════
                _buildSectionHeader('🔧 TRAITEMENTS'),
                _buildDetailRow(
                  'Nombre de traitements',
                  '${client.treatmentCount}',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Modifier'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _showEditClientDialog(context, client);
            },
          ),
        ],
      ),
    );
  }

  /// Affiche la boîte de dialogue de modification du client (style Contrat)
  void _showEditClientDialog(BuildContext context, Client client) {
    final nomController = TextEditingController(text: client.nom);
    final prenomController = TextEditingController(text: client.prenom);
    final emailController = TextEditingController(text: client.email);
    final telephoneController = TextEditingController(text: client.telephone);
    final adresseController = TextEditingController(text: client.adresse);
    String selectedAxe = client.axe;
    String selectedCategorie = client.categorie;
    final nifController = TextEditingController(text: client.nif);
    final statController = TextEditingController(text: client.stat);

    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Modifier les informations du client'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═════════════════════════════════════════
                // SECTION: INFORMATIONS PERSONNELLES
                // ═════════════════════════════════════════
                _buildSectionHeader('👤 INFORMATIONS PERSONNELLES'),
                _buildEditField('Nom', nomController),
                _buildEditField('Prénom', prenomController),
                _buildEditField('Email', emailController),
                _buildEditField('Téléphone', telephoneController),
                const SizedBox(height: 16),

                // ═════════════════════════════════════════
                // SECTION: ADRESSE & LOCALISATION
                // ═════════════════════════════════════════
                _buildSectionHeader('📍 ADRESSE & LOCALISATION'),
                _buildEditField('Adresse', adresseController),
                _buildAxisDropdown((value) {
                  selectedAxe = value;
                }, selectedAxe),
                const SizedBox(height: 16),

                // ═════════════════════════════════════════
                // SECTION: CATÉGORIE & INFOS FISCALES
                // ═════════════════════════════════════════
                _buildSectionHeader('📋 CATÉGORIE & INFOS'),
                _buildCategoryDropdown((value) {
                  selectedCategorie = value;
                }, selectedCategorie),
                if (selectedCategorie == 'Société') ...[
                  const SizedBox(height: 8),
                  _buildEditField('NIF', nifController),
                  _buildEditField('STAT', statController),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Enregistrer'),
            onPressed: () {
              if (nomController.text.isNotEmpty &&
                  prenomController.text.isNotEmpty) {
                final updatedClient = Client(
                  clientId: client.clientId,
                  nom: nomController.text,
                  prenom: prenomController.text,
                  email: emailController.text,
                  telephone: telephoneController.text,
                  adresse: adresseController.text,
                  categorie: selectedCategorie,
                  nif: nifController.text,
                  stat: statController.text,
                  axe: selectedAxe,
                  dateAjout: client.dateAjout,
                  treatmentCount: client.treatmentCount,
                );

                context.read<ClientRepository>().updateClient(updatedClient);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Client modifié avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '⚠️ Veuillez remplir les champs obligatoires',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Construit un champ de texte pour l'édition
  Widget _buildEditField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  /// Dropdown pour les axes
  Widget _buildAxisDropdown(Function(String) onChanged, String selectedValue) {
    final axes = ['Nord (N)', 'Sud (S)', 'Est (E)', 'Ouest (O)', 'Centre (C)'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: 'Axe',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        items: axes.map((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        onChanged: (String? value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }

  /// Dropdown pour les catégories
  Widget _buildCategoryDropdown(
    Function(String) onChanged,
    String selectedValue,
  ) {
    final categories = ['Particulier', 'Organisation', 'Société'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: 'Catégorie',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        items: categories.map((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        onChanged: (String? value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }

  /// Construit un header de section (style Contrat)
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  /// Construit une ligne de détail (style Contrat)
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Flexible(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche la confirmation de suppression
  void _showDeleteConfirmation(
    BuildContext context,
    ClientRepository repository,
    int clientId,
    String clientName,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le client $clientName?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await repository.deleteClient(clientId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Client supprimé avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
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
