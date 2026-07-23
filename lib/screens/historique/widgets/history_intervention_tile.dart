import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../utils/date_utils.dart' as date_utils;

class HistoryInterventionTile extends StatelessWidget {
  final DateTime date;
  final String status;
  final VoidCallback onTap;

  const HistoryInterventionTile({
    super.key,
    required this.date,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDone = status.toLowerCase().contains('effectué');
    final statusColor = isDone ? AppTheme.successGreen : AppTheme.warningOrange;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isDone ? Icons.check_circle_outline_rounded : Icons.schedule_rounded, 
          color: statusColor, 
          size: 20
        ),
      ),
      title: Text(
        date_utils.DateUtils.formatDateFull(date),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 8, 
                  fontWeight: FontWeight.w900, 
                  color: statusColor, 
                  letterSpacing: 0.5
                ),
              ),
            ),
          ],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded, 
        size: 14, 
        color: isDark ? Colors.white12 : Colors.grey[300]
      ),
    );
  }
}
