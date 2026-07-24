import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/client.dart';
import '../../../services/database_service.dart';
import '../../../widgets/index.dart';
import '../../../../utils/date_utils.dart' as date_utils;
import 'client_details_dialog.dart';

class ClientPlanningDialog extends StatelessWidget {
  final Client client;
  final VoidCallback onDataChanged;

  const ClientPlanningDialog({
    super.key,
    required this.client,
    required this.onDataChanged,
  });

  static void show(BuildContext context, Client client, VoidCallback onDataChanged) {
    AppDialogs.showBlurDialog(
      context: context,
      builder: (ctx) => ClientPlanningDialog(
        client: client,
        onDataChanged: onDataChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: _buildDialogHeader(context, 'Parcours Planning', client.fullName),
      content: SizedBox(
        width: 550,
        child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
          future: _loadClientTreatmentsByType(client.clientId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()));

            final groupedTreatments = snapshot.data ?? {};
            if (groupedTreatments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_busy_rounded, size: 48, color: isDark ? Colors.white10 : Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text('Aucun traitement planifié'),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: groupedTreatments.length,
              itemBuilder: (context, index) {
                final typeTraitement = groupedTreatments.keys.elementAt(index);
                final traitements = groupedTreatments[typeTraitement] ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 16),
                      child: Row(
                        children: [
                          Container(width: 3, height: 16, decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 12),
                          Text(typeTraitement.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppTheme.primaryBlue, letterSpacing: 1.2)),
                          const Spacer(),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text('${traitements.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue))),
                        ],
                      ),
                    ),
                    ...traitements.map((planning) {
                      final date = planning['date_planification'] as DateTime?;
                      final capitalizedDate = date != null ? date_utils.DateUtils.formatDateFull(date) : 'Date inconnue';

                      final etat = planning['etat'] as String? ?? '-';
                      final isEffectue = etat.toLowerCase().contains('effectué');
                      final statusColor = isEffectue ? (isDark ? AppTheme.darkSuccess : AppTheme.successGreen) : (isDark ? AppTheme.darkWarning : AppTheme.warningOrange);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: AppTheme.cardDecoration(context, radius: 16),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(width: 4, decoration: BoxDecoration(color: statusColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)))),
                              Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(capitalizedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), const SizedBox(height: 4), Text('Réf: ${planning['contrat_reference']}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[600]))]))),
                              Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(etat.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900))))),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            ClientDetailsDialog.show(context, client, onDataChanged);
          },
          child: const Text('RETOUR AUX DÉTAILS'),
        ),
      ],
    );
  }

  Widget _buildDialogHeader(BuildContext context, String title, String subtitle) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1))), child: Text(subtitle.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue, letterSpacing: 1.2), textAlign: TextAlign.center)),
    ]);
  }

  Future<Map<String, List<Map<String, dynamic>>>> _loadClientTreatmentsByType(int clientId) async {
    const sql = '''
      SELECT DISTINCT t.traitement_id, t.contrat_id, tt.typeTraitement, tt.categorieTraitement as type, c.reference_contrat as contrat_reference, pd.planning_detail_id, pd.date_planification, pd.statut as etat, p.planning_id, cl.axe
      FROM Traitement t
      INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
      INNER JOIN Contrat c ON t.contrat_id = c.contrat_id
      INNER JOIN Client cl ON c.client_id = cl.client_id
      LEFT JOIN Planning p ON p.traitement_id = t.traitement_id
      LEFT JOIN PlanningDetails pd ON pd.planning_id = p.planning_id
      WHERE c.client_id = ?
      ORDER BY tt.typeTraitement ASC, pd.date_planification ASC
    ''';
    final rows = await DatabaseService().query(sql, [clientId]);
    final groupedMap = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final typeTraitement = (row['typeTraitement'] as String?) ?? 'Sans type';
      final planningData = {
        'traitementId': row['traitement_id'] as int, 'contratId': row['contrat_id'] as int, 'nom': typeTraitement, 'type': row['type'] as String, 'contrat_reference': row['contrat_reference'] as String, 'planning_detail_id': row['planning_detail_id'], 'date_planification': row['date_planification'] is String ? DateTime.parse(row['date_planification'] as String) : row['date_planification'] as DateTime?, 'axe': row['axe'] as String? ?? '-', 'etat': row['etat'] as String? ?? '-',
      };
      if (!groupedMap.containsKey(typeTraitement)) groupedMap[typeTraitement] = [];
      if (planningData['planning_detail_id'] != null) groupedMap[typeTraitement]!.add(planningData);
    }

    // TRI INTELLIGENT PAR TYPE
    for (final key in groupedMap.keys) {
      groupedMap[key]!.sort((a, b) {
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

    return groupedMap;
  }
}
