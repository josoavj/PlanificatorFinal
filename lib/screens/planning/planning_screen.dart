import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../core/theme.dart';
import '../../utils/date_utils.dart' as date_utils;
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
  final Map<String, List<Map<String, dynamic>>> _treatmentCache = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await context.read<PlanningDetailsRepository>().loadAllTreatmentsComplete();
    if (mounted) {
      setState(() {
        _treatmentCache.clear();
      });
    }
  }

  String _convertToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int || value is double) return value.toString();
    return value.toString();
  }

  List<Map<String, dynamic>> _getTreatmentsForDay(DateTime day, List<Map<String, dynamic>> treatments) {
    final dayKey = '${day.year}-${day.month}-${day.day}';
    if (_treatmentCache.containsKey(dayKey)) return _treatmentCache[dayKey]!;

    final result = treatments.where((t) {
      try {
        final dateStr = _convertToString(t['date']);
        if (dateStr.isEmpty) return false;
        final parts = dateStr.split('-');
        if (parts.length != 3) return false;
        final tDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        return isSameDay(tDate, DateTime(day.year, day.month, day.day));
      } catch (e) { return false; }
    }).toList();

    _treatmentCache[dayKey] = result;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'planning_refresh', 
        onPressed: _loadData, 
        tooltip: 'Actualiser', 
        child: const Icon(Icons.refresh)
      ),
      body: Consumer<PlanningDetailsRepository>(
        builder: (context, repo, _) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final treatments = _getTreatmentsForDay(_selectedDay, repo.allTreatmentsComplete);

          return SingleChildScrollView(
            child: Column(
              children: [
                CalendarWidget(
                  focusedDay: _focusedDay, 
                  selectedDay: _selectedDay, 
                  treatments: repo.allTreatmentsComplete, 
                  onDaySelected: (s, f) => setState(() { _selectedDay = s; _focusedDay = f; }), 
                  onPageChanged: (f) => _focusedDay = f, 
                  getTreatmentsForDay: _getTreatmentsForDay
                ),
                Container(
                  padding: const EdgeInsets.all(24), 
                  decoration: BoxDecoration(color: isDark ? AppTheme.darkBg : Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4, 
                            height: 24, 
                            decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(2)),
                          ), 
                          const SizedBox(width: 12), 
                          Expanded(
                            child: Text(
                              _formatDateLong(_selectedDay), 
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 18)
                            )
                          )
                        ]
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
                              MaterialPageRoute(
                                builder: (context) => PlanningDetailScreen(
                                  treatment: treatments[index], 
                                  planningDetailId: treatments[index]['planning_detail_id'] ?? 0
                                )
                              )
                            )
                          )
                        )
                      else if (repo.isLoading) 
                        const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()))
                      else if (repo.errorMessage != null) 
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16), 
                            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), 
                            child: Text('Erreur: ${repo.errorMessage}', style: const TextStyle(color: AppTheme.errorRed))
                          )
                        )
                      else 
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0), 
                            child: Column(
                              children: [
                                Icon(Icons.event_busy_rounded, size: 48, color: isDark ? Colors.white24 : Colors.grey[300]), 
                                const SizedBox(height: 16), 
                                Text(
                                  'Aucun traitement prévu pour ce jour', 
                                  style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400], fontWeight: FontWeight.w500)
                                )
                              ]
                            )
                          )
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
