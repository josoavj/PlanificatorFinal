import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/index.dart';
import '../../repositories/index.dart';
import '../../widgets/index.dart';
import '../../utils/date_utils.dart' as DateUtils;
import '../../services/database_service.dart';

class ContratScreen extends StatefulWidget {
  final int? clientId; // Si null, affiche tous les contrats

  const ContratScreen({Key? key, this.clientId}) : super(key: key);

  @override
  State<ContratScreen> createState() => _ContratScreenState();
}

class _ContratScreenState extends State<ContratScreen> {
  late Future<List<Map<String, dynamic>>> _contratsWithClientsAndTreatments;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  void _initializeData() {
    if (!_initialized) {
      _initialized = true;
      _contratsWithClientsAndTreatments = _fetchContratsWithDetails();
    }
  }

  /// Récupère les contrats avec les infos du client et nombre de traitements
  Future<List<Map<String, dynamic>>> _fetchContratsWithDetails() async {
    try {
      print('🔍 Début du chargement des contrats...');
      final contratsRepository = context.read<ContratRepository>();
      final clientRepository = context.read<ClientRepository>();

      print('✅ Repositories chargés');

      // Charger tous les clients
      print('📥 Chargement des clients...');
      await clientRepository.loadClients();
      final allClients = clientRepository.clients;
      print('✅ ${allClients.length} clients chargés');

      // Charger tous les contrats
      print('📥 Chargement des contrats...');
      if (widget.clientId != null) {
        await contratsRepository.loadContratsForClient(widget.clientId!);
      } else {
        await contratsRepository.loadContrats();
      }
      final contrats = contratsRepository.contrats;
      print('✅ ${contrats.length} contrats chargés');

      // Créer un map client_id -> Client pour accès rapide
      final clientMap = <int, Client>{};
      for (final client in allClients) {
        clientMap[client.clientId] = client;
      }

      // Pour chaque contrat, récupérer les infos du client et nombre de traitements
      final result = <Map<String, dynamic>>[];
      for (final contrat in contrats) {
        final client = clientMap[contrat.clientId];
        // TODO: récupérer nombre de traitements pour ce contrat
        final numTraitements = 0; // À implémenter

        result.add({
          'contrat': contrat,
          'client': client,
          'numTraitements': numTraitements,
        });
      }

      print('✅ ${result.length} contrats avec détails préparés');
      return result;
    } catch (e) {
      print('❌ Erreur chargement contrats: $e');
      print(e.toString());
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    _initializeData();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des contrats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un contrat',
            onPressed: () => _showAddContratDialog(),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _contratsWithClientsAndTreatments,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _contratsWithClientsAndTreatments =
                            _fetchContratsWithDetails();
                      });
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyStateWidget(
              title: 'Aucun contrat',
              message: 'Aucun contrat trouvé. Créez-en un pour commencer.',
              icon: Icons.description_outlined,
            );
          }

          final contratsWithDetails = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: contratsWithDetails.length,
            itemBuilder: (context, index) {
              final data = contratsWithDetails[index];
              final contrat = data['contrat'] as Contrat;
              final client = data['client'] as Client?;
              final numTraitements = data['numTraitements'] as int;

              return _buildContratListItem(
                contrat: contrat,
                client: client,
                numTraitements: numTraitements,
              );
            },
          );
        },
      ),
    );
  }

  /// Afficher un contrat en tant qu'élément de liste cliquable
  Widget _buildContratListItem({
    required Contrat contrat,
    required Client? client,
    required int numTraitements,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final clientName = client?.nom ?? 'Client inconnu';
    final clientPrenom = client?.prenom ?? '';
    final fullName = '$clientName $clientPrenom'.trim();
    final clientEmail = client?.email ?? 'N/A';
    final clientPhone = client?.telephone ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 2,
      child: InkWell(
        onTap: () => _showContratDetails(contrat, client, numTraitements),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne 1: Nom et Prénom du client
              Text(
                fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Ligne 2: Date contrat et nombre de traitements
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Contrat: ${dateFormat.format(contrat.dateContrat)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$numTraitements traitement(s)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Ligne 3: Email et Téléphone
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '📧 $clientEmail',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('📞 $clientPhone', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddContratDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ContratCreationFlowScreen(clientId: widget.clientId),
      ),
    );
  }

  void _showContratDetails(
    Contrat contrat,
    Client? client,
    int numTraitements,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Détails du Contrat'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═════════════════════════════════════════
                // SECTION: INFORMATIONS CLIENT
                // ═════════════════════════════════════════
                _buildSectionHeader('👤 INFORMATIONS CLIENT'),
                if (client != null) ...[
                  _buildDetailRow('Nom', client.nom),
                  _buildDetailRow(
                    'Prénom',
                    client.prenom.isNotEmpty ? client.prenom : '-',
                  ),
                  _buildDetailRow('Email', client.email),
                  _buildDetailRow('Téléphone', client.telephone),
                  _buildDetailRow('Adresse', client.adresse),
                  _buildDetailRow('Catégorie', client.categorie),
                  if (client.nif.isNotEmpty) _buildDetailRow('NIF', client.nif),
                  if (client.stat.isNotEmpty)
                    _buildDetailRow('STAT', client.stat),
                  _buildDetailRow('Axe', client.axe),
                ] else ...[
                  const Text('Informations client non disponibles'),
                ],
                const SizedBox(height: 16),

                // ═════════════════════════════════════════
                // SECTION: INFORMATIONS CONTRAT
                // ═════════════════════════════════════════
                _buildSectionHeader('📋 INFORMATIONS CONTRAT'),
                _buildDetailRow('Référence', contrat.referenceContrat),
                _buildDetailRow(
                  'Date Contrat',
                  DateFormat('dd/MM/yyyy').format(contrat.dateContrat),
                ),
                _buildDetailRow(
                  'Date Début',
                  DateFormat('dd/MM/yyyy').format(contrat.dateDebut),
                ),
                _buildDetailRow(
                  'Date Fin',
                  DateFormat('dd/MM/yyyy').format(contrat.dateFin),
                ),
                _buildDetailRow('Catégorie', contrat.categorie),
                _buildDetailRow('Statut', contrat.statutContrat),
                _buildDetailRow('Durée', '${contrat.dureeContrat} mois'),
                const SizedBox(height: 16),

                // ═════════════════════════════════════════
                // SECTION: TRAITEMENTS
                // ═════════════════════════════════════════
                _buildSectionHeader('🔧 TRAITEMENTS ($numTraitements)'),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadTraitements(contrat.contratId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Aucun traitement'),
                      );
                    }

                    final traitements = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: traitements.length,
                      itemBuilder: (context, index) {
                        final t = traitements[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t['nom'] ?? 'Traitement',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Type: ${t['type'] ?? '-'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Bouton: Modifier infos client
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (client != null) {
                _editClient(client);
              }
            },
            child: const Text('✏️ Modifier Client'),
          ),

          // Bouton: Voir factures (si plusieurs traitements)
          if (numTraitements > 0)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _viewFactures(contrat);
              },
              child: const Text('📄 Factures'),
            ),

          // Bouton: Voir planning (si traitements)
          if (numTraitements > 0)
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _viewPlanning(contrat);
              },
              child: const Text('📅 Planning'),
            ),

          // Bouton: Supprimer
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteContrat(contrat);
            },
            child: const Text(
              '🗑️ Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),

          // Bouton: Fermer
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// Charger les traitements d'un contrat
  Future<List<Map<String, dynamic>>> _loadTraitements(int contratId) async {
    try {
      final db = DatabaseService();
      const sql = '''
        SELECT t.traitement_id, t.contrat_id, tt.typeTraitement as nom,
               tt.categorieTraitement as type
        FROM Traitement t
        LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
        WHERE t.contrat_id = ?
      ''';
      return await db.query(sql, [contratId]);
    } catch (e) {
      print('Erreur chargement traitements: $e');
      return [];
    }
  }

  /// Éditer les informations du client
  void _editClient(Client client) {
    // TODO: Ouvrir l'écran de modification du client
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Modification du client ${client.nom} en cours...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Voir les factures du contrat
  void _viewFactures(Contrat contrat) {
    // TODO: Ouvrir l'écran des factures
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Factures du contrat ${contrat.referenceContrat}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Voir le planning du contrat
  void _viewPlanning(Contrat contrat) {
    // TODO: Ouvrir l'écran de planning
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Planning du contrat ${contrat.referenceContrat}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Supprimer un contrat
  void _deleteContrat(Contrat contrat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le contrat ${contrat.referenceContrat}? '
          'Toutes les données associées seront supprimées.',
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
                await context.read<ContratRepository>().deleteContrat(
                  contrat.contratId,
                );
                if (!mounted) return;
                Navigator.of(context).pop(); // Fermer le dialogue principal
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Contrat supprimé avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Recharger la liste
                setState(() {
                  _contratsWithClientsAndTreatments =
                      _fetchContratsWithDetails();
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
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

  /// Construire un header de section
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
              value,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de création progressive d'un contrat par cartes
class _ContratCreationFlowScreen extends StatefulWidget {
  final int? clientId;

  const _ContratCreationFlowScreen({Key? key, this.clientId}) : super(key: key);

  @override
  State<_ContratCreationFlowScreen> createState() =>
      _ContratCreationFlowScreenState();
}

class _ContratCreationFlowScreenState
    extends State<_ContratCreationFlowScreen> {
  // Étapes principales : 0=Contrat, 1=Client, 2=Planning/Facture, 3=Résumé
  int _mainStep = 0;
  int _treatmentIndex =
      0; // Index du traitement actuel (dans _selectedTreatments)
  int _treatmentSubStep = 0; // 0=Planning, 1=Facture pour le traitement actuel

  late TextEditingController _numeroContrat;
  late TextEditingController _dateContrat;
  late TextEditingController _dateDebut;
  late TextEditingController _dateFin;
  late TextEditingController _categorie;
  late TextEditingController _duree;
  bool _isDeterminee = false;
  List<int> _selectedTreatments = [];
  List<TypeTraitement> _allTreatments = [];

  // Données client
  late TextEditingController _responsable;
  late TextEditingController _nif;
  late TextEditingController _stat;

  // Données planning par traitement
  Map<int, Map<String, dynamic>> _treatmentPlanning = {};

  // Données facture par traitement
  Map<int, Map<String, dynamic>> _treatmentFactures = {};

  @override
  void initState() {
    super.initState();
    _numeroContrat = TextEditingController();
    _dateContrat = TextEditingController();
    _dateDebut = TextEditingController();
    _dateFin = TextEditingController();
    _categorie = TextEditingController(text: 'Nouveau');
    _duree = TextEditingController(text: '12');
    _responsable = TextEditingController();
    _nif = TextEditingController();
    _stat = TextEditingController();
    _loadTreatments();
  }

  /// Charge les types de traitement depuis la base de données
  Future<void> _loadTreatments() async {
    try {
      final repository = context.read<TypeTraitementRepository>();
      await repository.loadAllTraitements();
      setState(() {
        _allTreatments = repository.traitements;
      });
    } catch (e) {
      print('Erreur lors du chargement des traitements: $e');
    }
  }

  @override
  void dispose() {
    _numeroContrat.dispose();
    _dateContrat.dispose();
    _dateDebut.dispose();
    _dateFin.dispose();
    _categorie.dispose();
    _duree.dispose();
    _responsable.dispose();
    _nif.dispose();
    _stat.dispose();
    super.dispose();
  }

  String _getCurrentTreatmentName() {
    if (_treatmentIndex >= _selectedTreatments.length) return '';
    final treatmentId = _selectedTreatments[_treatmentIndex];
    try {
      return _allTreatments.firstWhere((t) => t.id == treatmentId).type;
    } catch (e) {
      return 'Traitement inconnu';
    }
  }

  int _getCurrentTreatmentId() {
    if (_treatmentIndex >= _selectedTreatments.length) return -1;
    return _selectedTreatments[_treatmentIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Indicateur de progression
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: _buildProgressIndicator(),
          ),
          // Contenu de la carte
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildMainContent(),
            ),
          ),
          // Boutons de navigation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                if (_mainStep > 0 || _treatmentSubStep > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _previousStep(),
                      child: const Text('Précédent'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canProceed() ? _nextStep : null,
                    child: Text(_getButtonLabel()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    if (_mainStep == 0) return 'Créer un contrat - Infos contrat';
    if (_mainStep == 1) return 'Créer un contrat - Infos client';
    if (_mainStep == 2) {
      return _treatmentSubStep == 0
          ? 'Planning: ${_getCurrentTreatmentName()}'
          : 'Facture: ${_getCurrentTreatmentName()}';
    }
    return 'Résumé du contrat';
  }

  String _getButtonLabel() {
    if (_mainStep == 2) {
      if (_treatmentSubStep == 0) return 'Suivant (Facture)';
      if (_treatmentIndex < _selectedTreatments.length - 1) {
        return 'Traitement suivant';
      }
      return 'Résumé';
    }
    if (_mainStep == 3) return 'Enregistrer';
    return 'Suivant';
  }

  Widget _buildProgressIndicator() {
    final steps = ['Contrat', 'Client', 'Planning/Facture', 'Résumé'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(steps.length, (i) {
          bool isCompleted = _mainStep > i;
          bool isActive = _mainStep == i;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? Colors.blue[700]
                        : isCompleted
                        ? Colors.green
                        : Colors.grey[300],
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            (i + 1).toString(),
                            style: TextStyle(
                              color: isActive || isCompleted
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.blue[700] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_mainStep == 0) return _buildContratInfoCard();
    if (_mainStep == 1) return _buildClientInfoCard();
    if (_mainStep == 2) {
      return _treatmentSubStep == 0
          ? _buildPlanningCard()
          : _buildFactureCard();
    }
    return _buildResumeCard();
  }

  void _previousStep() {
    setState(() {
      if (_mainStep == 2) {
        if (_treatmentSubStep > 0) {
          _treatmentSubStep--;
        } else if (_treatmentIndex > 0) {
          _treatmentIndex--;
          _treatmentSubStep = 1; // Retour à facture du traitement précédent
        } else {
          _mainStep--;
        }
      } else if (_mainStep > 0) {
        _mainStep--;
      }
    });
  }

  void _nextStep() {
    if (_mainStep == 0) {
      if (!_canProceed()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez remplir tous les champs et sélectionner au moins un traitement',
            ),
          ),
        );
        return;
      }
      setState(() => _mainStep++);
    } else if (_mainStep == 1) {
      if (!_canProceed()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez remplir les informations du responsable'),
          ),
        );
        return;
      }
      setState(() => _mainStep++);
    } else if (_mainStep == 2) {
      if (_treatmentSubStep == 0) {
        // Valider planning et passer à facture
        if (!_validatePlanningData()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Veuillez remplir toutes les informations du planning',
              ),
            ),
          );
          return;
        }
        setState(() => _treatmentSubStep++);
      } else {
        // Valider facture et passer au traitement suivant
        if (!_validateFactureData()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Veuillez remplir toutes les informations de la facture',
              ),
            ),
          );
          return;
        }

        if (_treatmentIndex < _selectedTreatments.length - 1) {
          // Traitement suivant
          setState(() {
            _treatmentIndex++;
            _treatmentSubStep = 0; // Recommencer au planning
          });
        } else {
          // Tous les traitements traités, aller au résumé
          setState(() => _mainStep++);
        }
      }
    } else if (_mainStep == 3) {
      // Enregistrement final
      _createFinalContrat();
    }
  }

  bool _validatePlanningData() {
    final treatmentId = _getCurrentTreatmentId();
    final planning = _treatmentPlanning[treatmentId];
    if (planning == null) return false;

    // Vérifier que les champs obligatoires sont remplis
    if ((planning['dateDebut'] as String).isEmpty) return false;
    if ((planning['dateFin'] as String).isEmpty) return false;
    if ((planning['dureeTraitement'] as String).isEmpty) return false;
    if ((planning['redondance'] as String).isEmpty) return false;

    return true;
  }

  bool _validateFactureData() {
    final treatmentId = _getCurrentTreatmentId();
    final facture = _treatmentFactures[treatmentId];
    if (facture == null) return false;

    // Vérifier que le montant est rempli
    if ((facture['montant'] as String).isEmpty) return false;

    return true;
  }

  /// Première carte : Informations du contrat + Sélection des traitements
  Widget _buildContratInfoCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations du contrat',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.blue[700]),
            ),
            const SizedBox(height: 20),
            // Numéro du contrat
            TextField(
              controller: _numeroContrat,
              decoration: InputDecoration(
                labelText: 'Numéro du contrat',
                hintText: 'Ex: REF-001',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Date du contrat
            TextField(
              controller: _dateContrat,
              decoration: InputDecoration(
                labelText: 'Date du contrat',
                hintText: 'dd/MM/yyyy',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () => _selectDate(_dateContrat),
            ),
            const SizedBox(height: 16),
            // Date de début
            TextField(
              controller: _dateDebut,
              decoration: InputDecoration(
                labelText: 'Date de début',
                hintText: 'dd/MM/yyyy',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () => _selectDate(_dateDebut),
            ),
            const SizedBox(height: 16),
            // Durée (déterminée = avec date fin, indéterminée = sans date fin)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Type de durée',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Déterminée (avec date fin)'),
                          leading: Radio<bool>(
                            value: true,
                            groupValue: _isDeterminee,
                            onChanged: (value) =>
                                setState(() => _isDeterminee = value ?? false),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('Indéterminée'),
                          leading: Radio<bool>(
                            value: false,
                            groupValue: _isDeterminee,
                            onChanged: (value) =>
                                setState(() => _isDeterminee = value ?? true),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isDeterminee) ...[
                    // Si déterminée : afficher date de fin obligatoire
                    TextField(
                      controller: _dateFin,
                      decoration: InputDecoration(
                        labelText: 'Date de fin',
                        hintText: 'dd/MM/yyyy',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(_dateFin),
                    ),
                  ] else ...[
                    // Si indéterminée : pas de date fin
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '⚠️ Pas de date de fin pour un contrat indéterminé',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Catégorie (Nouveau / Renouvellement)
            DropdownButtonFormField<String>(
              value: _categorie.text,
              decoration: InputDecoration(
                labelText: 'Catégorie du contrat',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Nouveau', child: Text('Nouveau')),
                DropdownMenuItem(
                  value: 'Renouvellement',
                  child: Text('Renouvellement'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _categorie.text = value ?? 'Nouveau';
                });
              },
            ),
            const SizedBox(height: 20),
            // Sélection des traitements
            Text(
              'Sélectionner les traitements',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.blue[700]),
            ),
            const SizedBox(height: 12),
            _buildTreatmentSelectionList(),
          ],
        ),
      ),
    );
  }

  /// Deuxième carte : Informations client (éditable selon la catégorie)
  Widget _buildClientInfoCard() {
    final clientRepository = context.read<ClientRepository>();
    final clients = clientRepository.clients;

    Client? selectedClient;
    if (widget.clientId != null) {
      try {
        selectedClient = clients.firstWhere(
          (c) => c.clientId == widget.clientId,
        );
      } catch (e) {
        selectedClient = clients.isNotEmpty ? clients.first : null;
      }
    } else if (clients.isNotEmpty) {
      selectedClient = clients.first;
    }

    if (selectedClient == null) {
      return Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Aucun client sélectionné',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    final isParticulier = selectedClient.categorie == 'Particulier';
    final isSociete = selectedClient.categorie == 'Société';

    // Initialiser les contrôleurs avec les données du client
    if (_responsable.text.isEmpty) {
      _responsable.text = selectedClient.prenom;
      _nif.text = selectedClient.nif;
      _stat.text = selectedClient.stat;
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations client',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.blue[700]),
            ),
            const SizedBox(height: 20),
            // Affichage du client (lecture seule)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            selectedClient.nom.isNotEmpty
                                ? selectedClient.nom[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedClient.nom,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              selectedClient.categorie,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailRow('Email', selectedClient.email),
                  const SizedBox(height: 8),
                  _DetailRow('Téléphone', selectedClient.telephone),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Champs éditables selon catégorie
            Text(
              'Compléter les informations',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.blue[700]),
            ),
            const SizedBox(height: 16),
            // Prénom ou Responsable (selon catégorie)
            TextField(
              controller: _responsable,
              decoration: InputDecoration(
                labelText: isParticulier ? 'Prénom' : 'Responsable',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // NIF et STAT (seulement pour Société)
            if (isSociete) ...[
              TextField(
                controller: _nif,
                decoration: InputDecoration(
                  labelText: 'NIF',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _stat,
                decoration: InputDecoration(
                  labelText: 'STAT',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Résumé des traitements sélectionnés
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Traitements à planifier (${_selectedTreatments.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedTreatments.isEmpty)
                    Text(
                      'Aucun traitement sélectionné',
                      style: TextStyle(color: Colors.green[600], fontSize: 12),
                    )
                  else
                    _buildSelectedTreatmentsSummary(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Troisième carte : Planification pour un traitement spécifique
  Widget _buildPlanningCard() {
    final treatmentId = _getCurrentTreatmentId();
    final treatmentName = _getCurrentTreatmentName();

    // Initialiser si nécessaire
    if (!_treatmentPlanning.containsKey(treatmentId)) {
      _treatmentPlanning[treatmentId] = {
        'dateDebut': '',
        'dateFin': '',
        'mois': 'Janvier', // Mois en texte (converti en INT au save)
        'dureeTraitement': '12', // Durée en mois
        'redondance': '1', // Fréquence en mois
      };
    }

    final planning = _treatmentPlanning[treatmentId]!;
    final mois = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Planning du traitement',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        treatmentName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_treatmentIndex + 1}/${_selectedTreatments.length}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Dates du planning
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectPlanningDate(treatmentId, 'dateDebut'),
                    child: TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date début',
                        hintText: 'dd/MM/yyyy',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      controller: TextEditingController(
                        text: planning['dateDebut'] as String,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectPlanningDate(treatmentId, 'dateFin'),
                    child: TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date fin',
                        hintText: 'dd/MM/yyyy',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      controller: TextEditingController(
                        text: planning['dateFin'] as String,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Mois (texte, pas chiffre)
            DropdownButtonFormField<String>(
              value: planning['mois'] as String,
              decoration: InputDecoration(
                labelText: 'Mois',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: mois
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  planning['mois'] = value ?? 'Janvier';
                });
              },
            ),
            const SizedBox(height: 16),
            // Durée du traitement (en mois)
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  planning['dureeTraitement'] = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Durée du traitement (en mois)',
                hintText: 'Ex: 12',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              controller: TextEditingController(
                text: planning['dureeTraitement'] as String,
              ),
            ),
            const SizedBox(height: 16),
            // Redondance (fréquence en mois)
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  planning['redondance'] = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Redondance (fréquence en mois)',
                hintText: 'Ex: 1',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              controller: TextEditingController(
                text: planning['redondance'] as String,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Quatrième carte : Facture pour un traitement spécifique
  Widget _buildFactureCard() {
    final treatmentId = _getCurrentTreatmentId();
    final treatmentName = _getCurrentTreatmentName();

    // Initialiser si nécessaire
    if (!_treatmentFactures.containsKey(treatmentId)) {
      _treatmentFactures[treatmentId] = {
        'reference': 'FCT-${DateTime.now().millisecondsSinceEpoch}',
        'montant': '',
      };
    }

    final facture = _treatmentFactures[treatmentId]!;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Facture du traitement',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        treatmentName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_treatmentIndex + 1}/${_selectedTreatments.length}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Référence facture (lecture seule)
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Référence',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              controller: TextEditingController(
                text: facture['reference'] as String,
              ),
            ),
            const SizedBox(height: 16),
            // Montant
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  facture['montant'] = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Montant',
                hintText: 'Ex: 1500.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: 'MGA',
              ),
              controller: TextEditingController(
                text: facture['montant'] as String,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cinquième carte : Résumé de toutes les données
  Widget _buildResumeCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé du contrat',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.blue[700]),
            ),
            const SizedBox(height: 20),
            // Infos contrat
            _buildSectionHeader('Informations du contrat'),
            _DetailRow('Date contrat', _dateContrat.text),
            _DetailRow('Date début', _dateDebut.text),
            _DetailRow('Date fin', _dateFin.text),
            _DetailRow('Catégorie', _categorie.text),
            const SizedBox(height: 16),
            // Infos client
            _buildSectionHeader('Informations client'),
            _DetailRow('Responsable', _responsable.text),
            if (_nif.text.isNotEmpty) _DetailRow('NIF', _nif.text),
            if (_stat.text.isNotEmpty) _DetailRow('STAT', _stat.text),
            const SizedBox(height: 16),
            // Traitements avec planning et facture
            _buildSectionHeader(
              'Traitements planifiés (${_selectedTreatments.length})',
            ),
            ..._buildTreatmentResumes(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  List<Widget> _buildTreatmentResumes() {
    final treatments = [
      {'id': 1, 'name': 'Nettoyage PC'},
      {'id': 2, 'name': 'Maintenance réseau'},
      {'id': 3, 'name': 'Support utilisateur'},
      {'id': 4, 'name': 'Sauvegarde données'},
      {'id': 5, 'name': 'Antivirus update'},
    ];

    return _selectedTreatments.asMap().entries.map((entry) {
      final idx = entry.key;
      final treatmentId = entry.value;
      final treatmentName =
          treatments.firstWhere((t) => t['id'] == treatmentId)['name']
              as String;
      final planning = _treatmentPlanning[treatmentId] ?? {};
      final facture = _treatmentFactures[treatmentId] ?? {};

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${idx + 1}. $treatmentName',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              'Planning:',
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow('Mois', planning['mois']?.toString() ?? '-'),
                  _DetailRow(
                    'Durée du traitement',
                    '${planning['dureeTraitement']?.toString() ?? '-'} mois',
                  ),
                  _DetailRow(
                    'Redondance',
                    '${planning['redondance']?.toString() ?? '-'} mois',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Facture:',
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    'Référence',
                    facture['reference']?.toString() ?? '-',
                  ),
                  _DetailRow(
                    'Montant',
                    '${facture['montant']?.toString() ?? '-'} MGA',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Liste pour sélectionner les traitements
  Widget _buildTreatmentSelectionList() {
    if (_allTreatments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Chargement des traitements...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Column(
      children: _allTreatments.map((treatment) {
        final id = treatment.id ?? 0;
        final isSelected = _selectedTreatments.contains(id);

        return Card(
          elevation: 0,
          color: isSelected ? Colors.blue[50] : Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedTreatments.add(id);
                } else {
                  _selectedTreatments.remove(id);
                }
              });
            },
            title: Text(treatment.type),
            subtitle: Text(treatment.categorie),
            activeColor: Colors.blue[700],
            controlAffinity: ListTileControlAffinity.leading,
          ),
        );
      }).toList(),
    );
  }

  /// Résumé des traitements sélectionnés
  Widget _buildSelectedTreatmentsSummary() {
    final selected = _allTreatments
        .where((t) => _selectedTreatments.contains(t.id))
        .toList();

    return Column(
      children: selected.map((treatment) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            border: Border.all(color: Colors.green[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      treatment.type,
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      treatment.categorie,
                      style: TextStyle(color: Colors.green[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Sélectionner une date
  Future<void> _selectDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(date);
    }
  }

  /// Vérifier si on peut procéder
  bool _canProceed() {
    if (_mainStep == 0) {
      // Vérifier que le numéro de contrat est rempli
      if (_numeroContrat.text.isEmpty) {
        return false;
      }
      // Vérifier que les dates sont remplies et les traitements sélectionnés
      if (_dateContrat.text.isEmpty || _dateDebut.text.isEmpty) {
        return false;
      }
      // Si déterminée → date fin obligatoire
      if (_isDeterminee && _dateFin.text.isEmpty) {
        return false;
      }
      // Vérifier que la catégorie est valide
      if (_categorie.text != 'Nouveau' && _categorie.text != 'Renouvellement') {
        return false;
      }
      if (_selectedTreatments.isEmpty) {
        return false;
      }
      return true;
    } else if (_mainStep == 1) {
      // Vérifier que responsable est rempli
      if (_responsable.text.isEmpty) {
        return false;
      }
      return true;
    } else if (_mainStep == 2) {
      if (_treatmentSubStep == 0) {
        // Validation planning
        return _validatePlanningData();
      } else {
        // Validation facture
        return _validateFactureData();
      }
    } else {
      // Résumé : toujours ok
      return true;
    }
  }

  /// Sélectionner une date planning
  Future<void> _selectPlanningDate(int treatmentId, String type) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        if (!_treatmentPlanning.containsKey(treatmentId)) {
          _treatmentPlanning[treatmentId] = {};
        }
        _treatmentPlanning[treatmentId]![type] = DateFormat(
          'dd/MM/yyyy',
        ).format(date);
      });
    }
  }

  /// Sélectionner une date facture
  /// Créer le contrat final
  void _createFinalContrat() async {
    try {
      final dateContratParsed = DateFormat(
        'dd/MM/yyyy',
      ).parse(_dateContrat.text);
      final dateDebutParsed = DateFormat('dd/MM/yyyy').parse(_dateDebut.text);

      // Si déterminée, utiliser la date saisie ; sinon calculer basée sur durée
      final dateFinParsed = _isDeterminee
          ? DateFormat('dd/MM/yyyy').parse(_dateFin.text)
          : dateDebutParsed.add(Duration(days: 365 * int.parse(_duree.text)));

      // Calculer la durée en mois
      final dureeEnMois =
          dateFinParsed.month -
          dateDebutParsed.month +
          12 * (dateFinParsed.year - dateDebutParsed.year);

      // Créer le contrat
      await context.read<ContratRepository>().createContrat(
        clientId: widget.clientId ?? 1,
        referenceContrat: _numeroContrat.text.isNotEmpty
            ? _numeroContrat.text
            : 'REF-${DateTime.now().millisecondsSinceEpoch}',
        dateContrat: dateContratParsed,
        dateDebut: dateDebutParsed,
        dateFin: dateFinParsed,
        statutContrat: 'Actif',
        duree: dureeEnMois,
        categorie: _categorie.text,
      );

      // Créer les plannings et factures pour chaque traitement sélectionné
      int planningsCreated = 0;
      int facturesCreated = 0;

      for (final treatmentId in _selectedTreatments) {
        final planningData = _treatmentPlanning[treatmentId];
        final factureData = _treatmentFactures[treatmentId];

        if (planningData != null && factureData != null) {
          // Récupérer les données du planning
          final moisDebut = _moisToInt(planningData['mois'] as String);
          final dureeTraitement =
              int.tryParse(planningData['dureeTraitement'] as String) ?? 12;
          final redondance =
              int.tryParse(planningData['redondance'] as String) ?? 1;

          // Créer le planning
          final planningId = await context
              .read<PlanningRepository>()
              .createPlanning(
                traitementId: treatmentId,
                dateDebutPlanification: dateDebutParsed,
                moisDebut: moisDebut,
                dureeTraitement: dureeTraitement,
                redondance: redondance,
              );

          if (planningId != -1) {
            planningsCreated++;

            // Générer les dates du planning automatiquement
            final planningDates = DateUtils.DateUtils.generatePlanningDates(
              dateDebut: dateDebutParsed,
              dureeTraitement: dureeTraitement,
              redondance: redondance,
            );

            // Créer un PlanningDetail pour chaque date générée
            // + UNE Facture pour chaque PlanningDetail
            for (final date in planningDates) {
              final planningDetail = await context
                  .read<PlanningDetailsRepository>()
                  .createPlanningDetails(planningId, date, statut: 'À venir');

              if (planningDetail != null) {
                // Créer une facture pour ce PlanningDetail
                // Référence facture: NULL (sera mise à jour lors du traitement)
                final montant = factureData['montant'] as String;

                if (montant.isNotEmpty) {
                  await context.read<FactureRepository>().createFactureComplete(
                    planningDetailId: planningDetail.planningDetailId,
                    referenceFacture: '', // Vide - sera mis à jour après
                    montant: int.tryParse(montant) ?? 0,
                    mode: 'À définir',
                    etat: 'À venir',
                    axe: 'À définir',
                    dateTraitement: date,
                  );
                  facturesCreated++;
                }
              }
            }
          }
        }
      }

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Contrat créé! $planningsCreated planning(s) + $facturesCreated facture(s).',
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  /// Convertir le mois texte (Janvier) en numéro (1)
  int _moisToInt(String mois) {
    const moisMap = {
      'Janvier': 1,
      'Février': 2,
      'Mars': 3,
      'Avril': 4,
      'Mai': 5,
      'Juin': 6,
      'Juillet': 7,
      'Août': 8,
      'Septembre': 9,
      'Octobre': 10,
      'Novembre': 11,
      'Décembre': 12,
    };
    return moisMap[mois] ?? 1;
  }
}

/// Widget de détail (clé-valeur)
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(value, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
      ],
    );
  }
}
