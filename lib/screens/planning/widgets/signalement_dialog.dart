import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/index.dart';
import '../../../repositories/signalement_repository.dart';
import '../../../utils/date_helper.dart';
import '../../../services/logging_service.dart';
import '../../../utils/app_snackbars.dart';
import '../../../core/theme.dart';
import '../../../widgets/index.dart';
import '../../../widgets/common/index.dart';

class SignalementDialog extends StatefulWidget {
  final PlanningDetails planningDetail;
  final VoidCallback onSaved;

  const SignalementDialog({
    super.key,
    required this.planningDetail,
    required this.onSaved,
  });

  @override
  State<SignalementDialog> createState() => _SignalementDialogState();
}

class _SignalementDialogState extends State<SignalementDialog> {
  late TextEditingController _motifCtrl;
  late TextEditingController _dateCtrl;

  final logger = createLoggerWithFileOutput(name: 'signalement_dialog');

  String _type = 'décalage'; // 'avancement' ou 'décalage'
  bool _changerRedondance =
      false; // Décaler TOUTES les dates futures (vs garder)
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _motifCtrl = TextEditingController();
    _dateCtrl = TextEditingController(
      text: DateHelper.format(widget.planningDetail.datePlanification),
    );
  }

  @override
  void dispose() {
    _motifCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSignalement() async {
    if (_isLoading) return;

    if (_motifCtrl.text.isEmpty) {
      AppSnackBars.showWarning(context, 'Veuillez entrer un motif');
      return;
    }

    if (_dateCtrl.text.isEmpty) {
      AppSnackBars.showWarning(context, 'Veuillez sélectionner une date');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = context.read<SignalementRepository>();
      final newDate = DateHelper.parseAny(_dateCtrl.text);
      final oldDate = widget.planningDetail.datePlanification;

      if (newDate == null) {
        AppSnackBars.showError(context, 'Date invalide');
        return;
      }

      //  ÉTAPE 1: Créer le signalement (enregistre le motif)
      await repo.createSignalement(
        planningDetailsId: widget.planningDetail.planningDetailId,
        motif: _motifCtrl.text,
        type: _type,
      );
      if (!mounted) return;
      logger.i(' Signalement créé');

      // ÉTAPE 2A: TOUJOURS modifier la date ACTUELLE d'abord
      logger.i(' Étape 2a: Modifier la date du planning courant');
      logger.i(
        '   planningDetailId=${widget.planningDetail.planningDetailId}, oldDate=$oldDate → newDate=$newDate',
      );
      await repo.modifierDatePlanning(
        planningDetailsId: widget.planningDetail.planningDetailId,
        newDate: newDate,
      );
      if (!mounted) return;

      // ÉTAPE 2B: Appliquer la logique DÉCALER vs GARDER
      if (_changerRedondance) {
        // === MODE 1: DÉCALER TOUTES les dates futures ===
        logger.i(
          ' MODE DÉCALER: appliquer l\'écart à TOUTES les dates futures',
        );
        logger.i(
          '   ancienneDateModifiee=$oldDate, nouvelleDateModifiee=$newDate',
        );

        await repo.modifierRedondance(
          planningId: widget.planningDetail.planningId,
          planningDetailsId: widget.planningDetail.planningDetailId,
          ancienneDateModifiee: oldDate,
          nouvelleDateModifiee: newDate,
        );
        if (!mounted) return;
      } else {
        // === MODE 2: GARDER - on a déjà modifié JUSTE cette date en 2A ===
        logger.i(' MODE GARDER: date modifiée (autres dates inchangées)');
      }

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);

        // Générer un message descriptif avec l'écart
        final ecart = _calculateEcart();
        final mois = ecart['mois'] as int;
        final jours = ecart['jours'] as int;
        final direction = ecart['direction'] as String;

        String messageEcart = '';
        if (direction == 'Décalage') {
          messageEcart = 'Décaler de ';
        } else if (direction == 'Avancement') {
          messageEcart = 'Avancer de ';
        } else {
          messageEcart = 'Date modifiée: ';
        }

        if (mois != 0) {
          messageEcart += '$mois mois';
          if (jours != 0) {
            messageEcart += ' et $jours jours';
          }
        } else if (jours != 0) {
          messageEcart += '$jours jours';
        }

        final modeTexte = _changerRedondance
            ? ' (toutes les dates futures)'
            : ' (cette date uniquement)';

        AppSnackBars.showSuccess(context, ' Signalement: $messageEcart$modeTexte');
      }
    } catch (e) {
      logger.e(' Erreur signalement: $e');
      if (mounted) {
        AppSnackBars.showError(context, 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    try {
      final currentDate = DateHelper.parseAny(_dateCtrl.text) ?? DateTime.now();

      final picked = await showDatePicker(
        context: context,
        initialDate: currentDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2099),
      );

      if (picked != null && mounted) {
        setState(() => _dateCtrl.text = DateHelper.format(picked));
      }
    } catch (e) {
      logger.e('Erreur sélection date: $e');
    }
  }

  /// Calcule l'écart de mois et jours entre deux dates
  Map<String, dynamic> _calculateEcart() {
    final oldDate = widget.planningDetail.datePlanification;
    final newDate = DateHelper.parseAny(_dateCtrl.text);

    if (newDate == null) {
      return {'mois': 0, 'jours': 0, 'total': 0, 'direction': ''};
    }

    final difference = newDate.difference(oldDate);
    final totalJours = difference.inDays;

    // Calculer les mois entiers et les jours restants
    int mois = 0;
    int jours = totalJours;

    if (totalJours.abs() >= 28) {
      // Approximation: 1 mois ≈ 30 jours
      mois = (totalJours / 30).toInt();
      jours = totalJours % 30;
    }

    // Direction: Avancement ou Décalage
    String direction = '';
    if (totalJours < 0) {
      direction = 'Avancement'; // Date antérieure
      mois = mois.abs();
      jours = jours.abs();
    } else if (totalJours > 0) {
      direction = 'Décalage'; // Date postérieure
    }

    return {
      'mois': mois,
      'jours': jours,
      'total': totalJours,
      'direction': direction,
    };
  }

  /// Génère un texte formaté pour l'écart
  String _ecartText() {
    final ecart = _calculateEcart();
    final mois = ecart['mois'] as int;
    final jours = ecart['jours'] as int;
    final direction = ecart['direction'] as String;

    if (direction.isEmpty) return '';

    String texte = ' ';

    if (mois != 0) {
      texte += '$mois mois';
      if (jours != 0) {
        texte += ' et $jours jours';
      }
    } else if (jours != 0) {
      texte += '$jours jours';
    } else {
      texte += 'Même date';
    }

    return texte;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // SECTION 1: PASSAGE ACTUEL
                    AppSection(
                      title: 'Informations de l\'Intervention',
                      margin: EdgeInsets.zero,
                      children: [
                        AppInfoTile(
                          icon: Icons.calendar_today_rounded, 
                          label: 'Date initialement prévue', 
                          value: DateHelper.format(widget.planningDetail.datePlanification),
                        ),
                        AppInfoTile(
                          icon: Icons.info_outline_rounded, 
                          label: 'Statut actuel', 
                          value: widget.planningDetail.statut.toUpperCase(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // SECTION 2: MODIFICATION
                    AppSection(
                      title: 'Nouveau Planning',
                      margin: EdgeInsets.zero,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Type de changement', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(value: 'avancement', label: Text('Avancement'), icon: Icon(Icons.fast_rewind_rounded)),
                                    ButtonSegment(value: 'décalage', label: Text('Décalage'), icon: Icon(Icons.fast_forward_rounded)),
                                  ],
                                  selected: {_type},
                                  onSelectionChanged: (v) => setState(() => _type = v.first),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _dateCtrl,
                                readOnly: true,
                                onTap: _selectDate,
                                decoration: InputDecoration(
                                  labelText: 'Nouvelle date souhaitée',
                                  prefixIcon: const Icon(Icons.event_repeat_rounded, color: Colors.amber),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_ecartText().trim().isNotEmpty) _buildGapBadge(),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: _motifCtrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Motif du signalement',
                              hintText: 'Pourquoi ce changement de date ?',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // SECTION 3: OPTIONS DE CASCADE
                    AppSection(
                      title: 'Impact sur le futur',
                      margin: EdgeInsets.zero,
                      children: [
                        _buildCascadeSwitch(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildFooterActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade700, Colors.orange.shade800],
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
              child: const Icon(Icons.notification_important_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            const Text(
              'SIGNALEMENT & REPORT',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGapBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.amber, size: 14),
          const SizedBox(width: 8),
          Text(
            _ecartText().toUpperCase(),
            style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCascadeSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _changerRedondance ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _changerRedondance ? Icons.dynamic_feed_rounded : Icons.looks_one_rounded, 
              color: _changerRedondance ? AppTheme.primaryBlue : Colors.grey, 
              size: 20
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Décaler en cascade ?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Appliquer ce décalage à TOUTES les dates futures', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Switch.adaptive(
            value: _changerRedondance, 
            onChanged: (v) => setState(() => _changerRedondance = v)
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('ANNULER'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: _isLoading ? null : _saveSignalement,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('ENREGISTRER LE REPORT'),
            ),
          ),
        ],
      ),
    );
  }
}
