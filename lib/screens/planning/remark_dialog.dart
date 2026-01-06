import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planificator/models/index.dart';
import 'package:planificator/repositories/remarque_repository.dart';
import 'package:planificator/repositories/facture_repository.dart';
import 'package:planificator/utils/date_helper.dart';

class RemarqueDialog extends StatefulWidget {
  final PlanningDetails planningDetail;
  final Facture facture;
  final VoidCallback onSaved;

  const RemarqueDialog({
    Key? key,
    required this.planningDetail,
    required this.facture,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<RemarqueDialog> createState() => _RemarqueDialogState();
}

class _RemarqueDialogState extends State<RemarqueDialog> {
  late TextEditingController _contenuCtrl;
  late TextEditingController _problemeCtrl;
  late TextEditingController _actionCtrl;
  late TextEditingController _montantCtrl;
  late TextEditingController _datePayementCtrl;
  late TextEditingController _etablissementCtrl;
  late TextEditingController _numeroChequeCtrl;

  bool _estPayee = false;
  String? _modePaiement;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _contenuCtrl = TextEditingController();
    _problemeCtrl = TextEditingController();
    _actionCtrl = TextEditingController();
    _montantCtrl = TextEditingController(
      text: widget.facture.montant.toString(),
    );
    _datePayementCtrl = TextEditingController();
    _etablissementCtrl = TextEditingController();
    _numeroChequeCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _contenuCtrl.dispose();
    _problemeCtrl.dispose();
    _actionCtrl.dispose();
    _montantCtrl.dispose();
    _datePayementCtrl.dispose();
    _etablissementCtrl.dispose();
    _numeroChequeCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveRemarque() async {
    if (_isLoading) return;

    // Validation
    if (_estPayee) {
      if (_modePaiement == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez choisir un mode de paiement')),
        );
        return;
      }
      if (_datePayementCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez remplir la date de paiement')),
        );
        return;
      }
      if (_modePaiement == 'Cheque' &&
          (_etablissementCtrl.text.isEmpty || _numeroChequeCtrl.text.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez remplir les infos chèque')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Validation: si montant est 0, on doit en saisir un
      if (widget.facture.montant == 0) {
        final montant = int.tryParse(_montantCtrl.text) ?? 0;
        if (montant == 0) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Veuillez entrer un montant valide'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final repo = context.read<RemarqueRepository>();

      // Créer la remarque
      await repo.createRemarque(
        planningDetailsId: widget.planningDetail.planningDetailId,
        factureId: widget.facture.factureId,
        contenu: _contenuCtrl.text.isEmpty ? null : _contenuCtrl.text,
        probleme: _problemeCtrl.text.isEmpty ? null : _problemeCtrl.text,
        action: _actionCtrl.text.isEmpty ? null : _actionCtrl.text,
        modePaiement: _estPayee ? _modePaiement : null,
        datePayement: _estPayee
            ? DateHelper.format(DateHelper.parseAny(_datePayementCtrl.text))
            : null,
        etablissement: _modePaiement == 'Chèque'
            ? _etablissementCtrl.text
            : null,
        numeroCheque: _modePaiement == 'Chèque' ? _numeroChequeCtrl.text : null,
        estPayee: _estPayee,
      );

      // ✅ Mettre à jour la facture
      final factureRepo = context.read<FactureRepository>();

      // Si montant était 0, le mettre à jour
      if (widget.facture.montant == 0) {
        final montant = int.tryParse(_montantCtrl.text) ?? 0;
        await factureRepo.updateFacturePrice(widget.facture.factureId, montant);
      }

      // Marquer comme payée si nécessaire
      if (_estPayee) {
        await factureRepo.markAsPaid(widget.facture.factureId);
      }

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Remarque & Facture enregistrées')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2099),
      );

      if (picked != null && mounted) {
        setState(() => _datePayementCtrl.text = DateHelper.format(picked));
      }
    } catch (e) {
      // Silencieusement ignorer si le dialog est fermé
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remarque - ${DateHelper.format(widget.planningDetail.datePlanification)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),

              // Référence et montant facture
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Réf: ${widget.facture.referenceFacture ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID Facture: ${widget.facture.factureId}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${widget.facture.montant} Ar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contenu remarque
              TextField(
                controller: _contenuCtrl,
                decoration: const InputDecoration(
                  labelText: 'Remarque (optionnelle)',
                  border: OutlineInputBorder(),
                  hintText: 'Notes sur la visite...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              // Problème identifié
              TextField(
                controller: _problemeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Problème identifié (optionnel)',
                  border: OutlineInputBorder(),
                  hintText: 'Problème rencontré...',
                ),
              ),
              const SizedBox(height: 12),

              // Action corrective
              TextField(
                controller: _actionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Action corrective (optionnelle)',
                  border: OutlineInputBorder(),
                  hintText: 'Action à prendre...',
                ),
              ),
              const SizedBox(height: 16),

              // Montant facture - SEULEMENT si = 0
              if (widget.facture.montant == 0) ...[
                TextField(
                  controller: _montantCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Montant (Ar) - OBLIGATOIRE',
                    border: OutlineInputBorder(),
                    hintText: 'Entrez le montant',
                    prefixText: 'Ar ',
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Montant: ${widget.facture.montant} Ar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Paiement
              CheckboxListTile(
                title: const Text('Marquer comme payée'),
                value: _estPayee,
                onChanged: (val) => setState(() => _estPayee = val ?? false),
              ),

              if (_estPayee) ...[
                const SizedBox(height: 12),

                // Mode de paiement
                DropdownButtonFormField(
                  value: _modePaiement,
                  decoration: const InputDecoration(
                    labelText: 'Mode de paiement',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Chèque', 'Espèce', 'Virement', 'Mobile Money']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) => setState(() => _modePaiement = val),
                ),
                const SizedBox(height: 12),

                // Date de paiement
                TextField(
                  controller: _datePayementCtrl,
                  decoration: InputDecoration(
                    labelText: 'Date de paiement',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _selectDate,
                    ),
                  ),
                  readOnly: true,
                ),

                // Champs spécifiques pour chèque
                if (_modePaiement == 'Chèque') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _etablissementCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Établissement bancaire',
                      border: OutlineInputBorder(),
                      hintText: 'Nom de la banque...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _numeroChequeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de chèque',
                      border: OutlineInputBorder(),
                      hintText: 'Ex: 123456',
                    ),
                  ),
                ],
              ],

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
                    onPressed: _isLoading ? null : _saveRemarque,
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
