import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<Map<String, dynamic>> treatments;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final Function(DateTime, List<Map<String, dynamic>>) getTreatmentsForDay;

  const CalendarWidget({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.treatments,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.getTreatmentsForDay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context, radius: 28),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: TableCalendar(
            firstDay: DateTime(2024),
            lastDay: DateTime(2079, 12, 31),
            focusedDay: focusedDay,
            locale: 'fr_FR',
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            onDaySelected: onDaySelected,
            onPageChanged: onPageChanged,
            eventLoader: (day) => List.generate(getTreatmentsForDay(day, treatments).length, (index) => 'e'),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: AppTheme.primaryBlue, 
                shape: BoxShape.circle, 
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                ],
              ),
              todayDecoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.15), 
                shape: BoxShape.circle, 
                border: Border.all(color: AppTheme.primaryBlue),
              ),
              todayTextStyle: TextStyle(color: isDark ? Colors.white : AppTheme.primaryBlue, fontWeight: FontWeight.bold),
              markerDecoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
              markersMaxCount: 3,
              defaultTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black87),
              weekendTextStyle: TextStyle(color: isDark ? AppTheme.accentBlue : Colors.blue.shade700),
              outsideTextStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false, 
              titleCentered: true, 
              titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              leftChevronIcon: Icon(Icons.chevron_left_rounded, color: isDark ? Colors.white : Colors.black87),
              rightChevronIcon: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white : Colors.black87),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12),
              weekendStyle: TextStyle(color: isDark ? AppTheme.accentBlue : Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}
