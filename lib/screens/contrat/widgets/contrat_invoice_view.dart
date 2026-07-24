import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/index.dart';
import '../../../services/database_service.dart';
import '../../../core/sql_queries.dart';
import '../../../widgets/index.dart';
import '../../../utils/number_formatter.dart';
import 'contrat_details_dialog.dart';

class ContratInvoiceView extends StatelessWidget {
  final Contrat contrat;
  final Client? client;
  final int numTraitements;
  final VoidCallback onDataChanged;

  const ContratInvoiceView({
    super.key,
    required this.contrat,
    this.client,
    required this.numTraitements,
    required this.onDataChanged,
  });

  static void show(BuildContext context, Contrat contrat, Client? client, int numTraitements, VoidCallback onDataChanged) {
    AppDialogs.showBlurDialog(
      context: context,
      builder: (ctx) => ContratInvoiceView(
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
      title: _buildDialogHeader(context, 'Factures du Contrat', contrat.referenceContrat),
      content: SizedBox(
        width: 550,
        child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
          future: _loadFacturesGroupedByTraitement(contrat.contratId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final facturesGrouped = snapshot.data ?? {};
            if (facturesGrouped.isEmpty) return const Center(child: Text('Aucune facture trouvée'));
            
            return ListView.builder(
              shrinkWrap: true,
              itemCount: facturesGrouped.length,
              itemBuilder: (context, index) {
                final type = facturesGrouped.keys.elementAt(index);
                final factures = facturesGrouped[type] ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsets.only(bottom: 12, top: 16), child: Row(children: [Container(width: 3, height: 16, decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 12), Text(type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppTheme.primaryBlue, letterSpacing: 1.2))])),
                    ...factures.map((f) {
                      final etat = f['etat'] as String? ?? 'Inconnu';
                      final isPaid = etat.toLowerCase().contains('payé');
                      final statusColor = isPaid ? (isDark ? AppTheme.darkSuccess : AppTheme.successGreen) : (isDark ? AppTheme.darkWarning : AppTheme.warningOrange);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: AppTheme.cardDecoration(context, radius: 16),
                        child: ListTile(
                          dense: true,
                          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(isPaid ? Icons.check_circle_outline : Icons.pending_actions_rounded, size: 18, color: statusColor)),
                          title: Text('Facture #${f['factureId']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('${NumberFormatter.formatMontant(f['montant'] as int)} Ar', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600])),
                          trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(etat.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900))),
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

  Future<Map<String, List<Map<String, dynamic>>>> _loadFacturesGroupedByTraitement(int id) async {
    final rows = await DatabaseService().query(SqlQueries.getFacturesGroupedByTraitement, [id]);
    final map = <String, List<Map<String, dynamic>>>{};
    for (final r in rows) {
      final type = r['typeTraitement'] ?? 'Sans type';
      if (!map.containsKey(type)) map[type] = [];
      map[type]!.add({
        'factureId': r['facture_id'],
        'montant': r['montant'],
        'dateTraitement': r['date_traitement'] is String
            ? DateTime.parse(r['date_traitement'])
            : r['date_traitement'],
        'etat': r['etat']
      });
    }

    // TRI INTELLIGENT : Passé (DESC) puis Futur (ASC)
    for (final key in map.keys) {
      map[key]!.sort((a, b) {
        final dateA = a['dateTraitement'] as DateTime;
        final dateB = b['dateTraitement'] as DateTime;
        final etatA = (a['etat'] as String? ?? '').toLowerCase();
        final etatB = (b['etat'] as String? ?? '').toLowerCase();

        final isDoneA = etatA.contains('payé') || etatA.contains('payée') || etatA.contains('effectué');
        final isDoneB = etatB.contains('payé') || etatB.contains('payée') || etatB.contains('effectué');

        // 1. Les faits en premier
        if (isDoneA != isDoneB) return isDoneA ? -1 : 1;

        // 2. Si les deux sont faits : le plus récent en premier (DESC)
        if (isDoneA) return dateB.compareTo(dateA);

        // 3. Si les deux sont à venir : le plus proche en premier (ASC)
        return dateA.compareTo(dateB);
      });
    }

    return map;
  }
}
