import 'package:material_ui/material_ui.dart';
import 'package:planificator/features/planning/repositories/planning_details_repository.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/theme.dart';
import '../domain/date_utils.dart' as date_utils;
import 'widgets/calendar_widget.dart';
import 'widgets/planning_card.dart';
import 'planning_detail_screen.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await context.read<PlanningDetailsRepository>().loadAllTreatmentsComplete();
  }

  List<Map<String, dynamic>> _getTreatmentsForDay(
    DateTime day,
    List<Map<String, dynamic>> treatments,
  ) {
    final targetStr =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return treatments.where((t) {
      final dateVal = t['date'];
      if (dateVal == null) return false;
      final dateStr = dateVal.toString();
      if (dateStr == targetStr || dateStr.startsWith(targetStr)) return true;
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          return y == day.year && m == day.month && d == day.day;
        }
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'planning_refresh',
        onPressed: _loadData,
        tooltip: 'Actualiser',
        child: const Icon(Icons.refresh),
      ),
      body: Consumer<PlanningDetailsRepository>(
        builder: (context, repo, _) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final treatments = _getTreatmentsForDay(
            _selectedDay,
            repo.allTreatmentsComplete,
          );

          return SingleChildScrollView(
            child: Column(
              children: [
                CalendarWidget(
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  treatments: repo.allTreatmentsComplete,
                  onDaySelected: (s, f) => setState(() {
                    _selectedDay = s;
                    _focusedDay = f;
                  }),
                  onPageChanged: (f) => _focusedDay = f,
                  getTreatmentsForDay: _getTreatmentsForDay,
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBg : Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _formatDateLong(_selectedDay),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (treatments.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: treatments.length,
                          itemBuilder: (context, index) => PlanningCard(
                            treatment: treatments[index],
                            onTap: () => Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                    ) => PlanningDetailScreen(
                                      treatment: treatments[index],
                                      planningDetailId:
                                          treatments[index]['planning_detail_id'] ??
                                          0,
                                    ),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                              ),
                            ),
                          ),
                        )
                      else if (repo.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (repo.errorMessage != null)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Erreur: ${repo.errorMessage}',
                              style: const TextStyle(color: AppTheme.errorRed),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_busy_rounded,
                                  size: 48,
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun traitement prévu pour ce jour',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey[400],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
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

  String _formatDateLong(DateTime date) {
    return date_utils.DateUtils.formatDateFull(date);
  }
}
