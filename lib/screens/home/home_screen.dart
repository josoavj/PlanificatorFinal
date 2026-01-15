import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../widgets/index.dart';
import '../../services/logging_service.dart';
import '../client/client_list_screen.dart';
import '../facture/facture_screen.dart';
import '../contrat/contrat_screen.dart';
import '../planning/planning_screen.dart';
import '../historique/historique_screen.dart';
import '../settings/settings_screen.dart';
import '../about/about_screen.dart';
import '../export/export_screen.dart';

final logger = createLoggerWithFileOutput(name: 'home_screen');

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
    return PopScope(
      canPop: false,
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
  void initState() {
    super.initState();
    _planningDetailsRepo = context.read<PlanningDetailsRepository>();
    // Les données sont déjà préchargées dans _AuthGate
    // Ne pas recharger ici pour éviter le double rendu
  }

  Future<void> _loadData() async {
    try {
      logger.i('🔄 Rafraîchissement manuel des données...');
      await _planningDetailsRepo.loadCurrentMonthTreatmentsComplete();
      await _planningDetailsRepo.loadUpcomingTreatmentsComplete();
      logger.i('✅ Rafraîchissement complété');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Données rafraîchies'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      logger.e('❌ Erreur lors du rafraîchissement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'BIENVENUE DANS PLANIFICATOR',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 25),

              // Two columns layout for current and next treatments (responsive)
              Consumer<PlanningDetailsRepository>(
                builder: (context, planningDetailsRepo, _) {
                  // Filtrer une seule fois pour éviter les recalculs
                  final currentMonthIds = planningDetailsRepo
                      .currentMonthTreatmentsComplete
                      .map((t) => t['planning_detail_id'] as int?)
                      .toSet();

                  final upcomingFiltered = planningDetailsRepo
                      .upcomingTreatmentsComplete
                      .where(
                        (treatment) => !currentMonthIds.contains(
                          treatment['planning_detail_id'] as int?,
                        ),
                      )
                      .toList();

                  final currentMonth =
                      planningDetailsRepo.currentMonthTreatmentsComplete;

                  logger.d(
                    '📊 Dashboard: ${currentMonth.length} en cours, ${upcomingFiltered.length} à venir',
                  );

                  // Responsive layout: 2 columns sur grand écran, 1 colonne sinon
                  final isMobile = MediaQuery.of(context).size.width < 900;

                  if (isMobile) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTreatmentSection(
                          title: 'En cours',
                          isLoading: planningDetailsRepo.isLoading,
                          errorMessage: planningDetailsRepo.errorMessage,
                          treatments: _formatTreatments(currentMonth),
                        ),
                        const SizedBox(height: 24),
                        _buildTreatmentSection(
                          title: 'À venir',
                          isLoading: planningDetailsRepo.isLoading,
                          errorMessage: planningDetailsRepo.errorMessage,
                          treatments: _formatTreatments(upcomingFiltered),
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT: A venir
                      Expanded(
                        child: _buildTreatmentSection(
                          title: 'À venir',
                          isLoading: planningDetailsRepo.isLoading,
                          errorMessage: planningDetailsRepo.errorMessage,
                          treatments: _formatTreatments(upcomingFiltered),
                        ),
                      ),
                      const SizedBox(width: 24),

                      // RIGHT: En cours
                      Expanded(
                        child: _buildTreatmentSection(
                          title: 'En cours',
                          isLoading: planningDetailsRepo.isLoading,
                          errorMessage: planningDetailsRepo.errorMessage,
                          treatments: _formatTreatments(currentMonth),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTreatmentSection({
    required String title,
    required bool isLoading,
    required List<Map<String, dynamic>> treatments,
    String? errorMessage,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(minHeight: 300, maxHeight: 600),
          child: _buildTreatmentTable(
            title: title,
            isLoading: isLoading,
            errorMessage: errorMessage,
            treatments: treatments,
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _formatTreatments(
    List<Map<String, dynamic>> rawTreatments,
  ) {
    return rawTreatments
        .map(
          (data) => {
            'date': _formatDate(data['date']),
            'nom': _convertToString(data['traitement'] ?? ''),
            'etat': _convertToString(data['etat'] ?? ''),
            'axe': _convertToString(data['axe'] ?? ''),
          },
        )
        .toList();
  }

  Widget _buildTreatmentTable({
    required String title,
    required bool isLoading,
    required List<Map<String, dynamic>> treatments,
    String? errorMessage,
  }) {
    // ✅ PRIORITÉ: Afficher les données si présentes, ignorer le spinner
    if (treatments.isNotEmpty) {
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SizedBox(
          width: double.infinity,
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
                      treatment['date'] ?? '',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      treatment['nom'] ?? '',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                  DataCell(
                    Text(
                      etat,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      treatment['axe'] ?? '',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      );
    }

    // ✅ Afficher le spinner que si pas de données ET isLoading
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

    // Aucun traitement
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
