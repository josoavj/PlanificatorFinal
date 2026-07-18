import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/index.dart';
import '../../../repositories/index.dart';
import '../../../widgets/index.dart';
import 'contrat_details_dialog.dart';

class ContratAbrogationDialog extends StatelessWidget {
  final Contrat contrat;
  final Client? client;
  final int numTraitements;
  final VoidCallback onDataChanged;

  const ContratAbrogationDialog({
    super.key,
    required this.contrat,
    this.client,
    required this.numTraitements,
    required this.onDataChanged,
  });

  static void show(BuildContext context, Contrat contrat, Client? client, int numTraitements, VoidCallback onDataChanged) {
    AppDialogs.showBlurDialog(
      context: context,
      builder: (ctx) => ContratAbrogationDialog(
        contrat: contrat,
        client: client,
        numTraitements: numTraitements,
        onDataChanged: onDataChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    String motif = '';

    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Abroger le Contrat', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Motif'), onChanged: (v) => motif = v),
            const SizedBox(height: 16),
            ListTile(title: Text('Date: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'), trailing: const Icon(Icons.calendar_today), onTap: () async {
              final d = await showDatePicker(context: context, initialDate: selectedDate, firstDate: contrat.dateDebut, lastDate: DateTime.now().add(const Duration(days: 365)));
              if (d != null) setState(() => selectedDate = d);
            }),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.close_rounded, size: 18), 
            onPressed: () {
              Navigator.pop(context);
              ContratDetailsDialog.show(context, contrat, client, numTraitements, onDataChanged);
            }, 
            label: const Text('ANNULER'),
          ),
          FilledButton.icon(icon: const Icon(Icons.check_circle_outline, size: 18), label: const Text('CONFIRMER'), style: FilledButton.styleFrom(backgroundColor: Colors.orange), onPressed: () async {
            Navigator.pop(context);
            await context.read<ContratRepository>().abrogateContract(contratId: contrat.contratId, abrogationDate: selectedDate, motif: motif, isAdmin: true);
            onDataChanged();
          }),
        ],
      ),
    );
  }
}

class ContratDeleteDialog extends StatelessWidget {
  final Contrat contrat;
  final Client? client;
  final int numTraitements;
  final VoidCallback onDataChanged;

  const ContratDeleteDialog({
    super.key,
    required this.contrat,
    this.client,
    required this.numTraitements,
    required this.onDataChanged,
  });

  static void show(BuildContext context, Contrat contrat, Client? client, int numTraitements, VoidCallback onDataChanged) {
    AppDialogs.showBlurDialog(
      context: context,
      builder: (ctx) => ContratDeleteDialog(
        contrat: contrat,
        client: client,
        numTraitements: numTraitements,
        onDataChanged: onDataChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmer la suppression', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('Supprimer définitivement le contrat ${contrat.referenceContrat} ?'),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.close_rounded, size: 18), 
          onPressed: () {
            Navigator.pop(context);
            ContratDetailsDialog.show(context, contrat, client, numTraitements, onDataChanged);
          }, 
          label: const Text('ANNULER'),
        ),
        FilledButton.icon(icon: const Icon(Icons.delete_forever_rounded, size: 18), label: const Text('SUPPRIMER'), style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed), onPressed: () async {
          Navigator.pop(context);
          await context.read<ContratRepository>().deleteContrat(contrat.contratId, isAdmin: context.read<AuthRepository>().isAdmin);
          onDataChanged();
        }),
      ],
    );
  }
}
