import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:Planificator/models/index.dart';
import 'package:Planificator/repositories/signalement_repository.dart';
import 'package:Planificator/utils/date_helper.dart';

class SignalementDialog extends StatefulWidget {
  final PlanningDetails planningDetail;
  final VoidCallback onSaved;

  const SignalementDialog({
    Key? key,
    required this.planningDetail,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<SignalementDialog> createState() => _SignalementDialogState();
}

class _SignalementDialogState extends State<SignalementDialog> {
  late TextEditingController _motifCtrl;
  late TextEditingController _dateCtrl;

  final logger = Logger();

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Veuillez entrer un motif')));
      return;
    }

    if (_dateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = context.read<SignalementRepository>();
      final newDate = DateHelper.parseAny(_dateCtrl.text);
      final oldDate = widget.planningDetail.datePlanification;

      if (newDate == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Date invalide')));
        return;
      }

      // ✅ ÉTAPE 1: Créer le signalement (enregistre le motif)
      await repo.createSignalement(
        planningDetailsId: widget.planningDetail.planningDetailId,
        motif: _motifCtrl.text,
        type: _type,
      );
      logger.i('✅ Signalement créé');

      // ✅ ÉTAPE 2A: TOUJOURS modifier la date ACTUELLE d'abord
      logger.i('📌 Étape 2a: Modifier la date du planning courant');
      logger.i(
        '   planningDetailId=${widget.planningDetail.planningDetailId}, oldDate=$oldDate → newDate=$newDate',
      );
      await repo.modifierDatePlanning(
        planningDetailsId: widget.planningDetail.planningDetailId,
        newDate: newDate,
      );

      // ✅ ÉTAPE 2B: Appliquer la logique DÉCALER vs GARDER
      if (_changerRedondance) {
        // === MODE 1: DÉCALER TOUTES les dates futures ===
        logger.i(
          '🔄 MODE DÉCALER: appliquer l\'écart à TOUTES les dates futures',
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
      } else {
        // === MODE 2: GARDER - on a déjà modifié JUSTE cette date en 2A ===
        logger.i('✅ MODE GARDER: date modifiée (autres dates inchangées)');
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Signalement: $messageEcart$modeTexte'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      logger.e('❌ Erreur signalement: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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

    String texte = '📊 ';

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
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Signalement - ${DateHelper.format(widget.planningDetail.datePlanification)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // Type de signalement
                Text(
                  'Type de signalement',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'avancement',
                      label: Text('Avancement'),
                    ),
                    ButtonSegment(value: 'décalage', label: Text('Décalage')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (newSelection) {
                    setState(() => _type = newSelection.first);
                  },
                ),
                const SizedBox(height: 16),

                // Motif
                TextField(
                  controller: _motifCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Motif du signalement',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: Visite impossible, client absent, ...',
                  ),
                  maxLines: 4,
                  minLines: 4,
                ),
                const SizedBox(height: 16),

                // Nouvelle date
                TextField(
                  controller: _dateCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nouvelle date de planification',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _selectDate,
                    ),
                  ),
                  readOnly: true,
                  onChanged: (_) {
                    setState(() {
                      // Auto-détection du type en fonction de l'écart
                      final ecart = _calculateEcart();
                      final direction = ecart['direction'] as String;
                      if (direction.isNotEmpty && direction != 'Même date') {
                        _type = direction.toLowerCase();
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),

                // 📊 Affichage de l'écart (jours/mois)
                if (_ecartText().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _ecartText(),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Décaler redondance
                CheckboxListTile(
                  title: const Text('Décaler TOUTES les dates futures'),
                  subtitle: const Text('(sinon ne modifie que cette date)'),
                  value: _changerRedondance,
                  onChanged: (val) {
                    setState(() => _changerRedondance = val ?? false);
                  },
                ),

                const SizedBox(height: 24),

                // Boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isLoading ? null : _saveSignalement,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Enregistrer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
