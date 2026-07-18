import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/client.dart';
import '../../repositories/index.dart';
import '../../widgets/index.dart';
import '../../services/database_service.dart';
import '../../services/logging_service.dart';

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
    // Charger les clients avec timeout et fallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeClientData();
    });
  }

  /// Initialise le chargement des données clients
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
      logger.i(' Clients chargés avec succès');
    } catch (e) {
      logger.e(' Erreur loadClients: $e');

      // En cas d'erreur, on essaie de recharger une fois de plus
      if (!mounted) return;

      try {
        logger.i(' Nouvelle tentative de chargement...');
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;
        await context.read<ClientRepository>().loadClients();

        logger.i(' Nouvelle tentative réussie');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(' Clients chargés après retry'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (retryError) {
        logger.e(' Retry aussi échoué: $retryError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(' Erreur: ${retryError.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
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
          // En-tête avec gradient bleu et barre de recherche (TOUJOURS VISIBLE)
          _buildHeader(context),

          // Contenu principal: état de chargement, erreur, liste ou vide
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  /// Construit le contenu principal (liste, chargement, erreur ou vide)
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
        //  État de chargement
        if (state.isInitiallyLoading) {
          return const LoadingWidget(message: 'Chargement des clients...');
        }

        //  État d'erreur
        if (state.errorMessage != null) {
          return ErrorDisplayWidget(
            message: state.errorMessage!,
            onRetry: () => context.read<ClientRepository>().loadClients(),
          );
        }

        //  Filtrer les clients par recherche
        final filteredClients = _filterClientsBySearch(state.clients);

        //  Liste des clients ou état vide
        if (filteredClients.isNotEmpty) {
          return PaginatedListView<Client>(
            items: filteredClients,
            isLoading: state.isLoading,
            hasMore: state.hasMoreClients,
            onLoadMore: () {
              logger.i('Chargement page suivante des clients');
              context.read<ClientRepository>().loadNextPage();
            },
            itemBuilder: (context, index) {
              final client = filteredClients[index];
              return _buildClientCard(context, client);
            },
          );
        }

        // État vide
        return Center(
          child: EmptyStateWidget(
            title: _searchQuery.isEmpty ? 'Aucun client' : 'Aucun résultat',
            message: _searchQuery.isEmpty
                ? 'Aucun client trouvé. Commencez par créer un client.'
                : 'Aucun client ne correspond à votre recherche',
            icon: Icons.people_outline,
            actionLabel: _searchQuery.isEmpty ? 'Ajouter un client' : null,
          ),
        );
      },
    );
  }

  /// Construit l'en-tête avec gradient et barre de recherche
  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : AppTheme.primaryBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de recherche avec bouton d'actualisation
          Row(
            children: [
              // Barre de recherche
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un client...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.white70),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white54 : Colors.white70),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Bouton d'actualisation
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                  onPressed: () async {
                    _searchQuery = '';
                    _searchController.clear();
                    await context.read<ClientRepository>().loadClients();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Badge nombre de clients
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Selector<ClientRepository, int>(
                  selector: (_, repo) => _filterClientsBySearch(repo.clients).length,
                  builder: (context, count, _) {
                    return Row(
                      children: [
                        const Icon(Icons.people_alt_rounded, color: Colors.white70, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          '$count ${count > 1 ? 'clients' : 'client'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit une carte client moderne
  Widget _buildClientCard(
    BuildContext context,
    Client client,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Container(
        decoration: AppTheme.cardDecoration(context, radius: 24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showClientDetails(context, client),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec avatar, nom et catégorie
                  Row(
                    children: [
                      // Avatar optimisé
                      _buildAvatar(client),
                      const SizedBox(width: 16),
                      // Informations client
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
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Email et badge catégorie
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    client.email.isNotEmpty ? client.email : 'Pas d\'email',
                                    style: TextStyle(
                                      color: isDark ? Colors.white38 : Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                  // Chips info avec couleurs vibrantes
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          context: context,
                          icon: Icons.location_on_outlined,
                          label: client.axe,
                          color: isDark ? AppTheme.darkWarning : Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoChip(
                          context: context,
                          icon: Icons.assignment_outlined,
                          label: '${client.treatmentCount} traitement(s)',
                          color: isDark ? AppTheme.darkSuccess : AppTheme.successGreen,
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

  /// Construit l'avatar avec gradient
  Widget _buildAvatar(Client client) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryBlue, AppTheme.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Center(
        child: Text(
          client.fullName.isNotEmpty ? client.fullName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
    );
  }

  /// Construit le badge de catégorie
  Widget _buildCategoryBadge(String categorie) {
    final color = _getCategoryColor(categorie);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        categorie.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Construit un chip d'information
  Widget _buildInfoChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
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
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Retourne la couleur selon la catégorie
  Color _getCategoryColor(String categorie) {
    switch (categorie.toLowerCase()) {
      case 'particulier':
        return Colors.blue[600]!;
      case 'organisation':
        return Colors.purple[600]!;
      case 'société':
        return Colors.teal[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  /// Filtre les clients selon la requête de recherche
  List<Client> _filterClientsBySearch(List<Client> clients) {
    if (_searchQuery.isEmpty) {
      return clients;
    }

    final query = _searchQuery.toLowerCase();
    return clients
        .where(
          (client) =>
              client.fullName.toLowerCase().contains(query) ||
              client.email.toLowerCase().contains(query) ||
              client.telephone.contains(query) ||
              client.adresse.toLowerCase().contains(query),
        )
        .toList();
  }

  /// Affiche la boîte de dialogue d'édition

  Widget _buildDialogHeader(BuildContext context, String title, String subtitle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
          ),
          child: Text(
            subtitle.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryBlue,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildSubtleDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 52,
      endIndent: 16,
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
    );
  }

  /// Affiche les détails du client dans un AlertDialog avec sections
  void _showClientDetails(BuildContext context, Client client) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppDialogs.showBlurDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: _buildDialogHeader(context, 'Détails du Client', client.fullName),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION: INFORMATIONS PERSONNELLES
                _buildSectionHeader('Identité'),
                Container(
                  decoration: AppTheme.cardDecoration(context, radius: 24),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.person_outline, 'Nom', client.nom),
                        _buildSubtleDivider(isDark),
                        _buildDetailRow(Icons.person_pin_outlined, client.prenomLabel, client.prenom),
                        _buildSubtleDivider(isDark),
                        _buildDetailRow(Icons.alternate_email_rounded, 'Email', client.email),
                        _buildSubtleDivider(isDark),
                        _buildDetailRow(Icons.phone_outlined, 'Téléphone', client.telephone),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION: ADRESSE & LOCALISATION
                _buildSectionHeader('Localisation'),
                Container(
                  decoration: AppTheme.cardDecoration(context, radius: 24),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.location_on_outlined, 'Adresse', client.adresse),
                        _buildSubtleDivider(isDark),
                        _buildDetailRow(Icons.map_outlined, 'Secteur / Axe', client.axe),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION: CATÉGORIE & INFOS FISCALES
                _buildSectionHeader('Classification'),
                Container(
                  decoration: AppTheme.cardDecoration(context, radius: 24),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.category_outlined, 'Catégorie', client.categorie),
                        if (client.categorie == 'Société') ...[
                          _buildSubtleDivider(isDark),
                          _buildDetailRow(Icons.description_outlined, 'NIF', client.nif),
                          _buildSubtleDivider(isDark),
                          _buildDetailRow(Icons.badge_outlined, 'STAT', client.stat),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION: TRAITEMENTS ASSOCIÉS
                _buildSectionHeader('Services actifs'),
                if (client.treatmentCount > 0)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _loadTraitementsByClient(client.clientId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      final traitements = snapshot.data ?? [];
                      if (traitements.isEmpty) {
                        return const Center(child: Text('Aucun traitement trouvé', style: TextStyle(fontSize: 12, color: Colors.grey)));
                      }

                      return Column(
                        children: traitements.map((t) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: AppTheme.cardDecoration(context, radius: 16),
                            child: ListTile(
                              dense: true,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.medical_services_outlined, size: 18, color: AppTheme.primaryBlue),
                              ),
                              title: Text(
                                t['nom'] ?? 'Traitement',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              subtitle: Text(
                                t['type'] ?? '-',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600]),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.cardDecoration(context, radius: 24),
                    child: Column(
                      children: [
                        Icon(Icons.assignment_late_outlined, color: isDark ? Colors.white10 : Colors.grey[300], size: 32),
                        const SizedBox(height: 8),
                        Text('Aucun traitement pour ce client', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('FERMER'),
          ),
          if (client.treatmentCount > 0)
            FilledButton.icon(
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: const Text('PLANNING'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _showClientPlanningDialog(context, client);
              },
            ),
          OutlinedButton.icon(
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('ÉDITER'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _showEditClientDialog(context, client);
            },
          ),
        ],
      ),
    );
  }

  /// Charger les traitements d'un client
  Future<List<Map<String, dynamic>>> _loadTraitementsByClient(
    int clientId,
  ) async {
    try {
      final database = DatabaseService();
      const sql = '''
        SELECT DISTINCT t.traitement_id, t.contrat_id, tt.typeTraitement as nom,
               tt.categorieTraitement as type
        FROM Traitement t
        LEFT JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
        INNER JOIN Contrat c ON t.contrat_id = c.contrat_id
        WHERE c.client_id = ?
        ORDER BY tt.typeTraitement ASC
      ''';
      return await database
          .query(sql, [clientId])
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              logger.e(
                'TIMEOUT at 30s for _loadTraitementsByClient clientId=$clientId',
              );
              throw TimeoutException(
                'Timeout loading treatments for client $clientId after 30 seconds',
              );
            },
          );
    } catch (e) {
      logger.e('Erreur chargement traitements du client: $e');
      return [];
    }
  }

  /// Afficher le planning groupé par type de traitement pour un client
  void _showClientPlanningDialog(BuildContext context, Client client) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppDialogs.showBlurDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: _buildDialogHeader(context, 'Parcours Planning', client.fullName),
        content: SizedBox(
          width: 550,
          child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
            future: _loadClientTreatmentsByType(client.clientId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final groupedTreatments = snapshot.data ?? {};
              if (groupedTreatments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy_rounded, size: 48, color: isDark ? Colors.white10 : Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('Aucun traitement planifié'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: groupedTreatments.length,
                itemBuilder: (context, index) {
                  final typeTraitement = groupedTreatments.keys.elementAt(index);
                  final traitements = groupedTreatments[typeTraitement] ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header du type de traitement (Moderne)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              typeTraitement.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                color: AppTheme.primaryBlue,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${traitements.length}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Liste des plannings style "Vibrant Glass"
                      ...traitements.map((planning) {
                        final date = planning['date_planification'] as DateTime?;
                        final dateStr = date != null 
                            ? DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(date)
                            : 'Date inconnue';
                        
                        final parts = dateStr.split(' ');
                        if (parts.isNotEmpty) parts[0] = parts[0][0].toUpperCase() + parts[0].substring(1);
                        if (parts.length > 2) parts[2] = parts[2][0].toUpperCase() + parts[2].substring(1);
                        final capitalizedDate = parts.join(' ');

                        final etat = planning['etat'] as String? ?? '-';
                        final isEffectue = etat.toLowerCase().contains('effectué');
                        final statusColor = isEffectue 
                            ? (isDark ? AppTheme.darkSuccess : AppTheme.successGreen)
                            : (isDark ? AppTheme.darkWarning : AppTheme.warningOrange);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: AppTheme.cardDecoration(context, radius: 16),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  width: 4,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          capitalizedDate,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Réf: ${planning['contrat_reference']}',
                                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        etat.toUpperCase(),
                                        style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('RETOUR AUX DÉTAILS'),
          ),
        ],
      ),
    );
  }

  /// Charger les plannings groupés par type de traitement pour un client
  Future<Map<String, List<Map<String, dynamic>>>> _loadClientTreatmentsByType(
    int clientId,
  ) async {
    try {
      final database = DatabaseService();
      const sql = '''
        SELECT DISTINCT 
          t.traitement_id, 
          t.contrat_id, 
          tt.typeTraitement,
          tt.categorieTraitement as type, 
          c.reference_contrat as contrat_reference,
          pd.planning_detail_id,
          pd.date_planification,
          pd.statut as etat,
          p.planning_id,
          cl.axe
        FROM Traitement t
        INNER JOIN TypeTraitement tt ON t.id_type_traitement = tt.id_type_traitement
        INNER JOIN Contrat c ON t.contrat_id = c.contrat_id
        INNER JOIN Client cl ON c.client_id = cl.client_id
        LEFT JOIN Planning p ON p.traitement_id = t.traitement_id
        LEFT JOIN PlanningDetails pd ON pd.planning_id = p.planning_id
        WHERE c.client_id = ?
        ORDER BY tt.typeTraitement ASC, pd.date_planification ASC
      ''';

      final rows = await database
          .query(sql, [clientId])
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              logger.e(
                'TIMEOUT at 45s for _loadClientTreatmentsByType clientId=$clientId',
              );
              throw TimeoutException(
                'Timeout loading treatment types for client $clientId after 45 seconds',
              );
            },
          );

      final groupedMap = <String, List<Map<String, dynamic>>>{};

      for (final row in rows) {
        final typeTraitement =
            (row['typeTraitement'] as String?) ?? 'Sans type';

        final planningData = {
          'traitementId': row['traitement_id'] as int,
          'contratId': row['contrat_id'] as int,
          'nom': typeTraitement,
          'type': row['type'] as String,
          'contrat_reference': row['contrat_reference'] as String,
          'planning_detail_id': row['planning_detail_id'],
          'date_planification': row['date_planification'] is String
              ? DateTime.parse(row['date_planification'] as String)
              : row['date_planification'] as DateTime?,
          'axe': row['axe'] as String? ?? '-',
          'etat': row['etat'] as String? ?? '-',
        };

        if (!groupedMap.containsKey(typeTraitement)) {
          groupedMap[typeTraitement] = [];
        }
        // Vérifier si cette entrée a au moins un planning detail
        if (planningData['planning_detail_id'] != null) {
          groupedMap[typeTraitement]!.add(planningData);
        }
      }

      return groupedMap;
    } catch (e) {
      logger.e('Erreur chargement traitements groupés: $e');
      return {};
    }
  }

  /// Affiche la boîte de dialogue de modification du client (style Contrat)
  void _showEditClientDialog(BuildContext context, Client client) {
    final nomController = TextEditingController(text: client.nom);
    final prenomController = TextEditingController(text: client.prenom);
    final emailController = TextEditingController(text: client.email);
    final telephoneController = TextEditingController(text: client.telephone);
    final adresseController = TextEditingController(text: client.adresse);
    String selectedAxe = client.axe;
    String selectedCategorie = client.categorie;
    final nifController = TextEditingController(text: client.nif);
    final statController = TextEditingController(text: client.stat);

    AppDialogs.showBlurDialog(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier les informations du client'),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ═════════════════════════════════════════
                  // SECTION: INFORMATIONS PERSONNELLES
                  // ═════════════════════════════════════════
                  _buildSectionHeader('INFORMATIONS PERSONNELLES'),
                  _buildEditField('Nom', nomController),
                  _buildEditField(
                    selectedCategorie == 'Société' ||
                            selectedCategorie == 'Organisation'
                        ? 'Responsable'
                        : 'Prénom',
                    prenomController,
                  ),
                  _buildEditField('Email', emailController),
                  _buildEditField('Téléphone', telephoneController),
                  const SizedBox(height: 16),

                  // ═════════════════════════════════════════
                  // SECTION: ADRESSE & LOCALISATION
                  // ═════════════════════════════════════════
                  _buildSectionHeader('ADRESSE & LOCALISATION'),
                  _buildEditField('Adresse', adresseController),
                  _buildAxisDropdown((value) {
                    setState(() {
                      selectedAxe = value;
                    });
                  }, selectedAxe),
                  const SizedBox(height: 16),

                  // ═════════════════════════════════════════
                  // SECTION: CATÉGORIE & INFOS FISCALES
                  // ═════════════════════════════════════════
                  _buildSectionHeader('CATÉGORIE & INFOS'),
                  _buildCategoryDropdown((value) {
                    setState(() {
                      selectedCategorie = value;
                      // Réinitialiser les champs NIF/STAT si passage à Particulier
                      if (value == 'Particulier') {
                        nifController.clear();
                        statController.clear();
                      }
                    });
                  }, selectedCategorie),

                  // Afficher les champs NIF/STAT uniquement pour Société
                  if (selectedCategorie == 'Société') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informations Fiscales',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildEditField('NIF', nifController),
                          _buildEditField('STAT', statController),
                        ],
                      ),
                    ),
                  ],

                  // Afficher un message pour Organisation
                  if (selectedCategorie == 'Organisation') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Les infos fiscales ne sont pas requises pour les organisations.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Enregistrer'),
              onPressed: () async {
                if (nomController.text.isNotEmpty &&
                    prenomController.text.isNotEmpty) {
                  final updatedClient = Client(
                    clientId: client.clientId,
                    nom: nomController.text,
                    prenom: prenomController.text,
                    email: emailController.text,
                    telephone: telephoneController.text,
                    adresse: adresseController.text,
                    categorie: selectedCategorie,
                    nif: nifController.text,
                    stat: statController.text,
                    axe: selectedAxe,
                    dateAjout: client.dateAjout,
                    treatmentCount: client.treatmentCount,
                  );

                  await context.read<ClientRepository>().updateClient(
                    updatedClient,
                  );
                  await context.read<ClientRepository>().loadClients();
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(' Client modifié avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        ' Veuillez remplir les champs obligatoires',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Construit un champ de texte pour l'édition
  Widget _buildEditField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  /// Dropdown pour les axes
  Widget _buildAxisDropdown(Function(String) onChanged, String selectedValue) {
    final axes = ['Nord (N)', 'Sud (S)', 'Est (E)', 'Ouest (O)', 'Centre (C)'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: selectedValue,
        decoration: InputDecoration(
          labelText: 'Axe',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        items: axes.map((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        onChanged: (String? value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }

  /// Dropdown pour les catégories
  Widget _buildCategoryDropdown(
    Function(String) onChanged,
    String selectedValue,
  ) {
    final categories = ['Particulier', 'Organisation', 'Société'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: selectedValue,
        decoration: InputDecoration(
          labelText: 'Catégorie',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        items: categories.map((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        onChanged: (String? value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }

  /// Déterminer la couleur du statut
  /// Construit un header de section
  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une ligne de détail avec icône
  Widget _buildDetailRow(IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(
        icon,
        size: 20,
        color: isDark ? AppTheme.accentBlue.withValues(alpha: 0.7) : AppTheme.primaryBlue.withValues(alpha: 0.7),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white38 : Colors.grey[500],
        ),
      ),
      subtitle: Text(
        value.isNotEmpty ? value : '-',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }
}

/// État du repository client pour le Selector
class ClientRepoState {
  final List<Client> clients;
  final bool isLoading;
  final bool isInitiallyLoading;
  final bool hasMoreClients;
  final String? errorMessage;

  ClientRepoState({
    required this.clients,
    required this.isLoading,
    required this.isInitiallyLoading,
    required this.hasMoreClients,
    this.errorMessage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientRepoState &&
          runtimeType == other.runtimeType &&
          clients == other.clients &&
          isLoading == other.isLoading &&
          isInitiallyLoading == other.isInitiallyLoading &&
          hasMoreClients == other.hasMoreClients &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      clients.hashCode ^
      isLoading.hashCode ^
      isInitiallyLoading.hashCode ^
      hasMoreClients.hashCode ^
      errorMessage.hashCode;
}
