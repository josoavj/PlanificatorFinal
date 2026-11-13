import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/theme.dart';

class CalendarWidget extends StatefulWidget {
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
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _visibleMonth;
  static const _weekdays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(widget.focusedDay.year, widget.focusedDay.month);
  }

  @override
  void didUpdateWidget(covariant CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedDay != widget.focusedDay &&
        (oldWidget.focusedDay.year != widget.focusedDay.year ||
            oldWidget.focusedDay.month != widget.focusedDay.month)) {
      _visibleMonth = DateTime(widget.focusedDay.year, widget.focusedDay.month);
    }
  }

  void _changeMonth(int offset) {
    final nextMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + offset,
    );
    setState(() => _visibleMonth = nextMonth);
    widget.onPageChanged(nextMonth);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
    final startOffset = firstOfMonth.weekday - 1;
    final dayCount = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final cellCount = ((startOffset + dayCount + 6) ~/ 7) * 7;
    final monthLabel = DateFormat('MMMM yyyy', 'fr_FR').format(_visibleMonth);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context, radius: 28),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Mois précédent',
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      monthLabel,
                      key: ValueKey(monthLabel),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Mois suivant',
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: _weekdays
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: day == 'D' || day == 'S'
                                ? (isDark
                                      ? AppTheme.accentBlue
                                      : Colors.blue.shade700)
                                : (isDark ? Colors.white70 : Colors.grey[700]),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cellCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 52,
              ),
              itemBuilder: (context, index) {
                final dayNumber = index - startOffset + 1;
                if (dayNumber < 1 || dayNumber > dayCount) {
                  return const SizedBox.shrink();
                }

                final day = DateTime(
                  _visibleMonth.year,
                  _visibleMonth.month,
                  dayNumber,
                );
                final isSelected = _sameDay(day, widget.selectedDay);
                final isToday = _sameDay(day, DateTime.now());
                final events = widget.getTreatmentsForDay(
                  day,
                  widget.treatments,
                );
                final foregroundColor = isSelected
                    ? Colors.white
                    : isToday
                    ? AppTheme.primaryBlue
                    : (isDark ? Colors.white : Colors.black87);

                return Padding(
                  padding: const EdgeInsets.all(2),
                  child: Material(
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : isToday
                        ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                        : Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => widget.onDaySelected(day, day),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNumber',
                            style: TextStyle(
                              color: foregroundColor,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 3),
                          SizedBox(
                            height: 5,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                events.length.clamp(0, 3),
                                (_) => Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
