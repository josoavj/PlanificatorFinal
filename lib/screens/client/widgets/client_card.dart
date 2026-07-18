import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/client.dart';
import '../../../repositories/index.dart';
import 'client_details_dialog.dart';

class ClientCard extends StatelessWidget {
  final Client client;

  const ClientCard({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Container(
        decoration: AppTheme.cardDecoration(context, radius: 24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => ClientDetailsDialog.show(
              context, 
              client, 
              () => context.read<ClientRepository>().loadClients()
            ),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildAvatar(client),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.fullName, 
                              style: TextStyle(
                                fontWeight: FontWeight.w800, 
                                fontSize: 16, 
                                color: isDark ? Colors.white : Colors.black87, 
                                letterSpacing: -0.3
                              ), 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    client.email.isNotEmpty ? client.email : 'Pas d\'email', 
                                    style: TextStyle(
                                      color: isDark ? Colors.white38 : Colors.grey[600], 
                                      fontSize: 12, 
                                      fontWeight: FontWeight.w500
                                    ), 
                                    maxLines: 1, 
                                    overflow: TextOverflow.ellipsis
                                  ),
                                ),
                                _buildCategoryBadge(client.categorie),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          context,
                          icon: Icons.location_on_outlined, 
                          label: client.axe, 
                          color: isDark ? AppTheme.darkWarning : Colors.orange.shade700
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoChip(
                          context,
                          icon: Icons.assignment_outlined, 
                          label: '${client.treatmentCount} traitement(s)', 
                          color: isDark ? AppTheme.darkSuccess : AppTheme.successGreen
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

  Widget _buildAvatar(Client client) {
    return Container(
      width: 52, 
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight, 
          colors: [AppTheme.primaryBlue, AppTheme.primaryDark]
        ), 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.2), 
            blurRadius: 8, 
            offset: const Offset(0, 4)
          ),
        ],
      ),
      child: Center(
        child: Text(
          client.fullName.isNotEmpty ? client.fullName[0].toUpperCase() : '?', 
          style: const TextStyle(
            fontWeight: FontWeight.w900, 
            color: Colors.white, 
            fontSize: 22
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String cat) {
    final color = _getCategoryColor(cat);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15), 
        borderRadius: BorderRadius.circular(10), 
        border: Border.all(color: color.withValues(alpha: 0.3))
      ),
      child: Text(
        cat.toUpperCase(), 
        style: TextStyle(
          color: color, 
          fontSize: 9, 
          fontWeight: FontWeight.w900, 
          letterSpacing: 0.5
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, {required IconData icon, required String label, required Color color}) {
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
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'particulier': return Colors.blue[600]!;
      case 'organisation': return Colors.purple[600]!;
      case 'société': return Colors.teal[600]!;
      default: return Colors.grey[600]!;
    }
  }
}
