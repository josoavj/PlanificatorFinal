import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/client.dart';
import '../../../services/database_service.dart';
import '../../../widgets/index.dart';
import '../../../utils/nif_stat_formatter.dart';
import '../../../utils/phone_formatter.dart';
import '../../../utils/number_formatter.dart';
import 'client_edit_dialog.dart';
import 'client_planning_dialog.dart';

class ClientDetailsDialog extends StatelessWidget {
  final Client client;
  final VoidCallback onDataChanged;

  const ClientDetailsDialog({
    super.key,
    required this.client,
    required this.onDataChanged,
  });

  static void show(BuildContext context, Client client, VoidCallback onDataChanged) {
    AppDialogs.showBlurDialog(
      context: context,
      builder: (ctx) => ClientDetailsDialog(
        client: client,
        onDataChanged: onDataChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: _buildDialogHeader(context, 'Détails du Client', client.fullName),
      content: SizedBox(
        width: 950, // Largeur accrue
        child: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- COLONNE GAUCHE (IDENTITÉ & LOCALISATION) ---
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Identité'),
                    Container(
                      decoration: AppTheme.cardDecoration(context, radius: 24),
                      child: Column(
                        children: [
                          _buildDetailRow(context, Icons.person_outline, 'Nom', client.nom),
                          _buildSubtleDivider(isDark),
                          _buildDetailRow(context, Icons.person_pin_outlined, client.prenomLabel, client.prenom),
                          _buildSubtleDivider(isDark),
                          _buildDetailRow(context, Icons.alternate_email_rounded, 'Email', client.email),
                          _buildSubtleDivider(isDark),
                          ...PhoneFormatter.split(client.telephone).asMap().entries.map((e) => Column(
                            children: [
                              _buildDetailRow(context, Icons.phone_outlined, e.key == 0 ? 'Téléphone' : 'Téléphone ${e.key + 1}', PhoneFormatter.format(e.value)),
                              if (e.key < PhoneFormatter.split(client.telephone).length - 1) _buildSubtleDivider(isDark),
                            ],
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 56), // Augmentation
                    _buildSectionHeader(context, 'Localisation'),
                    Container(
                      decoration: AppTheme.cardDecoration(context, radius: 24),
                      child: Column(
                        children: [
                          _buildDetailRow(context, Icons.location_on_outlined, 'Adresse', client.adresse),
                          _buildSubtleDivider(isDark),
                          _buildDetailRow(context, Icons.map_outlined, 'Secteur / Axe', client.axe),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 32),

              // --- COLONNE DROITE (SERVICES & FINANCE) ---
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Classification'),
                    Container(
                      decoration: AppTheme.cardDecoration(context, radius: 24),
                      child: Column(
                        children: [
                          _buildDetailRow(context, Icons.category_outlined, 'Catégorie', client.categorie),
                          if (client.categorie == 'Société') ...[
                            _buildSubtleDivider(isDark),
                            _buildDetailRow(context, Icons.description_outlined, 'NIF', NifStatFormatter.formatNif(client.nif)),
                            _buildSubtleDivider(isDark),
                            _buildDetailRow(context, Icons.badge_outlined, 'STAT', NifStatFormatter.formatStat(client.stat)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 48), // Augmentation
                    _buildSectionHeader(context, 'Services actifs'),
                    if (client.treatmentCount > 0)
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _loadTraitementsDetailedByClient(client.clientId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(strokeWidth: 2)));
                          final traitements = snapshot.data ?? [];
                          if (traitements.isEmpty) return const Center(child: Text('Aucun traitement trouvé', style: TextStyle(fontSize: 12, color: Colors.grey)));

                          return Column(
                            children: traitements.map((t) => _buildClientTreatmentCard(context, t, isDark)).toList(),
                          );
                        },
                      )
                    else
                      _buildNoTreatmentState(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('FERMER')),
        if (client.treatmentCount > 0)
          FilledButton.icon(
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: const Text('PLANNING'),
            onPressed: () {
              Navigator.of(context).pop();
              ClientPlanningDialog.show(context, client, onDataChanged);
            },
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text('ÉDITER'),
          onPressed: () {
            Navigator.of(context).pop();
            ClientEditDialog.show(context, client, onDataChanged);
          },
        ),
      ],
    );
  }

  Widget _buildClientTreatmentCard(BuildContext context, Map<String, dynamic> t, bool isDark) {
    final montant = _parseValue(t['montant_total']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.cardDecoration(context, radius: 20),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.medical_services_outlined, size: 18, color: AppTheme.primaryBlue),
        ),
        title: Text(t['nom'] ?? 'Traitement', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(t['type'] ?? '-', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600])),
        trailing: Text(
          '${NumberFormatter.formatMontant(montant)} Ar',
          style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryBlue, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildNoTreatmentState(bool isDark) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(null as dynamic, radius: 24), // null context safety bypassed for simple UI
      child: Column(
        children: [
          Icon(Icons.assignment_late_outlined, color: isDark ? Colors.white10 : Colors.grey[300], size: 32),
          const SizedBox(height: 8),
          Text('Aucun traitement pour ce client', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  int _parseValue(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.toInt();
    
    // Tentative de parsing propre (gestion des décimales .00 de MySQL)
    final str = val.toString().trim();
    final parsed = double.tryParse(str);
    if (parsed != null) return parsed.toInt();

    // Fallback de secours (nettoyage si format bizarre)
    final numericOnly = str.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(numericOnly) ?? 0;
  }

  Future<List<Map<String, dynamic>>> _loadTraitementsDetailedByClient(int clientId) async {
    final sql = '''
      SELECT 
          t.traitement_id, 
          tt.typeTraitement as nom, 
          tt.categorieTraitement as type,
          (SELECT SUM(f.montant) 
           FROM Facture f 
           WHERE f.facture_id IN (
               SELECT DISTINCT pd2.facture_id 
               FROM PlanningDetails pd2 
               INNER JOIN Planning p2 ON pd2.planning_id = p2.planning_id 
               WHERE p2.traitement_id = t.traitement_id
           )) as montant_total
      FROM Traitement t
      LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
      INNER JOIN Contrat c ON t.contrat_id = c.contrat_id
      WHERE c.client_id = ?
      ORDER BY tt.typeTraitement ASC
    ''';
    return await DatabaseService().query(sql, [clientId]);
  }

  // --- HELPERS ---

  Widget _buildDialogHeader(BuildContext context, String title, String subtitle) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1))), child: Text(subtitle.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue, letterSpacing: 1.2), textAlign: TextAlign.center)),
    ]);
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 12), child: Row(children: [
      Container(width: 4, height: 14, decoration: BoxDecoration(color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue)),
    ]));
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(dense: true, visualDensity: VisualDensity.compact, leading: Icon(icon, size: 20, color: isDark ? AppTheme.accentBlue.withValues(alpha: 0.7) : AppTheme.primaryBlue.withValues(alpha: 0.7)), title: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.grey[500])), subtitle: Text(value.isNotEmpty ? value : '-', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)), contentPadding: const EdgeInsets.symmetric(horizontal: 16));
  }

  Widget _buildSubtleDivider(bool isDark) => Divider(height: 1, thickness: 0.5, indent: 52, endIndent: 16, color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1));
}
