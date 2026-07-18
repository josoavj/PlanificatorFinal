import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../models/index.dart';
import 'contrat_details_dialog.dart';

class ContratCard extends StatelessWidget {
  final Contrat contrat;
  final Client? client;
  final int numTraitements;
  final VoidCallback onUpdate;

  const ContratCard({
    super.key,
    required this.contrat,
    this.client,
    required this.numTraitements,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final fullName = client?.fullName ?? 'Client inconnu';
    final clientPhone = client?.telephone ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Container(
        decoration: AppTheme.cardDecoration(context, radius: 24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => ContratDetailsDialog.show(
              context, 
              contrat, 
              client, 
              numTraitements, 
              onUpdate
            ),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52, 
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.3), 
                              blurRadius: 10, 
                              offset: const Offset(0, 4)
                            )
                          ],
                        ),
                        child: const Icon(Icons.description_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName, 
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.w900, 
                                color: isDark ? Colors.white : Colors.black87, 
                                letterSpacing: -0.4
                              )
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withValues(alpha: 0.1), 
                                    borderRadius: BorderRadius.circular(6)
                                  ),
                                  child: Text(
                                    contrat.referenceContrat, 
                                    style: const TextStyle(
                                      fontSize: 10, 
                                      fontWeight: FontWeight.bold, 
                                      color: AppTheme.primaryBlue
                                    )
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildStatusBadge(contrat.statutContrat, isDark),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildVibrantIndicator(
                          context,
                          icon: Icons.layers_rounded, 
                          label: '$numTraitements service(s)', 
                          color: isDark ? AppTheme.darkSuccess : AppTheme.successGreen, 
                        )
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildVibrantIndicator(
                          context,
                          icon: Icons.calendar_today_rounded, 
                          label: dateFormat.format(contrat.dateContrat), 
                          color: isDark ? AppTheme.darkWarning : Colors.orange.shade700, 
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_enabled_rounded, 
                        size: 14, 
                        color: isDark ? Colors.white24 : Colors.grey[400]
                      ),
                      const SizedBox(width: 6),
                      Text(
                        clientPhone, 
                        style: TextStyle(
                          fontSize: 11, 
                          color: isDark ? Colors.white38 : Colors.grey[600], 
                          fontWeight: FontWeight.w500
                        )
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

  Widget _buildStatusBadge(String status, bool isDark) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(), 
        style: TextStyle(
          fontSize: 9, 
          fontWeight: FontWeight.w900, 
          color: color, 
          letterSpacing: 0.5
        )
      ),
    );
  }

  Widget _buildVibrantIndicator(BuildContext context, {required IconData icon, required String label, required Color color}) {
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

  Color _getStatusColor(String s) {
    final l = s.toLowerCase();
    if (l.contains('actif')) return AppTheme.successGreen;
    if (l.contains('résilié')) return Colors.orange;
    if (l.contains('terminé')) return Colors.grey;
    return AppTheme.primaryBlue;
  }
}
