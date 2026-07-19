import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../repositories/index.dart';
import '../../../services/logging_service.dart';
import '../../../utils/app_snackbars.dart';
import 'treatment_list_view.dart';
import 'stat_card.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    try {
      logger.i(' Dashboard: Chargement des données...');
      
      // Mois actuel
      await _planningDetailsRepo.loadCurrentMonthTreatmentsComplete();
      
      // Mois prochains (à partir du 1er du mois suivant)
      final now = DateTime.now();
      final firstDayNextMonth = DateTime(now.year, now.month + 1);
      await _planningDetailsRepo.loadUpcomingTreatmentsComplete(startDate: firstDayNextMonth);
      
      logger.i(' Dashboard: Données chargées avec succès');
    } catch (e) {
      logger.e(' Dashboard: Erreur chargement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_refresh',
        onPressed: () async {
          await _loadData();
          if (mounted) AppSnackBars.showSuccess(context, 'Données actualisées');
        },
        tooltip: 'Rafraîchir les données',
        child: const Icon(Icons.refresh),
      ),
      body: Consumer<PlanningDetailsRepository>(
        builder: (context, repo, _) {
          final currentMonth = repo.currentMonthTreatmentsComplete;
          final upcoming = repo.upcomingTreatmentsComplete;
          
          final stats = _calculateStats(currentMonth);

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(),
                const SizedBox(height: 32),
                
                // Statistics Row
                Row(
                  children: [
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Traitements du mois',
                        value: '${stats.total}',
                        icon: Icons.assignment_outlined,
                        color: Colors.blue,
                        subtitle: 'Total prévu en ${_getCurrentMonthName()}',
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Effectués',
                        value: '${stats.completed}',
                        icon: Icons.check_circle_outline_rounded,
                        color: Colors.green,
                        subtitle: '${stats.percent}% de complétion',
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Restants',
                        value: '${stats.remaining}',
                        icon: Icons.pending_actions_rounded,
                        color: Colors.orange,
                        subtitle: 'À traiter avant la fin du mois',
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Main Lists Row
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En Cours (Mois actuel)
                      Expanded(
                        child: TreatmentListView(
                          title: 'En cours (${_getCurrentMonthName()})',
                          isLoading: repo.isLoading,
                          errorMessage: repo.errorMessage,
                          treatments: _formatData(currentMonth),
                        ),
                      ),
                      const SizedBox(width: 32),
                      // À Venir (Mois prochains)
                      Expanded(
                        child: TreatmentListView(
                          title: 'À venir (Mois prochains)',
                          isLoading: repo.isLoading,
                          errorMessage: repo.errorMessage,
                          treatments: _formatData(upcoming),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TABLEAU DE BORD',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.blue,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bienvenue dans Planificator',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  _DashboardStats _calculateStats(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return _DashboardStats(0, 0, 0, 0);
    
    int total = data.length;
    int completed = data.where((item) => item['etat'] == 'Effectué').length;
    int remaining = total - completed;
    int percent = total > 0 ? ((completed / total) * 100).round() : 0;
    
    return _DashboardStats(total, completed, remaining, percent);
  }

  List<Map<String, dynamic>> _formatData(List<Map<String, dynamic>> raw) {
    return raw.map((item) => {
      ...item,
      'nom': item['traitement']?.toString() ?? 'Sans nom',
      'etat': item['etat']?.toString() ?? 'N/A',
      'axe': item['axe']?.toString() ?? 'Non défini',
    }).toList();
  }

  String _getCurrentMonthName() {
    final now = DateTime.now();
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[now.month - 1];
  }
}

class _DashboardStats {
  final int total;
  final int completed;
  final int remaining;
  final int percent;
  _DashboardStats(this.total, this.completed, this.remaining, this.percent);
}
