import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/index.dart';
import '../../repositories/index.dart';
import '../../widgets/index.dart';
import '../../core/sql_queries.dart';
import '../../services/database_service.dart';
import '../../services/logging_service.dart';
import 'contrat_creation_dialog.dart';
import 'widgets/contrat_card.dart';
import 'widgets/contrat_list_header.dart';

class ContratScreen extends StatefulWidget {
  final int? clientId;
  const ContratScreen({super.key, this.clientId});

  @override
  State<ContratScreen> createState() => _ContratScreenState();
}

class _ContratScreenState extends State<ContratScreen> {
  Future<List<Map<String, dynamic>>>? _contratsFuture;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final logger = createLoggerWithFileOutput(name: 'contrat_screen');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reloadData() {
    setState(() {
      _contratsFuture = _fetchContratsWithDetails();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _contratsFuture,
        builder: (context, snapshot) {
          if (_contratsFuture == null || snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorDisplayWidget(
              message: 'Erreur: ${snapshot.error}', 
              onRetry: _reloadData
            );
          }

          final allData = snapshot.data ?? [];
          final filteredData = _filterData(allData);

          return Column(
            children: [
              ContratListHeader(
                searchController: _searchController,
                searchQuery: _searchQuery,
                onSearchChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                onRefresh: _reloadData,
                contratCount: filteredData.length,
              ),
              Expanded(
                child: filteredData.isEmpty
                    ? const EmptyStateWidget(
                        title: 'Aucun contrat', 
                        message: 'Créez un contrat pour commencer.', 
                        icon: Icons.description_outlined
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          final data = filteredData[index];
                          return ContratCard(
                            contrat: data['contrat'] as Contrat,
                            client: data['client'] as Client?,
                            numTraitements: data['numTraitements'] as int,
                            onUpdate: _reloadData,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'contrat_add',
        onPressed: _showAddContratDialog,
        label: const Text('Ajouter un contrat'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  List<Map<String, dynamic>> _filterData(List<Map<String, dynamic>> data) {
    if (_searchQuery.isEmpty) return data;
    return data.where((item) {
      final client = item['client'] as Client?;
      final contrat = item['contrat'] as Contrat;
      return '${client?.fullName}'.toLowerCase().contains(_searchQuery) ||
             contrat.referenceContrat.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _showAddContratDialog() async {
    final result = await AppDialogs.showBlurDialog<bool>(
      context: context,
      builder: (ctx) => const ContratCreationDialog(),
    );
    if (result == true) _reloadData();
  }
}
