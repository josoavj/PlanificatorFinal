import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/index.dart';
import '../../../repositories/index.dart';
import '../../../widgets/index.dart';
import '../../../utils/app_snackbars.dart';
import '../../../utils/number_formatter.dart';
import '../../planning/widgets/remark_dialog.dart';

class HistoryDetailDialog extends StatefulWidget {
  final Map<String, dynamic> rawData;
  final int planningDetailId;

  const HistoryDetailDialog({
    super.key,
    required this.rawData,
    required this.planningDetailId,
  });

  static void show(BuildContext context, Map<String, dynamic> rawData) {
    final id = rawData['planning_detail_id'] as int?;
    if (id == null) return;

    AppDialogs.showBlurDialog(
      context: context,
      builder: (context) => HistoryDetailDialog(
        rawData: rawData,
        planningDetailId: id,
      ),
    );
  }

  @override
  State<HistoryDetailDialog> createState() => _HistoryDetailDialogState();
}

class _HistoryDetailDialogState extends State<HistoryDetailDialog> {
  late Future<Map<String, dynamic>> _historyDataFuture;

  @override
  void initState() {
    super.initState();
    _historyDataFuture = _loadAllData();
  }

  Future<Map<String, dynamic>> _loadAllData() async {
    final id = widget.planningDetailId;
    final remarqueRepo = context.read<RemarqueRepository>();
    final signalementRepo = context.read<SignalementRepository>();
    final factureRepo = context.read<FactureRepository>();

    final results = await Future.wait([
      remarqueRepo.getRemarques(id),
      signalementRepo.getSignalements(id),
      factureRepo.getFacturesByPlanningDetail(id),
    ]);

    final remarques = results[0] as List<Remarque>;
    final signalements = results[1] as List<Signalement>;
    final factures = results[2] as List<Facture>;

    List<Map<String, dynamic>> priceHistory = [];
    if (factures.isNotEmpty) {
      priceHistory = await factureRepo.getPriceHistory(factures.first.factureId);
    }

    return {
      'remarques': remarques,
      'signalements': signalements,
      'facture': factures.isNotEmpty ? factures.first : null,
      'priceHistory': priceHistory,
    };
  }

