import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planificator/screens/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:collection/collection.dart';
import 'dart:convert';
import '../../models/index.dart';
import '../../repositories/index.dart';
import '../../widgets/index.dart';
import '../../utils/date_utils.dart' as DateUtils;
import '../../utils/date_helper.dart';
import '../../utils/number_formatter.dart';
import '../../services/database_service.dart';
import '../../services/logging_service.dart';

class ContratScreen extends StatefulWidget {
  final int? clientId;
  const ContratScreen({super.key, this.clientId});

  @override
  State<ContratScreen> createState() => _ContratScreenState();
}

class _ContratScreenState extends State<ContratScreen> {
  late Future<List<Map<String, dynamic>>> _contratsWithClientsAndTreatments;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final logger = createLoggerWithFileOutput(name: 'contrat_screen');
  int _contratCount = 0;

  @override
  void initState() {
    super.initState();
    // Initialiser les données une seule fois au démarrage
    _contratsWithClientsAndTreatments = _fetchContratsWithDetails();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Recharger les données
  void _reloadData() {
    setState(() {
      _contratsWithClientsAndTreatments = _fetchContratsWithDetails();
    });
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

  /// Construit l'en-tête avec gradient et barre de recherche
  Widget _buildHeader(BuildContext context) {
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
          // Barre de recherche avec bouton d'actualisation
          Row(
            children: [
              // Barre de recherche
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par client ou référence...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
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
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Bouton d'actualisation
              Tooltip(
                message: 'Actualiser',
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () {
                      _searchQuery = '';
                      _searchController.clear();
                      _reloadData();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Badge nombre de contrats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_contratCount ${_contratCount > 1 ? 'contrats' : 'contrat'}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // En-tête avec gradient bleu et barre de recherche
          _buildHeader(context),
          // Liste des contrats
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
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
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
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
                    message:
                        'Aucun contrat trouvé. Créez-en un pour commencer.',
                    icon: Icons.description_outlined,
                  );
                }

                var contratsWithDetails = snapshot.data!;

                // Appliquer le filtre de recherche
                if (_searchQuery.isNotEmpty) {
                  contratsWithDetails = contratsWithDetails.where((data) {
                    final client = data['client'] as Client?;
                    final contrat = data['contrat'] as Contrat;
                    final clientName =
                        '${client?.nom ?? ""} ${client?.prenom ?? ""}'
                            .toLowerCase();
                    final contratRef = contrat.referenceContrat.toLowerCase();

                    return clientName.contains(_searchQuery) ||
                        contratRef.contains(_searchQuery);
                  }).toList();
                }

                // Mettre à jour le nombre de contrats affichés
                _contratCount = contratsWithDetails.length;

                // Message si aucun résultat après recherche
                if (contratsWithDetails.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun contrat correspondant à "$_searchQuery"',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'contrat_add',
        onPressed: _showAddContratDialog,
        label: const Text('Ajouter un contrat'),
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
    // Pour Société et Organisation, afficher uniquement le Nom
    final isSocieteOrganisation =
        client?.categorie == 'Société' || client?.categorie == 'Organisation';
    final fullName = isSocieteOrganisation
        ? clientName
        : '$clientName $clientPrenom'.trim();
    final clientEmail = client?.email ?? 'N/A';
    final clientPhone = client?.telephone ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showContratDetails(contrat, client, numTraitements),
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
            padding: const EdgeInsets.all(12),
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
                const SizedBox(height: 4),

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
                        vertical: 2,
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
                const SizedBox(height: 6),

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
                    Text(
                      '📞 $clientPhone',
                      style: const TextStyle(fontSize: 12),
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
          width: 550,
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
                    client.prenomLabel,
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
                _buildDetailRow('Numéro Contrat', '#${contrat.contratId}'),
                _buildDetailRow('Référence', contrat.referenceContrat),
                _buildDetailRow(
                  'Date Contrat',
                  DateFormat('dd/MM/yyyy').format(contrat.dateContrat),
                ),
                _buildDetailRow(
                  'Date Début',
                  DateFormat('dd/MM/yyyy').format(contrat.dateDebut),
                ),
                if (contrat.dateFin != null)
                  _buildDetailRow(
                    'Date Fin',
                    DateFormat('dd/MM/yyyy').format(contrat.dateFin!),
                  ),
                _buildDetailRow('Catégorie', contrat.categorie),
                _buildDetailRow('Statut', contrat.statutContrat),
                _buildDetailRow('Durée Totale', '${contrat.dureeContrat} mois'),
                if (contrat.duree != null)
                  _buildDetailRow('Durée Restante', '${contrat.duree} mois'),
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
                const SizedBox(height: 16),

                // ═════════════════════════════════════════
                // SECTION: STATISTIQUES PAR TRAITEMENT
                // ═════════════════════════════════════════
                _buildSectionHeader('📊 STATISTIQUES PAR TRAITEMENT'),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadTraitementStatistics(contrat.contratId),
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
                        child: Text('Aucune statistique disponible'),
                      );
                    }

                    final stats = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stats.length,
                      itemBuilder: (context, index) {
                        final stat = stats[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            border: Border.all(color: Colors.blue[200]!),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stat['nom'] ?? 'Traitement',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '📅 Planifications: ${stat['planifications'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    'Redondance: ${_getRedondanceLabel(stat['redondance'] as int? ?? 1)}', //  Ajouter redondance
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '💰 ${stat['montantTotal'] ?? 0} MGA',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  Text(
                                    '📄 Factures: ${stat['factures'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '💬 Remarques: ${stat['remarques'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    '📋 Historiques: ${stat['historiques'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
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

          // Bouton: Abroger/Résilier (si contrat actif)
          if (contrat.statutContrat == 'Actif')
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showAbrogationDialog(contrat);
              },
              child: const Text(
                '⚠️ Abroger',
                style: TextStyle(color: Colors.orange),
              ),
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

  /// Charger les statistiques pour chaque traitement
  Future<List<Map<String, dynamic>>> _loadTraitementStatistics(
    int contratId,
  ) async {
    try {
      final db = DatabaseService();

      // Récupérer tous les traitements du contrat
      final traitements = await _loadTraitements(contratId);
      final stats = <Map<String, dynamic>>[];

      for (final t in traitements) {
        final traitementId = t['traitement_id'] as int?;
        if (traitementId == null) continue;

        int plannings = 0;
        int factures = 0;
        int remarques = 0;
        int historiques = 0;
        int montantTotal = 0;

        try {
          // Compter les planifications
          const sqlPlannings = '''
            SELECT COUNT(*) as count FROM Planning WHERE traitement_id = ?
          ''';
          final planningsResult = await db.query(sqlPlannings, [traitementId]);
          plannings =
              (planningsResult.isNotEmpty
                  ? planningsResult[0]['count'] as int?
                  : 0) ??
              0;
        } catch (e) {
          logger.w('Erreur comptage planifications: $e');
          plannings = 0;
        }

        try {
          // Compter les factures
          const sqlFactures = '''
            SELECT COUNT(*) as count FROM Facture f
            INNER JOIN PlanningDetails pd ON f.planning_detail_id = pd.planning_detail_id
            INNER JOIN Planning p ON pd.planning_id = p.planning_id
            WHERE p.traitement_id = ?
          ''';
          final facturesResult = await db.query(sqlFactures, [traitementId]);
          factures =
              (facturesResult.isNotEmpty
                  ? facturesResult[0]['count'] as int?
                  : 0) ??
              0;
        } catch (e) {
          logger.w('Erreur comptage factures: $e');
          factures = 0;
        }

        try {
          // Compter les remarques via planning_detail_id
          const sqlRemarques = '''
            SELECT COUNT(*) as count FROM Remarque r
            INNER JOIN PlanningDetails pd ON r.planning_detail_id = pd.planning_detail_id
            INNER JOIN Planning p ON pd.planning_id = p.planning_id
            WHERE p.traitement_id = ?
          ''';
          final remarquesResult = await db.query(sqlRemarques, [traitementId]);
          remarques =
              (remarquesResult.isNotEmpty
                  ? remarquesResult[0]['count'] as int?
                  : 0) ??
              0;
        } catch (e) {
          logger.w('Erreur comptage remarques: $e');
          remarques = 0;
        }

        try {
          // Compter les historiques (table Historique, pas HistoriqueEvent)
          const sqlHistoriques = '''
            SELECT COUNT(*) as count FROM Historique h
            WHERE h.facture_id IN (
              SELECT f.facture_id FROM Facture f
              INNER JOIN PlanningDetails pd ON f.planning_detail_id = pd.planning_detail_id
              INNER JOIN Planning p ON pd.planning_id = p.planning_id
              WHERE p.traitement_id = ?
            )
          ''';
          final historiquesResult = await db.query(sqlHistoriques, [
            traitementId,
          ]);
          historiques =
              (historiquesResult.isNotEmpty
                  ? historiquesResult[0]['count'] as int?
                  : 0) ??
              0;
        } catch (e) {
          logger.w('Erreur comptage historiques: $e');
          historiques = 0;
        }

        try {
          // Calculer le montant total (montant est un double)
          const sqlMontant = '''
            SELECT COALESCE(SUM(CAST(f.montant AS DECIMAL(10,2))), 0) as total FROM Facture f
            INNER JOIN PlanningDetails pd ON f.planning_detail_id = pd.planning_detail_id
            INNER JOIN Planning p ON pd.planning_id = p.planning_id
            WHERE p.traitement_id = ?
          ''';
          final montantResult = await db.query(sqlMontant, [traitementId]);
          montantTotal = montantResult.isNotEmpty
              ? (montantResult[0]['total'] as num?)?.toInt() ?? 0
              : 0;
        } catch (e) {
          logger.w('Erreur calcul montant: $e');
          montantTotal = 0;
        }

        // Récupérer la redondance du planning pour ce traitement
        int redondance = 1; // Défaut: mensuel
        try {
          const sqlRedondance = '''
            SELECT redondance FROM Planning WHERE traitement_id = ? LIMIT 1
          ''';
          final redondanceResult = await db.query(sqlRedondance, [
            traitementId,
          ]);
          if (redondanceResult.isNotEmpty) {
            final redondanceValue = redondanceResult[0]['redondance'];
            if (redondanceValue != null) {
              redondance = int.tryParse(redondanceValue.toString()) ?? 1;
            }
          }
        } catch (e) {
          logger.w('Erreur récupération redondance: $e');
          redondance = 1;
        }

        stats.add({
          'nom': t['nom'] ?? 'Traitement',
          'planifications': plannings,
          'factures': factures,
          'remarques': remarques,
          'historiques': historiques,
          'montantTotal': montantTotal,
          'redondance': redondance,
        });
      }

      return stats;
    } catch (e) {
      logger.e('Erreur chargement statistiques: $e');
      return [];
    }
  }

  /// Convertir la redondance numérique en libellé lisible
  String _getRedondanceLabel(int redondance) {
    switch (redondance) {
      case 0:
        return 'Une seule fois';
      case 1:
        return 'Mensuel';
      case 2:
        return 'Bi-mensuel';
      case 3:
        return 'Trimestriel';
      case 6:
        return 'Semestriel (6 mois)';
      case 12:
        return 'Annuel (12 mois)';
      default:
        return 'Tous les $redondance mois';
    }
  }

  /// Éditer les informations du client
  void _editClient(Client client) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Modification du client ${client.nom} en cours...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Voir les factures du contrat (groupées par type de traitement)
  void _viewFactures(Contrat contrat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Factures du Contrat'),
        content: SizedBox(
          width: 550,
          child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
            future: _loadFacturesGroupedByTraitement(contrat.contratId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Text('Erreur: ${snapshot.error}');
              }

              final facturesGrouped = snapshot.data ?? {};

              if (facturesGrouped.isEmpty) {
                // Aucune facture trouvée → afficher liste des traitements
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadTraitements(contrat.contratId),
                  builder: (context, traitementSnapshot) {
                    if (traitementSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final traitements = traitementSnapshot.data ?? [];

                    if (traitements.isEmpty) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text('Aucune facture trouvée'),
                          const SizedBox(height: 8),
                          const Text(
                            'Aucun traitement disponible',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      );
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aucune facture pour ce contrat',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Choisissez un traitement à réparer:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: traitements.length,
                          itemBuilder: (context, index) {
                            final traitement = traitements[index];
                            final nom = traitement['nom'] ?? 'Traitement';
                            final type = traitement['type'] ?? '-';
                            final traitementId =
                                traitement['traitement_id'] as int;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(nom),
                                subtitle: Text('Type: $type'),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  _showRepairDialog(
                                    contrat: contrat,
                                    traitementId: traitementId,
                                    traitementName: nom,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: facturesGrouped.length,
                itemBuilder: (context, index) {
                  final traitementType = facturesGrouped.keys.elementAt(index);
                  final factures = facturesGrouped[traitementType] ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header du type de traitement
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              traitementType,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.blue[900],
                              ),
                            ),
                            Text(
                              '${factures.length} facture(s)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Liste des factures pour ce traitement
                      ...factures.map((f) {
                        final dateStr = DateFormat(
                          'EEEE dd MMMM yyyy',
                          'fr_FR',
                        ).format(f['dateTraitement'] as DateTime);
                        final parts = dateStr.split(' ');
                        if (parts.isNotEmpty) {
                          parts[0] =
                              parts[0][0].toUpperCase() + parts[0].substring(1);
                        }
                        if (parts.length > 2) {
                          parts[2] =
                              parts[2][0].toUpperCase() + parts[2].substring(1);
                        }
                        final capitalizedDate = parts.join(' ');

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          title: Text('Facture #${f['factureId']}'),
                          subtitle: Text('${f['montant']} Ar - ${f['etat']}'),
                          trailing: Text(
                            capitalizedDate,
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      // Bouton réparer pour ce groupe
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.build, size: 18),
                            label: const Text(
                              'Réparer la facture de ce traitement',
                            ),
                            onPressed: () {
                              _repairTreatmentType(contrat, traitementType);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// Réparer les factures d'un type de traitement spécifique
  Future<void> _repairTreatmentType(
    Contrat contrat,
    String traitementType,
  ) async {
    try {
      final db = DatabaseService();

      // Récupérer le traitement ID pour ce type
      const sql = '''
        SELECT t.traitement_id, t.contrat_id
        FROM Traitement t
        INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
        WHERE t.contrat_id = ? AND tt.typeTraitement = ?
        LIMIT 1
      ''';

      final results = await db.query(sql, [contrat.contratId, traitementType]);

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Traitement non trouvé'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final traitementId = results[0]['traitement_id'] as int;

      // Afficher le dialog de réparation avec le traitement pré-sélectionné
      if (mounted) {
        _showRepairDialog(
          contrat: contrat,
          traitementId: traitementId,
          traitementName: traitementType,
        );
      }
    } catch (e) {
      logger.e('Erreur lors de la recherche du traitement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Charger les factures groupées par type de traitement
  Future<Map<String, List<Map<String, dynamic>>>>
  _loadFacturesGroupedByTraitement(int contratId) async {
    try {
      final db = DatabaseService();
      const sql = '''
        SELECT DISTINCT 
          f.facture_id, 
          f.montant, 
          f.date_traitement,
          f.etat,
          tt.typeTraitement
        FROM Facture f
        INNER JOIN PlanningDetails pd ON f.planning_detail_id = pd.planning_detail_id
        INNER JOIN Planning p ON pd.planning_id = p.planning_id
        INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
        INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
        WHERE t.contrat_id = ?
        ORDER BY tt.typeTraitement ASC, f.date_traitement ASC
      ''';

      final rows = await db.query(sql, [contratId]);

      final groupedMap = <String, List<Map<String, dynamic>>>{};

      for (final row in rows) {
        final typeTraitement =
            (row['typeTraitement'] as String?) ?? 'Sans type';
        final factureData = {
          'factureId': row['facture_id'] as int,
          'montant': row['montant'] as int,
          'dateTraitement': row['date_traitement'] is String
              ? DateTime.parse(row['date_traitement'] as String)
              : row['date_traitement'] as DateTime,
          'etat': row['etat'] as String,
        };

        if (!groupedMap.containsKey(typeTraitement)) {
          groupedMap[typeTraitement] = [];
        }
        groupedMap[typeTraitement]!.add(factureData);
      }

      return groupedMap;
    } catch (e) {
      logger.e('Erreur chargement factures groupées: $e');
      return {};
    }
  }

  /// Afficher le formulaire de réparation avec prix
  void _showRepairDialog({
    required Contrat contrat,
    required int traitementId,
    required String traitementName,
  }) {
    final prixController = TextEditingController();
    final referenceController = TextEditingController(
      text: 'REF-${DateTime.now().millisecondsSinceEpoch}',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🔧 Détails Réparation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Traitement: $traitementName'),
            const SizedBox(height: 16),
            TextField(
              controller: prixController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Prix (Ar)',
                hintText: '50000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: referenceController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Référence (auto-générée)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prixStr = prixController.text.trim();
              if (prixStr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Veuillez entrer un prix'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final prix = int.parse(prixStr);
                Navigator.of(ctx).pop();

                final count = await context
                    .read<FactureRepository>()
                    .regenerateFacturesForTraitement(
                      traitementId: traitementId,
                      montant: prix,
                      referencePrefix: referenceController.text,
                      deleteExisting: false,
                    );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ $count factures créées/restaurées'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _reloadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Réparer'),
          ),
        ],
      ),
    );
  }

  /// Voir le planning du contrat
  void _viewPlanning(Contrat contrat) {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<Client?>(
        future: _loadClientForContrat(contrat.clientId),
        builder: (context, clientSnapshot) {
          final clientName = clientSnapshot.data != null
              ? clientSnapshot.data!.fullName
              : 'Client';

          return AlertDialog(
            title: Text('📅 Planning pour $clientName'),
            content: SizedBox(
              width: 550,
              child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                future: _loadContratPlanningsByType(contrat.contratId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text('Erreur: ${snapshot.error}');
                  }

                  final groupedTreatments = snapshot.data ?? {};

                  if (groupedTreatments.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Aucun traitement trouvé'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: groupedTreatments.length,
                    itemBuilder: (context, index) {
                      final typeTraitement = groupedTreatments.keys.elementAt(
                        index,
                      );
                      final traitements =
                          groupedTreatments[typeTraitement] ?? [];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header du type de traitement
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  typeTraitement,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.blue[900],
                                  ),
                                ),
                                Text(
                                  '${traitements.length} traitement(s)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Liste des plannings OU message si orphelin
                          if (traitements.isNotEmpty &&
                              traitements.first['planning_detail_id'] == null)
                            // TRAITEMENT ORPHELIN: Afficher un message spécial
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                border: Border.all(
                                  color: Colors.orange[300]!,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_rounded,
                                    color: Colors.orange[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '⚠️ SANS PLANNING',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Colors.orange[900],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Ce traitement n\'a pas encore de planning ni de factures.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            // ✅ TRAITEMENT AVEC PLANNING: Afficher les dates
                            ...traitements.map((planning) {
                              final dateStr =
                                  planning['date_planification'] != null
                                  ? DateFormat(
                                      'EEEE dd MMMM yyyy',
                                      'fr_FR',
                                    ).format(
                                      planning['date_planification']
                                          as DateTime,
                                    )
                                  : 'Date N/A';
                              final parts = dateStr.split(' ');
                              if (parts.isNotEmpty) {
                                parts[0] =
                                    parts[0][0].toUpperCase() +
                                    parts[0].substring(1);
                              }
                              if (parts.length > 2) {
                                parts[2] =
                                    parts[2][0].toUpperCase() +
                                    parts[2].substring(1);
                              }
                              final capitalizedDate = parts.join(' ');

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 0.5,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            capitalizedDate,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          planning['etat'] ?? '-',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _getStatusColorForPlanning(
                                              planning['etat'] as String?,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Axe: ${planning['axe'] ?? '-'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          const SizedBox(height: 12),
                          // Boutons d'action
                          Row(
                            children: [
                              // Bouton Changer redondance
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Obtenir le premier traitementId du groupe pour cette modification
                                    final firstPlanning = traitements.isNotEmpty
                                        ? traitements.first
                                        : null;
                                    if (firstPlanning != null) {
                                      _showModifyRedondanceDialog(
                                        ctx,
                                        contrat.contratId,
                                        firstPlanning['traitementId'] as int,
                                        typeTraitement,
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Changer redondance'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[600],
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Bouton Réparer données
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final firstPlanning = traitements.isNotEmpty
                                      ? traitements.first
                                      : null;
                                  if (firstPlanning != null) {
                                    // Demander le montant avant réparation
                                    await _showRepairMontantDialog(
                                      firstPlanning['traitementId'] as int,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.build),
                                label: const Text('Réparer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[600],
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Charger les plannings groupés par type de traitement pour un contrat
  Future<Map<String, List<Map<String, dynamic>>>> _loadContratPlanningsByType(
    int contratId,
  ) async {
    try {
      final database = DatabaseService();
      const sql = '''
        SELECT DISTINCT 
          t.traitement_id, 
          t.contrat_id, 
          tt.typeTraitement,
          tt.categorieTraitement as type,
          pd.planning_detail_id,
          pd.date_planification,
          pd.statut as etat,
          p.planning_id,
          cl.axe
        FROM Traitement t
        INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
        INNER JOIN Contrat c ON t.contrat_id = c.contrat_id
        INNER JOIN Client cl ON c.client_id = cl.client_id
        LEFT JOIN Planning p ON p.traitement_id = t.traitement_id
        LEFT JOIN PlanningDetails pd ON pd.planning_id = p.planning_id
        WHERE c.contrat_id = ?
        ORDER BY tt.typeTraitement ASC, pd.date_planification ASC
      ''';

      final rows = await database.query(sql, [contratId]);

      final groupedMap = <String, List<Map<String, dynamic>>>{};
      final treatmentIds = <int>{}; // Tracker pour éviter les doublons

      for (final row in rows) {
        final typeTraitement =
            (row['typeTraitement'] as String?) ?? 'Sans type';
        final traitementId = row['traitement_id'] as int;

        // Créer une entry par planning_detail (pour chaque date)
        if (row['planning_detail_id'] != null) {
          final planningData = {
            'traitementId': traitementId,
            'contratId': row['contrat_id'] as int,
            'nom': typeTraitement,
            'type': row['type'] as String,
            'planning_detail_id': row['planning_detail_id'],
            'date_planification': row['date_planification'] is String
                ? DateTime.parse(row['date_planification'] as String)
                : row['date_planification'] as DateTime?,
            'axe': row['axe'] as String? ?? '-',
            'etat': row['etat'] as String? ?? '-',
          };

          if (!groupedMap.containsKey(typeTraitement)) {
            groupedMap[typeTraitement] = [];
          }
          groupedMap[typeTraitement]!.add(planningData);
        } else if (!treatmentIds.contains(traitementId)) {
          //  AJOUTER LES TRAITEMENTS ORPHELINS (sans planning)
          treatmentIds.add(traitementId);
          final planningData = {
            'traitementId': traitementId,
            'contratId': row['contrat_id'] as int,
            'nom': typeTraitement,
            'type': row['type'] as String,
            'planning_detail_id': null,
            'date_planification': null,
            'axe': row['axe'] as String? ?? '-',
            'etat': '⚠️ SANS PLANNING',
          };

          if (!groupedMap.containsKey(typeTraitement)) {
            groupedMap[typeTraitement] = [];
          }
          groupedMap[typeTraitement]!.add(planningData);
        }
      }

      return groupedMap;
    } catch (e) {
      logger.e('Erreur chargement plannings: $e');
      return {};
    }
  }

  /// Afficher un dialog pour modifier la redondance et régénérer les plannings
  /// OU créer un nouveau planning si absent
  Future<void> _showModifyRedondanceDialog(
    BuildContext ctx,
    int contratId,
    int traitementId,
    String typeTraitement,
  ) async {
    // Récupérer les informations du traitement existant
    final db = DatabaseService();
    const sql = '''
      SELECT 
        p.planning_id,
        p.traitement_id,
        p.duree_traitement,
        p.redondance,
        MIN(pd.date_planification) as first_date,
        COUNT(pd.planning_detail_id) as nb_details,
        GROUP_CONCAT(DISTINCT pd.planning_detail_id) as detail_ids,
        MAX(pd.date_planification) as last_date
      FROM Planning p
      LEFT JOIN PlanningDetails pd ON pd.planning_id = p.planning_id
      WHERE p.traitement_id = ?
      GROUP BY p.planning_id
      LIMIT 1
    ''';

    final result = await db.query(sql, [traitementId]);

    // SI PLANNING ABSENT: créer un nouveau
    if (result.isEmpty) {
      logger.i(
        '⚠️ Aucun planning trouvé pour traitement $traitementId, création...',
      );
      if (!mounted) return;
      _showCreatePlanningDialog(ctx, contratId, traitementId, typeTraitement);
      return;
    }

    // SINON: modifier le planning existant
    final currentData = result.first;
    final currentFirstDate = currentData['first_date'] != null
        ? (currentData['first_date'] is String
              ? DateTime.parse(currentData['first_date'] as String)
              : currentData['first_date'] as DateTime?)
        : null;

    // Récupérer la durée en MOIS depuis la table Planning, pas le nombre de détails
    final currentDuree = currentData['duree_traitement'] as int? ?? 12;
    final currentRedondance = currentData['redondance'] as int? ?? 1;

    String selectedRedondance = '1'; // Mensuel par défaut
    DateTime? selectedDate = currentFirstDate;

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

    // Afficher le dialog de modification
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('🔄 Modifier redondance - $typeTraitement'),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Redondance actuelle: ${_getRedondanceLabel(currentRedondance)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sélecteur de redondance
                  DropdownButtonFormField<String>(
                    value: selectedRedondance,
                    decoration: InputDecoration(
                      labelText: 'Nouvelle redondance',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    items: redondanceOptions
                        .map(
                          (opt) => DropdownMenuItem(
                            value: opt['value'] as String,
                            child: Text(opt['label'] as String),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedRedondance = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Sélecteur de date
                  Text(
                    'Date de début du planning:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate != null
                                ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                                : 'Sélectionner une date',
                            style: TextStyle(
                              color: selectedDate != null
                                  ? Colors.black
                                  : Colors.grey[500],
                            ),
                          ),
                          Icon(Icons.calendar_today, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Durée (à vérifier)
                  Text(
                    'Durée du traitement: ${(currentDuree / (int.tryParse(selectedRedondance) ?? 1)).ceil()} mois',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedDate == null) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez sélectionner une date'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  if (!mounted) return;
                  Navigator.pop(dialogCtx); // Fermer le dialog de modification

                  // Demander le montant avant régénération
                  if (!mounted) return;
                  _showMontantInputDialog(
                    context,
                    traitementId,
                    selectedDate!.toUtc(),
                    int.tryParse(selectedRedondance) ?? 1,
                    currentDuree,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                ),
                child: const Text('Régénérer'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Créer un nouveau planning pour un traitement sans planning
  Future<void> _showCreatePlanningDialog(
    BuildContext ctx,
    int contratId,
    int traitementId,
    String typeTraitement,
  ) async {
    final dateController = TextEditingController();
    final durationController = TextEditingController(text: '12');
    final montantController = TextEditingController();
    String selectedRedondance = '1'; // Mensuel par défaut

    final redondanceOptions = [
      {'label': 'Mensuel', 'value': '1'},
      {'label': 'Bimestriel', 'value': '2'},
      {'label': 'Trimestriel', 'value': '3'},
      {'label': 'Quadrimestriel', 'value': '4'},
      {'label': 'Semestriel', 'value': '6'},
      {'label': 'Annuel', 'value': '12'},
      {'label': 'Une seule fois', 'value': '0'},
    ];

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('📅 Créer un planning - $typeTraitement'),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ Ce traitement n\'a pas encore de planning. Créez-en un:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date début
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          dateController.text = DateFormat(
                            'dd/MM/yyyy',
                          ).format(date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateController.text.isNotEmpty
                                  ? dateController.text
                                  : 'Sélectionner date début',
                              style: TextStyle(
                                color: dateController.text.isNotEmpty
                                    ? Colors.black
                                    : Colors.grey[500],
                              ),
                            ),
                            Icon(Icons.calendar_today, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Durée en mois
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Durée du traitement',
                        hintText: 'Ex: 12',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixText: 'mois',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Redondance
                    DropdownButtonFormField<String>(
                      value: selectedRedondance,
                      decoration: InputDecoration(
                        labelText: 'Redondance',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      items: redondanceOptions
                          .map(
                            (opt) => DropdownMenuItem(
                              value: opt['value'] as String,
                              child: Text(opt['label'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedRedondance = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Montant
                    TextField(
                      controller: montantController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Montant unitaire',
                        hintText: 'Ex: 50000 ou 50 000',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixText: 'Ar',
                        helperText: 'Montant par planification',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validations
                  if (dateController.text.isEmpty) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez sélectionner une date'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  if (montantController.text.isEmpty) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez entrer un montant'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  try {
                    // Parser la date et le montant
                    final selectedDate = DateFormat(
                      'dd/MM/yyyy',
                    ).parse(dateController.text);
                    final duree = int.tryParse(durationController.text) ?? 12;
                    final redondance = int.tryParse(selectedRedondance) ?? 1;
                    final montant = NumberFormatter.parseMontant(
                      montantController.text,
                    );

                    if (!mounted) return;
                    Navigator.pop(dialogCtx);

                    // Créer le planning dans la base de données
                    await _createPlanningForTreatment(
                      traitementId: traitementId,
                      dateDebut: selectedDate,
                      duree: duree,
                      redondance: redondance,
                      montant: montant,
                      contratId: contratId,
                    );

                    // Recharger le planning
                    if (mounted) {
                      Navigator.pop(context);
                      _viewPlanning(
                        Contrat(
                          contratId: contratId,
                          clientId: 0,
                          referenceContrat: '',
                          dateContrat: DateTime.now(),
                          dateDebut: DateTime.now(),
                          dateFin: null,
                          statutContrat: '',
                          duree: null,
                          categorie: '',
                          dureeContrat: 0,
                        ),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                ),
                child: const Text('Créer'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Créer un planning complet (table Planning + PlanningDetails + Factures)
  Future<void> _createPlanningForTreatment({
    required int traitementId,
    required DateTime dateDebut,
    required int duree,
    required int redondance,
    required int montant,
    required int contratId,
  }) async {
    try {
      final db = DatabaseService();

      logger.i(
        '✨ Création planning: traitementId=$traitementId, duree=$duree, redondance=$redondance, montant=$montant',
      );

      // 1. Créer l'enregistrement Planning
      const sqlCreatePlanning = '''
        INSERT INTO Planning (
          traitement_id,
          date_debut_planification,
          duree_traitement,
          redondance,
          date_fin_planification
        ) VALUES (?, ?, ?, ?, DATE_ADD(?, INTERVAL ? MONTH))
      ''';

      final dateStr = dateDebut.toUtc().toString().split(' ')[0];
      await db.execute(sqlCreatePlanning, [
        traitementId,
        dateStr,
        duree,
        redondance,
        dateStr,
        duree,
      ]);

      // Récupérer l'ID du planning créé
      const sqlGetPlanningId =
          'SELECT planning_id FROM Planning WHERE traitement_id = ? LIMIT 1';
      final planningIdResult = await db.query(sqlGetPlanningId, [traitementId]);

      if (planningIdResult.isEmpty) {
        throw Exception('Impossible de récupérer l\'ID du planning créé');
      }

      final planningId = planningIdResult.first['planning_id'] as int;
      logger.i('✅ Planning créé: ID $planningId');

      // 2. Générer les dates
      final planningDates = DateUtils.DateUtils.generatePlanningDates(
        dateDebut: dateDebut,
        dureeTraitement: duree,
        redondance: redondance,
      );

      logger.i('📅 ${planningDates.length} dates générées');

      // 3. Créer les PlanningDetails
      int detailsCreated = 0;
      for (final date in planningDates) {
        const sqlInsertDetail = '''
          INSERT INTO PlanningDetails (planning_id, date_planification, statut)
          VALUES (?, ?, 'À venir')
        ''';
        final dateStr = date.toUtc().toString().split(' ')[0];
        await db.execute(sqlInsertDetail, [planningId, dateStr]);
        detailsCreated++;
      }

      logger.i('✅ $detailsCreated planning details créés');

      // 4. Récupérer l'axe du client
      String clientAxe = 'Centre (C)';
      const sqlGetAxe = '''
        SELECT COALESCE(cl.axe, 'Centre (C)') as axe
        FROM Contrat c
        INNER JOIN Client cl ON c.client_id = cl.client_id
        WHERE c.contrat_id = ?
      ''';
      try {
        final axeResult = await db.query(sqlGetAxe, [contratId]);
        if (axeResult.isNotEmpty) {
          clientAxe = axeResult.first['axe'] as String? ?? 'Centre (C)';
        }
      } catch (e) {
        logger.w('⚠️ Impossible de récupérer axe: $e');
      }

      // 5. Créer les Factures pour chaque PlanningDetail
      const sqlGetDetails = '''
        SELECT planning_detail_id FROM PlanningDetails WHERE planning_id = ?
      ''';
      final detailsResult = await db.query(sqlGetDetails, [planningId]);

      int facturesCreated = 0;
      for (final detail in detailsResult) {
        final planningDetailId = detail['planning_detail_id'] as int;
        const sqlInsertFacture = '''
          INSERT INTO Facture (
            planning_detail_id,
            reference_facture,
            montant,
            mode,
            date_traitement,
            etat,
            axe
          ) VALUES (?, ?, ?, NULL, NOW(), 'À venir', ?)
        ''';

        final reference = 'FAC-${DateTime.now().millisecondsSinceEpoch}';
        await db.execute(sqlInsertFacture, [
          planningDetailId,
          reference,
          montant,
          clientAxe,
        ]);
        facturesCreated++;
      }

      logger.i('✅ $facturesCreated factures créées');

      // 6. Recharger les données
      await context
          .read<PlanningDetailsRepository>()
          .loadAllTreatmentsComplete();
      await context.read<FactureRepository>().loadAllFactures();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✨ Planning créé! $detailsCreated dates, $facturesCreated factures.',
          ),
          backgroundColor: Colors.green[700],
        ),
      );

      logger.i('✅ Planning complètement créé');
    } catch (e) {
      logger.e('❌ Erreur création planning: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red[700]),
      );
    }
  }

  /// Afficher un dialog pour saisir le montant avant régénération
  Future<void> _showMontantInputDialog(
    BuildContext ctx,
    int traitementId,
    DateTime datePlanification,
    int redondance,
    int dureeTraitement,
  ) async {
    final montantController = TextEditingController();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('💰 Saisir le montant unitaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrez le montant unitaire (par planification)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: montantController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Montant',
                hintText: 'Ex: 50000 ou 1 500 000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: 'Ar',
                helperText: 'Les espaces sont ignorés',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final montantStr = montantController.text.trim();
              if (montantStr.isEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer un montant'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                // Parser le montant avec NumberFormatter (gère les espaces)
                final montant = NumberFormatter.parseMontant(montantStr);

                if (!mounted) return;
                Navigator.pop(dialogCtx); // Fermer le dialog de montant

                // Appeler la régénération avec le montant
                await _regeneratePlanningDetails(
                  traitementId,
                  datePlanification,
                  redondance,
                  dureeTraitement,
                  montant,
                );

                // Recharger le planning
                if (mounted) {
                  Navigator.pop(context); // Fermer le dialog de planning
                  _viewPlanning(
                    Contrat(
                      contratId: 0,
                      clientId: 0,
                      referenceContrat: '',
                      dateContrat: DateTime.now(),
                      dateDebut: DateTime.now(),
                      dateFin: null,
                      statutContrat: '',
                      duree: null,
                      categorie: '',
                      dureeContrat: 0,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
            child: const Text('Régénérer'),
          ),
        ],
      ),
    );
  }

  /// Régénérer les planning details et factures pour un traitement
  Future<void> _regeneratePlanningDetails(
    int traitementId,
    DateTime datePlanification,
    int redondance,
    int dureeTraitement,
    int montant, // Nouveau paramètre: montant saisi manuellement
  ) async {
    try {
      final db = DatabaseService();

      logger.i(
        '🔄 Régénération planning: traitementId=$traitementId, redondance=$redondance, duree=$dureeTraitement, montant=$montant',
      );

      // Récupérer le planning existant
      const sqlGetPlanning = '''
        SELECT planning_id FROM Planning WHERE traitement_id = ? LIMIT 1
      ''';
      final planningResult = await db.query(sqlGetPlanning, [traitementId]);

      if (planningResult.isEmpty) {
        logger.e('❌ Aucun planning trouvé pour traitementId $traitementId');
        return;
      }

      final planningId = planningResult.first['planning_id'] as int;

      // Mettre à jour la redondance et duree dans Planning
      const sqlUpdatePlanning = '''
        UPDATE Planning 
        SET redondance = ?, duree_traitement = ?, date_debut_planification = ?
        WHERE planning_id = ?
      ''';
      await db.execute(sqlUpdatePlanning, [
        redondance,
        dureeTraitement,
        datePlanification.toUtc().toString().split(' ')[0], // Format DATE
        planningId,
      ]);
      logger.i(
        '✅ Planning mis à jour: redondance=$redondance, duree=$dureeTraitement',
      );

      // Supprimer les planning details existants
      const sqlDeleteDetails =
          'DELETE FROM PlanningDetails WHERE planning_id = ?';
      await db.execute(sqlDeleteDetails, [planningId]);
      logger.i('✅ Planning details supprimés');

      // Supprimer les factures associées aux details supprimés
      const sqlDeleteFactures = '''
        DELETE FROM Facture WHERE planning_detail_id NOT IN (
          SELECT planning_detail_id FROM PlanningDetails
        )
      ''';
      await db.execute(sqlDeleteFactures);
      logger.i('✅ Factures orphelines supprimées');

      // Générer les nouvelles dates
      final planningDates = DateUtils.DateUtils.generatePlanningDates(
        dateDebut: datePlanification,
        dureeTraitement: dureeTraitement,
        redondance: redondance,
      );

      logger.i(
        '📅 ${planningDates.length} dates générées (redondance=$redondance, duree=$dureeTraitement mois)',
      );

      // Créer les nouveaux planning details
      int detailsCreated = 0;
      for (final date in planningDates) {
        const sqlInsertDetail = '''
          INSERT INTO PlanningDetails (planning_id, date_planification, statut)
          VALUES (?, ?, 'À venir')
        ''';
        // Convertir en UTC pour MySQL et formater en DATE
        final dateStr = date.toUtc().toString().split(' ')[0];
        await db.execute(sqlInsertDetail, [planningId, dateStr]);
        detailsCreated++;
      }

      logger.i('✅ $detailsCreated planning details créés');

      // Créer les factures pour chaque planning detail
      const sqlGetDetails = '''
        SELECT 
          pd.planning_detail_id,
          p.traitement_id,
          t.contrat_id
        FROM PlanningDetails pd
        INNER JOIN Planning p ON pd.planning_id = p.planning_id
        INNER JOIN Traitement t ON p.traitement_id = t.traitement_id
        WHERE p.planning_id = ?
      ''';

      final detailsResult = await db.query(sqlGetDetails, [planningId]);

      // Récupérer l'axe du client pour ce contrat
      String clientAxe = 'Centre (C)'; // Valeur par défaut
      if (detailsResult.isNotEmpty) {
        final contratId = detailsResult.first['contrat_id'] as int;
        const sqlGetAxe = '''
          SELECT COALESCE(cl.axe, 'Centre (C)') as axe
          FROM Contrat c
          INNER JOIN Client cl ON c.client_id = cl.client_id
          WHERE c.contrat_id = ?
        ''';
        try {
          final axeResult = await db.query(sqlGetAxe, [contratId]);
          if (axeResult.isNotEmpty) {
            clientAxe = axeResult.first['axe'] as String? ?? 'Centre (C)';
          }
        } catch (e) {
          logger.w('⚠️ Impossible de récupérer axe du client: $e');
        }
      }

      int facturesCreated = 0;
      for (final detail in detailsResult) {
        final planningDetailId = detail['planning_detail_id'] as int;

        // ✅ UTILISER LE MONTANT SAISI MANUELLEMENT
        const sqlInsertFacture = '''
          INSERT INTO Facture (
            planning_detail_id,
            reference_facture,
            montant,
            mode,
            date_traitement,
            etat,
            axe
          ) VALUES (?, ?, ?, NULL, NOW(), 'À venir', ?)
        ''';

        final reference = 'FAC-${DateTime.now().millisecondsSinceEpoch}';
        await db.execute(sqlInsertFacture, [
          planningDetailId,
          reference,
          montant, // ✅ Utiliser le montant passé en paramètre
          clientAxe,
        ]);
        facturesCreated++;
      }

      logger.i('✅ $facturesCreated factures créées avec montant=$montant Ar');

      // Recharger les données
      await context
          .read<PlanningDetailsRepository>()
          .loadAllTreatmentsComplete();
      await context.read<FactureRepository>().loadAllFactures();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Régénération complète! $detailsCreated dates, $facturesCreated factures.',
          ),
          backgroundColor: Colors.green[700],
        ),
      );
    } catch (e) {
      logger.e('❌ Erreur régénération: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red[700]),
      );
    }
  }

  /// Réparer les données de planning (régénère les détails et factures si manquants)
  Future<void> _showRepairMontantDialog(int traitementId) async {
    try {
      final db = DatabaseService();

      // Vérifier d'abord si la réparation est nécessaire
      const sqlCheckPlanning = '''
        SELECT 
          p.planning_id,
          p.duree_traitement,
          p.redondance,
          p.date_debut_planification,
          COUNT(pd.planning_detail_id) as nb_details
        FROM Planning p
        LEFT JOIN PlanningDetails pd ON pd.planning_id = p.planning_id
        WHERE p.traitement_id = ?
        GROUP BY p.planning_id
        LIMIT 1
      ''';

      final checkResult = await db.query(sqlCheckPlanning, [traitementId]);

      if (checkResult.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Aucun planning trouvé'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final planning = checkResult.first;
      final nbDetailsActuels = planning['nb_details'] as int? ?? 0;
      final duree = planning['duree_traitement'] as int? ?? 12;
      final redondance = planning['redondance'] as int? ?? 1;
      final dateDebut = planning['date_debut_planification'] != null
          ? (planning['date_debut_planification'] is String
                ? DateTime.parse(planning['date_debut_planification'] as String)
                : planning['date_debut_planification'] as DateTime)
          : DateTime.now();

      // Générer les dates attendues pour vérifier
      final expectedDates = DateUtils.DateUtils.generatePlanningDates(
        dateDebut: dateDebut,
        dureeTraitement: duree,
        redondance: redondance,
      );

      logger.i(
        '🔍 Vérification: $nbDetailsActuels details actuels vs ${expectedDates.length} attendus',
      );

      // Si les données sont déjà correctes, ne pas demander le montant
      if (nbDetailsActuels >= expectedDates.length) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '✅ Les données de planning sont intègres, aucune réparation nécessaire',
              ),
              backgroundColor: Colors.blue,
            ),
          );
        }
        return;
      }

      // Les données manquent, demander le montant
      final montantController = TextEditingController();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Montant unitaire pour réparation'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Détails manquants détectés: $nbDetailsActuels/${expectedDates.length}\nEntrez le montant unitaire:',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: montantController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '50 000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixText: '₦ ',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  final montantText = montantController.text.trim();
                  if (montantText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez entrer un montant'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  try {
                    final montant = NumberFormatter.parseMontant(montantText);
                    Navigator.of(context).pop();
                    _repairPlanningData(traitementId, montant);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Montant invalide: $e'),
                        backgroundColor: Colors.red[700],
                      ),
                    );
                  }
                },
                child: const Text('Réparer'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      logger.e('❌ Erreur vérification réparation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _repairPlanningData(int traitementId, int montant) async {
    try {
      final db = DatabaseService();

      logger.i(
        '🔧 Réparation des données de planning pour traitementId=$traitementId avec montant=$montant',
      );

      // Récupérer les infos du planning
      const sqlGetPlanning = '''
        SELECT 
          p.planning_id,
          p.traitement_id,
          p.date_debut_planification,
          p.duree_traitement,
          p.redondance,
          COUNT(pd.planning_detail_id) as nb_details
        FROM Planning p
        LEFT JOIN PlanningDetails pd ON pd.planning_id = p.planning_id
        WHERE p.traitement_id = ?
        GROUP BY p.planning_id
        LIMIT 1
      ''';

      final planningResult = await db.query(sqlGetPlanning, [traitementId]);

      if (planningResult.isEmpty) {
        logger.e('❌ Aucun planning trouvé');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Aucun planning trouvé pour ce traitement'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final planning = planningResult.first;
      final planningId = planning['planning_id'] as int;
      final dateDebut = planning['date_debut_planification'] != null
          ? (planning['date_debut_planification'] is String
                ? DateTime.parse(planning['date_debut_planification'] as String)
                : planning['date_debut_planification'] as DateTime)
          : DateTime.now();
      final duree = planning['duree_traitement'] as int? ?? 12;
      final redondance = planning['redondance'] as int? ?? 1;
      final nbDetailsActuels = planning['nb_details'] as int? ?? 0;

      logger.i(
        '📋 Planning actuel: $nbDetailsActuels details, duree=$duree, redondance=$redondance',
      );

      // Générer les dates attendues
      final expectedDates = DateUtils.DateUtils.generatePlanningDates(
        dateDebut: dateDebut,
        dureeTraitement: duree,
        redondance: redondance,
      );

      logger.i('📅 Dates attendues: ${expectedDates.length}');

      // Vérifier les détails manquants
      if (nbDetailsActuels < expectedDates.length) {
        logger.i(
          '⚠️ ${expectedDates.length - nbDetailsActuels} details manquants, régénération...',
        );

        // Récupérer les dates existantes
        const sqlGetExistingDates = '''
          SELECT date_planification FROM PlanningDetails 
          WHERE planning_id = ?
        ''';
        final existingResult = await db.query(sqlGetExistingDates, [
          planningId,
        ]);
        final existingDates = existingResult
            .map((r) => r['date_planification'] as String)
            .toSet();

        logger.i('✅ Dates existantes: ${existingDates.length}');

        // Créer les details manquants
        int detailsCreated = 0;
        for (final date in expectedDates) {
          final dateStr = date.toUtc().toString().split(' ')[0];
          if (!existingDates.contains(dateStr)) {
            const sqlInsertDetail = '''
              INSERT INTO PlanningDetails (planning_id, date_planification, statut)
              VALUES (?, ?, 'À venir')
            ''';
            await db.execute(sqlInsertDetail, [planningId, dateStr]);
            detailsCreated++;
          }
        }

        logger.i(
          '✅ $detailsCreated planning details créés lors de la réparation',
        );

        // Récupérer l'axe du client
        String clientAxe = 'Centre (C)';
        const sqlGetAxe = '''
          SELECT COALESCE(cl.axe, 'Centre (C)') as axe
          FROM Contrat c
          INNER JOIN Client cl ON c.client_id = cl.client_id
          WHERE c.contrat_id = (
            SELECT contrat_id FROM Traitement WHERE traitement_id = ?
          )
        ''';
        try {
          final axeResult = await db.query(sqlGetAxe, [traitementId]);
          if (axeResult.isNotEmpty) {
            clientAxe = axeResult.first['axe'] as String? ?? 'Centre (C)';
          }
        } catch (e) {
          logger.w('⚠️ Impossible de récupérer axe du client: $e');
        }

        // Créer les factures manquantes
        const sqlGetDetailsWithoutFacture = '''
          SELECT pd.planning_detail_id
          FROM PlanningDetails pd
          WHERE pd.planning_id = ? 
          AND pd.planning_detail_id NOT IN (
            SELECT planning_detail_id FROM Facture
          )
        ''';
        final detailsWithoutFacture = await db.query(
          sqlGetDetailsWithoutFacture,
          [planningId],
        );

        int facturesCreated = 0;
        for (final detail in detailsWithoutFacture) {
          final planningDetailId = detail['planning_detail_id'] as int;
          const sqlInsertFacture = '''
            INSERT INTO Facture (
              planning_detail_id,
              reference_facture,
              montant,
              mode,
              date_traitement,
              etat,
              axe
            ) VALUES (?, ?, ?, NULL, NOW(), 'À venir', ?)
          ''';
          final reference = 'FAC-${DateTime.now().millisecondsSinceEpoch}';
          await db.execute(sqlInsertFacture, [
            planningDetailId,
            reference,
            montant,
            clientAxe,
          ]);
          facturesCreated++;
        }

        logger.i('✅ $facturesCreated factures créées lors de la réparation');

        // Recharger les données
        await context
            .read<PlanningDetailsRepository>()
            .loadAllTreatmentsComplete();
        await context.read<FactureRepository>().loadAllFactures();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Réparation complète! $detailsCreated details et $facturesCreated factures créés avec montant $montant Ar.',
            ),
            backgroundColor: Colors.green[700],
          ),
        );
      } else {
        logger.i('ℹ️ Aucune réparation nécessaire - données cohérentes');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Les données sont intègres, aucune réparation nécessaire',
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }

      logger.i('✅ Réparation terminée');
    } catch (e) {
      logger.e('❌ Erreur réparation: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red[700]),
      );
    }
  }

  /// Charger le client par son ID
  Future<Client?> _loadClientForContrat(int clientId) async {
    try {
      final clientRepository = context.read<ClientRepository>();
      final db = DatabaseService();

      // Essayer de récupérer du repository
      final clients = clientRepository.clients;
      final client = clients.firstWhereOrNull((c) => c.clientId == clientId);
      if (client != null) {
        return client;
      }

      // Si pas trouvé, chercher en base de données
      const sql = '''
        SELECT 
          client_id, nom, prenom, email, telephone, adresse, 
          categorie, nif, stat, axe
        FROM Client
        WHERE client_id = ?
      ''';
      final rows = await db.query(sql, [clientId]);
      if (rows.isNotEmpty) {
        return Client.fromMap(rows[0]);
      }

      return null;
    } catch (e) {
      logger.e('Erreur chargement client: $e');
      return null;
    }
  }

  /// Déterminer la couleur de statut pour le planning
  Color _getStatusColorForPlanning(String? status) {
    if (status == null) return Colors.grey[600]!;
    final lowerStatus = status.toLowerCase();

    if (lowerStatus.contains('complété') ||
        lowerStatus.contains('done') ||
        lowerStatus.contains('terminé')) {
      return Colors.green[700]!;
    } else if (lowerStatus.contains('classé sans suite') ||
        lowerStatus.contains('cancelled') ||
        lowerStatus.contains('annulé')) {
      return Colors.red[700]!;
    } else {
      return Colors.orange[700]!;
    }
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
              // Fermer d'abord le dialog avec le dialog context
              Navigator.of(ctx).pop();
              try {
                await context.read<ContratRepository>().deleteContrat(
                  contrat.contratId,
                );
                if (!mounted) return;
                // Recharger la liste sans essayer de pop
                setState(() {
                  _contratsWithClientsAndTreatments =
                      _fetchContratsWithDetails();
                });
                // Recharger la liste des clients pour recalculer le treatment_count
                await context.read<ClientRepository>().loadClients();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Contrat supprimé avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
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

  /// Afficher le dialogue d'abrogation/résiliation de contrat
  void _showAbrogationDialog(Contrat contrat) {
    DateTime? selectedDate = DateTime.now();
    String motif = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('⚠️ Abroger/Résilier le Contrat'),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contrat: ${contrat.referenceContrat}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '⚠️ ATTENTION : Cette action marquera tous les traitements futurs '
                    'comme "Classé sans suite" et ne peut pas être annulée.',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Date d\'abrogation :'),
                  const SizedBox(height: 8),
                  // Sélecteur de date
                  GestureDetector(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: contrat.dateDebut,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                            : 'Sélectionner une date',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Motif de l\'abrogation (optionnel) :'),
                  const SizedBox(height: 8),
                  TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Raison de la résiliation...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      motif = value;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                if (selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez sélectionner une date'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                Navigator.of(ctx).pop();
                try {
                  final success = await context
                      .read<ContratRepository>()
                      .abrogateContract(
                        contratId: contrat.contratId,
                        abrogationDate: selectedDate!,
                        motif: motif.isNotEmpty ? motif : null,
                      );

                  if (!mounted) return;

                  if (success) {
                    setState(() {
                      _contratsWithClientsAndTreatments =
                          _fetchContratsWithDetails();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ Contrat ${contrat.referenceContrat} résilié '
                          'à partir du ${DateFormat('dd/MM/yyyy').format(selectedDate!)}',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '❌ Erreur lors de la résiliation du contrat',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                '✓ Confirmer l\'abrogation',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _buildMainContent(),
                ),
              ),
            ),
          ),
          // Boutons de navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                if (_mainStep > 0 || _treatmentSubStep > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: const Size(0, 40),
                      ),
                      onPressed: () => _previousStep(),
                      child: const Text('Précédent'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 40),
                    ),
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
        (planning['moisDebut'] as String).isEmpty) {
      return false;
    }
    if ((planning['moisFin'] as String?) == null ||
        (planning['moisFin'] as String).isEmpty) {
      return false;
    }

    // Vérifier que la durée du traitement est remplie
    if ((planning['dureeTraitement'] as String?) == null ||
        (planning['dureeTraitement'] as String).isEmpty) {
      return false;
    }

    // Vérifier que la redondance (fréquence) est sélectionnée
    if ((planning['redondance'] as String?) == null ||
        (planning['redondance'] as String).isEmpty) {
      return false;
    }

    return true;
  }

  bool _validateFactureData() {
    final treatmentId = _getCurrentTreatmentId();
    final facture = _treatmentFactures[treatmentId];
    if (facture == null) return false;

    // Vérifier que le montant est rempli et valide
    final montantStr = (facture['montant'] as String?) ?? '';
    if (montantStr.isEmpty) return false;
    if (!NumberFormatter.isValidMontant(montantStr)) return false;

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

    // Utiliser NumberFormatter pour parser les montants avec espaces (ex: "50 000")
    try {
      final montant = NumberFormatter.parseMontant(montantStr);
      final nombrePlanifications = _calculateNumberOfPlannings(treatmentId);
      return montant * nombrePlanifications;
    } catch (e) {
      logger.e('Erreur parsing montant: $montantStr - $e');
      return 0;
    }
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
    final needsNifStat = isSociete;

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
              onChanged: (_) => setState(() {}),
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
                onChanged: (_) => setState(() {}),
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
                onChanged: (_) => setState(() {}),
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
              onChanged: (_) => setState(() {}),
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
              onChanged: (_) => setState(() {}),
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
              onChanged: (_) => setState(() {}),
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
              initialValue:
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

            // NIF et STAT (pour Société uniquement)
            if (needsNifStat) ...[
              TextField(
                controller: _clientNif,
                onChanged: (_) => setState(() {}),
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
                onChanged: (_) => setState(() {}),
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
        'datePlanification': DateFormat('dd/MM/yyyy')
            .parse(_dateDebut.text)
            .toIso8601String(), // Date de planification (par défaut = date de début du contrat)
        'moisDebut': 'Janvier $anneeDebut',
        'moisFin': _isDeterminee ? 'Décembre $anneeDebut' : 'Indéterminée',
        'dureeTraitement': dureeDefaut,
        'redondance': '1', // Défaut: mensuel
      };
    } else {
      // S'assurer que les clés existent (au cas où on charge depuis le cache)
      final planning = _treatmentPlanning[treatmentId]!;
      if (!planning.containsKey('datePlanification')) {
        planning['datePlanification'] = DateFormat(
          'dd/MM/yyyy',
        ).parse(_dateDebut.text).toIso8601String();
      }
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
      if (!planning.containsKey('dureeTraitement')) {
        planning['dureeTraitement'] = '12';
      }
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
                                  // Pour 12 mois: ajouter 11 mois (janvier + 11 = décembre)
                                  moisFin = picked.month + 11;
                                  anneeFin = picked.year;
                                  if (moisFin > 12) {
                                    moisFin -= 12;
                                    anneeFin += 1;
                                  }
                                }
                                planning['moisFin'] =
                                    '${moisNoms[moisFin - 1]} $anneeFin';

                                // Calculer la durée du traitement
                                if (_isDeterminee && _dateFin.text.isNotEmpty) {
                                  try {
                                    final dateFin = DateFormat(
                                      'dd/MM/yyyy',
                                    ).parse(_dateFin.text);
                                    // Durée = nombre de mois complets
                                    // Janvier à décembre = 12 mois, donc durée = 12
                                    // dateFin.month - picked.month = 12 - 1 = 11
                                    // Donc: ajouter 1 pour obtenir la durée totale en mois
                                    int duree =
                                        dateFin.month - picked.month + 1;
                                    if (duree <= 0) duree += 12;
                                    planning['dureeTraitement'] = duree
                                        .toString();
                                  } catch (e) {
                                    planning['dureeTraitement'] = '12';
                                  }
                                } else {
                                  planning['dureeTraitement'] = '12';
                                }
                                _saveProgress();
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
              initialValue: (planning['redondance'] as String?) ?? '1',
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
                _saveProgress();
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
            // Montant (champ éditable) - Accepte les espaces comme séparateurs
            TextField(
              controller: montantController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  // Stocker la valeur brute (avec espaces si l'utilisateur les ajoute)
                  facture['montant'] = value;
                });
                _saveProgress();
              },
              decoration: InputDecoration(
                labelText: 'Montant unitaire',
                hintText: 'Ex: 50 000 ou 1500000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: 'Ar',
                helperText:
                    'Montant en Ariary par planification (espaces autorisés)',
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
                        '${NumberFormatter.formatMontant(NumberFormatter.parseMontant((facture['montant'] as String?) ?? '0'))} Ar',
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
            _DetailRow('Numéro contrat', _numeroContrat.text),
            _DetailRow('Date contrat', _dateContrat.text),
            _DetailRow('Date début', _dateDebut.text),
            _DetailRow('Date fin', _dateFin.text),
            _DetailRow('Catégorie', _categorie.text),
            const SizedBox(height: 16),
            // Infos client
            _buildSectionHeader('Informations client'),
            _DetailRow('Catégorie', _clientCategorie.text),
            _DetailRow('Nom', _clientNom.text),
            if (_clientPrenom.text.isNotEmpty) ...[
              _DetailRow(
                _clientCategorie.text == 'Société' ||
                        _clientCategorie.text == 'Organisation'
                    ? 'Responsable'
                    : 'Prénom',
                _clientPrenom.text,
              ),
            ],
            _DetailRow('Email', _clientEmail.text),
            _DetailRow('Téléphone', _clientTelephone.text),
            _DetailRow('Adresse', _clientAdresse.text),
            _DetailRow(
              'Axe',
              _clientAxe.text.isNotEmpty ? _clientAxe.text : 'Centre (C)',
            ),
            if (_clientNif.text.isNotEmpty) _DetailRow('NIF', _clientNif.text),
            if (_clientStat.text.isNotEmpty)
              _DetailRow('STAT', _clientStat.text),
            const SizedBox(height: 16),
            // Traitements avec planning et facture
            _buildSectionHeader(
              'Traitements planifiés (${_selectedTreatments.length})',
            ),
            ..._buildTreatmentResumes(),
            const SizedBox(height: 20),
            // Statistiques
            _buildSectionHeader('Statistiques par traitement'),
            ..._buildTreatmentStatistics(),
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
    // Utiliser les vrais traitements chargés depuis la DB au lieu d'une liste en dur
    return _selectedTreatments.asMap().entries.map((entry) {
      final idx = entry.key;
      final treatmentId = entry.value;

      // Chercher le traitement réel dans la liste
      final treatmentFound = _allTreatments.firstWhereOrNull(
        (t) => t.id == treatmentId,
      );
      if (treatmentFound == null) {
        // Si le traitement n'est pas trouvé, ignorer cette entrée
        return const SizedBox.shrink();
      }

      // Utiliser les propriétés réelles du TypeTraitement
      final treatmentName = treatmentFound.displayName;
      final planning = _treatmentPlanning[treatmentId] ?? {};
      final facture = _treatmentFactures[treatmentId] ?? {};

      // Calculs
      final nombrePlanifications = _calculateNumberOfPlannings(treatmentId);
      // Utiliser NumberFormatter pour parser les montants avec espaces
      int montantUnitaire = 0;
      try {
        montantUnitaire = NumberFormatter.parseMontant(
          (facture['montant'] as String?) ?? '0',
        );
      } catch (e) {
        montantUnitaire = 0;
      }
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
                  // Déterminer si c'est une seule fois
                  Builder(
                    builder: (context) {
                      final redondance =
                          int.tryParse(
                            planning['redondance']?.toString() ?? '1',
                          ) ??
                          1;
                      final isOnceOnly = redondance == 0;

                      if (isOnceOnly) {
                        // Une seule fois : afficher juste la date de planification
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailRow(
                              'Date de planification',
                              _formatPlanningDate(
                                planning['datePlanification'],
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Récurrent : afficher première et dernière date + durée et redondance
                        final dateDebut = planning['datePlanification'];
                        final dureeTraitement =
                            int.tryParse(
                              planning['dureeTraitement']?.toString() ?? '12',
                            ) ??
                            12;
                        final dateFin = _calculateLastPlanningDate(
                          dateDebut,
                          dureeTraitement,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailRow(
                              'Première date de planning',
                              _formatPlanningDate(dateDebut),
                            ),
                            _DetailRow(
                              'Dernière date de traitement',
                              _formatPlanningDate(dateFin),
                            ),
                            const SizedBox(height: 8),
                            _DetailRow(
                              'Durée du traitement',
                              '${planning['dureeTraitement']?.toString() ?? '-'} mois',
                            ),
                            _DetailRow(
                              'Redondance',
                              _getRedondanceLabel(redondance),
                            ),
                          ],
                        );
                      }
                    },
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
      childAspectRatio: 4.5,
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

      // Si c'est la date de début et que c'est "Déterminée", calculer automatiquement la date fin
      if (controller == _dateDebut && _isDeterminee) {
        // Ajouter le nombre de mois (12 par défaut, ou selon _duree si modifiable)
        final dureeEnMois = int.tryParse(_duree.text) ?? 12;
        // Ajouter (dureeEnMois - 1) mois à la date de début
        // Car le mois 1 = date de début, donc pour 12 mois, on ajoute 11 mois
        final dateFin = _addMonthsToDate(date, dureeEnMois - 1);
        _dateFin.text = DateFormat('dd/MM/yyyy').format(dateFin);
      }
    }
  }

  /// Ajouter des mois à une date
  DateTime _addMonthsToDate(DateTime date, int months) {
    final month = date.month - 1 + months;
    final year = date.year + (month ~/ 12);
    final newMonth = (month % 12) + 1;

    // Gérer le dernier jour du mois
    final daysInMonth = DateTime(year, newMonth + 1, 0).day;
    final day = date.day > daysInMonth ? daysInMonth : date.day;

    return DateTime(year, newMonth, day);
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
          _clientAdresse.text.isEmpty ||
          _clientAxe.text.isEmpty) {
        return false;
      }
      // Vérifier prénom pour particulier
      if (_clientCategorie.text == 'Particulier' &&
          _clientPrenom.text.isEmpty) {
        return false;
      }
      // Vérifier NIF et STAT pour Société uniquement
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

      logger.i(
        '🔧 Création des traitements et planifications pour contrat $contratId',
      );
      logger.i('   Traitements sélectionnés: ${_selectedTreatments.length}');
      logger.i('   Planning map size: ${_treatmentPlanning.length}');
      logger.i('   Facture map size: ${_treatmentFactures.length}');

      if (_treatmentPlanning.isNotEmpty) {
        logger.i('   Planning keys: ${_treatmentPlanning.keys.toList()}');
      }
      if (_treatmentFactures.isNotEmpty) {
        logger.i('   Facture keys: ${_treatmentFactures.keys.toList()}');
      }

      // ✅ Charger l'axe du client pour l'utiliser dans les factures
      String? clientAxe;
      try {
        final clientRepo = context.read<ClientRepository>();
        final clientIndex = clientRepo.clients.indexWhere(
          (c) => c.clientId == clientId,
        );
        if (clientIndex != -1) {
          clientAxe = clientRepo.clients[clientIndex].axe;
          logger.i('   ✅ Axe du client: $clientAxe');
        }
      } catch (e) {
        logger.e('   ⚠️ Erreur récupération axe client: $e');
      }

      for (final typeTraitementId in _selectedTreatments) {
        logger.i('  → Traitement type ID: $typeTraitementId');

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

        logger.i('    ✅ Traitement créé: ID $createdTraitementId');

        traitementMap[typeTraitementId] = createdTraitementId;

        final planningData = _treatmentPlanning[typeTraitementId];
        final factureData = _treatmentFactures[typeTraitementId];

        logger.i(
          '    Planning data: ${planningData != null ? "✅ Présentes" : "❌ MANQUANTES"}',
        );
        logger.i(
          '    Facture data: ${factureData != null ? "✅ Présentes" : "❌ MANQUANTES"}',
        );

        // ✅ DEBUG: Afficher le contenu de factureData
        if (factureData != null) {
          logger.i('    Facture content: $factureData');
          logger.i('    Montant value: ${factureData['montant']}');
        }

        // ✅ VALIDATION: Si données manquantes, skip ce traitement
        if (planningData == null) {
          logger.e(
            '    ❌ SKIP: Planning data manquantes pour traitement $typeTraitementId',
          );
          continue;
        }
        if (factureData == null) {
          logger.e(
            '    ❌ SKIP: Facture data manquantes pour traitement $typeTraitementId',
          );
          continue;
        }

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

        logger.i(
          '    📅 Params planning: mois=$moisDebut, duree=$dureeTraitement, redondance=$redondance',
        );

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
          logger.i('    ✅ Planning créé: ID $planningId');

          // ✅ Utiliser la date de planification sélectionnée par l'utilisateur!
          logger.i('    🔍 DEBUG planningData: $planningData');
          logger.i(
            '    🔍 datePlanification type: ${planningData['datePlanification'].runtimeType}',
          );
          logger.i(
            '    🔍 datePlanification value: ${planningData['datePlanification']}',
          );

          final datePlanificationSelected =
              planningData['datePlanification'] is DateTime
              ? planningData['datePlanification'] as DateTime
              : planningData['datePlanification'] is String &&
                    (planningData['datePlanification'] as String).isNotEmpty
              ? DateTime.parse(planningData['datePlanification'] as String)
              : DateTime.now();

          logger.i(
            '    📅 Date de planification sélectionnée: ${datePlanificationSelected.day}/${datePlanificationSelected.month}/${datePlanificationSelected.year}',
          );

          // Générer les dates du planning automatiquement
          final planningDates = DateUtils.DateUtils.generatePlanningDates(
            dateDebut: datePlanificationSelected,
            dureeTraitement: dureeTraitement,
            redondance: redondance,
          );

          logger.i(
            '    📅 ${planningDates.length} dates générées (à partir du ${datePlanificationSelected.day}/${datePlanificationSelected.month}/${datePlanificationSelected.year})',
          );

          if (planningDates.isEmpty) {
            logger.w('    ⚠️ AUCUNE DATE GÉNÉRÉE! Vérifier les paramètres!');
            logger.i(
              '    dureeTraitement=$dureeTraitement, redondance=$redondance',
            );
            continue; // ✅ Skip ce traitement si aucune date
          }

          // Créer un PlanningDetail pour chaque date générée
          // + UNE Facture pour chaque PlanningDetail
          for (final date in planningDates) {
            logger.i('      📍 Création planning detail pour date: $date');

            final planningDetail = await context
                .read<PlanningDetailsRepository>()
                .createPlanningDetails(planningId, date, statut: 'À venir');

            logger.i(
              '      🔍 Planning detail null? ${planningDetail == null}',
            );

            if (planningDetail != null) {
              logger.i(
                '        ✅ PlanningDetail créé: ID ${planningDetail.planningDetailId}',
              );
              // Créer une facture pour ce PlanningDetail
              // Référence facture: vide, sera remplie manuellement lors de l'ajout de remarque
              final montantStr = (factureData['montant'] as String?) ?? '';
              logger.i('        💰 Montant brut: "$montantStr"');

              int montant = 0;
              if (montantStr.isNotEmpty) {
                try {
                  // Utiliser NumberFormatter pour parser les montants avec espaces
                  montant = NumberFormatter.parseMontant(montantStr);
                  logger.i('✅ Montant parsé: $montant Ar');
                } catch (e) {
                  logger.e('❌ Erreur parsing montant: $montantStr - $e');
                  montant = 0;
                }
              } else {
                logger.i('⚠️ Montant vide, utilisation de 0 Ar');
              }

              try {
                final factureId = await context
                    .read<FactureRepository>()
                    .createFactureComplete(
                      planningDetailId: planningDetail.planningDetailId,
                      referenceFacture: '', // Vide - sera rempli manuellement
                      montant: montant,
                      mode:
                          null, // Mode à définir plus tard (pas de valeur par défaut)
                      etat: 'À venir',
                      axe: clientAxe,
                      dateTraitement: date,
                    );

                if (factureId != -1) {
                  facturesCreated++;
                  logger.i(
                    '      ✅ Facture créée: ID $factureId, montant: $montant Ar',
                  );
                } else {
                  logger.e(
                    '❌ Erreur lors de la création facture pour planning_detail ${planningDetail.planningDetailId}',
                  );
                }
              } catch (e) {
                logger.e('❌ Exception création facture: $e');
              }
            }
          }
        } else {
          logger.e(
            '❌ Erreur création planning pour traitement $createdTraitementId',
          );
        }
      }

      if (!mounted) return;

      // Nettoyer les données sauvegardées après succès
      await _clearSavedProgress();
      await context.read<ContratRepository>().loadContrats();
      await context.read<ClientRepository>().loadClients();
      await context
          .read<PlanningDetailsRepository>()
          .loadAllTreatmentsComplete();
      await context.read<FactureRepository>().loadAllFactures();

      Navigator.pop(context);

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Contrat créé! $planningsCreated planning(s) + $facturesCreated facture(s).',
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 4),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        // La Future a été exécutée et les données sont en cache
        // Le FutureBuilder va utiliser le cache mis en place par loadContrats()
      }
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

  /// Convertir la valeur de redondance en label lisible
  String _getRedondanceLabel(int redondance) {
    switch (redondance) {
      case 0:
        return 'Une seule fois';
      case 1:
        return 'Mensuel (1 mois)';
      case 2:
        return 'Bimestriel (2 mois)';
      case 3:
        return 'Trimestriel (3 mois)';
      case 4:
        return 'Quadrimestriel (4 mois)';
      case 6:
        return 'Semestriel (6 mois)';
      case 12:
        return 'Annuel (12 mois)';
      default:
        return 'Tous les $redondance mois';
    }
  }

  /// Formater la date de planning pour l'affichage
  String _formatPlanningDate(dynamic dateValue) {
    try {
      // Validation et conversion de type sécurisée
      if (dateValue == null) {
        return '-';
      }

      DateTime? date;
      if (dateValue is DateTime) {
        date = dateValue;
      } else if (dateValue is String && dateValue.isNotEmpty) {
        // Gérer les formats MySQL (DATE et DATETIME)
        try {
          date = dateValue.contains('T')
              ? DateTime.parse(dateValue)
              : DateTime.parse('${dateValue}T00:00:00');
        } catch (parseError) {
          return '-';
        }
      }

      // Validation de la date parsée
      if (date == null || date.year < 1900 || date.year > 2100) {
        return '-';
      }

      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return '-';
    }
  }

  /// Calculer la dernière date de planning en fonction de la durée
  DateTime _calculateLastPlanningDate(dynamic dateValue, int dureeTraitement) {
    try {
      // Validation et conversion de type sécurisée
      if (dateValue == null || dureeTraitement <= 0) {
        return DateTime.now();
      }

      DateTime? startDate;
      if (dateValue is DateTime) {
        startDate = dateValue;
      } else if (dateValue is String && dateValue.isNotEmpty) {
        try {
          startDate = dateValue.contains('T')
              ? DateTime.parse(dateValue)
              : DateTime.parse('${dateValue}T00:00:00');
        } catch (parseError) {
          return DateTime.now();
        }
      }

      // Vérifier la validité de startDate
      if (startDate == null || startDate.year < 1900 || startDate.year > 2100) {
        return DateTime.now();
      }

      // Ajouter (dureeTraitement - 1) mois pour obtenir la dernière date
      // Car janvier + 12 mois = décembre (pas janvier 2027)
      final month = startDate.month - 1 + (dureeTraitement - 1);
      final year = startDate.year + (month ~/ 12);
      final newMonth = (month % 12) + 1;

      // Gestion sécurisée du dernier jour du mois
      final daysInMonth = DateTime(year, newMonth + 1, 0).day;
      final day = startDate.day > daysInMonth ? daysInMonth : startDate.day;

      // Validation finale
      final result = DateTime(year, newMonth, day);
      if (result.year < 1900 || result.year > 2100) {
        return DateTime.now();
      }

      return result;
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Construire les statistiques pour chaque traitement
  List<Widget> _buildTreatmentStatistics() {
    return _selectedTreatments.asMap().entries.map((entry) {
      final idx = entry.key;
      final treatmentId = entry.value;

      // Chercher le traitement réel dans la liste
      final treatmentFound = _allTreatments.firstWhereOrNull(
        (t) => t.id == treatmentId,
      );
      if (treatmentFound == null) {
        return const SizedBox.shrink();
      }

      final treatmentName = treatmentFound.displayName;
      final facture = _treatmentFactures[treatmentId] ?? {};
      final nombrePlanifications = _calculateNumberOfPlannings(treatmentId);

      // Obtenir la redondance pour ce traitement
      final planning = _treatmentPlanning[treatmentId];
      final redondanceValue =
          (planning?['redondance'] as String?)?.split(' ')[0] ?? '1';
      final redondanceLabel = _getRedondanceLabel(
        int.tryParse(redondanceValue) ?? 1,
      );

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
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
              '${idx + 1}. $treatmentName',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _DetailRow('Planifications', '$nombrePlanifications prévues'),
            _DetailRow('Redondance', redondanceLabel), //  Ajouter la redondance
            _DetailRow(
              'Factures',
              '${facture['reference']?.toString() != null ? 'Oui' : 'À créer'}',
            ),
            _DetailRow('Remarques', 'À vérifier'),
            _DetailRow('Historiques', 'À charger'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Détails:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  _DetailRow('Type traitement', treatmentFound.type),
                  _DetailRow('Catégorie', treatmentFound.categorie),
                  _DetailRow(
                    'Coût total',
                    '${_calculateTotalCost(treatmentId)} MGA',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
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
