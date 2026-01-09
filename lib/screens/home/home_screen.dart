import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../repositories/index.dart';
import '../../widgets/index.dart';
import '../client/client_list_screen.dart';
import '../facture/facture_screen.dart';
import '../contrat/contrat_screen.dart';
import '../planning/planning_screen.dart';
import '../historique/historique_screen.dart';
import '../settings/settings_screen.dart';
import '../about/about_screen.dart';
import '../export/export_screen.dart';

final logger = Logger();

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<String> _pageTitles = [
    'Accueil',
    'Contrats',
    'Clients',
    'Planning',
    'Factures',
    'Historique',
    'Export',
    'À propos',
    'Paramètres',
  ];

  @override
  void initState() {
    super.initState();
    //WidgetsBinding.instance.addPostFrameCallback((_) {
    //  logger.i('🏠 HomeScreen mounted with initial tab index $_selectedIndex');
    //});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_pageTitles[_selectedIndex]),
          centerTitle: true,
          elevation: 2,
        ),
        drawer: SidebarNavigation(
          selectedIndex: _selectedIndex,
          onItemSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: const [
            _DashboardTab(),
            ContratScreen(),
            ClientListScreen(),
            PlanningScreen(),
            FactureScreen(),
            HistoriqueScreen(),
            ExportScreen(),
            AboutScreen(),
            SettingsScreen(),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab({Key? key}) : super(key: key);

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  late PlanningDetailsRepository _planningDetailsRepo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _planningDetailsRepo = context.read<PlanningDetailsRepository>();
    logger.i('📱 _DashboardTabState mounted, loading data...');
    _loadData();
  }

  void _loadData() {
    logger.i('🔄 Démarrage du chargement des données complètes...');
    _planningDetailsRepo.loadCurrentMonthTreatmentsComplete();
    _planningDetailsRepo.loadUpcomingTreatmentsComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_refresh',
        onPressed: _loadData,
        tooltip: 'Rafraîchir les données',
        child: const Icon(Icons.refresh),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'BIENVENUE DANS PLANIFICATOR',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 25),

            // Two columns layout for current and next treatments
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT: A venir (mois prochain) - sans redondance 1 mois
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A venir',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(minHeight: 400),
                        child: Consumer<PlanningDetailsRepository>(
                          builder: (context, planningDetailsRepo, _) {
                            // ✅ "A venir" = Traitements du MOIS SUIVANT
                            // MAIS exclure ceux déjà affichés dans "En cours"
                            final currentMonthIds = planningDetailsRepo
                                .currentMonthTreatmentsComplete
                                .map((t) => t['planning_detail_id'] as int?)
                                .toSet();

                            final filteredTreatments = planningDetailsRepo
                                .upcomingTreatmentsComplete
                                .where(
                                  (treatment) => !currentMonthIds.contains(
                                    treatment['planning_detail_id'] as int?,
                                  ),
                                )
                                .toList();

                            logger.d(
                              '🔄 Rebuilding upcoming table with ${filteredTreatments.length} items (exclu ${currentMonthIds.length} en cours)',
                            );
                            return _buildTreatmentTable(
                              title: 'Prochains traitements',
                              isLoading: planningDetailsRepo.isLoading,
                              errorMessage: planningDetailsRepo.errorMessage,
                              treatments: filteredTreatments
                                  .map(
                                    (data) => {
                                      'date': _formatDate(data['date']),
                                      'nom': _convertToString(
                                        data['traitement'] ?? '',
                                      ),
                                      'etat': _convertToString(
                                        data['etat'] ?? '',
                                      ),
                                      'axe': _convertToString(
                                        data['axe'] ?? '',
                                      ),
                                    },
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // RIGHT: En cours (mois actuel) - affiche à venir ET effectué
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'En cours',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(minHeight: 400),
                        child: Consumer<PlanningDetailsRepository>(
                          builder: (context, planningDetailsRepo, _) {
                            // ✅ "En cours" = TOUS les traitements du MOIS ACTUEL
                            // (affichage complet: à venir, en cours, effectué)
                            final filteredTreatments = planningDetailsRepo
                                .currentMonthTreatmentsComplete
                                .toList();

                            logger.d(
                              '🔄 Rebuilding current month table with ${filteredTreatments.length} items (mois actuel)',
                            );
                            return _buildTreatmentTable(
                              title: 'Traitements en cours',
                              isLoading: planningDetailsRepo.isLoading,
                              errorMessage: planningDetailsRepo.errorMessage,
                              treatments: filteredTreatments
                                  .map(
                                    (data) => {
                                      'date': _formatDate(data['date']),
                                      'nom': _convertToString(
                                        data['traitement'] ?? '',
                                      ),
                                      'etat': _convertToString(
                                        data['etat'] ?? '',
                                      ),
                                      'axe': _convertToString(
                                        data['axe'] ?? '',
                                      ),
                                    },
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentTable({
    required String title,
    required bool isLoading,
    required List<Map<String, dynamic>> treatments,
    String? errorMessage,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Erreur: $errorMessage',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (treatments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Aucun traitement',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Nom')),
          DataColumn(label: Text('État')),
          DataColumn(label: Text('Axe')),
        ],
        rows: treatments.map((treatment) {
          final etat = treatment['etat'] ?? '';
          final bgColor = etat == 'Effectué'
              ? Colors.green.shade50
              : etat == 'À venir'
              ? Colors.red.shade50
              : Colors.white;
          final textColor = etat == 'Effectué'
              ? Colors.green.shade700
              : etat == 'À venir'
              ? Colors.red.shade700
              : Colors.black;

          return DataRow(
            color: WidgetStatePropertyAll(bgColor),
            cells: [
              DataCell(
                Text(
                  // ✅ CORRECTION: Utiliser 'date_planification' au lieu de 'date'
                  treatment['date_planification'] ?? treatment['date'] ?? '',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              DataCell(
                Text(
                  treatment['nom'] ?? '',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              DataCell(
                Text(
                  treatment['etat'] ?? '',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              DataCell(
                Text(
                  treatment['axe'] ?? '',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// ✅ Helper pour convertir une valeur en String (gère Blob, DateTime, String)
  String _convertToString(dynamic value) {
    if (value == null) return 'N/A';

    // Si c'est déjà une String
    if (value is String) return value;

    // Si c'est un DateTime
    if (value is DateTime) {
      return value.toIso8601String().split('T')[0];
    }

    // Si c'est un Blob, le convertir en bytes puis en String
    if (value.runtimeType.toString().contains('Blob')) {
      try {
        // Convertir Blob en String
        return value.toString();
      } catch (e) {
        logger.e('Erreur conversion Blob: $e');
        return 'N/A';
      }
    }

    // Fallback: convertir en String
    return value.toString();
  }

  /// ✅ Helper pour formater les dates (gère DateTime et String)
  String _formatDate(dynamic dateInput) {
    if (dateInput == null) return 'N/A';

    String dateStr;

    // Gérer les deux cas: DateTime ou String
    if (dateInput is DateTime) {
      dateStr = dateInput.toIso8601String().split('T')[0]; // YYYY-MM-DD
    } else if (dateInput is String) {
      dateStr = dateInput;
    } else {
      return 'N/A';
    }

    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1]}-${parts[0]}'; // YYYY-MM-DD → DD-MM-YYYY
      }
    } catch (e) {
      logger.e('Erreur formatage date: $e');
    }
    return dateStr;
  }
}
