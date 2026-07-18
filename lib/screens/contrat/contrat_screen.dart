import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/index.dart';
import '../../repositories/index.dart';
import '../../widgets/index.dart';
import '../../core/sql_queries.dart';
import '../../services/database_service.dart';
import '../../services/logging_service.dart';
import 'contrat_creation_dialog.dart';
import 'widgets/contrat_details_dialog.dart';

class ContratScreen extends StatefulWidget {
  final int? clientId;
  const ContratScreen({super.key, this.clientId});

  @override
  State<ContratScreen> createState() => _ContratScreenState();
}

class _ContratScreenState extends State<ContratScreen> {
  late Future<List<Map<String, dynamic>>> _contratsWithClientsAndTreatments;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final logger = createLoggerWithFileOutput(name: 'contrat_screen');
  int _contratCount = 0;

  @override
  void initState() {
    super.initState();
    _contratsWithClientsAndTreatments = _fetchContratsWithDetails();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reloadData() {
    setState(() {
      _contratsWithClientsAndTreatments = _fetchContratsWithDetails();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchContratsWithDetails() async {
    try {
      final contratsRepository = context.read<ContratRepository>();
      final clientRepository = context.read<ClientRepository>();
      final db = DatabaseService();

      await clientRepository.loadClients();
      var allClients = clientRepository.clients;

      if (allClients.isEmpty) {
        final rows = await db.query(SqlQueries.getAllClientsBasic);
        allClients = rows.map((row) => Client.fromMap(row)).toList();
      }

      await contratsRepository.loadContrats();
      var contrats = contratsRepository.contrats;

      final clientMap = <int, Client>{};
      for (final client in allClients) {
        clientMap[client.clientId] = client;
      }

      if (widget.clientId != null) {
        contrats = contrats.where((c) => c.clientId == widget.clientId).toList();
      }

      final result = <Map<String, dynamic>>[];
      for (final contrat in contrats) {
        final client = clientMap[contrat.clientId];
        final treatmentRows = await db.query(SqlQueries.countTreatmentsByContrat, [contrat.contratId]);
        final numTraitements = treatmentRows.isNotEmpty ? (treatmentRows[0]['count'] as int? ?? 0) : 0;

        result.add({
          'contrat': contrat,
          'client': client,
          'numTraitements': numTraitements,
        });
      }
      return result;
    } catch (e) {
      logger.e('ERREUR chargement contrats: $e');
      return [];
    }
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : AppTheme.primaryBlue,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un contrat...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.white70),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white54 : Colors.white70),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() { _searchQuery = ''; });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (value) {
                    setState(() { _searchQuery = value.toLowerCase(); });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                  onPressed: _reloadData,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_rounded, color: Colors.white70, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      '$_contratCount ${_contratCount > 1 ? 'contrats' : 'contrat'}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _contratsWithClientsAndTreatments,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));

                var contratsWithDetails = snapshot.data ?? [];
                if (_searchQuery.isNotEmpty) {
                  contratsWithDetails = contratsWithDetails.where((data) {
                    final client = data['client'] as Client?;
                    final contrat = data['contrat'] as Contrat;
                    return '${client?.fullName}'.toLowerCase().contains(_searchQuery) ||
                           contrat.referenceContrat.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                _contratCount = contratsWithDetails.length;

                if (contratsWithDetails.isEmpty) {
                  return const EmptyStateWidget(title: 'Aucun contrat', message: 'Créez un contrat pour commencer.', icon: Icons.description_outlined);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: contratsWithDetails.length,
                  itemBuilder: (context, index) {
                    final data = contratsWithDetails[index];
                    return _buildContratListItem(
                      contrat: data['contrat'] as Contrat,
                      client: data['client'] as Client?,
                      numTraitements: data['numTraitements'] as int,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'contrat_add',
        onPressed: _showAddContratDialog,
        label: const Text('Ajouter un contrat'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContratListItem({required Contrat contrat, required Client? client, required int numTraitements}) {
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
            onTap: () => ContratDetailsDialog.show(context, contrat, client, numTraitements, _reloadData),
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
                          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.primaryBlue, AppTheme.primaryDark]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.description_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fullName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.4)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                  child: Text(contrat.referenceContrat, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
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
                      Expanded(child: _buildVibrantIndicator(icon: Icons.layers_rounded, label: '$numTraitements service(s)', color: isDark ? AppTheme.darkSuccess : AppTheme.successGreen, isDark: isDark)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildVibrantIndicator(icon: Icons.calendar_today_rounded, label: dateFormat.format(contrat.dateContrat), color: isDark ? AppTheme.darkWarning : Colors.orange.shade700, isDark: isDark)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.phone_enabled_rounded, size: 14, color: isDark ? Colors.white24 : Colors.grey[400]),
                      const SizedBox(width: 6),
                      Text(clientPhone, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[600], fontWeight: FontWeight.w500)),
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
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
    );
  }

  Widget _buildVibrantIndicator({required IconData icon, required String label, required Color color, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black87, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  void _showAddContratDialog() async {
    final result = await AppDialogs.showBlurDialog<bool>(
      context: context,
      builder: (ctx) => const ContratCreationDialog(),
    );
    if (result == true) _reloadData();
  }

  Color _getStatusColor(String s) {
    final l = s.toLowerCase();
    if (l.contains('actif')) return AppTheme.successGreen;
    if (l.contains('résilié')) return Colors.orange;
    if (l.contains('terminé')) return Colors.grey;
    return AppTheme.primaryBlue;
  }
}
