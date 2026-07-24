import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/index.dart';
import '../../../services/database_service.dart';
import '../../../widgets/index.dart';
import '../../../utils/app_snackbars.dart';
import 'contrat_details_dialog.dart';

class ContratPlanningView extends StatelessWidget {
  final Contrat contrat;
  final Client? client;
  final int numTraitements;
  final VoidCallback onDataChanged;

  const ContratPlanningView({
    super.key,
    required this.contrat,
    this.client,
    required this.numTraitements,
    required this.onDataChanged,
  });

  static void show(BuildContext context, Contrat contrat, Client? client, int numTraitements, VoidCallback onDataChanged) {
    AppDialogs.showBlurDialog(
      context: context,
      builder: (ctx) => ContratPlanningView(
        contrat: contrat,
        client: client,
        numTraitements: numTraitements,
        onDataChanged: onDataChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: _buildDialogHeader(context, 'Parcours Planning', client?.fullName ?? 'Client'),
      content: SizedBox(
        width: 550,
        child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
          future: _loadContratPlanningsByType(contrat.contratId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final grouped = snapshot.data ?? {};
            if (grouped.isEmpty) return const Center(child: Text('Aucun passage planifié'));

            return ListView.builder(
              shrinkWrap: true,
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final type = grouped.keys.elementAt(index);
                final list = grouped[type] ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsets.only(bottom: 12, top: 16), child: Row(children: [Container(width: 3, height: 16, decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 12), Text(type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppTheme.primaryBlue, letterSpacing: 1.2))])),
                    ...list.map((p) {
                      final date = p['date_planification'] as DateTime?;
                      final etat = p['etat'] as String? ?? '-';
                      final statusColor = _getStatusColorForPlanning(etat);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: AppTheme.cardDecoration(context, radius: 16),
                        child: IntrinsicHeight(
                          child: Row(children: [
                            Container(width: 4, decoration: BoxDecoration(color: statusColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)))),
                            Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Date inconnue', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text('Axe: ${p['axe'] ?? '-'}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[600]))]))),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(etat.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900)))),
                          ]),
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: Row(children: [
                        Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.edit_calendar_rounded, size: 16), label: const Text('REDONDANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), onPressed: () => _showModifyRedondanceDialog(context, type))),
                        const SizedBox(width: 12),
                        Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.build_circle_outlined, size: 16), label: const Text('RÉPARER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), onPressed: () => _showRepairMontantDialog(context))),
                      ]),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), 
          onPressed: () {
            Navigator.of(context).pop();
            ContratDetailsDialog.show(context, contrat, client, numTraitements, onDataChanged);
          }, 
          label: const Text('RETOUR AUX DÉTAILS'),
        ),
      ],
    );
  }

  // --- HELPERS ---

  Widget _buildDialogHeader(BuildContext context, String title, String subtitle) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: Text(subtitle.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue, letterSpacing: 1.2))),
    ]);
  }

  Color _getStatusColorForPlanning(String? s) {
    if (s == null) return Colors.grey;
    final l = s.toLowerCase();
    if (l.contains('effectué')) return AppTheme.successGreen;
    if (l.contains('classé')) return AppTheme.errorRed;
    return AppTheme.warningOrange;
  }

  Future<Map<String, List<Map<String, dynamic>>>> _loadContratPlanningsByType(int id) async {
    final rows = await DatabaseService().query('''
        SELECT DISTINCT t.traitement_id, tt.typeTraitement, pd.planning_detail_id, pd.date_planification, pd.statut, cl.axe
        FROM Traitement t
        JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
        JOIN Contrat c ON t.contrat_id = c.contrat_id
        JOIN Client cl ON c.client_id = cl.client_id
        LEFT JOIN Planning p ON t.traitement_id = p.traitement_id
        LEFT JOIN PlanningDetails pd ON p.planning_id = pd.planning_id
        WHERE t.contrat_id = ?
        ORDER BY tt.typeTraitement ASC, pd.date_planification ASC
    ''', [id]);
    
    final map = <String, List<Map<String, dynamic>>>{};
    for (final r in rows) {
      final type = r['typeTraitement'] ?? 'Sans type';
      if (!map.containsKey(type)) map[type] = [];
      map[type]!.add({
        'traitementId': r['traitement_id'], 
        'planning_detail_id': r['planning_detail_id'], 
        'date_planification': r['date_planification'] is String ? DateTime.parse(r['date_planification']) : r['date_planification'], 
        'etat': r['statut'], 
        'axe': r['axe']
      });
    }

    // TRI INTELLIGENT PAR TYPE
    for (final key in map.keys) {
      map[key]!.sort((a, b) {
        final dateA = a['date_planification'] as DateTime?;
        final dateB = b['date_planification'] as DateTime?;
        final statusA = (a['etat'] as String? ?? '').toLowerCase();
        final statusB = (b['etat'] as String? ?? '').toLowerCase();

        final isDoneA = statusA.contains('effectué');
        final isDoneB = statusB.contains('effectué');

        if (isDoneA != isDoneB) return isDoneA ? -1 : 1;
        if (dateA == null || dateB == null) return 0;
        if (isDoneA) return dateB.compareTo(dateA); // Passé : Récent d'abord
        return dateA.compareTo(dateB); // Futur : Prochain d'abord
      });
    }

    return map;
  }

  void _showModifyRedondanceDialog(BuildContext context, String type) {
    AppSnackBars.showInfo(context, 'Modification redondance pour $type');
  }

  void _showRepairMontantDialog(BuildContext context) {
    AppSnackBars.showInfo(context, 'Réparation en cours...');
  }
}
