import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class HistoryClientCard extends StatelessWidget {
  final String clientName;
  final String axe;
  final int totalInterventions;
  final int completedInterventions;
  final VoidCallback onTap;

  const HistoryClientCard({
    super.key,
    required this.clientName,
    required this.axe,
    required this.totalInterventions,
    required this.completedInterventions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration(context, radius: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.person_rounded, color: AppTheme.primaryBlue, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 12, color: isDark ? Colors.white38 : Colors.grey),
                          const SizedBox(width: 4),
                          Text(axe, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[600], fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$completedInterventions/$totalInterventions',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryBlue),
                    ),
                    const Text('Passages', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(width: 24),
                Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white12 : Colors.grey[300]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
