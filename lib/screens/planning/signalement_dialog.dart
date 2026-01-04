import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:planificator/models/index.dart';
import 'package:planificator/repositories/signalement_repository.dart';
import 'package:planificator/utils/date_helper.dart';

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

      // ✅ ÉTAPE 2: Appliquer la logique DÉCALER vs GARDER
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
        // === MODE 2: GARDER les autres dates (modifie JUSTE celle-ci) ===
        logger.i('📌 MODE GARDER: modifier JUSTE cette date');
        logger.i(
          '   planningDetailId=${widget.planningDetail.planningDetailId}, newDate=$newDate',
        );

        await repo.modifierDatePlanning(
          planningDetailsId: widget.planningDetail.planningDetailId,
          newDate: newDate,
        );
      }

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);

        final modeTexte = _changerRedondance
            ? 'toutes les dates décalées'
            : 'date modifiée';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signalement de $_type enregistré ($modeTexte)'),
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
    final picked = await showDatePicker(
      context: context,
      initialDate: DateHelper.parseAny(_dateCtrl.text),
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[700]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateCtrl.text = DateHelper.format(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  ButtonSegment(value: 'avancement', label: Text('Avancement')),
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
                maxLines: 2,
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
    );
  }
}
