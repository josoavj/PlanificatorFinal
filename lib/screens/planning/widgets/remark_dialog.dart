import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/index.dart';
import '../../../repositories/remarque_repository.dart';
import '../../../repositories/facture_repository.dart';
import '../../../utils/date_helper.dart';
import '../../../repositories/auth_repository.dart';
import '../../../utils/app_snackbars.dart';
import '../../../utils/number_formatter.dart';
import '../../../core/theme.dart';
import '../../../widgets/index.dart';
import '../../../widgets/common/index.dart';

class RemarqueDialog extends StatefulWidget {
  final PlanningDetails planningDetail;
  final Facture facture;
  final Remarque? existingRemarque; // Optionnel : pour l'édition
  final VoidCallback onSaved;

  const RemarqueDialog({
    super.key,
    required this.planningDetail,
    required this.facture,
    this.existingRemarque,
    required this.onSaved,
  });

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
  late TextEditingController _referenceCtrl;

  bool _estPayee = false;
  String? _modePaiement;
  bool _isLoading = false;
  bool _anomalieDetectee = false;

  @override
  void initState() {
    super.initState();
    final rem = widget.existingRemarque;
    final fac = widget.facture;

    _contenuCtrl = TextEditingController(text: rem?.contenu ?? '');
    _problemeCtrl = TextEditingController(text: rem?.probleme ?? '');
    _actionCtrl = TextEditingController(text: rem?.action ?? '');
    _montantCtrl = TextEditingController(
      text: NumberFormatter.formatMontant(fac.montant),
    );
    
    _datePayementCtrl = TextEditingController(
      text: fac.dateCheque != null ? DateHelper.format(fac.dateCheque!) : ''
    );
    _etablissementCtrl = TextEditingController(text: fac.etablissementPayeur ?? '');
    _numeroChequeCtrl = TextEditingController(text: fac.numeroCheque ?? '');
    _referenceCtrl = TextEditingController(text: fac.referenceFacture ?? '');

    _estPayee = fac.isPaid;
    _modePaiement = fac.mode;
    
    // Si édition, on regarde si un problème était noté (différent de "Aucun")
    if (rem != null) {
      _anomalieDetectee = rem.probleme != null && 
          rem.probleme!.toLowerCase() != 'aucun' && 
          rem.probleme!.isNotEmpty;
    }
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
    _referenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveRemarque() async {
    if (_isLoading) return;

    // Validation
    if (_anomalieDetectee) {
      if (_problemeCtrl.text.isEmpty) {
        AppSnackBars.showWarning(context, 'Veuillez décrire le problème rencontré');
        return;
      }
      if (_actionCtrl.text.isEmpty) {
        AppSnackBars.showWarning(context, 'Veuillez préciser l\'action corrective prise');
        return;
      }
    }

    if (_estPayee) {
      if (_modePaiement == null) {
        AppSnackBars.showWarning(context, 'Veuillez choisir un mode de paiement');
        return;
      }
      if (_datePayementCtrl.text.isEmpty) {
        AppSnackBars.showWarning(context, 'Veuillez remplir la date de paiement');
        return;
      }
      if (_modePaiement == 'Chèque' &&
          (_etablissementCtrl.text.isEmpty || _numeroChequeCtrl.text.isEmpty)) {
        AppSnackBars.showWarning(context, 'Veuillez remplir les infos chèque');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final isEditing = widget.existingRemarque != null;
      final repo = context.read<RemarqueRepository>();
      final factureRepo = context.read<FactureRepository>();
      final authRepo = context.read<AuthRepository>();

      final currentMontant = NumberFormatter.parseMontant(_montantCtrl.text);

      // Validation: si montant est 0, on doit en saisir un
      if (currentMontant == 0) {
        setState(() => _isLoading = false);
        AppSnackBars.showWarning(context, 'Veuillez entrer un montant valide');
        return;
      }

      bool success = false;
      final pText = _anomalieDetectee ? (_problemeCtrl.text.isEmpty ? 'Non spécifié' : _problemeCtrl.text) : 'Aucun';
      final aText = _anomalieDetectee ? (_actionCtrl.text.isEmpty ? 'Aucune action' : _actionCtrl.text) : 'Aucun';

      if (isEditing) {
        // MODE ÉDITION
        success = await repo.updateRemarqueFull(
          remarqueId: widget.existingRemarque!.id!,
          factureId: widget.facture.factureId,
          contenu: _contenuCtrl.text.isEmpty ? 'RAS' : _contenuCtrl.text,
          probleme: pText,
          action: aText,
          modePaiement: _estPayee ? _modePaiement : null,
          datePayement: _estPayee && _datePayementCtrl.text.isNotEmpty
              ? _datePayementCtrl.text
              : null,
          etablissement: _modePaiement == 'Chèque' ? _etablissementCtrl.text : null,
          numeroCheque: _modePaiement == 'Chèque' ? _numeroChequeCtrl.text : null,
          estPayee: _estPayee,
        );

        // Mettre à jour le montant si nécessaire
        if (currentMontant != widget.facture.montant) {
          await factureRepo.updateFacturePrice(
            widget.facture.factureId,
            currentMontant,
            isAdmin: authRepo.isAdmin,
          );
        }

        // Mettre à jour la référence
        if (_referenceCtrl.text != (widget.facture.referenceFacture ?? '')) {
          await factureRepo.updateFactureReference(
            widget.facture.factureId,
            _referenceCtrl.text,
          );
        }
      } else {
        // MODE CRÉATION
        success = await repo.createRemarque(
          planningDetailsId: widget.planningDetail.planningDetailId,
          factureId: widget.facture.factureId,
          contenu: _contenuCtrl.text.isEmpty ? 'RAS' : _contenuCtrl.text,
          probleme: pText,
          action: aText,
          modePaiement: _estPayee ? _modePaiement : null,
          datePayement: _estPayee && _datePayementCtrl.text.isNotEmpty
              ? _datePayementCtrl.text
              : null,
          etablissement: _modePaiement == 'Chèque' ? _etablissementCtrl.text : null,
          numeroCheque: _modePaiement == 'Chèque' ? _numeroChequeCtrl.text : null,
          estPayee: _estPayee,
        );

        // Mises à jour supplémentaires si création
        if (widget.facture.montant == 0 || currentMontant != widget.facture.montant) {
          await factureRepo.updateFacturePrice(
            widget.facture.factureId,
            currentMontant,
            isAdmin: authRepo.isAdmin,
          );
        }
        if (_referenceCtrl.text.isNotEmpty) {
          await factureRepo.updateFactureReference(
            widget.facture.factureId,
            _referenceCtrl.text,
          );
        }
      }

      if (success && mounted) {
        widget.onSaved();
        Navigator.pop(context);
        AppSnackBars.showSuccess(
          context, 
          isEditing ? 'Informations mises à jour' : 'Remarque & Facture enregistrées'
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBars.showError(context, ' Erreur: $e');
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
      // Ignorer
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.existingRemarque != null;
    final statusColor = isEditing ? AppTheme.accentBlue : AppTheme.successGreen;

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
            _buildHeader(context, statusColor),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // SECTION 1: INFOS PASSAGE
                    AppSection(
                      title: 'Informations du Passage',
                      margin: EdgeInsets.zero,
                      children: [
                        AppInfoTile(
                          icon: Icons.calendar_today_rounded, 
                          label: 'Date prévue', 
                          value: DateHelper.format(widget.planningDetail.datePlanification),
                        ),
                        AppInfoTile(
                          icon: Icons.receipt_long_rounded, 
                          label: 'Référence Facture', 
                          value: _referenceCtrl.text.isNotEmpty ? _referenceCtrl.text : (widget.facture.referenceFacture ?? 'Génération auto'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: _contenuCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Notes de visite (Remarque)',
                              hintText: 'Comment s\'est déroulée l\'intervention ?',
                              filled: true,
                              fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // SECTION 2: ANOMALIES
                    AppSection(
                      title: 'Rapport d\'Anomalie',
                      margin: EdgeInsets.zero,
                      children: [
                        _buildAnomalyToggle(),
                        if (_anomalieDetectee) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _problemeCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Problème identifié',
                                    prefixIcon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _actionCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Action corrective prise',
                                    prefixIcon: const Icon(Icons.build_circle_outlined, color: Colors.green),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // SECTION 3: COMPTABILITÉ
                    AppSection(
                      title: 'Détails Financiers',
                      margin: EdgeInsets.zero,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              TextField(
                                controller: _referenceCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Numéro de Facture',
                                  prefixIcon: const Icon(Icons.tag_rounded),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _montantCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [AmountInputFormatter()],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  labelText: 'Montant à facturer (Ar)',
                                  prefixIcon: const Icon(Icons.payments_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        _buildPaymentSwitch(),
                        
                        if (_estPayee) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  initialValue: _modePaiement,
                                  decoration: InputDecoration(
                                    labelText: 'Mode de règlement',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  items: ['Chèque', 'Espèce', 'Virement', 'Mobile Money']
                                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                                      .toList(),
                                  onChanged: (v) => setState(() => _modePaiement = v),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _datePayementCtrl,
                                  readOnly: true,
                                  onTap: _selectDate,
                                  decoration: InputDecoration(
                                    labelText: 'Date de paiement',
                                    prefixIcon: const Icon(Icons.calendar_month_rounded),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                if (_modePaiement == 'Chèque') ...[
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _etablissementCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Établissement bancaire',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _numeroChequeCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'N° de chèque',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
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

  Widget _buildHeader(BuildContext context, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
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
              child: Icon(
                widget.existingRemarque != null ? Icons.edit_note_rounded : Icons.add_task_rounded, 
                color: Colors.white, 
                size: 32
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.existingRemarque != null ? 'ÉDITION DU RAPPORT' : 'VALIDATION DU PASSAGE',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyToggle() {
    return InkWell(
      onTap: () => setState(() => _anomalieDetectee = !_anomalieDetectee),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _anomalieDetectee ? Colors.orange.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _anomalieDetectee ? Icons.report_problem_rounded : Icons.check_circle_outline_rounded, 
                color: _anomalieDetectee ? Colors.orange : Colors.grey, 
                size: 20
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Anomalie détectée ?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('Cochez si un problème a eu lieu lors du passage', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            Switch.adaptive(
              value: _anomalieDetectee, 
              activeTrackColor: Colors.orange,
              onChanged: (v) => setState(() => _anomalieDetectee = v)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _estPayee ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _estPayee ? Icons.verified_rounded : Icons.pending_rounded, 
              color: _estPayee ? Colors.green : Colors.grey, 
              size: 20
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Marquer comme payée', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Enregistrer le règlement immédiatement', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Switch.adaptive(
            value: _estPayee, 
            activeTrackColor: Colors.green,
            onChanged: (v) => setState(() => _estPayee = v)
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
              onPressed: _isLoading ? null : _saveRemarque,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(widget.existingRemarque != null ? 'METTRE À JOUR' : 'ENREGISTRER'),
            ),
          ),
        ],
      ),
    );
  }
}
