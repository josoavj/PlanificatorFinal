import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/client.dart';
import '../../repositories/index.dart';
import '../../widgets/index.dart';
import '../../services/logging_service.dart';
import '../../utils/app_snackbars.dart';
import 'widgets/client_card.dart';
import 'widgets/client_list_header.dart';

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
          ClientListHeader(
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            searchQuery: _searchQuery,
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onRefresh: () async {
              _searchQuery = '';
              _searchController.clear();
              await context.read<ClientRepository>().loadClients();
            },
          ),
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
            itemBuilder: (context, index) => ClientCard(client: filteredClients[index]),
          );
        }

        return Center(
          child: EmptyStateWidget(
            title: _searchQuery.isEmpty ? 'Aucun client' : 'Aucun résultat',
            message: _searchQuery.isEmpty ? 'Aucun client trouvé. Commencez par créer un client.' : 'Aucun client ne correspond à votre recherche',
            icon: Icons.people_outline,
            actionLabel: _searchQuery.isEmpty ? 'Ajouter un client' : null,
          ),
        );
      },
    );
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
