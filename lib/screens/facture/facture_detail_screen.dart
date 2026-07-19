import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/index.dart';
import '../../repositories/index.dart';
import 'widgets/facture_price_dialog.dart';

class FactureDetailScreen extends StatefulWidget {
  final List<Facture> factures;
  final String groupTitle;

  const FactureDetailScreen({
    super.key,
    required this.factures,
    required this.groupTitle,
  });

  @override
  State<FactureDetailScreen> createState() => _FactureDetailScreenState();
}

class _FactureDetailScreenState extends State<FactureDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final sorted = List<Facture>.from(widget.factures)
      ..sort((a, b) => b.dateTraitement.compareTo(a.dateTraitement));
    
    int total = 0;
    int unpaid = 0;
    for (final f in sorted) {
      total += f.montant;
      if (f.etat.toLowerCase() != 'payé' && f.etat.toLowerCase() != 'payée') {
        unpaid += f.montant;
      }
    }
    final paid = total - unpaid;

    return Scaffold(
      appBar: AppBar(title: Text(widget.groupTitle), elevation: 1),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(label: 'Total', amount: total, color: Colors.blue),
                  _SummaryItem(label: 'Payé', amount: paid, color: Colors.green),
                  _SummaryItem(label: 'Non Payé', amount: unpaid, color: Colors.orange),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final facture = sorted[index];
                  return _FactureRow(
                    facture: facture,
                    onTapModifier: () => FacturePriceDialog.show(
                      context,
                      facture,
                      widget.groupTitle,
                      () => setState(() {}),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;

  const _SummaryItem({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          '$amount Ar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

class _FactureRow extends StatelessWidget {
  final Facture facture;
  final VoidCallback onTapModifier;

  const _FactureRow({required this.facture, required this.onTapModifier});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthRepository>().isAdmin;
    final isPaid = facture.etat.toLowerCase() == 'payé' || facture.etat.toLowerCase() == 'payée';
    final statusColor = isPaid ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: (isPaid || !isAdmin) ? null : onTapModifier,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(facture.dateTraitement),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isPaid ? Colors.grey : Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${facture.montant} Ar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isPaid ? Colors.grey : Colors.black,
                        ),
                      ),
                      if (isAdmin && !isPaid) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.edit, size: 14, color: Colors.blue),
                      ],
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          facture.etat,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (facture.referenceFacture != null && facture.referenceFacture!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Réf: ${facture.referenceFacture}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
