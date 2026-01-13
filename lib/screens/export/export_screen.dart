import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../repositories/index.dart';
import '../../models/index.dart';
import '../../utils/excel_utils.dart';
import '../../services/database_service.dart';

final logger = Logger();

class ExportScreen extends StatefulWidget {
  const ExportScreen({Key? key}) : super(key: key);

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isExporting = false;
  bool _isLoadingClients = true;
  String? _lastExportPath;
  final ExcelService _excelService = ExcelService();

  // Dropdowns
  String _selectedCategory = 'Facture';
  String _selectedTraitement = 'Tous';
  String _selectedMois = 'Tous';
  String _selectedClient = 'Tous';

  // Options pour les dropdowns
  final List<String> _categories = ['Facture', 'Traitement'];
  List<String> _traitements = ['Tous'];
  Map<String, String> _traitementMap = {
    'Tous': 'Tous',
  }; // Map affichage -> valeur DB
  final List<String> _mois = [
    'Tous',
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
  List<String> _clients = ['Tous'];
  Map<String, int> _clientMap = {'Tous': -1}; // Map nom -> client_id

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClients();
      // Charger les traitements au démarrage (pour "Tous" = tous les clients)
      _loadTreatmentsForClient(-1); // -1 = Tous
    });
  }

  Future<void> _loadClients() async {
    try {
      final db = DatabaseService();

      // Charger DIRECTEMENT tous les clients depuis la base de données
      const sql = '''
        SELECT client_id, nom, prenom, categorie
        FROM Client
        ORDER BY nom ASC
      ''';

      logger.i('📥 Chargement des clients depuis la DB...');
      final rows = await db.query(sql);
      logger.i('📦 ${rows.length} clients trouvés en DB');

      final clientMap = <String, int>{'Tous': -1};
      final clientList = ['Tous'];

      for (final row in rows) {
        final clientId = row['client_id'] as int;
        final nom = row['nom'] as String;
        final prenom = row['prenom'] as String;
        final categorie = row['categorie'] as String;

        // Construire le fullName selon la catégorie
        final fullName = (categorie == 'Société' || categorie == 'Organisation')
            ? nom
            : '$prenom $nom'.trim();

        clientMap[fullName] = clientId;
        clientList.add(fullName);
        logger.i('✅ Client ajouté: $fullName (ID: $clientId, Cat: $categorie)');
      }

      if (mounted) {
        setState(() {
          _clients = clientList;
          _clientMap = clientMap;
          _isLoadingClients = false;
          logger.i(
            '✅ ${clientList.length - 1} clients affichables (total: ${clientList.length} avec Tous)',
          );
        });
      }
    } catch (e) {
      logger.e('❌ Erreur lors du chargement des clients: $e');
      if (mounted) {
        setState(() => _isLoadingClients = false);
      }
    }
  }

  Future<void> _loadTreatmentsForClient(int clientId) async {
    try {
      final planningRepo = context.read<PlanningDetailsRepository>();

      // Charger les traitements pour le client sélectionné
      final treatmentList = await planningRepo.getTreatmentTypesForClient(
        clientId,
      );

      final traitementMap = <String, String>{'Tous': 'Tous'};
      final treatments = ['Tous'];

      for (final treatment in treatmentList) {
        // Éviter les doublons (ne pas ajouter "Tous" si déjà présent)
        if (treatment != 'Tous' && !treatments.contains(treatment)) {
          traitementMap[treatment] = treatment;
          treatments.add(treatment);
        }
      }

      if (mounted) {
        setState(() {
          _traitements = treatments;
          _traitementMap = traitementMap;
          _selectedTraitement = 'Tous';
          final clientName = clientId == -1
              ? 'tous les clients'
              : _selectedClient;
          logger.i('✅ ${treatments.length - 1} traitements pour $clientName');
        });
      }
    } catch (e) {
      logger.e('❌ Erreur lors du chargement des traitements: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Titre principal
                Text(
                  'Rendu en format EXCEL',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                // Catégorie
                _buildDropdownRow(
                  label: 'Catégorie',
                  value: _selectedCategory,
                  items: _categories,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      // Si Facture: forcer Tous les mois
                      if (value == 'Facture') {
                        _selectedMois = 'Tous';
                      }
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Traitement (visible seulement si catégorie = Traitement)
                if (_selectedCategory == 'Traitement') ...[
                  _buildDropdownRow(
                    label: 'Traitement',
                    value: _selectedTraitement,
                    items: _traitements,
                    onChanged: (value) {
                      setState(() {
                        _selectedTraitement = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Mois (désactivé pour Facture, obligatoirement "Tous")
                if (_selectedCategory == 'Traitement')
                  _buildDropdownRow(
                    label: 'Mois',
                    value: _selectedMois,
                    items: _mois,
                    onChanged: (value) {
                      setState(() {
                        _selectedMois = value;
                      });
                    },
                  )
                else
                  _buildDisabledDropdownRow(
                    label: 'Mois',
                    value: 'Tous',
                    reason: 'Tous les mois (export Facture)',
                  ),
                const SizedBox(height: 24),

                // Client
                _isLoadingClients
                    ? Row(
                        children: [
                          Text(
                            'Client',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              height: 56,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[400]!),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[100],
                              ),
                              child: const Align(
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : _buildDropdownRow(
                        label: 'Client',
                        value: _selectedClient,
                        items: _clients,
                        onChanged: (value) {
                          setState(() {
                            _selectedClient = value;
                            // Les traitements sont chargés une fois au démarrage
                            // Pas besoin de les recharger quand on change de client
                          });
                        },
                      ),
                const SizedBox(height: 40),

                // Question et boutons
                Text(
                  'Voulez-vous générer un rendu?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // Boutons Générer, Actualiser et Annuler
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[400],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                      ),
                      onPressed: _isExporting
                          ? null
                          : () => _generererExcel(context),
                      child: _isExporting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.green[700]!,
                                ),
                              ),
                            )
                          : const Text(
                              'Générer',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[400],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                      ),
                      onPressed: _isExporting
                          ? null
                          : () => _actualiserDonnees(),
                      child: const Text(
                        'Actualiser',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                      ),
                      onPressed: () => _reinitialiserSelections(),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),

                // Affichage du statut d'export
                if (_lastExportPath != null) ...[
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      border: Border.all(color: Colors.green[300]!, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[700],
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Export réussi !',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Fichier sauvegardé:',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          _lastExportPath!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: DropdownButton<String>(
              value: value,
              underline: const SizedBox(),
              isExpanded: true,
              isDense: false,
              itemHeight: 56,
              menuMaxHeight: 400,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisabledDropdownRow({
    required String label,
    required String value,
    required String reason,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: reason,
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _actualiserDonnees() async {
    setState(() {
      _isLoadingClients = true;
      _selectedClient = 'Tous';
      _selectedTraitement = 'Tous';
      _selectedMois = 'Tous';
      _selectedCategory = 'Facture';
    });

    // Recharger les clients
    await _loadClients();

    // Recharger les traitements (pour "Tous")
    await _loadTreatmentsForClient(-1);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Données actualisées'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }

    logger.i('🔄 Actualisation complète des données');
  }

  Future<void> _generererExcel(BuildContext context) async {
    setState(() => _isExporting = true);

    try {
      if (_selectedCategory == 'Facture') {
        final clientId = _clientMap[_selectedClient] ?? -1;
        await _exportFactures(context, clientId);
      } else if (_selectedCategory == 'Traitement') {
        final clientId = _clientMap[_selectedClient] ?? -1;
        await _exportTraitements(context, clientId);
      }

      if (mounted) {
        setState(() => _isExporting = false);
        _showSuccessDialog(
          context,
          'Export généré',
          'L\'export a été généré avec succès',
        );
      }
    } catch (e) {
      logger.e('Erreur lors de la génération de l\'export: $e');
      if (mounted) {
        setState(() => _isExporting = false);
        _showErrorDialog(context, 'Erreur d\'export', e.toString());
      }
    }
  }

  Future<void> _exportFactures(BuildContext context, int clientId) async {
    try {
      final factureRepo = context.read<FactureRepository>();
      List<Facture> factures;

      // Charger les factures filtrées par client si clientId != -1
      if (clientId != -1) {
        await factureRepo.loadFacturesForClient(clientId);
        factures = factureRepo.factures;
      } else {
        // Charger toutes les factures
        await factureRepo.loadAllFactures();
        factures = factureRepo.factures;
      }

      // Filtrer par mois si ce n'est pas "Tous"
      if (_selectedMois != 'Tous') {
        final monthIndex = _mois.indexOf(_selectedMois);
        factures = factures.where((f) {
          final dateTraitement = f.dateTraitement;
          return dateTraitement.month == monthIndex;
        }).toList();
      }

      if (factures.isEmpty) {
        _showErrorDialog(
          context,
          'Aucune donnée',
          'Aucune facture à exporter pour ce client',
        );
        return;
      }

      // Préparer les données pour Excel
      List<Map<String, dynamic>> data = [];
      for (var facture in factures) {
        data.add({
          'Numéro Facture': facture.referenceFacture ?? 'N/A',
          'Date de Planification':
              facture.datePlanification?.toString().split(' ')[0] ??
              DateTime.now().toString().split(' ')[0],
          'Date de Facturation': facture.dateTraitement.toString().split(
            ' ',
          )[0],
          'Type de Traitement': facture.typeTreatment ?? 'Standard',
          'Etat du Planning': facture.etatPlanning ?? 'Complété',
          'Mode de Paiement': facture.mode ?? 'N/A',
          'Détails Paiement': 'N/A',
          'Etat de Paiement': facture.etat,
          'Montant Facturé': facture.montant,
        });
      }

      await _excelService.genererFactureExcel(
        data,
        '${_selectedClient}_${_selectedMois}',
        DateTime.now().year,
        _selectedMois == 'Tous' ? 0 : _mois.indexOf(_selectedMois),
      );

      if (mounted) {
        setState(
          () => _lastExportPath = '${_selectedClient}_${_selectedMois}.xlsx',
        );
      }
    } catch (e) {
      logger.e('Erreur lors de l\'export des factures: $e');
      rethrow;
    }
  }

  Future<void> _exportTraitements(BuildContext context, int clientId) async {
    try {
      final planningDetailsRepo = context.read<PlanningDetailsRepository>();
      final monthIndex = _mois.indexOf(_selectedMois) + 1;
      final year = DateTime.now().year;

      // Déterminer le traitement à passer (null si 'Tous')
      final treatmentType = _selectedTraitement != 'Tous'
          ? _selectedTraitement
          : null;

      // Récupérer les traitements du mois/client/traitement spécifique
      final treatments = await planningDetailsRepo
          .getTreatmentsByMonthAndClient(
            year: year,
            month: monthIndex,
            clientId: clientId == -1 ? null : clientId,
            treatmentType: treatmentType,
          );

      if (treatments.isEmpty) {
        _showErrorDialog(
          context,
          'Aucune donnée',
          'Aucun traitement à exporter pour ce client ce mois-ci',
        );
        return;
      }

      // Préparer les données pour Excel en mappant les colonnes
      List<Map<String, dynamic>> data = [];
      for (var treatment in treatments) {
        data.add({
          'Date du traitement': treatment['Date du traitement'],
          'Traitement concerné': treatment['Traitement concerné'] ?? 'N/A',
          'Catégorie du traitement':
              treatment['Catégorie du traitement'] ?? 'N/A',
          'Client concerné': treatment['Client concerné'] ?? 'N/A',
          'Catégorie du client': treatment['Catégorie du client'] ?? 'N/A',
          'Axe du client': treatment['Axe du client'] ?? 'N/A',
          'Etat traitement': treatment['Etat traitement'] ?? 'À venir',
        });
      }

      await _excelService.generateTraitementsExcel(data, year, monthIndex);

      if (mounted) {
        setState(
          () => _lastExportPath =
              '${_selectedClient}_Traitements_$_selectedMois.xlsx',
        );
      }
    } catch (e) {
      logger.e('Erreur lors de l\'export des traitements: $e');
      rethrow;
    }
  }

  void _reinitialiserSelections() {
    setState(() {
      _selectedCategory = 'Facture';
      _selectedTraitement = 'Tous';
      _selectedMois = 'Janvier';
      _selectedClient = 'Tous';
      _lastExportPath = null;
    });
  }

  void _showSuccessDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.check_circle, color: Colors.green[600], size: 48),
        title: Text('✅ $title'),
        content: SelectableText(message),
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.close),
            label: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.error, color: Colors.red[600], size: 48),
        title: Text('❌ $title'),
        content: SelectableText(message),
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx),
            icon: const Icon(Icons.close),
            label: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
