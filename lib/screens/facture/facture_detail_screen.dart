import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/index.dart';
import '../../repositories/index.dart';
import '../../core/theme.dart';
import '../../widgets/index.dart';
import '../../utils/number_formatter.dart';
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
      appBar: AppBar(
        title: Text(widget.groupTitle), 
        elevation: 2,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Montant Total', 
                    amount: total, 
                    color: AppTheme.primaryBlue,
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    label: 'Déjà Réglé', 
                    amount: paid, 
                    color: AppTheme.successGreen,
                    icon: Icons.check_circle_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    label: 'Reste à payer', 
                    amount: unpaid, 
                    color: AppTheme.warningOrange,
                    icon: Icons.error_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            AppSection(
              title: 'Historique des Factures',
              margin: EdgeInsets.zero,
              children: sorted.map((facture) => _FactureRow(
                facture: facture,
                onTapModifier: () => FacturePriceDialog.show(
                  context,
                  facture,
                  widget.groupTitle,
                  () => setState(() {}),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label, 
    required this.amount, 
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(context, radius: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label', 
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.w900, 
                    color: isDark ? Colors.white38 : Colors.grey[600],
                    letterSpacing: 0.5
                  )
                ),
                const SizedBox(height: 2),
                Text(
                  '${NumberFormatter.formatMontant(amount)} Ar', 
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
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
    final statusColor = isPaid ? AppTheme.successGreen : AppTheme.errorRed;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: (isPaid || !isAdmin) ? null : onTapModifier,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isPaid ? Icons.verified_rounded : Icons.pending_rounded, 
          color: statusColor, 
          size: 20
        ),
      ),
      title: Row(
        children: [
          Text(
            DateFormat('dd MMMM yyyy', 'fr_FR').format(facture.dateTraitement),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Spacer(),
          Text(
            '${NumberFormatter.formatMontant(facture.montant)} Ar',
            style: TextStyle(
              fontWeight: FontWeight.w900, 
              fontSize: 15,
              color: isPaid ? statusColor : (isDark ? Colors.white : Colors.black87)
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Text(
              facture.referenceFacture != null ? 'Réf: ${facture.referenceFacture}' : 'Aucune référence',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[600]),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                facture.etat.toUpperCase(),
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 0.5),
              ),
            ),
            if (isAdmin && !isPaid) ...[
              const SizedBox(width: 8),
              const Icon(Icons.edit_note_rounded, size: 16, color: AppTheme.primaryBlue),
            ],
          ],
        ),
      ),
    );
  }
}
