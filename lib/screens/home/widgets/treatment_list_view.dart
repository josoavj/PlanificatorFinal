import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import 'treatment_detail_dialog.dart';

class TreatmentListView extends StatelessWidget {
  final String title;
  final bool isLoading;
  final List<Map<String, dynamic>> treatments;
  final String? errorMessage;
  final VoidCallback? onActionPressed;

  const TreatmentListView({
    super.key,
    required this.title,
    required this.isLoading,
    required this.treatments,
    this.errorMessage,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            if (onActionPressed != null)
              TextButton(
                onPressed: onActionPressed,
                child: const Text('Voir tout'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: AppTheme.cardDecoration(context, radius: 24),
            clipBehavior: Clip.antiAlias,
            child: _buildContent(context, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    if (isLoading && treatments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 32),
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (treatments.isEmpty) {
      return Center(
        child: Text(
          'Aucun traitement',
          style: TextStyle(color: isDark ? Colors.white24 : Colors.grey[400]),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: treatments.length,
        separatorBuilder: (context, index) => Divider(
          height: 1, 
          indent: 64, 
          endIndent: 16,
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
        ),
        itemBuilder: (context, index) {
            final item = treatments[index];
          final etat = (item['etat'] ?? '').toString();
          final isEffectue = etat.trim() == 'Effectué';
          
          final factureEtat = (item['facture_etat'] ?? '').toString().toLowerCase();
          final isPaye = factureEtat.contains('payé');
  
          // NOUVELLE LOGIQUE DE COULEUR
          final Color statusColor;
          if (isPaye) {
            statusColor = AppTheme.successGreen; // Vert si payé
          } else if (isEffectue) {
            statusColor = AppTheme.errorRed; // Rouge si fait mais pas payé
          } else {
            statusColor = AppTheme.warningOrange; // Orange si à venir / en attente
          }
  
          return ListTile(
            onTap: () => TreatmentDetailDialog.show(context, item),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isEffectue ? Icons.check_circle_outline : Icons.schedule_rounded,
                color: statusColor,
                size: 20,
              ),
            ),
            title: Text(
              item['nom'] ?? 'Sans nom',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Icon(Icons.location_on_outlined, size: 12, color: isDark ? Colors.white38 : Colors.grey),
                const SizedBox(width: 4),
                Text(
                  item['axe'] ?? 'N/A',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[600]),
                ),
              ],
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDisplayDate(item['date']),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    etat.toUpperCase(),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDisplayDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}'; // Jour/Mois pour le Dashboard
      }
    } catch (e) {
      // Format de date invalide
    }
    return dateStr;
  }
}
