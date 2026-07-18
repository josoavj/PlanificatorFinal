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
import '../../utils/app_snackbars.dart';

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
            onTap: () => _showContratDetails(contrat, client, numTraitements),
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

  void _showAddContratDialog() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ContratCreationFlowScreen(clientId: widget.clientId)));
  }

  void _showContratDetails(Contrat contrat, Client? client, int numTraitements) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppDialogs.showBlurDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: _buildDialogHeader(context, 'Détails du Contrat', contrat.referenceContrat),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Client associé'),
                if (client != null)
                  Container(
                    decoration: AppTheme.cardDecoration(context, radius: 24),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        children: [
                          _buildDetailTile(Icons.person_outline, 'Nom Complet', client.fullName, isDark),
                          _buildSubtleDivider(isDark),
                          _buildDetailTile(Icons.alternate_email_rounded, 'Email', client.email, isDark),
                          _buildSubtleDivider(isDark),
                          _buildDetailTile(Icons.phone_outlined, 'Téléphone', client.telephone, isDark),
                        ],
                      ),
                    ),
                  )
                else
                  const Text('Informations client non disponibles'),
                const SizedBox(height: 24),

                _buildSectionHeader('Paramètres du Contrat'),
                Container(
                  decoration: AppTheme.cardDecoration(context, radius: 24),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        _buildDetailTile(Icons.tag_rounded, 'Référence', contrat.referenceContrat, isDark),
                        _buildSubtleDivider(isDark),
                        _buildDetailTile(Icons.event_note_rounded, 'Date Signature', DateFormat('dd/MM/yyyy').format(contrat.dateContrat), isDark),
                        _buildSubtleDivider(isDark),
                        _buildDetailTile(Icons.info_outline_rounded, 'Statut actuel', contrat.statutContrat, isDark, valueColor: _getStatusColor(contrat.statutContrat)),
                        _buildSubtleDivider(isDark),
                        _buildDetailTile(Icons.timer_outlined, 'Durée du contrat', _getDisplayDuration(contrat), isDark),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionHeader('Services & Progression'),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadTraitements(contrat.contratId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)));
                    final traitements = snapshot.data ?? [];
                    if (traitements.isEmpty) return const Center(child: Text('Aucun service planifié', style: TextStyle(fontSize: 12, color: Colors.grey)));
                    
                    return Column(
                      children: traitements.map((t) {
                        final total = t['total_planif'] is int ? t['total_planif'] as int : int.tryParse(t['total_planif']?.toString() ?? '0') ?? 0;
                        final faites = t['planif_faites'] is int ? t['planif_faites'] as int : int.tryParse(t['planif_faites']?.toString() ?? '0') ?? 0;
                        
                        // Conversion sécurisée du Blob/String pour les statuts
                        final dynamic statutsRaw = t['statuts'];
                        final String statutsStr = statutsRaw is List<int> 
                            ? String.fromCharCodes(statutsRaw) 
                            : (statutsRaw?.toString() ?? '');
                            
                        final hasClassed = statutsStr.toLowerCase().contains('classé');
                        final percent = total > 0 ? (faites / total).clamp(0.0, 1.0) : 0.0;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: AppTheme.cardDecoration(context, radius: 16),
                          child: ListTile(
                            dense: true,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: (hasClassed ? Colors.red : AppTheme.primaryBlue).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(hasClassed ? Icons.cancel_outlined : Icons.calendar_today_rounded, size: 18, color: hasClassed ? Colors.red : AppTheme.primaryBlue),
                            ),
                            title: Text(t['nom'] ?? 'Service', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('$faites / $total passages réalisés', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600])),
                                if (total > 0) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: percent,
                                      backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
                                      color: percent >= 1.0 ? Colors.green : AppTheme.primaryBlue,
                                      minHeight: 4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: hasClassed 
                                ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: const Text('ARRÊTÉ', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)))
                                : null,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton.icon(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => Navigator.of(ctx).pop(), label: const Text('FERMER')),
          if (numTraitements > 0) ...[
            FilledButton.icon(
              icon: const Icon(Icons.description_rounded, size: 18),
              label: const Text('FACTURES'),
              onPressed: () { Navigator.of(ctx).pop(); _viewFactures(contrat); },
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: const Text('PLANNING'),
              onPressed: () { Navigator.of(ctx).pop(); _viewPlanning(contrat); },
              style: FilledButton.styleFrom(backgroundColor: AppTheme.successGreen),
            ),
          ],
          if (contrat.statutContrat == 'Actif' && context.read<AuthRepository>().isAdmin)
            FilledButton.icon(
              icon: const Icon(Icons.history_toggle_off_rounded, size: 18),
              onPressed: () { Navigator.of(ctx).pop(); _showAbrogationDialog(contrat); },
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              label: const Text('ABROGER'),
            ),
          if (context.read<AuthRepository>().isAdmin)
            FilledButton.icon(
              onPressed: () { Navigator.of(ctx).pop(); _deleteContrat(contrat); },
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('SUPPRIMER'),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            ),
        ],
      ),
    );
  }

  void _viewFactures(Contrat contrat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    AppDialogs.showBlurDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: _buildDialogHeader(context, 'Factures du Contrat', contrat.referenceContrat),
        content: SizedBox(
          width: 550,
          child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
            future: _loadFacturesGroupedByTraitement(contrat.contratId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final facturesGrouped = snapshot.data ?? {};
              if (facturesGrouped.isEmpty) return const Center(child: Text('Aucune facture trouvée'));
              return ListView.builder(
                shrinkWrap: true,
                itemCount: facturesGrouped.length,
                itemBuilder: (context, index) {
                  final type = facturesGrouped.keys.elementAt(index);
                  final factures = facturesGrouped[type] ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(padding: const EdgeInsets.only(bottom: 12, top: 16), child: Row(children: [Container(width: 3, height: 16, decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 12), Text(type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppTheme.primaryBlue, letterSpacing: 1.2))])),
                      ...factures.map((f) {
                        final etat = f['etat'] as String? ?? 'Inconnu';
                        final isPaid = etat.toLowerCase().contains('payé');
                        final statusColor = isPaid ? (isDark ? AppTheme.darkSuccess : AppTheme.successGreen) : (isDark ? AppTheme.darkWarning : AppTheme.warningOrange);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: AppTheme.cardDecoration(context, radius: 16),
                          child: ListTile(
                            dense: true,
                            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(isPaid ? Icons.check_circle_outline : Icons.pending_actions_rounded, size: 18, color: statusColor)),
                            title: Text('Facture #${f['factureId']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text('${f['montant']} Ar', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600])),
                            trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(etat.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900))),
                          ),
                        );
                      }),
                    ],
                  );
                },
              );
            },
          ),
        ),
        actions: [TextButton.icon(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.of(ctx).pop(), label: const Text('RETOUR'))],
      ),
    );
  }

  void _viewPlanning(Contrat contrat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    AppDialogs.showBlurDialog(
      context: context,
      builder: (ctx) => FutureBuilder<Client?>(
        future: _loadClientForContrat(contrat.clientId),
        builder: (context, clientSnapshot) {
          return AlertDialog(
            title: _buildDialogHeader(context, 'Parcours Planning', clientSnapshot.data?.fullName ?? 'Client'),
            content: SizedBox(
              width: 550,
              child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                future: _loadContratPlanningsByType(contrat.contratId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final grouped = snapshot.data ?? {};
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final type = grouped.keys.elementAt(index);
                      final list = grouped[type] ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(padding: const EdgeInsets.only(bottom: 12, top: 16), child: Row(children: [Container(width: 3, height: 16, decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 12), Text(type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppTheme.primaryBlue, letterSpacing: 1.2))])),
                          ...list.map((p) {
                            final date = p['date_planification'] as DateTime?;
                            final etat = p['etat'] as String? ?? '-';
                            final statusColor = _getStatusColorForPlanning(etat);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: AppTheme.cardDecoration(context, radius: 16),
                              child: IntrinsicHeight(
                                child: Row(children: [
                                  Container(width: 4, decoration: BoxDecoration(color: statusColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)))),
                                  Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Date inconnue', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text('Axe: ${p['axe'] ?? '-'}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[600]))]))),
                                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(etat.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900)))),
                                ]),
                              ),
                            );
                          }),
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 16),
                            child: Row(children: [
                              Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.edit_calendar_rounded, size: 16), label: const Text('REDONDANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), onPressed: () => _showModifyRedondanceDialog(ctx, contrat.contratId, list.first['traitementId'], type))),
                              const SizedBox(width: 12),
                              Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.build_circle_outlined, size: 16), label: const Text('RÉPARER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), onPressed: () => _showRepairMontantDialog(list.first['traitementId']))),
                            ]),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            actions: [TextButton.icon(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.of(ctx).pop(), label: const Text('RETOUR'))],
          );
        },
      ),
    );
  }

  void _deleteContrat(Contrat contrat) {
    AppDialogs.showBlurDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Supprimer définitivement le contrat ${contrat.referenceContrat} ?'),
        actions: [
          TextButton.icon(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => Navigator.pop(ctx), label: const Text('ANNULER')),
          FilledButton.icon(icon: const Icon(Icons.delete_forever_rounded, size: 18), label: const Text('SUPPRIMER'), style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed), onPressed: () async {
            Navigator.pop(ctx);
            await context.read<ContratRepository>().deleteContrat(contrat.contratId, isAdmin: context.read<AuthRepository>().isAdmin);
            _reloadData();
          }),
        ],
      ),
    );
  }

  void _showAbrogationDialog(Contrat contrat) {
    DateTime selectedDate = DateTime.now();
    String motif = '';
    AppDialogs.showBlurDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
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
            TextButton.icon(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => Navigator.pop(ctx), label: const Text('ANNULER')),
            FilledButton.icon(icon: const Icon(Icons.check_circle_outline, size: 18), label: const Text('CONFIRMER'), style: FilledButton.styleFrom(backgroundColor: Colors.orange), onPressed: () async {
              Navigator.pop(ctx);
              await context.read<ContratRepository>().abrogateContract(contratId: contrat.contratId, abrogationDate: selectedDate, motif: motif, isAdmin: true);
              _reloadData();
            }),
          ],
        ),
      ),
    );
  }

  String _getDisplayDuration(Contrat contrat) {
    if (contrat.dureeType == 'Indéterminée') return 'Indéterminée';
    if (contrat.dateFin != null) {
      final diff = contrat.dateFin!.difference(contrat.dateDebut);
      final months = (diff.inDays / 30.44).round();
      if (contrat.statutContrat == 'Résilié') {
        final dateRes = DateFormat('dd/MM/yyyy').format(contrat.dateFin!);
        return '$months mois (résilié le $dateRes)';
      }
      if (months > 0) return '$months mois';
    }
    if (contrat.dureeContrat > 0) return '${contrat.dureeContrat} mois';
    return 'Non définie';
  }

  Widget _buildDialogHeader(BuildContext context, String title, String subtitle) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: Text(subtitle.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue, letterSpacing: 1.2))),
    ]);
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 12), child: Row(children: [
      Container(width: 4, height: 14, decoration: BoxDecoration(color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue, letterSpacing: 1.2)),
    ]));
  }

  Widget _buildDetailTile(IconData icon, String label, String value, bool isDark, {Color? valueColor}) {
    return ListTile(dense: true, visualDensity: VisualDensity.compact, leading: Icon(icon, size: 20, color: isDark ? AppTheme.accentBlue.withValues(alpha: 0.7) : AppTheme.primaryBlue.withValues(alpha: 0.7)), title: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.grey[500])), subtitle: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? (isDark ? Colors.white : Colors.black87))), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0));
  }

  Widget _buildSubtleDivider(bool isDark) => Divider(height: 1, thickness: 0.5, indent: 52, endIndent: 16, color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1));

  Color _getStatusColor(String s) {
    final l = s.toLowerCase();
    if (l.contains('actif')) return AppTheme.successGreen;
    if (l.contains('résilié')) return Colors.orange;
    if (l.contains('terminé')) return Colors.grey;
    return AppTheme.primaryBlue;
  }

  Color _getStatusColorForPlanning(String? s) {
    if (s == null) return Colors.grey;
    final l = s.toLowerCase();
    if (l.contains('effectué')) return AppTheme.successGreen;
    if (l.contains('classé')) return AppTheme.errorRed;
    return AppTheme.warningOrange;
  }

  Future<List<Map<String, dynamic>>> _loadTraitements(int id) async => await DatabaseService().query(SqlQueries.getTraitementsDetailedByContrat, [id]);

  Future<Map<String, List<Map<String, dynamic>>>> _loadFacturesGroupedByTraitement(int id) async {
    final rows = await DatabaseService().query(SqlQueries.getFacturesGroupedByTraitement, [id]);
    final map = <String, List<Map<String, dynamic>>>{};
    for (final r in rows) {
      final type = r['typeTraitement'] ?? 'Sans type';
      if (!map.containsKey(type)) map[type] = [];
      map[type]!.add({'factureId': r['facture_id'], 'montant': r['montant'], 'dateTraitement': r['date_traitement'] is String ? DateTime.parse(r['date_traitement']) : r['date_traitement'], 'etat': r['etat']});
    }
    return map;
  }

  Future<Map<String, List<Map<String, dynamic>>>> _loadContratPlanningsByType(int id) async {
    final rows = await DatabaseService().query('''
        SELECT DISTINCT t.traitement_id, tt.typeTraitement, pd.planning_detail_id, pd.date_planification, pd.statut, cl.axe
        FROM Traitement t
        JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
        JOIN Contrat c ON t.contrat_id = c.contrat_id
        JOIN Client cl ON c.client_id = cl.client_id
        LEFT JOIN Planning p ON t.traitement_id = p.traitement_id
        LEFT JOIN PlanningDetails pd ON p.planning_id = pd.planning_id
        WHERE t.contrat_id = ?
        ORDER BY tt.typeTraitement ASC, pd.date_planification ASC
    ''', [id]);
    final map = <String, List<Map<String, dynamic>>>{};
    for (final r in rows) {
      final type = r['typeTraitement'] ?? 'Sans type';
      if (!map.containsKey(type)) map[type] = [];
      map[type]!.add({'traitementId': r['traitement_id'], 'planning_detail_id': r['planning_detail_id'], 'date_planification': r['date_planification'] is String ? DateTime.parse(r['date_planification']) : r['date_planification'], 'etat': r['statut'], 'axe': r['axe']});
    }
    return map;
  }

  Future<Client?> _loadClientForContrat(int id) async {
    final rows = await DatabaseService().query('SELECT * FROM Client WHERE client_id = ?', [id]);
    return rows.isNotEmpty ? Client.fromMap(rows[0]) : null;
  }

  void _showModifyRedondanceDialog(BuildContext ctx, int cId, int tId, String type) {
    AppSnackBars.showInfo(ctx, 'Modification redondance pour $type');
  }

  Future<void> _showRepairMontantDialog(int tId) async {
    AppSnackBars.showInfo(context, 'Réparation en cours...');
  }
}

class _ContratCreationFlowScreen extends StatefulWidget {
  final int? clientId;
  const _ContratCreationFlowScreen({this.clientId});
  @override
  State<_ContratCreationFlowScreen> createState() => _ContratCreationFlowScreenState();
}

class _ContratCreationFlowScreenState extends State<_ContratCreationFlowScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un contrat')),
      body: Center(child: Text('Le flux de création est en cours de modernisation.')),
    );
  }
}
