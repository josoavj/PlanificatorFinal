import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../repositories/index.dart';
import '../../../services/logging_service.dart';
import '../../../utils/app_snackbars.dart';
import 'treatment_table.dart';

final logger = createLoggerWithFileOutput(name: 'dashboard_tab');

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  late PlanningDetailsRepository _planningDetailsRepo;

  @override
  void initState() {
    super.initState();
    _planningDetailsRepo = context.read<PlanningDetailsRepository>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          logger.i(' Dashboard: Chargement automatique des données...');
          await _planningDetailsRepo.loadCurrentMonthTreatmentsComplete();
          await _planningDetailsRepo.loadUpcomingTreatmentsComplete();
          logger.i(' Dashboard: Données chargées avec succès');
        } catch (e) {
          logger.e(' Dashboard: Erreur chargement: $e');
        }
      }
    });
  }

  Future<void> _loadData() async {
    try {
      logger.i(' Rafraîchissement manuel des données...');
      await _planningDetailsRepo.loadCurrentMonthTreatmentsComplete();
      await _planningDetailsRepo.loadUpcomingTreatmentsComplete();
      logger.i(' Rafraîchissement complété');

      if (mounted) {
        AppSnackBars.showSuccess(context, ' Données rafraîchies');
      }
    } catch (e) {
      logger.e(' Erreur lors du rafraîchissement: $e');
      if (mounted) {
        AppSnackBars.showError(context, ' Erreur: $e');
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
              Text(
                'BIENVENUE DANS PLANIFICATOR',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 25),
              Consumer<PlanningDetailsRepository>(
                builder: (context, planningDetailsRepo, _) {
                  final currentMonth = planningDetailsRepo.currentMonthTreatmentsComplete;
                  final upcoming = planningDetailsRepo.upcomingTreatmentsComplete;
                  final isMobile = MediaQuery.of(context).size.width < 900;

                  if (isMobile) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TreatmentTable(
                          title: 'En cours',
                          isLoading: planningDetailsRepo.isLoading,
                          errorMessage: planningDetailsRepo.errorMessage,
                          treatments: _formatTreatments(currentMonth),
                        ),
                        const SizedBox(height: 24),
                        TreatmentTable(
                          title: 'À venir',
                          isLoading: planningDetailsRepo.isLoading,
                          errorMessage: planningDetailsRepo.errorMessage,
                          treatments: _formatTreatments(upcoming),
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TreatmentTable(
                          title: 'À venir',
                          isLoading: planningDetailsRepo.isLoading,
                          errorMessage: planningDetailsRepo.errorMessage,
                          treatments: _formatTreatments(upcoming),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: TreatmentTable(
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

  List<Map<String, dynamic>> _formatTreatments(List<Map<String, dynamic>> rawTreatments) {
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

  String _convertToString(dynamic value) {
    if (value == null) return 'N/A';
    if (value is String) return value;
    if (value is DateTime) return value.toIso8601String().split('T')[0];
    return value.toString();
  }

  String _formatDate(dynamic dateInput) {
    if (dateInput == null) return 'N/A';
    String dateStr;
    if (dateInput is DateTime) {
      dateStr = dateInput.toIso8601String().split('T')[0];
    } else if (dateInput is String) {
      dateStr = dateInput;
    } else {
      return 'N/A';
    }
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1]}-${parts[0]}';
      }
    } catch (e) {
      logger.e('Erreur formatage date: $e');
    }
    return dateStr;
  }
}
