import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/index.dart';
import '../../../repositories/index.dart';
import '../../../utils/app_snackbars.dart';
import '../../../utils/number_formatter.dart';
import '../../../widgets/app_dialogs.dart';

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
    final prixInitialCtrl = TextEditingController(text: facture.montant.toString());
    final prixNewCtrl = TextEditingController();

    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Modification de Prix'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(groupTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text('Date: ${DateFormat('dd/MM/yyyy').format(facture.dateTraitement)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              const Text('Prix Initial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              TextField(controller: prixInitialCtrl, readOnly: true, decoration: InputDecoration(filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.all(12))),
              const SizedBox(height: 16),
              const Text('Nouveau Prix', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              TextField(controller: prixNewCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Ex: 50 000 ou 1500000', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.all(12), helperText: 'Les espaces sont autorisés')),
              const SizedBox(height: 16),
              Text('Statut actuel: ${facture.etat}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (prixNewCtrl.text.isEmpty) {
                AppSnackBars.showInfo(context, 'Veuillez entrer un nouveau prix');
                return;
              }
              try {
                final oldPrix = NumberFormatter.parseMontant(prixInitialCtrl.text);
                final newPrix = NumberFormatter.parseMontant(prixNewCtrl.text);
                if (newPrix <= 0) {
                  AppSnackBars.showError(context, 'Le montant doit être supérieur à 0');
                  return;
                }

                final authRepo = context.read<AuthRepository>();
                final factureRepo = context.read<FactureRepository>();
                final success = await factureRepo.majMontantEtHistorique(facture.factureId, oldPrix, newPrix, isAdmin: authRepo.isAdmin);

                if (!context.mounted) return;
                if (!success) {
                  AppSnackBars.showError(context, 'Erreur lors de la modification');
                  return;
                }

                Navigator.pop(context);
                AppSnackBars.showSuccess(context, 'Prix modifié avec succès');
                await context.read<FactureRepository>().loadAllFactures();
                onDataChanged();
              } catch (e) {
                AppSnackBars.showError(context, 'Erreur: $e');
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
