import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planificator/screens/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'dart:convert';
import '../../models/index.dart';
import '../../repositories/index.dart';
import '../../widgets/index.dart';
import '../../utils/date_utils.dart' as DateUtils;
import '../../utils/date_helper.dart';
import '../../services/database_service.dart';

class ContratScreen extends StatefulWidget {
  final int? clientId;
  const ContratScreen({super.key, this.clientId});

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
      final contratsRepository = context.read<ContratRepository>();
      final clientRepository = context.read<ClientRepository>();
      final db = DatabaseService();

      // Charger tous les clients
      logger.d('📥 Chargement des clients via repository...');
      await clientRepository.loadClients();
      var allClients = clientRepository.clients;
      logger.d('✅ ${allClients.length} clients via repository');

      // Si aucun client n'a été chargé, charger directement de la BD
      if (allClients.isEmpty) {
        logger.w(
          '⚠️ Aucun client via repository, chargement direct de la BD...',
        );
        const sql = '''
          SELECT 
            client_id, nom, prenom, email, telephone, adresse, 
            categorie, nif, stat, axe
          FROM Client
          ORDER BY nom ASC
        ''';
        final rows = await db.query(sql);
        allClients = rows.map((row) => Client.fromMap(row)).toList();
        logger.i('✅ ${allClients.length} clients chargés directement');
      }

      if (allClients.isEmpty) {
        logger.w('⚠️ AUCUN CLIENT TROUVÉ !');
      } else {
        for (final client in allClients) {
          logger.d(
            '  🔑 ID=${client.clientId}, ${client.nom} ${client.prenom}',
          );
        }
      }

      // Charger tous les contrats
      logger.d('📥 Chargement des contrats...');
      await contratsRepository.loadContrats();
      var contrats = contratsRepository.contrats;
      logger.i('✅ ${contrats.length} contrats chargés');

      if (contrats.isNotEmpty) {
        for (final c in contrats.take(3)) {
          logger.d('  📋 ${c.referenceContrat} (ClientID=${c.clientId})');
        }
      }

      // Créer un map client_id -> Client pour accès rapide
      final clientMap = <int, Client>{};
      for (final client in allClients) {
        clientMap[client.clientId] = client;
      }
      logger.d('📊 Map créée: ${clientMap.length} clients');

      // Si un clientId est spécifié, filtrer uniquement les contrats de ce client
      if (widget.clientId != null) {
        contrats = contrats
            .where((c) => c.clientId == widget.clientId)
            .toList();
        logger.d(
          '🔍 Filtre: ${contrats.length} contrats pour client ${widget.clientId}',
        );
      }

      // Pour chaque contrat, récupérer les infos du client et nombre de traitements
      final result = <Map<String, dynamic>>[];
      for (final contrat in contrats) {
        final client = clientMap[contrat.clientId];

        // Récupérer nombre de traitements pour ce contrat
        const treatmentSql =
            'SELECT COUNT(*) as count FROM Traitement WHERE contrat_id = ?';
        final treatmentRows = await db.query(treatmentSql, [contrat.contratId]);
        final numTraitements = treatmentRows.isNotEmpty
            ? (treatmentRows[0]['count'] as int? ?? 0)
            : 0;

        result.add({
          'contrat': contrat,
          'client': client,
          'numTraitements': numTraitements,
        });
      }

