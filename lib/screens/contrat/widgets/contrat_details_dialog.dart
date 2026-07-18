import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/index.dart';
import '../../../repositories/index.dart';
import '../../../services/database_service.dart';
import '../../../core/sql_queries.dart';
import '../../../widgets/index.dart';
import 'contrat_planning_view.dart';
import 'contrat_invoice_view.dart';
import 'contrat_action_dialogs.dart';

class ContratDetailsDialog extends StatelessWidget {
  final Contrat contrat;
  final Client? client;
  final int numTraitements;
  final VoidCallback onDataChanged;

  const ContratDetailsDialog({
    super.key,
    required this.contrat,
    this.client,
    required this.numTraitements,
    required this.onDataChanged,
  });

  static void show(BuildContext context, Contrat contrat, Client? client, int numTraitements, VoidCallback onDataChanged) {
    AppDialogs.showBlurDialog(
      context: context,
      builder: (ctx) => ContratDetailsDialog(
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
      title: _buildDialogHeader(context, 'Détails du Contrat', contrat.referenceContrat),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context, 'Client associé'),
              if (client != null)
                Container(
                  decoration: AppTheme.cardDecoration(context, radius: 24),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        _buildDetailTile(context, Icons.person_outline, 'Nom Complet', client!.fullName, isDark),
                        _buildSubtleDivider(isDark),
                        _buildDetailTile(context, Icons.alternate_email_rounded, 'Email', client!.email, isDark),
                        _buildSubtleDivider(isDark),
                        _buildDetailTile(context, Icons.phone_outlined, 'Téléphone', client!.telephone, isDark),
                      ],
                    ),
                  ),
                )
              else
                const Text('Informations client non disponibles'),
              const SizedBox(height: 24),

              _buildSectionHeader(context, 'Paramètres du Contrat'),
              Container(
                decoration: AppTheme.cardDecoration(context, radius: 24),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      _buildDetailTile(context, Icons.tag_rounded, 'Référence', contrat.referenceContrat, isDark),
                      _buildSubtleDivider(isDark),
                      _buildDetailTile(context, Icons.event_note_rounded, 'Date Signature', DateFormat('dd/MM/yyyy').format(contrat.dateContrat), isDark),
                      _buildSubtleDivider(isDark),
                      _buildDetailTile(context, Icons.info_outline_rounded, 'Statut actuel', contrat.statutContrat, isDark, valueColor: _getStatusColor(contrat.statutContrat)),
                      _buildSubtleDivider(isDark),
                      _buildDetailTile(context, Icons.timer_outlined, 'Durée du contrat', _getDisplayDuration(contrat), isDark),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionHeader(context, 'Services & Progression'),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _loadTraitements(contrat.contratId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)));
                  final traitements = snapshot.data ?? [];
                  if (traitements.isEmpty) return const Center(child: Text('Aucun service planifié', style: TextStyle(fontSize: 12, color: Colors.grey)));
                  
                  return Column(
                    children: traitements.map((t) {
                      final total = t['total_planif'] is int ? t['total_planif'] as int : int.tryParse(t['total_planif']?.toString() ?? '0') ?? 0;
                      final faites = t['planif_faites'] is int ? t['planif_faites'] as int : int.tryParse(t['planif_faites']?.toString() ?? '0') ?? 0;
                      
                      final dynamic statutsRaw = t['statuts'];
                      final String statutsStr = statutsRaw is List<int> ? String.fromCharCodes(statutsRaw) : (statutsRaw?.toString() ?? '');
                          
                      final hasClassed = statutsStr.toLowerCase().contains('classé');
                      final percent = total > 0 ? (faites / total).clamp(0.0, 1.0) : 0.0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: AppTheme.cardDecoration(context, radius: 16),
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: (hasClassed ? Colors.red : AppTheme.primaryBlue).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                            child: Icon(hasClassed ? Icons.cancel_outlined : Icons.calendar_today_rounded, size: 18, color: hasClassed ? Colors.red : AppTheme.primaryBlue),
                          ),
                          title: Text(t['nom'] ?? 'Service', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('$faites / $total passages réalisés', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600])),
                              if (total > 0) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: percent,
                                    backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
                                    color: percent >= 1.0 ? Colors.green : AppTheme.primaryBlue,
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: hasClassed 
                              ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: const Text('ARRÊTÉ', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)))
                              : null,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        TextButton.icon(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => Navigator.of(context).pop(), label: const Text('FERMER')),
        if (numTraitements > 0) ...[
          FilledButton.icon(
            icon: const Icon(Icons.description_rounded, size: 18),
            label: const Text('FACTURES'),
            onPressed: () { 
              Navigator.of(context).pop(); 
              ContratInvoiceView.show(context, contrat, client, numTraitements, onDataChanged);
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: const Text('PLANNING'),
            onPressed: () { 
              Navigator.of(context).pop(); 
              ContratPlanningView.show(context, contrat, client, numTraitements, onDataChanged);
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.successGreen),
          ),
        ],
        if (contrat.statutContrat == 'Actif' && context.read<AuthRepository>().isAdmin)
          FilledButton.icon(
            icon: const Icon(Icons.history_toggle_off_rounded, size: 18),
            onPressed: () { 
              Navigator.of(context).pop(); 
              ContratAbrogationDialog.show(context, contrat, client, numTraitements, onDataChanged);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            label: const Text('ABROGER'),
          ),
        if (context.read<AuthRepository>().isAdmin)
          FilledButton.icon(
            onPressed: () { 
              Navigator.of(context).pop(); 
              ContratDeleteDialog.show(context, contrat, client, numTraitements, onDataChanged);
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('SUPPRIMER'),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 12), child: Row(children: [
      Container(width: 4, height: 14, decoration: BoxDecoration(color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue, letterSpacing: 1.2)),
    ]));
  }

  Widget _buildDetailTile(BuildContext context, IconData icon, String label, String value, bool isDark, {Color? valueColor}) {
    return ListTile(dense: true, visualDensity: VisualDensity.compact, leading: Icon(icon, size: 20, color: isDark ? AppTheme.accentBlue.withValues(alpha: 0.7) : AppTheme.primaryBlue.withValues(alpha: 0.7)), title: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.grey[500])), subtitle: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? (isDark ? Colors.white : Colors.black87))), contentPadding: const EdgeInsets.symmetric(horizontal: 16));
  }

  Widget _buildSubtleDivider(bool isDark) => Divider(height: 1, thickness: 0.5, indent: 52, endIndent: 16, color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1));

  Color _getStatusColor(String s) {
    final l = s.toLowerCase();
    if (l.contains('actif')) return AppTheme.successGreen;
    if (l.contains('résilié')) return Colors.orange;
    if (l.contains('terminé')) return Colors.grey;
    return AppTheme.primaryBlue;
  }

  String _getDisplayDuration(Contrat contrat) {
    if (contrat.dureeType == 'Indéterminée') return 'Indéterminée';
    if (contrat.dateFin != null) {
      final diff = contrat.dateFin!.difference(contrat.dateDebut);
      final months = (diff.inDays / 30.44).round();
      if (contrat.statutContrat == 'Résilié') {
        final dateRes = DateFormat('dd/MM/yyyy').format(contrat.dateFin!);
        return '$months mois (résilié le $dateRes)';
      }
      if (months > 0) return '$months mois';
    }
    if (contrat.dureeContrat > 0) return '${contrat.dureeContrat} mois';
    return 'Non définie';
  }

  Future<List<Map<String, dynamic>>> _loadTraitements(int id) async => await DatabaseService().query(SqlQueries.getTraitementsDetailedByContrat, [id]);
}
