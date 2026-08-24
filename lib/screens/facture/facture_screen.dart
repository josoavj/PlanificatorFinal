import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../models/index.dart';
import 'widgets/facture_group_card.dart';
import 'widgets/facture_list_header.dart';
import 'facture_detail_screen.dart';
import '../../widgets/paginated_list_view.dart';

class FactureScreen extends StatefulWidget {
  const FactureScreen({super.key});

  @override
  State<FactureScreen> createState() => _FactureScreenState();
}

class _FactureScreenState extends State<FactureScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 0;
  bool _isMoreLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await context.read<FactureRepository>().loadFacturesPage(0);
  }

  Future<void> _loadMore() async {
    if (_isMoreLoading) return;
    setState(() => _isMoreLoading = true);
    _currentPage++;
    await context.read<FactureRepository>().loadFacturesPage(_currentPage);
    if (mounted) setState(() => _isMoreLoading = false);
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
          // Filtrage local (ok pour search sets raisonnables)
          final filteredFactures = _filterFactures(factureRepo.factures);
          final groupedData = _groupFactures(filteredFactures);
          final sortedKeys = groupedData.keys.toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

          return Column(
            children: [
              FactureListHeader(
                searchController: _searchController,
                searchQuery: _searchQuery,
                onSearchChanged: (v) => setState(() => _searchQuery = v),
                onRefresh: () {
                  _searchQuery = '';
                  _searchController.clear();
                  _currentPage = 0;
                  _loadData();
                },
                factureCount: filteredFactures.length,
                treatmentCount: groupedData.keys.length,
              ),
              Expanded(
                child: factureRepo.isLoading && factureRepo.factures.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _buildList(factureRepo, sortedKeys, groupedData),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(FactureRepository repo, List<String> sortedKeys, Map<String, List<Facture>> groupedData) {
    if (sortedKeys.isEmpty && !repo.isLoading) {
      return const Center(child: Text('Aucune facture trouvée'));
    }

    return PaginatedListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      items: sortedKeys,
      isLoading: _isMoreLoading || repo.isLoading,
      hasMore: repo.hasMoreFactures,
      onLoadMore: _loadMore,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final group = groupedData[key]!;
        return FactureGroupCard(
          title: key,
          factures: group,
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => 
                  FactureDetailScreen(factures: group, groupTitle: key),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
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