      logger.i('🎯 ${result.length} contrats retournés');
      return result;
    } catch (e) {
      logger.e('❌ ERREUR chargement contrats: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    _initializeData();
    return Scaffold(
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddContratDialog,
        label: const Text('Ajout'),
        icon: const Icon(Icons.add),
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
                  if (client.categorie == 'Société') ...[
                    if (client.nif.isNotEmpty)
                      _buildDetailRow('NIF', client.nif),
                    if (client.stat.isNotEmpty)
                      _buildDetailRow('STAT', client.stat),
                  ],
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
                  contrat.dateFin != null
                      ? DateFormat('dd/MM/yyyy').format(contrat.dateFin!)
                      : 'Indéterminée',
                ),
                _buildDetailRow('Catégorie', contrat.categorie),
                _buildDetailRow('Statut', contrat.statutContrat),
                _buildDetailRow(
                  'Durée',
                  contrat.duree != null
                      ? '${contrat.duree} mois'
                      : 'Indéterminée',
                ),
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
      logger.e('Erreur chargement traitements: $e');
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

  // Données client - nouveau client à créer
  late TextEditingController _clientNom;
  late TextEditingController _clientPrenom;
  late TextEditingController _clientEmail;
  late TextEditingController _clientTelephone;
  late TextEditingController _clientAdresse;
  late TextEditingController _clientCategorie;
  late TextEditingController _clientNif;
  late TextEditingController _clientStat;
  late TextEditingController _clientAxe;

  // Données planning par traitement
  Map<int, Map<String, dynamic>> _treatmentPlanning = {};

  // Données facture par traitement
  Map<int, Map<String, dynamic>> _treatmentFactures = {};

  // Controllers de montant par traitement (pour éviter les resets lors des rebuilds)
  Map<int, TextEditingController> _montantControllers = {};

  @override
  void initState() {
    super.initState();
    _numeroContrat = TextEditingController();
    _dateContrat = TextEditingController();
    _dateDebut = TextEditingController();
    _dateFin = TextEditingController();
    _categorie = TextEditingController(text: 'Nouveau');
    _duree = TextEditingController(text: '12');

    // Initialiser les contrôleurs client
    _clientNom = TextEditingController();
    _clientPrenom = TextEditingController();
    _clientEmail = TextEditingController();
    _clientTelephone = TextEditingController();
    _clientAdresse = TextEditingController();
    _clientCategorie = TextEditingController(text: 'Particulier');
    _clientNif = TextEditingController();
    _clientStat = TextEditingController();
    _clientAxe = TextEditingController(text: 'Centre (C)');

    _loadTreatments();

    // Vérifier s'il y a une création en cours et proposer de continuer
    _checkForSavedProgress();
  }

  /// Vérifier s'il y a une création de contrat en cours et proposer de continuer
  Future<void> _checkForSavedProgress() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final hasSavedProgress = prefs.getBool('contract_in_progress') ?? false;

      if (hasSavedProgress && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Création en cours'),
            content: const Text(
              'Une création de contrat a été interrompue.\n\nVoulez-vous continuer où vous aviez laissé ou recommencer ?',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Charger les données sauvegardées
                  await _loadSavedProgress();
                  if (mounted) {
                    setState(() {});
                  }
                },
                child: const Text(
                  'Continuer',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Nettoyer les données sauvegardées
                  await _clearSavedProgress();
                },
                child: const Text(
                  'Recommencer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  /// Sauvegarder l'état actuel du formulaire
  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Nettoyer les données pour les rendre sérialisables en JSON
      final cleanedPlanning = _serializeMap(_treatmentPlanning);
      final cleanedFactures = _serializeMap(_treatmentFactures);

      final data = {
        'numeroContrat': _numeroContrat.text,
        'dateContrat': _dateContrat.text,
        'dateDebut': _dateDebut.text,
        'dateFin': _dateFin.text,
        'categorie': _categorie.text,
        'duree': _duree.text,
        'isDeterminee': _isDeterminee,
        'selectedTreatments': _selectedTreatments,
        'mainStep': _mainStep,
        'treatmentIndex': _treatmentIndex,
        // Client
        'clientNom': _clientNom.text,
        'clientPrenom': _clientPrenom.text,
        'clientEmail': _clientEmail.text,
        'clientTelephone': _clientTelephone.text,
        'clientAdresse': _clientAdresse.text,
        'clientCategorie': _clientCategorie.text,
        'clientNif': _clientNif.text,
        'clientStat': _clientStat.text,
        'clientAxe': _clientAxe.text,
        // Planning et factures
        'treatmentPlanning': cleanedPlanning,
        'treatmentFactures': cleanedFactures,
      };

      await prefs.setString('contract_saved_data', jsonEncode(data));
      await prefs.setBool('contract_in_progress', true);
      logger.i('Progression sauvegardée avec succès');
    } catch (e) {
      logger.e('Erreur lors de la sauvegarde: $e');
    }
  }

  /// Charger les données sauvegardées
  Future<void> _loadSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString('contract_saved_data');

      if (jsonData != null) {
        final data = jsonDecode(jsonData) as Map<String, dynamic>;

        _numeroContrat.text = data['numeroContrat'] ?? '';
        _dateContrat.text = data['dateContrat'] ?? '';
        _dateDebut.text = data['dateDebut'] ?? '';
        _dateFin.text = data['dateFin'] ?? '';
        _categorie.text = data['categorie'] ?? 'Nouveau';
        _duree.text = data['duree'] ?? '12';
        _isDeterminee = data['isDeterminee'] ?? false;
        _selectedTreatments = List<int>.from(data['selectedTreatments'] ?? []);
        _mainStep = data['mainStep'] ?? 0;
        _treatmentIndex = data['treatmentIndex'] ?? 0;

        // Client
        _clientNom.text = data['clientNom'] ?? '';
        _clientPrenom.text = data['clientPrenom'] ?? '';
        _clientEmail.text = data['clientEmail'] ?? '';
        _clientTelephone.text = data['clientTelephone'] ?? '';
        _clientAdresse.text = data['clientAdresse'] ?? '';
        _clientCategorie.text =
            [
              'Particulier',
              'Organisation',
              'Société',
            ].contains(data['clientCategorie'])
            ? data['clientCategorie']
            : 'Particulier';
        _clientNif.text = data['clientNif'] ?? '';
        _clientStat.text = data['clientStat'] ?? '';
        _clientAxe.text =
            [
              'Nord (N)',
              'Sud (S)',
              'Est (E)',
              'Ouest (O)',
              'Centre (C)',
            ].contains(data['clientAxe'])
            ? data['clientAxe']
            : 'Centre (C)';

        // Planning et factures
        if (data['treatmentPlanning'] is Map) {
          _treatmentPlanning = Map<int, Map<String, dynamic>>.from(
            (data['treatmentPlanning'] as Map).map(
              (k, v) => MapEntry(
                int.parse(k.toString()),
                Map<String, dynamic>.from(v as Map),
              ),
            ),
          );
        }
        if (data['treatmentFactures'] is Map) {
          _treatmentFactures = Map<int, Map<String, dynamic>>.from(
            (data['treatmentFactures'] as Map).map(
              (k, v) => MapEntry(
                int.parse(k.toString()),
                Map<String, dynamic>.from(v as Map),
              ),
            ),
          );
        }
      }
    } catch (e) {
      logger.e('Erreur lors du chargement: $e');
    }
  }

  /// Nettoyer les données sauvegardées
  Future<void> _clearSavedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('contract_saved_data');
      await prefs.setBool('contract_in_progress', false);
    } catch (e) {
      logger.e('Erreur lors de la suppression: $e');
    }
  }

  /// Charge les types de traitement depuis la base de données
  Future<void> _loadTreatments() async {
    try {
      // Différer le chargement après le build initial pour éviter setState() pendant le build
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final repository = context.read<TypeTraitementRepository>();
        await repository.loadAllTraitements();
        if (mounted) {
          setState(() {
            _allTreatments = repository.traitements;
          });
        }
      });
    } catch (e) {
      logger.e('Erreur lors du chargement des traitements: $e');
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
    _clientNom.dispose();
    _clientPrenom.dispose();
    _clientEmail.dispose();
    _clientTelephone.dispose();
    _clientAdresse.dispose();
    _clientCategorie.dispose();
    _clientNif.dispose();
    _clientStat.dispose();
    _clientAxe.dispose();
    // Nettoyer les controllers de montant
    for (final controller in _montantControllers.values) {
      controller.dispose();
    }
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

  /// Vérifier et corriger le mois saisi par l'utilisateur avec fuzzy matching
  /// Retourne le mois corrigé ou une chaîne vide si non valide
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
            color: Colors.white,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ligne de progression avec connecteurs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(steps.length, (i) {
                bool isCompleted = _mainStep > i;
                bool isActive = _mainStep == i;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cercle numéroté
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isCompleted
                            ? LinearGradient(
                                colors: [
                                  Colors.green[600]!,
                                  Colors.green[400]!,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : isActive
                            ? LinearGradient(
                                colors: [Colors.blue[700]!, Colors.blue[500]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: !isCompleted && !isActive
                            ? Colors.grey[200]
                            : null,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : isCompleted
                            ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.2),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 24,
                              )
                            : Text(
                                (i + 1).toString(),
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    // Connecteur (sauf après le dernier cercle)
                    if (i < steps.length - 1)
                      SizedBox(
                        width: 32,
                        height: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _mainStep > i
                                ? LinearGradient(
                                    colors: [
                                      Colors.green[500]!,
                                      Colors.green[400]!,
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.grey[300]!,
                                      Colors.grey[200]!,
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          // Libellés des étapes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(steps.length, (i) {
                bool isCompleted = _mainStep > i;
                bool isActive = _mainStep == i;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Aligné avec le cercle de 48px
                    SizedBox(
                      width: 48,
                      child: Text(
                        steps[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isActive
                              ? Colors.blue[700]
                              : isCompleted
                              ? Colors.green[600]
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                    // Espace pour le connecteur
                    if (i < steps.length - 1) const SizedBox(width: 32),
                  ],
                );
              }),
            ),
          ),
        ],
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
    // Sauvegarder après chaque étape précédente
    _saveProgress();
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
      _saveProgress();
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
      _saveProgress();
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
        _saveProgress();
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
          _saveProgress();
        } else {
          // Tous les traitements traités, aller au résumé
          setState(() => _mainStep++);
          _saveProgress();
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

    // Vérifier que la date de planification a été sélectionnée
    if (planning['datePlanification'] == null) return false;

    // Vérifier que les mois sont remplis
    if ((planning['moisDebut'] as String?) == null ||
        (planning['moisDebut'] as String).isEmpty)
      return false;
    if ((planning['moisFin'] as String?) == null ||
        (planning['moisFin'] as String).isEmpty)
      return false;

    // Vérifier que la durée du traitement est remplie
    if ((planning['dureeTraitement'] as String?) == null ||
        (planning['dureeTraitement'] as String).isEmpty)
      return false;

    // Vérifier que la redondance (fréquence) est sélectionnée
    if ((planning['redondance'] as String?) == null ||
        (planning['redondance'] as String).isEmpty)
      return false;

    return true;
  }

  bool _validateFactureData() {
    final treatmentId = _getCurrentTreatmentId();
    final facture = _treatmentFactures[treatmentId];
    if (facture == null) return false;

    // Vérifier que le montant est rempli
    if ((facture['montant'] as String?) == null ||
        (facture['montant'] as String).isEmpty)
      return false;

    return true;
  }

  /// Calcule le nombre de planifications pour un traitement
  /// basé sur la redondance et la durée
  int _calculateNumberOfPlannings(int treatmentId) {
    final planning = _treatmentPlanning[treatmentId];
    if (planning == null) return 0;

    final redondance =
        int.tryParse(
          (planning['redondance'] as String?)?.split(' ')[0] ?? '1',
        ) ??
        1;
    final dureeTraitement =
        int.tryParse((planning['dureeTraitement'] as String?) ?? '12') ?? 12;

    // Calcul: nombre de mois / fréquence en mois
    // Ex: 12 mois / 1 mois = 12 planifications
    // Ex: 12 mois / 3 mois = 4 planifications
    if (redondance == 0) {
      return 1; // Une seule fois
    }
    return (dureeTraitement / redondance).ceil();
  }

  /// Calcule le coût total pour un traitement
  /// = Montant unitaire × Nombre de planifications
  int _calculateTotalCost(int treatmentId) {
    final facture = _treatmentFactures[treatmentId];
    if (facture == null) return 0;

    final montantStr = (facture['montant'] as String?) ?? '';
    if (montantStr.isEmpty) return 0;

    final montant = int.tryParse(montantStr) ?? 0;
    final nombrePlanifications = _calculateNumberOfPlannings(treatmentId);

    return montant * nombrePlanifications;
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
            const SizedBox(height: 12),
            // Numéro du contrat
            TextField(
              controller: _numeroContrat,
              decoration: InputDecoration(
                labelText: 'Numéro du contrat',
                hintText: 'Ex: REF-001',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Trois dates côte à côte
            Row(
              children: [
                // Date du contrat
                Builder(
                  builder: (context) => Expanded(
                    child: TextField(
                      controller: _dateContrat,
                      decoration: InputDecoration(
                        labelText: 'Date contrat',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context, _dateContrat),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Date de début
                Builder(
                  builder: (context) => Expanded(
                    child: TextField(
                      controller: _dateDebut,
                      decoration: InputDecoration(
                        labelText: 'Date début',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context, _dateDebut),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Date de fin (affichée si déterminée)
                if (_isDeterminee)
                  Builder(
                    builder: (context) => Expanded(
                      child: TextField(
                        controller: _dateFin,
                        decoration: InputDecoration(
                          labelText: 'Date fin',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            size: 18,
                          ),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context, _dateFin),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Durée (déterminée = avec date fin, indéterminée = sans date fin)
            Container(
              padding: const EdgeInsets.all(10),
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
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text(
                            'Déterminée',
                            style: TextStyle(fontSize: 12),
                          ),
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
                          title: const Text(
                            'Indéterminée',
                            style: TextStyle(fontSize: 12),
                          ),
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
                  // Si déterminée : afficher date de fin obligatoire
                  if (_isDeterminee)
                    Builder(
                      builder: (context) => TextField(
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
                        onTap: () => _selectDate(context, _dateFin),
                      ),
                    )
                  else
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
    final isSociete = _clientCategorie.text == 'Société';
    final isParticulier = _clientCategorie.text == 'Particulier';

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
              'Créer un nouveau client',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.blue[700]),
            ),
            const SizedBox(height: 20),

            // Catégorie client
            DropdownButtonFormField<String>(
              value:
                  [
                    'Particulier',
                    'Organisation',
                    'Société',
                  ].contains(_clientCategorie.text)
                  ? _clientCategorie.text
                  : 'Particulier',
              decoration: InputDecoration(
                labelText: 'Catégorie',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Particulier',
                  child: Text('Particulier'),
                ),
                DropdownMenuItem(
                  value: 'Organisation',
                  child: Text('Organisation'),
                ),
                DropdownMenuItem(value: 'Société', child: Text('Société')),
              ],
              onChanged: (value) {
                setState(() {
                  _clientCategorie.text = value ?? 'Particulier';
                });
              },
            ),
            const SizedBox(height: 16),

            // Nom
            TextField(
              controller: _clientNom,
              decoration: InputDecoration(
                labelText: isSociete ? 'Nom de la société' : 'Nom',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Prénom/Responsable (seulement pour Particulier, sinon c'est Responsable)
            if (isParticulier) ...[
              TextField(
                controller: _clientPrenom,
                decoration: InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              TextField(
                controller: _clientPrenom,
                decoration: InputDecoration(
                  labelText: 'Responsable',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Email
            TextField(
              controller: _clientEmail,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Téléphone
            TextField(
              controller: _clientTelephone,
              decoration: InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Adresse
            TextField(
              controller: _clientAdresse,
              decoration: InputDecoration(
                labelText: 'Adresse',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Axe
            DropdownButtonFormField<String>(
              value:
                  [
                    'Nord (N)',
                    'Sud (S)',
                    'Est (E)',
                    'Ouest (O)',
                    'Centre (C)',
                  ].contains(_clientAxe.text)
                  ? _clientAxe.text
                  : 'Centre (C)',
              decoration: InputDecoration(
                labelText: 'Axe',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'Nord (N)', child: Text('Nord (N)')),
                DropdownMenuItem(value: 'Sud (S)', child: Text('Sud (S)')),
                DropdownMenuItem(value: 'Est (E)', child: Text('Est (E)')),
                DropdownMenuItem(value: 'Ouest (O)', child: Text('Ouest (O)')),
                DropdownMenuItem(
                  value: 'Centre (C)',
                  child: Text('Centre (C)'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _clientAxe.text = value ?? 'Centre (C)';
                });
              },
            ),
            const SizedBox(height: 12),

            // NIF et STAT (seulement pour Société)
            if (isSociete) ...[
              TextField(
                controller: _clientNif,
                decoration: InputDecoration(
                  labelText: 'NIF',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _clientStat,
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
      // Durée automatique: 12 mois si indéterminée, sinon la durée du contrat
      final dureeDefaut = _isDeterminee
          ? (int.tryParse(_duree.text) ?? 12).toString()
          : '12';

      // Extraire l'année de la date début du contrat
      String anneeDebut = DateTime.now().year.toString();
      try {
        final dateDebut = DateFormat('dd/MM/yyyy').parse(_dateDebut.text);
        anneeDebut = dateDebut.year.toString();
      } catch (e) {
        // Utiliser l'année actuelle par défaut
      }

      _treatmentPlanning[treatmentId] = {
        'dateDebut': _dateDebut.text, // Date de début du contrat
        'moisDebut': 'Janvier $anneeDebut',
        'moisFin': _isDeterminee ? 'Décembre $anneeDebut' : 'Indéterminée',
        'dureeTraitement': dureeDefaut,
        'redondance': '1', // Défaut: mensuel
      };
    } else {
      // S'assurer que les clés existent (au cas où on charge depuis le cache)
      final planning = _treatmentPlanning[treatmentId]!;
      if (!planning.containsKey('dateDebut'))
        planning['dateDebut'] = _dateDebut.text;
      if (!planning.containsKey('moisDebut')) {
        String anneeDebut = DateTime.now().year.toString();
        try {
          final dateDebut = DateFormat('dd/MM/yyyy').parse(_dateDebut.text);
          anneeDebut = dateDebut.year.toString();
        } catch (e) {
          // Utiliser l'année actuelle par défaut
        }
        planning['moisDebut'] = 'Janvier $anneeDebut';
      }
      if (!planning.containsKey('moisFin')) {
        String anneeFin = DateTime.now().year.toString();
        try {
          final dateDebut = DateFormat('dd/MM/yyyy').parse(_dateDebut.text);
          anneeFin = dateDebut.year.toString();
        } catch (e) {
          // Utiliser l'année actuelle par défaut
        }
        planning['moisFin'] = _isDeterminee
            ? 'Décembre $anneeFin'
            : 'Indéterminée';
      }
      if (!planning.containsKey('dureeTraitement'))
        planning['dureeTraitement'] = '12';
      if (!planning.containsKey('redondance')) planning['redondance'] = '1';
    }

    final planning = _treatmentPlanning[treatmentId]!;

    // Options de redondance
    final redondanceOptions = [
      {'label': 'Mensuel', 'value': '1'},
      {'label': 'Bimestriel', 'value': '2'},
      {'label': 'Trimestriel', 'value': '3'},
      {'label': 'Quadrimestriel', 'value': '4'},
      {'label': 'Semestriel', 'value': '6'},
      {'label': 'Annuel', 'value': '12'},
      {'label': 'Une seule fois', 'value': '0'},
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

            // Dates côte à côte: début du contrat et planification
            Row(
              children: [
                // Date de début du contrat (lecture seule)
                Expanded(
                  child: TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Date début du contrat',
                      hintText: 'dd/MM/yyyy',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(text: _dateDebut.text),
                  ),
                ),
                const SizedBox(width: 12),
                // Date de planification (sélection)
                Expanded(
                  child: Builder(
                    builder: (context) => TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date de planification',
                        hintText: 'Tap pour sélectionner',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            DateTime initialDate = DateTime.now();
                            // Si une date a déjà été sélectionnée, l'utiliser comme date initiale
                            if (planning['datePlanification'] != null &&
                                (planning['datePlanification'] as String)
                                    .isNotEmpty) {
                              try {
                                initialDate = DateTime.parse(
                                  planning['datePlanification'] as String,
                                );
                              } catch (e) {
                                // Utiliser la date de début du contrat par défaut
                                final parsed = DateHelper.parseAny(
                                  _dateDebut.text,
                                );
                                if (parsed != null) {
                                  initialDate = parsed;
                                }
                              }
                            } else {
                              // Utiliser la date de début du contrat par défaut
                              final parsed = DateHelper.parseAny(
                                _dateDebut.text,
                              );
                              if (parsed != null) {
                                initialDate = parsed;
                              }
                            }

                            final picked = await showDatePicker(
                              context: context,
                              initialDate: initialDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                // Stocker la date en format ISO string pour la sérialisation JSON
                                planning['datePlanification'] = picked
                                    .toIso8601String();
                                // Auto-remplir moisDebut avec le mois de la date sélectionnée
                                final moisNoms = [
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
                                planning['moisDebut'] =
                                    '${moisNoms[picked.month - 1]} ${picked.year}';

                                // Calculer automatiquement moisFin
                                int moisFin;
                                int anneeFin = picked.year;
                                if (_isDeterminee && _dateFin.text.isNotEmpty) {
                                  // Si déterminé: calculer basé sur la date fin réelle
                                  try {
                                    final dateFin = DateFormat(
                                      'dd/MM/yyyy',
                                    ).parse(_dateFin.text);
                                    moisFin = dateFin.month;
                                    anneeFin = dateFin.year;
                                  } catch (e) {
                                    moisFin = 12; // Décembre par défaut
                                  }
                                } else {
                                  // Si indéterminé: 12 mois à partir du mois début
                                  // Ajouter 12 mois à la date de début
                                  moisFin =
                                      picked.month; // Même mois, année suivante
                                  anneeFin = picked.year + 1;
                                }
                                planning['moisFin'] =
                                    '${moisNoms[moisFin - 1]} $anneeFin';

                                // Calculer la durée du traitement
                                if (_isDeterminee && _dateFin.text.isNotEmpty) {
                                  try {
                                    final dateFin = DateFormat(
                                      'dd/MM/yyyy',
                                    ).parse(_dateFin.text);
                                    int duree = dateFin.month - picked.month;
                                    if (duree <= 0) duree += 12;
                                    planning['dureeTraitement'] = duree
                                        .toString();
                                  } catch (e) {
                                    planning['dureeTraitement'] = '12';
                                  }
                                } else {
                                  planning['dureeTraitement'] = '12';
                                }
                              });
                            }
                          },
                        ),
                      ),
                      controller: TextEditingController(
                        text: planning['datePlanification'] != null
                            ? DateHelper.format(
                                planning['datePlanification'] is DateTime
                                    ? planning['datePlanification'] as DateTime
                                    : DateTime.parse(
                                        planning['datePlanification'] as String,
                                      ),
                              )
                            : '',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mois début et fin côte à côte (auto-remplis, lecture seule)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Mois début',
                      hintText: 'Auto-rempli',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText: 'Auto-remplit par la date',
                      helperStyle: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    controller: TextEditingController(
                      text: (planning['moisDebut'] as String?) ?? 'Janvier',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Mois fin',
                      hintText: 'Auto-calculé',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText: _isDeterminee
                          ? 'Basé sur la date fin'
                          : 'Indéterminé = 12 mois',
                      helperStyle: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    controller: TextEditingController(
                      text: (planning['moisFin'] as String?) ?? 'Décembre',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Durée du traitement (auto-remplie)
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Durée du traitement (en mois)',
                hintText: 'Auto-calculée',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              controller: TextEditingController(
                text: (planning['dureeTraitement'] as String?) ?? '12',
              ),
            ),
            const SizedBox(height: 16),

            // Redondance (fréquence)
            DropdownButtonFormField<String>(
              value: (planning['redondance'] as String?) ?? '1',
              decoration: InputDecoration(
                labelText: 'Fréquence',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: redondanceOptions
                  .map(
                    (opt) => DropdownMenuItem(
                      value: opt['value'],
                      child: Text(opt['label'] ?? ''),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  planning['redondance'] = value ?? '1';
                });
              },
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
    } else {
      // S'assurer que les clés existent (au cas où on charge depuis le cache)
      final facture = _treatmentFactures[treatmentId]!;
      if (!facture.containsKey('reference')) {
        facture['reference'] = 'FCT-${DateTime.now().millisecondsSinceEpoch}';
      }
      if (!facture.containsKey('montant')) {
        facture['montant'] = '';
      }
    }

    // Créer ou récupérer le controller pour le montant
    if (!_montantControllers.containsKey(treatmentId)) {
      _montantControllers[treatmentId] = TextEditingController(
        text: (_treatmentFactures[treatmentId]?['montant'] as String?) ?? '',
      );
    } else {
      // Mettre à jour le texte du controller s'il a changé
      final montantController = _montantControllers[treatmentId]!;
      final currentMontant =
          _treatmentFactures[treatmentId]?['montant'] as String? ?? '';
      if (montantController.text != currentMontant) {
        montantController.text = currentMontant;
      }
    }

    final facture = _treatmentFactures[treatmentId]!;
    final montantController = _montantControllers[treatmentId]!;

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
                text:
                    (facture['reference'] as String?) ??
                    'FCT-${DateTime.now().millisecondsSinceEpoch}',
              ),
            ),
            const SizedBox(height: 16),
            // Montant (champ éditable)
            TextField(
              controller: montantController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setState(() {
                  facture['montant'] = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Montant unitaire',
                hintText: 'Ex: 1500.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: 'MGA',
                helperText: 'Montant en Ariary par planification',
                helperStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 20),
            // Affichage du calcul du total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calcul du coût total du traitement',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nombre de planifications:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      Text(
                        '${_calculateNumberOfPlannings(treatmentId)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Montant unitaire:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      Text(
                        '${(facture['montant'] as String?) ?? '0'} MGA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'COÛT TOTAL:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${_calculateTotalCost(treatmentId)} MGA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
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
            _DetailRow('Nom', _clientNom.text),
            if (_clientPrenom.text.isNotEmpty)
              _DetailRow('Prénom', _clientPrenom.text),
            _DetailRow('Email', _clientEmail.text),
            _DetailRow('Téléphone', _clientTelephone.text),
            if (_clientNif.text.isNotEmpty) _DetailRow('NIF', _clientNif.text),
            if (_clientStat.text.isNotEmpty)
              _DetailRow('STAT', _clientStat.text),
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

      // Calculs
      final nombrePlanifications = _calculateNumberOfPlannings(treatmentId);
      final montantUnitaire =
          int.tryParse((facture['montant'] as String?) ?? '0') ?? 0;
      final totalCoust = _calculateTotalCost(treatmentId);

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${idx + 1}. $treatmentName',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${totalCoust.toString()} MGA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
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
                    '${planning['redondance']?.toString() ?? '-'}',
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
                  _DetailRow('Montant unitaire', '$montantUnitaire MGA'),
                  _DetailRow('Nb planifications', '$nombrePlanifications'),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green[200]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Colors.green[700],
                          ),
                        ),
                        Text(
                          '$totalCoust MGA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Colors.green[700],
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
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 9.5,
      mainAxisSpacing: 3,
      crossAxisSpacing: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _allTreatments.map((treatment) {
        final id = treatment.id ?? 0;
        final isSelected = _selectedTreatments.contains(id);

        return Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: isSelected ? Colors.blue[50] : Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedTreatments.remove(id);
                } else {
                  _selectedTreatments.add(id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Checkbox(
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
                    activeColor: Colors.blue[700],
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Expanded(
                    child: Text(
                      treatment.type,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
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

  /// Sélectionner une date (wrapper simple)
  /// Sélectionner une date
  Future<void> _selectDate(
    BuildContext ctx,
    TextEditingController controller,
  ) async {
    final date = await showDatePicker(
      context: ctx,
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
      // Vérifier que tous les champs client sont remplis
      if (_clientNom.text.isEmpty ||
          _clientEmail.text.isEmpty ||
          _clientTelephone.text.isEmpty ||
          _clientAdresse.text.isEmpty) {
        return false;
      }
      // Vérifier prénom pour particulier
      if (_clientCategorie.text == 'Particulier' &&
          _clientPrenom.text.isEmpty) {
        return false;
      }
      // Vérifier NIF et STAT pour Société seulement
      if (_clientCategorie.text == 'Société' &&
          (_clientNif.text.isEmpty || _clientStat.text.isEmpty)) {
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
  /// Créer le contrat final
  void _createFinalContrat() async {
    try {
      // ÉTAPE 1: Créer le nouveau client
      final newClient = Client(
        clientId: 0, // L'ID sera généré par la BD
        nom: _clientNom.text,
        prenom: _clientPrenom.text,
        email: _clientEmail.text,
        telephone: _clientTelephone.text,
        adresse: _clientAdresse.text.isNotEmpty ? _clientAdresse.text : '',
        categorie: _clientCategorie.text,
        // NIF et STAT seulement pour les Sociétés
        nif: _clientCategorie.text == 'Société' ? _clientNif.text : '',
        stat: _clientCategorie.text == 'Société' ? _clientStat.text : '',
        axe: _clientAxe.text.isNotEmpty ? _clientAxe.text : 'Centre (C)',
        dateAjout: DateTime.now(),
      );

      final clientId = await context.read<ClientRepository>().createClient(
        newClient,
      );

      if (clientId == -1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la création du client'),
            ),
          );
        }
        return;
      }

      // ÉTAPE 2: Créer le contrat avec l'ID du client créé
      final dateContratParsed = DateFormat(
        'dd/MM/yyyy',
      ).parse(_dateContrat.text);
      final dateDebutParsed = DateFormat('dd/MM/yyyy').parse(_dateDebut.text);

      // Si déterminée, utiliser la date saisie ; sinon null
      DateTime? dateFinParsed;
      int? dureeEnMois;

      if (_isDeterminee) {
        dateFinParsed = DateFormat('dd/MM/yyyy').parse(_dateFin.text);
        dureeEnMois =
            dateFinParsed.month -
            dateDebutParsed.month +
            12 * (dateFinParsed.year - dateDebutParsed.year);
      }

      // Créer le contrat
      final contratId = await context.read<ContratRepository>().createContrat(
        clientId: clientId,
        referenceContrat: _numeroContrat.text.isNotEmpty
            ? _numeroContrat.text
            : 'REF-${DateTime.now().millisecondsSinceEpoch}',
        dateContrat: dateContratParsed,
        dateDebut: dateDebutParsed,
        dateFin: dateFinParsed,
        statutContrat: 'Actif',
        duree: dureeEnMois,
        categorie: _categorie.text,
        dureeStatus: _isDeterminee ? 'Déterminée' : 'Indéterminée',
      );

      if (contratId == -1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la création du contrat'),
            ),
          );
        }
        return;
      }

      // Créer les plannings et factures pour chaque traitement sélectionné
      int planningsCreated = 0;
      int facturesCreated = 0;

      // Mapper typeTraitementId → traitementId créé dans la BDD
      final Map<int, int> traitementMap = {};

      for (final typeTraitementId in _selectedTreatments) {
        // Étape 1: Créer l'enregistrement Traitement dans la BDD
        final createdTraitementId = await context
            .read<ContratRepository>()
            .createTraitement(
              contratId: contratId,
              typeTraitementId: typeTraitementId,
            );

        if (createdTraitementId == -1) {
          Logger().e(
            '❌ Erreur création traitement pour type $typeTraitementId',
          );
          continue;
        }

        traitementMap[typeTraitementId] = createdTraitementId;

        final planningData = _treatmentPlanning[typeTraitementId];
        final factureData = _treatmentFactures[typeTraitementId];

        if (planningData != null && factureData != null) {
          // Récupérer les données du planning
          // Extraire le mois du texte "Janvier 2025"
          final moisDebutStr =
              (planningData['moisDebut'] as String?) ?? 'Janvier 1';
          final moisDebutWords = moisDebutStr.split(' ');
          final moisDebut = _moisToInt(moisDebutWords[0]);

          final dureeTraitement =
              int.tryParse(
                (planningData['dureeTraitement'] as String?) ?? '12',
              ) ??
              12;
          final redondance =
              int.tryParse((planningData['redondance'] as String?) ?? '1') ?? 1;

          // Créer le planning
          final planningId = await context
              .read<PlanningRepository>()
              .createPlanning(
                traitementId: createdTraitementId,
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
                // Référence facture: vide, sera remplie manuellement lors de l'ajout de remarque
                final montant = (factureData['montant'] as String?) ?? '';

                if (montant.isNotEmpty) {
                  await context.read<FactureRepository>().createFactureComplete(
                    planningDetailId: planningDetail.planningDetailId,
                    referenceFacture: '', // Vide - sera rempli manuellement
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

      // Nettoyer les données sauvegardées après succès
      await _clearSavedProgress();

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

  /// Nettoyer une Map pour la rendre sérialisable en JSON
  /// Convertit les clés int en String et les DateTime en string ISO 8601
  Map<String, Map<String, dynamic>> _serializeMap(
    Map<int, Map<String, dynamic>> input,
  ) {
    final result = <String, Map<String, dynamic>>{};
    for (final entry in input.entries) {
      final cleanedValue = <String, dynamic>{};
      for (final item in entry.value.entries) {
        if (item.value is DateTime) {
          // Convertir DateTime en string ISO
          cleanedValue[item.key] = (item.value as DateTime).toIso8601String();
        } else if (item.value is! String &&
            item.value is! int &&
            item.value is! double &&
            item.value is! bool &&
            item.value is! List &&
            item.value is! Map &&
            item.value != null) {
          // Convertir les autres types complexes en string
          cleanedValue[item.key] = item.value.toString();
        } else {
          cleanedValue[item.key] = item.value;
        }
      }
      // Convertir la clé int en String
      result[entry.key.toString()] = cleanedValue;
    }
    return result;
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
