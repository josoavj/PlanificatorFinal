import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/facture.dart';
import '../../models/planning_details.dart';
import '../../models/remarque.dart';
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
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final planningDetailId = widget.planningDetailId;
    final factureRepo = context.read<FactureRepository>();
    final remarqueRepo = context.read<RemarqueRepository>();
    final planningRepo = context.read<PlanningDetailsRepository>();

    // Charger les 3 sources en parallèle pour la réactivité
    final results = await Future.wait([
      planningRepo.getPlanningDetailComplete(planningDetailId),
      factureRepo.getFacturesByPlanningDetail(planningDetailId),
      remarqueRepo.getRemarques(planningDetailId),
    ]);

    final treatmentData = results[0] as Map<String, dynamic>?;
    final factures = results[1] as List<Facture>;
    final remarques = results[2] as List<Remarque>;

    return {
      'treatment': treatmentData ?? widget.treatment,
      'facture': factures.isNotEmpty ? factures.first : null,
      'remarque': remarques.isNotEmpty ? remarques.first : null,
    };
  }

  void _refresh() {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingWidget());
          }

          final treatment = snapshot.data?['treatment'] as Map<String, dynamic>;
          final facture = snapshot.data?['facture'] as Facture?;
          final remarque = snapshot.data?['remarque'] as Remarque?;
          
          final trait = treatment['traitement']?.toString() ?? '';
          final axe = treatment['axe']?.toString() ?? '';
          final etat = treatment['etat']?.toString() ?? '';
          final isEffectue = etat.toLowerCase().contains('effectué');
          
          final isPaye = facture?.isPaid ?? false;
          final isLocked = isEffectue && isPaye;

          final statusColor = isEffectue 
              ? (isDark ? AppTheme.darkSuccess : AppTheme.successGreen) 
              : (isDark ? AppTheme.darkWarning : AppTheme.warningOrange);

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 70),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // BADGE DE STATUT FINAL
                      if (isLocked)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_rounded, color: AppTheme.successGreen, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('DOSSIER TERMINÉ', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.successGreen, fontSize: 11, letterSpacing: 1)),
                                    Text('Le passage a été effectué et la facture est réglée.', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

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
                            value: etat.toUpperCase(),
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
                        title: isLocked ? 'Gestion Administrative' : 'Actions disponibles',
                        margin: EdgeInsets.zero,
                        children: [
                          if (isLocked)
                            AppActionCard(
                              icon: Icons.edit_note_rounded, 
                              title: 'Modifier les informations', 
                              subtitle: 'Corriger la remarque ou les détails financiers', 
                              onTap: () => _showEditRemarqueDialog(treatment, facture!, remarque),
                            )
                          else ...[
                            AppActionCard(
                              icon: Icons.edit_note_rounded, 
                              title: 'Ajouter une remarque', 
                              subtitle: 'Noter des précisions ou créer une facture', 
                              onTap: () => _showRemarqueDialog(treatment),
                            ),
                            AppActionCard(
                              icon: Icons.report_problem_outlined, 
                              title: 'Signaler un problème', 
                              subtitle: 'Enregistrer une anomalie durant le traitement', 
                              onTap: () => _showSignalementDialog(treatment),
                              isDestructive: true,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditRemarqueDialog(Map<String, dynamic> treatment, Facture facture, Remarque? remarque) {
    final pd = PlanningDetails.fromJson(treatment);
    AppDialogs.showBlurDialog(
      context: context, 
      builder: (ctx) => RemarqueDialog(
        planningDetail: pd, 
        facture: facture, 
        existingRemarque: remarque,
        onSaved: () async { 
          await context.read<PlanningDetailsRepository>().refreshAll(); 
          await context.read<FactureRepository>().loadAllFactures(); 
          if (mounted) {
            _refresh();
          }
        }
      )
    );
  }

  void _showRemarqueDialog(Map<String, dynamic> treatment) {
    final pd = PlanningDetails.fromJson(treatment);
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
                axe: treatment['axe'] ?? '', 
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
                          // Utilisation du refresh global consolidé
                          await context.read<PlanningDetailsRepository>().refreshAll(); 
                          await context.read<FactureRepository>().loadAllFactures(); 
                          if (mounted) {
                            AppSnackBars.showSuccess(context, 'Remarque ajoutée'); 
                            _refresh();
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

  void _showSignalementDialog(Map<String, dynamic> treatment) {
    final pd = PlanningDetails.fromJson(treatment);
    AppDialogs.showBlurDialog(
      context: context, 
      builder: (ctx) => SignalementDialog(
        planningDetail: pd, 
        onSaved: () async { 
          // Utilisation du refresh global consolidé
          await context.read<PlanningDetailsRepository>().refreshAll(); 
          await context.read<FactureRepository>().loadAllFactures(); 
          if (mounted) {
            AppSnackBars.showSuccess(context, 'Signalement enregistré'); 
            _refresh();
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
