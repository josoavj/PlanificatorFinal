import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/index.dart';

class FactureGroupCard extends StatelessWidget {
  final String title;
  final List<Facture> factures;
  final VoidCallback onTap;

  const FactureGroupCard({
    super.key,
    required this.title,
    required this.factures,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int total = 0;
    int unpaid = 0;
    for (final f in factures) {
      total += f.montant;
      if (f.etat.toLowerCase() != 'payé' && f.etat.toLowerCase() != 'payée') {
        unpaid += f.montant;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Container(
        decoration: AppTheme.cardDecoration(context, radius: 24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.2), 
                              blurRadius: 8, 
                              offset: const Offset(0, 4)
                            )
                          ],
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title, 
                              style: TextStyle(
                                fontSize: 15, 
                                fontWeight: FontWeight.w900, 
                                color: isDark ? Colors.white : Colors.black87, 
                                letterSpacing: -0.4
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${factures.length} facture(s)', 
                              style: TextStyle(
                                fontSize: 12, 
                                color: isDark ? Colors.white38 : Colors.grey[600],
                                fontWeight: FontWeight.w500
                              )
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? Colors.white24 : Colors.grey.shade400),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoIndicator(
                          context,
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Total: $total Ar',
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoIndicator(
                          context,
                          icon: Icons.error_outline_rounded,
                          label: 'À régler: $unpaid Ar',
                          color: unpaid > 0 ? AppTheme.warningOrange : AppTheme.successGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoIndicator(BuildContext context, {required IconData icon, required String label, required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08), 
        borderRadius: BorderRadius.circular(14), 
        border: Border.all(color: color.withValues(alpha: 0.15))
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label, 
              style: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black87, 
                fontSize: 12, 
                fontWeight: FontWeight.w600
              ), 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis
            )
          ),
        ],
      ),
    );
  }
}
