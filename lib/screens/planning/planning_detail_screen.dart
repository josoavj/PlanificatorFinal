import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/planning_details.dart';
import '../../repositories/index.dart';
import '../../core/theme.dart';
import '../../widgets/index.dart';
import 'widgets/signalement_dialog.dart';
import 'widgets/remark_dialog.dart';
import '../../utils/app_snackbars.dart';

class PlanningDetailScreen extends StatefulWidget {
  final Map<String, dynamic> treatment;
  final int planningDetailId;

  const PlanningDetailScreen({
    super.key,
    required this.treatment,
    required this.planningDetailId,
  });

  @override
  State<PlanningDetailScreen> createState() => _PlanningDetailScreenState();
}

class _PlanningDetailScreenState extends State<PlanningDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trait = widget.treatment['traitement']?.toString() ?? '';
    final axe = widget.treatment['axe']?.toString() ?? '';
    final etat = widget.treatment['etat']?.toString() ?? '';
    final isEffectue = etat.toLowerCase().contains('effectué');
    final statusColor = isEffectue 
        ? (isDark ? AppTheme.darkSuccess : AppTheme.successGreen) 
        : (isDark ? AppTheme.darkWarning : AppTheme.warningOrange);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 70),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  AppSection(
                    title: 'Détails du Traitement',
                    margin: EdgeInsets.zero,
                    children: [
                      AppInfoTile(
                        icon: Icons.medical_services_outlined, 
                        label: 'Service', 
                        value: trait,
                      ),
                      AppInfoTile(
                        icon: Icons.map_outlined, 
                        label: 'Axe / Secteur', 
                        value: axe,
                      ),
                      AppInfoTile(
                        icon: Icons.info_outline_rounded, 
                        label: 'État actuel', 
                        value: etat,
                        trailing: Icon(
                          isEffectue ? Icons.check_circle : Icons.pending,
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  AppSection(
                    title: 'Actions disponibles',
                    margin: EdgeInsets.zero,
                    children: [
                      AppActionCard(
                        icon: Icons.edit_note_rounded, 
                        title: 'Ajouter une remarque', 
                        subtitle: 'Noter des précisions ou créer une facture', 
                        onTap: _showRemarqueDialog,
                      ),
                      AppActionCard(
                        icon: Icons.report_problem_outlined, 
                        title: 'Signaler un problème', 
                        subtitle: 'Enregistrer une anomalie durant le traitement', 
                        onTap: _showSignalementDialog,
                        isDestructive: true,
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

  void _showRemarqueDialog() {
    final pd = PlanningDetails.fromJson(widget.treatment);
    AppDialogs.showBlurDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (ctx) => AlertDialog(
        title: const Text('Créer Facture'), 
        content: const Text('Une facture sera créée automatiquement pour cette date'), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')), 
          ElevatedButton(
            onPressed: () async {
              final fId = await context.read<FactureRepository>().createFactureComplete(
                planningDetailId: pd.planningDetailId, 
                referenceFacture: 'FAC-${DateTime.now().millisecondsSinceEpoch}', 
                montant: 0, 
                etat: 'À venir', 
                axe: widget.treatment['axe'] ?? '', 
                dateTraitement: pd.datePlanification
              );
              if (fId != -1) {
                final factures = await context.read<FactureRepository>().getFacturesByPlanningDetail(pd.planningDetailId);
                if (factures.isNotEmpty) {
                  if (mounted) Navigator.pop(ctx);
                  if (mounted) {
                    AppDialogs.showBlurDialog(
                      context: context, 
                      builder: (ctx2) => RemarqueDialog(
                        planningDetail: pd, 
                        facture: factures.first, 
                        onSaved: () async { 
                          await context.read<PlanningDetailsRepository>().loadAllTreatmentsComplete(); 
                          await context.read<FactureRepository>().loadAllFactures(); 
                          if (mounted) {
                            AppSnackBars.showSuccess(context, 'Remarque ajoutée'); 
                            Navigator.of(context).pop();
                          }
                        }
                      )
                    );
                  }
                }
              }
            }, 
            child: const Text('Créer Facture')
          )
        ]
      )
    );
  }

  void _showSignalementDialog() {
    final pd = PlanningDetails.fromJson(widget.treatment);
    AppDialogs.showBlurDialog(
      context: context, 
      builder: (ctx) => SignalementDialog(
        planningDetail: pd, 
        onSaved: () async { 
          await context.read<PlanningDetailsRepository>().loadAllTreatmentsComplete(); 
          await context.read<FactureRepository>().loadAllFactures(); 
          if (mounted) {
            AppSnackBars.showSuccess(context, 'Signalement enregistré'); 
            Navigator.of(context).pop(); 
          }
        }
      )
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      alignment: Alignment.center, 
      clipBehavior: Clip.none, 
      children: [
        Container(
          height: 230, 
          width: double.infinity, 
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).colorScheme.surfaceContainer : AppTheme.primaryBlue, 
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(48))
          )
        ),
        Positioned(
          top: 40, 
          left: 8, 
          child: IconButton(
            onPressed: () => Navigator.pop(context), 
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24)
          )
        ),
        Positioned(
          bottom: -45, 
          child: Container(
            padding: const EdgeInsets.all(6), 
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBg : Colors.white, 
              shape: BoxShape.circle, 
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))
              ]
            ), 
            child: Container(
              width: 100, 
              height: 100, 
              decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), shape: BoxShape.circle), 
              child: const Icon(Icons.calendar_today_rounded, size: 48, color: AppTheme.primaryBlue)
            )
          )
        )
      ]
    );
  }
}
