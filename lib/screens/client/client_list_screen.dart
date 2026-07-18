import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/client.dart';
import '../../repositories/index.dart';
import '../../widgets/index.dart';
import '../../services/logging_service.dart';
import '../../utils/app_snackbars.dart';
import 'widgets/client_details_dialog.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  final logger = createLoggerWithFileOutput(name: 'client_list_screen');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeClientData();
    });
  }

  Future<void> _initializeClientData() async {
    try {
      logger.i('Debut initialisation clients...');
      await context.read<ClientRepository>().loadClients().timeout(
        const Duration(seconds: 65),
        onTimeout: () {
          logger.e(' Timeout chargement clients après 65 secondes');
          throw TimeoutException('Chargement clients timeout');
        },
      );
    } catch (e) {
      logger.e(' Erreur loadClients: $e');
      if (!mounted) return;
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        await context.read<ClientRepository>().loadClients();
        if (mounted) AppSnackBars.showSuccess(context, ' Clients chargés après retry');
      } catch (retryError) {
        if (mounted) AppSnackBars.showError(context, ' Erreur: ${retryError.toString()}');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Selector<ClientRepository, ClientRepoState>(
      selector: (_, repo) => ClientRepoState(
        clients: repo.clients,
        isLoading: repo.isLoading,
        isInitiallyLoading: repo.isInitiallyLoading,
        hasMoreClients: repo.hasMoreClients,
        errorMessage: repo.errorMessage,
      ),
      builder: (context, state, _) {
        if (state.isInitiallyLoading) return const LoadingWidget(message: 'Chargement des clients...');
        if (state.errorMessage != null) return ErrorDisplayWidget(message: state.errorMessage!, onRetry: () => context.read<ClientRepository>().loadClients());

        final filteredClients = _filterClientsBySearch(state.clients);
        if (filteredClients.isNotEmpty) {
          return PaginatedListView<Client>(
            items: filteredClients,
            isLoading: state.isLoading,
            hasMore: state.hasMoreClients,
            onLoadMore: () => context.read<ClientRepository>().loadNextPage(),
            itemBuilder: (context, index) => _buildClientCard(context, filteredClients[index]),
          );
        }

        return Center(child: EmptyStateWidget(title: _searchQuery.isEmpty ? 'Aucun client' : 'Aucun résultat', message: _searchQuery.isEmpty ? 'Aucun client trouvé. Commencez par créer un client.' : 'Aucun client ne correspond à votre recherche', icon: Icons.people_outline, actionLabel: _searchQuery.isEmpty ? 'Ajouter un client' : null));
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(color: isDark ? colorScheme.surfaceContainer : AppTheme.primaryBlue, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32))),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un client...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.white70),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white54 : Colors.white70),
                    suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true, fillColor: Colors.white.withValues(alpha: 0.15),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 12),
              Container(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)), child: IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22), onPressed: () async { _searchQuery = ''; _searchController.clear(); await context.read<ClientRepository>().loadClients(); })),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                child: Selector<ClientRepository, int>(
                  selector: (_, repo) => _filterClientsBySearch(repo.clients).length,
                  builder: (context, count, _) => Row(children: [const Icon(Icons.people_alt_rounded, color: Colors.white70, size: 14), const SizedBox(width: 8), Text('$count ${count > 1 ? 'clients' : 'client'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5))]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, Client client) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Container(
        decoration: AppTheme.cardDecoration(context, radius: 24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => ClientDetailsDialog.show(context, client, () => context.read<ClientRepository>().loadClients()),
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
                            Text(client.fullName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Row(children: [Expanded(child: Text(client.email.isNotEmpty ? client.email : 'Pas d\'email', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)), _buildCategoryBadge(client.categorie)]),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(children: [Expanded(child: _buildInfoChip(icon: Icons.location_on_outlined, label: client.axe, color: isDark ? AppTheme.darkWarning : Colors.orange.shade700)), const SizedBox(width: 12), Expanded(child: _buildInfoChip(icon: Icons.assignment_outlined, label: '${client.treatmentCount} traitement(s)', color: isDark ? AppTheme.darkSuccess : AppTheme.successGreen))]),
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
      width: 52, height: 52,
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.primaryBlue, AppTheme.primaryDark]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Center(child: Text(client.fullName.isNotEmpty ? client.fullName[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 22))),
    );
  }

  Widget _buildCategoryBadge(String cat) {
    final color = _getCategoryColor(cat);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(cat.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label, required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 10), Expanded(child: Text(label, style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black87, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis))]),
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

  List<Client> _filterClientsBySearch(List<Client> clients) {
    if (_searchQuery.isEmpty) return clients;
    final q = _searchQuery.toLowerCase();
    return clients.where((c) => c.fullName.toLowerCase().contains(q) || c.email.toLowerCase().contains(q) || c.telephone.contains(q) || c.adresse.toLowerCase().contains(q)).toList();
  }
}

class ClientRepoState {
  final List<Client> clients;
  final bool isLoading;
  final bool isInitiallyLoading;
  final bool hasMoreClients;
  final String? errorMessage;
  ClientRepoState({required this.clients, required this.isLoading, required this.isInitiallyLoading, required this.hasMoreClients, this.errorMessage});
  @override
  bool operator ==(Object other) => identical(this, other) || other is ClientRepoState && runtimeType == other.runtimeType && clients == other.clients && isLoading == other.isLoading && isInitiallyLoading == other.isInitiallyLoading && hasMoreClients == other.hasMoreClients && errorMessage == other.errorMessage;
  @override
  int get hashCode => clients.hashCode ^ isLoading.hashCode ^ isInitiallyLoading.hashCode ^ hasMoreClients.hashCode ^ errorMessage.hashCode;
}