  void _refresh() {
    setState(() {
      _historyDataFuture = _loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final traitName = widget.rawData['traitement']?.toString() ?? 'Intervention';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 850,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(traitName),
            Flexible(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _historyDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: LoadingWidget(message: 'Compilation du dossier...'));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  final data = snapshot.data!;
                  final remarque = (data['remarques'] as List<Remarque>).firstOrNull;
                  final signalements = data['signalements'] as List<Signalement>;
                  final facture = data['facture'] as Facture?;
                  final prices = data['priceHistory'] as List<Map<String, dynamic>>;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // COLONNE GAUCHE : RÉALISATION & MOUVEMENT
                            Expanded(
                              child: Column(
                                children: [
                                  _buildRealizationSection(remarque),
                                  const SizedBox(height: 24),
                                  _buildMovementSection(signalements),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // COLONNE DROITE : FINANCE & TARIFS
                            Expanded(
                              child: Column(
                                children: [
                                  _buildFinanceSection(facture),
                                  const SizedBox(height: 24),
                                  _buildPriceHistorySection(prices),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: AppTheme.darkBgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
              child: const Icon(Icons.history_edu_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              'JOURNAL DE BORD'.toUpperCase(),
              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealizationSection(Remarque? remarque) {
    final isDone = remarque != null;
    return AppSection(
      title: 'Détails de Réalisation',
      margin: EdgeInsets.zero,
      children: [
        AppInfoTile(
          icon: Icons.task_alt_rounded, 
          label: 'État du passage', 
          value: isDone ? 'EFFECTUÉ' : 'NON RÉALISÉ',
        ),
        if (isDone) ...[
          AppInfoTile(
            icon: Icons.notes_rounded, 
            label: 'Notes de visite', 
            value: remarque.contenu ?? 'Aucune note',
          ),
          AppInfoTile(
            icon: Icons.report_problem_outlined, 
            label: 'Anomalie détectée', 
            value: remarque.probleme ?? 'Aucun',
          ),
        ],
      ],
    );
  }

  Widget _buildMovementSection(List<Signalement> signalements) {
    return AppSection(
      title: 'Mouvements Calendaires',
      margin: EdgeInsets.zero,
      children: [
        if (signalements.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Aucun report ou avancement.', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
          )
        else
          ...signalements.map((s) => ListTile(
            dense: true,
            leading: Icon(
              s.type.toLowerCase() == 'avancement' ? Icons.fast_rewind_rounded : Icons.fast_forward_rounded,
              color: Colors.amber,
              size: 18,
            ),
            title: Text(s.type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.amber)),
            subtitle: Text(s.motif, style: const TextStyle(fontSize: 12)),
          )),
      ],
    );
  }

  Widget _buildFinanceSection(Facture? facture) {
    if (facture == null) return const SizedBox();
    return AppSection(
      title: 'Volet Financier',
      margin: EdgeInsets.zero,
      children: [
        AppInfoTile(
          icon: Icons.tag_rounded, 
          label: 'Référence Facture', 
          value: facture.referenceFacture ?? 'N/A',
        ),
        AppInfoTile(
          icon: Icons.payments_outlined, 
          label: 'Montant facturé', 
          value: '${NumberFormatter.formatMontant(facture.montant)} Ar',
        ),
        AppInfoTile(
          icon: Icons.account_balance_wallet_outlined, 
          label: 'État de règlement', 
          value: facture.etat.toUpperCase(),
        ),
        if (facture.isPaid)
          AppInfoTile(
            icon: Icons.credit_card_rounded, 
            label: 'Mode de paiement', 
            value: facture.mode ?? 'Non spécifié',
          ),
      ],
    );
  }

  Widget _buildPriceHistorySection(List<Map<String, dynamic>> prices) {
    return AppSection(
      title: 'Évolution du Tarif',
      margin: EdgeInsets.zero,
      children: [
        if (prices.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Le tarif n\'a pas changé.', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
          )
        else
          ...prices.map((p) {
            final oldP = p['old_amount'] as int;
            final newP = p['new_amount'] as int;
            final date = DateTime.parse(p['change_date'].toString());
            return ListTile(
              dense: true,
              leading: const Icon(Icons.trending_up_rounded, color: AppTheme.primaryBlue, size: 16),
              title: Text(
                '${NumberFormatter.formatMontant(oldP)} → ${NumberFormatter.formatMontant(newP)} Ar',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              subtitle: Text(
                'Le ${DateFormat('dd/MM/yyyy HH:mm').format(date)}',
                style: const TextStyle(fontSize: 10),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final isAdmin = context.read<AuthRepository>().isAdmin;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('FERMER'),
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                onPressed: () => _openCorrectionMode(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                label: const Text('MODIFIER LE RAPPORT'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openCorrectionMode(BuildContext context) async {
    // On doit charger la facture et la remarque actuelles pour le dialogue
    final id = widget.planningDetailId;
    final factureRepo = context.read<FactureRepository>();
    final remarqueRepo = context.read<RemarqueRepository>();

    final facts = await factureRepo.getFacturesByPlanningDetail(id);
    final rems = await remarqueRepo.getRemarques(id);

    if (!mounted) return;
    if (facts.isEmpty) {
      AppSnackBars.showError(context, 'Données financières manquantes');
      return;
    }

    final pd = PlanningDetails.fromJson(widget.rawData);
    
    AppDialogs.showBlurDialog(
      context: context,
      builder: (ctx) => RemarqueDialog(
        planningDetail: pd,
        facture: facts.first,
        existingRemarque: rems.isNotEmpty ? rems.first : null,
        onSaved: () {
          _refresh();
          context.read<PlanningDetailsRepository>().loadAllTreatmentsComplete();
        },
      ),
    );
  }
}
