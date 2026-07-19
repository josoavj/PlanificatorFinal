import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/common/index.dart';
import '../../../utils/number_formatter.dart';
import '../../../repositories/index.dart';

import '../../client/widgets/client_details_dialog.dart';

import '../../../utils/date_utils.dart' as date_utils;

class TreatmentDetailDialog extends StatelessWidget {
  final Map<String, dynamic> data;

  const TreatmentDetailDialog({super.key, required this.data});

  static void show(BuildContext context, Map<String, dynamic> data) {
    AppDialogs.showBlurDialog(
      context: context,
      builder: (context) => TreatmentDetailDialog(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Logique des statuts
    final etat = (data['etat'] ?? 'Non défini').toString();
    final isEffectue = etat.trim() == 'Effectué';
    final statusColor = isEffectue ? AppTheme.successGreen : AppTheme.warningOrange;
    
    // Logique facture
    final montant = data['montant'] ?? 0;
    final factureEtat = (data['facture_etat'] ?? '').toString().toLowerCase().trim();
    final isPaye = factureEtat.contains('payé');
    
    // Contacts
    final telephone = data['telephone'] ?? '';
    final email = data['email'] ?? 'Non renseigné';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 800, // Largeur Desktop
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 12),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, statusColor),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // PREMIÈRE LIGNE (2 COLONNES)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppSection(
                            title: 'Informations Générales',
                            margin: EdgeInsets.zero,
                            children: [
                              AppInfoTile(
                                icon: Icons.assignment_rounded, 
                                label: 'Traitement / Client', 
                                value: data['nom'] ?? 'N/A',
                              ),
                              AppInfoTile(
                                icon: Icons.calendar_today_rounded, 
                                label: isEffectue ? 'Date de passage' : 'Date prévue', 
                                value: _formatFullDate(data['date']),
                              ),
                              AppInfoTile(
                                icon: Icons.info_outline_rounded, 
                                label: 'État du passage', 
                                value: etat.toUpperCase(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: AppSection(
                            title: 'Finances & Zone',
                            margin: EdgeInsets.zero,
                            children: [
                              AppInfoTile(
                                icon: Icons.payments_outlined, 
                                label: isPaye ? 'Montant payé' : 'Montant à prévoir', 
                                value: '${NumberFormatter.formatMontant(montant)} Ar',
                              ),
                              AppInfoTile(
                                icon: Icons.map_outlined, 
                                label: 'Axe / Secteur', 
                                value: data['axe'] ?? 'N/A',
                              ),
                              AppInfoTile(
                                icon: Icons.receipt_long_outlined, 
                                label: 'Statut Facturation', 
                                value: isPaye ? 'PAYÉE' : 'NON RÉGLÉE',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // DEUXIÈME LIGNE (CONTACTS - COTE À COTE)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppSection(
                            title: 'Contact Téléphonique',
                            margin: EdgeInsets.zero,
                            children: [
                              AppInfoTile(
                                icon: Icons.phone_android_rounded, 
                                label: 'Mobile', 
                                value: _formatPhone(telephone),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: AppSection(
                            title: 'Contact Email',
                            margin: EdgeInsets.zero,
                            children: [
                              AppInfoTile(
                                icon: Icons.alternate_email_rounded, 
                                label: 'Email', 
                                value: email,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: const Icon(Icons.description_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            const Text(
              'RÉSUMÉ DU TRAITEMENT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              label: const Text('FERMER'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(Icons.person_search_rounded, size: 18),
              onPressed: () async {
                final clientId = data['client_id'];
                if (clientId != null && clientId is int) {
                  final clientRepo = context.read<ClientRepository>();
                  
                  // Afficher un petit loader si le chargement prend du temps
                  await clientRepo.loadClient(clientId);
                  final client = clientRepo.currentClient;
                  
                  if (client != null && context.mounted) {
                    Navigator.pop(context); // Fermer le résumé
                    ClientDetailsDialog.show(context, client, () {
                      // Callback si changement de données
                    });
                  }
                }
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              label: const Text('VOIR FICHE CLIENT'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return 'Non renseigné';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return phone;
    return '${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 8)} ${digits.substring(8, 10)}';
  }

  String _formatFullDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return date_utils.DateUtils.formatDateFull(date);
    } catch (e) {
      return dateStr;
    }
  }
}
