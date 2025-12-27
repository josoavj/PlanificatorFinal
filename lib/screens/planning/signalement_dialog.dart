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
  late TextEditingController _nouvelleRedondanceCtrl;

  final logger = Logger();

  String _type = 'décalage'; // 'avancement' ou 'décalage'
  bool _changerRedondance =
      false; // Changer redondance pour tous les futurs (vs garder)
  int? _nouvelleRedondance; // Pour 'changer redondance'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _motifCtrl = TextEditingController();
    _dateCtrl = TextEditingController(
      text: DateHelper.format(widget.planningDetail.datePlanification),
    );
    _nouvelleRedondanceCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _motifCtrl.dispose();
    _dateCtrl.dispose();
    _nouvelleRedondanceCtrl.dispose();
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

    if (_changerRedondance && _nouvelleRedondance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une nouvelle redondance'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = context.read<SignalementRepository>();
      final newDate = DateHelper.parseAny(_dateCtrl.text);

      if (newDate == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Date invalide')));
        return;
      }

      // Créer le signalement
      await repo.createSignalement(
        planningDetailsId: widget.planningDetail.planningDetailId,
        motif: _motifCtrl.text,
        type: _type,
      );

      // Modifier la date
      await repo.modifierDatePlanning(
        planningDetailsId: widget.planningDetail.planningDetailId,
        newDate: newDate,
      );

      // Si "changer redondance": à implémenter après ajout de planningId au modèle
      if (_changerRedondance && _nouvelleRedondance != null) {
        // TODO: Implement redondance modification when planningId is available
      }

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signalement de $_type enregistré')),
        );
      }
    } catch (e) {
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

              // Changer redondance
              CheckboxListTile(
                title: const Text('Changer la redondance pour tous les futurs'),
                subtitle: const Text('(sinon ne modifie que cette date)'),
                value: _changerRedondance,
                onChanged: (val) {
                  setState(() => _changerRedondance = val ?? false);
                },
              ),

              // Nouvelle redondance (si coché)
              if (_changerRedondance)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nouvelle redondance',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(
                            value: 0,
                            label: Text('Une seule fois'),
                          ),
                          ButtonSegment(value: 1, label: Text('1 mois')),
                          ButtonSegment(value: 2, label: Text('2 mois')),
                          ButtonSegment(value: 3, label: Text('3 mois')),
                        ],
                        selected: {_nouvelleRedondance ?? 1},
                        onSelectionChanged: (newSelection) {
                          setState(
                            () => _nouvelleRedondance = newSelection.first,
                          );
                        },
                      ),
                    ],
                  ),
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
