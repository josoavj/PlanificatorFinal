import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/index.dart';
import '../../repositories/planning_details_repository.dart';
import 'widgets/history_client_card.dart';
import 'history_client_detail_screen.dart';

class HistoryClientListScreen extends StatefulWidget {
  final String title;
  final String code;
  final PlanningDetailsRepository repository;

  const HistoryClientListScreen({
    super.key,
    required this.title,
    required this.code,
    required this.repository,
  });

  @override
  State<HistoryClientListScreen> createState() => _HistoryClientListScreenState();
}

class _HistoryClientListScreenState extends State<HistoryClientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 0;
  bool _isMoreLoading = false;
  
  // Données groupées persistantes pour éviter le recalcul en build
  Map<String, List<Map<String, dynamic>>> _cachedGroupedData = {};
  List<String> _cachedFilteredClients = [];

  @override
  void initState() {
    super.initState();
    _processData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _processData() {
    // Filtrer par catégorie
    final treatments = widget.repository.allTreatmentsComplete.where((item) {
      final code = _normalizeCategoryCode(item['categorieTraitement']?.toString() ?? '');
      return code == widget.code;
    }).toList();

    _cachedGroupedData = _groupDataByClient(treatments);
    _cachedFilteredClients = _filterClients(_cachedGroupedData);
  }

  String _normalizeCategoryCode(String raw) {
    final upper = raw.toUpperCase().trim();
    if (upper.startsWith('AT') || upper.contains('ANTI TERMITES')) return 'AT';
    if (upper.startsWith('NI') || upper.contains('NETTOYAGE')) return 'NI';
    if (upper.startsWith('RO') || upper.contains('RAMASSAGE')) return 'RO';
    return 'PC';
  }

  Future<void> _loadMore() async {
    if (_isMoreLoading) return;
    setState(() => _isMoreLoading = true);
    
    _currentPage++;
    await widget.repository.loadHistoryPage(page: _currentPage);
    
    if (mounted) {
      setState(() {
        _processData();
        _isMoreLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // On ne recalcule que si la recherche change
    final filteredClients = _searchQuery.isEmpty 
        ? _cachedFilteredClients 
        : _cachedFilteredClients.where((c) => c.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildHeader(filteredClients.length),
          Expanded(
            child: filteredClients.isEmpty && !widget.repository.isLoading
                ? const EmptyStateWidget(
                    title: 'Aucun client',
                    message: 'Aucune intervention trouvée pour cette catégorie.',
                    icon: Icons.person_search_rounded,
                  )
                : PaginatedListView(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                    items: filteredClients,
                    isLoading: _isMoreLoading || widget.repository.isLoading,
                    hasMore: widget.repository.hasMoreHistory,
                    onLoadMore: _loadMore,
                    itemBuilder: (context, index) {
                      final clientName = filteredClients[index];
                      final interventions = _cachedGroupedData[clientName]!;
                      final completedCount = interventions.where((i) => i['etat']?.toString().contains('Effectué') ?? false).length;

                      return HistoryClientCard(
                        clientName: clientName,
                        axe: interventions.isNotEmpty ? (interventions.first['axe'] ?? 'N/A') : 'N/A',
                        totalInterventions: interventions.length,
                        completedInterventions: completedCount,
                        onTap: () => _showClientHistory(context, clientName, interventions),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count CLIENTS',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryBlue, fontSize: 11),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 24),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: AppTheme.cardDecoration(context, radius: 20),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Rechercher un client...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue),
          suffixIcon: _searchQuery.isNotEmpty 
              ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                }) 
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupDataByClient(List<Map<String, dynamic>> data) {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final item in data) {
      String label = item['traitement']?.toString() ?? 'Client Inconnu';
      String client = label;
      if (label.contains(' pour ')) {
        client = label.split(' pour ').last.trim();
      }
      groups.putIfAbsent(client, () => []).add(item);
    }
    return groups;
  }

  List<String> _filterClients(Map<String, List<Map<String, dynamic>>> groupedData) {
    final clients = groupedData.keys.toList();

    // TRI PAR ACTIVITÉ RÉCENTE (DESC)
    clients.sort((a, b) {
      final lastA = _getLatestActivity(groupedData[a]!);
      final lastB = _getLatestActivity(groupedData[b]!);
      
      if (lastA == null && lastB == null) return a.compareTo(b);
      if (lastA == null) return 1;
      if (lastB == null) return -1;
      
      return lastB.compareTo(lastA);
    });

    if (_searchQuery.isEmpty) return clients;
    final q = _searchQuery.toLowerCase();
    return clients.where((c) => c.toLowerCase().contains(q)).toList();
  }

  DateTime? _getLatestActivity(List<Map<String, dynamic>> interventions) {
    DateTime? latest;
    for (final i in interventions) {
      final date = _parseDate(i['date_planification'] ?? i['date']);
      if (date != null) {
        if (latest == null || date.isAfter(latest)) {
          latest = date;
        }
      }
    }
    return latest;
  }

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    return DateTime.tryParse(val.toString());
  }

  void _showClientHistory(BuildContext context, String clientName, List<Map<String, dynamic>> interventions) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HistoryClientDetailScreen(
          clientName: clientName,
          interventions: interventions,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: SlideTransition(
            position: animation.drive(Tween(begin: const Offset(0.05, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))),
            child: child,
          ));
        },
      ),
    );
  }
}
