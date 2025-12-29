import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../core/theme.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({Key? key}) : super(key: key);

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
  }

  /// Convertir une valeur dynamique en String
  String _convertToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int || value is double) return value.toString();
    if (value is DateTime) return value.toIso8601String();

    // Gérer les Blob (MySql driver)
    if (value.runtimeType.toString() == 'Blob') {
      try {
        if (value is List<int>) {
          return String.fromCharCodes(value);
        }
        return value.toString();
      } catch (e) {
        return '';
      }
    }

    return value.toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Charger les traitements planifiés depuis la base de données
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<PlanningDetailsRepository>()
          .loadUpcomingTreatmentsComplete();
    });
  }

  List<String> _getEventsMarkers(
    DateTime day,
    List<Map<String, dynamic>> treatments,
  ) {
    final treatmentsForDay = _getTreatmentsForDay(day, treatments);
    // Retourner une liste de marqueurs (un par traitement)
    return List.generate(treatmentsForDay.length, (index) => 'event_$index');
  }

  List<Map<String, dynamic>> _getTreatmentsForDay(
    DateTime day,
    List<Map<String, dynamic>> treatments,
  ) {
    return treatments.where((treatment) {
      try {
        final dateValue = treatment['date'];
        final dateStr = _convertToString(dateValue);
        if (dateStr.isEmpty) return false;

        final parts = dateStr.split('-');
        if (parts.length != 3) return false;

        final treatmentDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );

        final normalizedDay = DateTime(day.year, day.month, day.day);
        return isSameDay(treatmentDate, normalizedDay);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PlanningDetailsRepository>(
        builder: (context, detailsRepository, _) {
          final treatmentsForSelected = _getTreatmentsForDay(
            _selectedDay,
            detailsRepository.upcomingTreatmentsComplete,
          );

          return SingleChildScrollView(
            child: Column(
              children: [
                // Calendrier
                Container(
                  padding: const EdgeInsets.all(8),
                  child: _buildCalendar(
                    detailsRepository.upcomingTreatmentsComplete,
                  ),
                ),

                // Événements du jour
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat(
                          'EEEE dd MMMM yyyy',
                          'fr_FR',
                        ).format(_selectedDay),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (detailsRepository.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (detailsRepository.errorMessage != null)
                        Center(
                          child: Text(
                            'Erreur: ${detailsRepository.errorMessage}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      else if (treatmentsForSelected.isEmpty)
                        const Center(child: Text('Aucun traitement ce jour'))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: treatmentsForSelected.length,
                          itemBuilder: (context, index) {
                            final treatment = treatmentsForSelected[index];
                            return _TreatmentCard(
                              traitement: _convertToString(
                                treatment['traitement'],
                              ),
                              axe: _convertToString(treatment['axe']),
                              etat: _convertToString(treatment['etat']),
                            );
                          },
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

  Widget _buildCalendar(List<Map<String, dynamic>> treatments) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TableCalendar(
          firstDay: DateTime(2024, 1, 1),
          lastDay: DateTime(2026, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: (day) => _getEventsMarkers(day, treatments),
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: AppTheme.accentBlue,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: Theme.of(context).textTheme.titleLarge!,
          ),
        ),
      ),
    );
  }
}

class _TreatmentCard extends StatelessWidget {
  final String traitement;
  final String axe;
  final String etat;

  const _TreatmentCard({
    Key? key,
    required this.traitement,
    required this.axe,
    required this.etat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isEffectue = etat == 'Effectué';
    final bgColor = isEffectue ? Colors.green[50] : Colors.red[50];
    final textColor = isEffectue ? Colors.green[900] : Colors.red[900];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: bgColor,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isEffectue ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isEffectue ? Icons.check_circle : Icons.pending_actions,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          traitement,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        subtitle: Text(
          'Axe: $axe',
          style: TextStyle(color: textColor, fontSize: 12),
        ),
        trailing: Text(
          etat,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
