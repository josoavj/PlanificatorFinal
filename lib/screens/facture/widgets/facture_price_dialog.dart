import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/index.dart';
import '../../../repositories/index.dart';
import '../../../utils/app_snackbars.dart';
import '../../../utils/number_formatter.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/common/index.dart';

import '../../../utils/date_utils.dart' as date_utils;

class FacturePriceDialog extends StatelessWidget {
  final Facture facture;
  final String groupTitle;
  final VoidCallback onDataChanged;

  const FacturePriceDialog({
    super.key,
    required this.facture,
    required this.groupTitle,
    required this.onDataChanged,
  });

  static void show(BuildContext context, Facture facture, String groupTitle, VoidCallback onDataChanged) {
    if (facture.etat == 'Payé' || facture.etat == 'Payée') {
      AppSnackBars.showError(context, ' Impossible de modifier le prix d\'une facture payée');
      return;
    }

    if (!context.read<AuthRepository>().isAdmin) {
      AppSnackBars.showError(context, ' Droits administrateur requis');
      return;
    }

    AppDialogs.showBlurDialog(
      context: context,
      builder: (ctx) => FacturePriceDialog(
        facture: facture,
        groupTitle: groupTitle,
        onDataChanged: onDataChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prixNewCtrl = TextEditingController();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 550, // Format Desktop
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  AppSection(
                    title: 'Détails de la Facture',
                    margin: EdgeInsets.zero,
                    children: [
                      AppInfoTile(
                        icon: Icons.receipt_long_rounded, 
                        label: 'Client / Traitement', 
                        value: groupTitle,
                      ),
                      AppInfoTile(
                        icon: Icons.calendar_today_rounded, 
                        label: 'Date du traitement', 
                        value: date_utils.DateUtils.formatDateFull(facture.dateTraitement),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AppSection(
                    title: 'Modification du montant',
                    margin: EdgeInsets.zero,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ANCIEN PRIX
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Ancien Prix', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  const SizedBox(height: 12),
                                  Container(
                                    height: 56, // Même hauteur que le TextField
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${NumberFormatter.formatMontant(facture.montant)} Ar',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, decoration: TextDecoration.lineThrough, color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // FLÈCHE
                            Padding(
                              padding: const EdgeInsets.only(top: 40, left: 8, right: 16),
                              child: Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryBlue.withValues(alpha: 0.5), size: 20),
                            ),

                            // NOUVEAU PRIX
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Nouveau Prix', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: prixNewCtrl,
                                    keyboardType: TextInputType.number,
                                    autofocus: true,
                                    inputFormatters: [AmountInputFormatter()],
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                                    decoration: InputDecoration(
                                      hintText: 'Ex: 85 000',
                                      prefixIcon: const Icon(Icons.payments_rounded, color: AppTheme.primaryBlue),
                                      suffixText: 'Ar',
                                      filled: true,
                                      fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8, left: 4),
                                    child: Text('Espaces gérés automatiquement', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('ANNULER'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            if (prixNewCtrl.text.isEmpty) {
                              AppSnackBars.showInfo(context, 'Veuillez entrer un nouveau prix');
                              return;
                            }
                            try {
                              final oldPrix = facture.montant;
                              final newPrix = NumberFormatter.parseMontant(prixNewCtrl.text);
                              if (newPrix <= 0) {
                                AppSnackBars.showError(context, 'Le montant doit être supérieur à 0');
                                return;
                              }

                              final authRepo = context.read<AuthRepository>();
                              final factureRepo = context.read<FactureRepository>();
                              final success = await factureRepo.majMontantEtHistorique(
                                facture.factureId, 
                                oldPrix, 
                                newPrix, 
                                isAdmin: authRepo.isAdmin
                              );

                              if (!context.mounted) return;
                              if (!success) {
                                AppSnackBars.showError(context, 'Erreur lors de la modification');
                                return;
                              }

                              Navigator.pop(context);
                              AppSnackBars.showSuccess(context, 'Prix modifié avec succès');
                              onDataChanged();
                            } catch (e) {
                              AppSnackBars.showError(context, 'Erreur: $e');
                            }
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('MODIFIER LE PRIX'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.edit_note_rounded, color: Colors.white, size: 40),
            SizedBox(height: 8),
            Text(
              'MODIFICATION DE PRIX',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
