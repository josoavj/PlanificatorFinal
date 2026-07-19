import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../models/index.dart';
import 'widgets/facture_group_card.dart';
import 'widgets/facture_list_header.dart';
import 'facture_detail_screen.dart';

class FactureScreen extends StatefulWidget {
  const FactureScreen({super.key});

  @override
  State<FactureScreen> createState() => _FactureScreenState();
}

class _FactureScreenState extends State<FactureScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<FactureRepository>().loadAllFactures();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<FactureRepository>(
        builder: (context, factureRepo, _) {
          final filteredFactures = _filterFactures(factureRepo.factures);
          final groupedData = _groupFactures(filteredFactures);

          return Column(
            children: [
              FactureListHeader(
                searchController: _searchController,
                searchQuery: _searchQuery,
                onSearchChanged: (v) => setState(() => _searchQuery = v),
                onRefresh: () {
                  _searchQuery = '';
                  _searchController.clear();
                  context.read<FactureRepository>().loadAllFactures();
                },
                factureCount: filteredFactures.length,
                treatmentCount: groupedData.keys.length,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: factureRepo.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : factureRepo.errorMessage != null
                          ? Center(child: Text('Erreur: ${factureRepo.errorMessage}', style: const TextStyle(color: Colors.red)))
                          : _buildList(groupedData),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(Map<String, List<Facture>> groupedData) {
    if (groupedData.isEmpty) {
      return const Center(child: Text('Aucune facture trouvée'));
    }

    final sortedKeys = groupedData.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final group = groupedData[key]!;
        return FactureGroupCard(
          title: key,
          factures: group,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FactureDetailScreen(factures: group, groupTitle: key),
            ),
          ),
        );
      },
    );
  }

  List<Facture> _filterFactures(List<Facture> factures) {
    if (_searchQuery.isEmpty) return factures;
    final q = _searchQuery.toLowerCase();
    return factures.where((f) => 
      (f.clientNom?.toLowerCase().contains(q) ?? false) || 
      (f.clientPrenom?.toLowerCase().contains(q) ?? false) || 
      (f.typeTreatment?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  Map<String, List<Facture>> _groupFactures(List<Facture> factures) {
    final Map<String, List<Facture>> grouped = {};
    for (final f in factures) {
      final key = '${f.clientFullName} - ${f.typeTreatment ?? 'N/A'}';
      grouped.putIfAbsent(key, () => []).add(f);
    }
    return grouped;
  }
}
