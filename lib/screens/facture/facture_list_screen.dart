import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../repositories/index.dart';
import '../../models/index.dart';
import '../../widgets/index.dart';

class FactureListScreen extends StatefulWidget {
  final int? clientId; // Si null, affiche toutes les factures

  const FactureListScreen({Key? key, this.clientId}) : super(key: key);

  @override
  State<FactureListScreen> createState() => _FactureListScreenState();
}

class _FactureListScreenState extends State<FactureListScreen> {
  late FactureRepository _factureRepository;
  String _filterState = 'all'; // 'all', 'paid', 'unpaid'

  @override
  void initState() {
    super.initState();
    _factureRepository = context.read<FactureRepository>();

    // ✅ Charger les factures (toutes ou par client)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.clientId != null) {
        await _factureRepository.loadFacturesForClient(widget.clientId!);
      } else {
        // ✅ CORRECTION: Charger TOUTES les factures si pas de clientId
        await _factureRepository.loadAllFactures();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'facture_list_refresh',
        onPressed: () async {
          if (widget.clientId != null) {
            await _factureRepository.loadFacturesForClient(widget.clientId!);
          } else {
            // ✅ CORRECTION: Recharger toutes les factures si pas de clientId
            await _factureRepository.loadAllFactures();
          }
        },
        tooltip: 'Actualiser',
        child: const Icon(Icons.refresh),
      ),
      body: Consumer<FactureRepository>(
        builder: (context, repository, _) {
          // État de chargement
          if (repository.isLoading) {
            return const LoadingWidget(message: 'Chargement des factures...');
          }

          // État d'erreur
          if (repository.errorMessage != null) {
            return ErrorDisplayWidget(
              message: repository.errorMessage!,
              onRetry: () {
                if (widget.clientId != null) {
                  repository.loadFacturesForClient(widget.clientId!);
                } else {
                  // ✅ CORRECTION: Recharger toutes les factures si pas de clientId
                  repository.loadAllFactures();
                }
              },
            );
          }

          // Récupérer et filtrer les factures
          final factures = repository.factures;
          final filteredFactures = _filterFactures(factures);

          // État vide
          if (filteredFactures.isEmpty) {
            return EmptyStateWidget(
              title: 'Aucune facture',
              message: _filterState == 'all'
                  ? 'Aucune facture trouvée'
                  : _filterState == 'paid'
                  ? 'Aucune facture payée'
                  : 'Aucune facture non payée',
              icon: Icons.receipt_outlined,
            );
          }

          // Grouper les factures par client et traitement
          final Map<String, List<Facture>> groupedByClient = {};
          for (final facture in filteredFactures) {
            final clientName = facture.clientFullName;
            if (!groupedByClient.containsKey(clientName)) {
              groupedByClient[clientName] = [];
            }
            groupedByClient[clientName]!.add(facture);
          }

          // Trier alphabétiquement par nom client, et trier les factures par date décroissante
          final sortedKeys = groupedByClient.keys.toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

          for (final key in sortedKeys) {
            groupedByClient[key]!.sort((a, b) {
              return b.dateTraitement.compareTo(
                a.dateTraitement,
              ); // Récent d'abord
            });
          }

          return Column(
            children: [
              // Filtres
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Toutes'),
                      selected: _filterState == 'all',
                      onSelected: (_) {
                        setState(() => _filterState = 'all');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Payées'),
                      selected: _filterState == 'paid',
                      onSelected: (_) {
                        setState(() => _filterState = 'paid');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Non payées'),
                      selected: _filterState == 'unpaid',
                      onSelected: (_) {
                        setState(() => _filterState = 'unpaid');
                      },
                    ),
                  ],
                ),
              ),

              // Statistiques
              _buildStatisticsBar(repository, filteredFactures),

              // Liste des factures groupées par client
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    final clientName = sortedKeys[index];
                    final clientFactures = groupedByClient[clientName]!;

                    return _ClientFacturesCard(
                      clientName: clientName,
                      factureCount: clientFactures.length,
                      totalAmount: clientFactures.fold<double>(
                        0.0,
                        (sum, f) => sum + (f.montant),
                      ),
                      paidAmount: clientFactures
                          .where((f) => f.isPaid)
                          .fold<double>(0.0, (sum, f) => sum + (f.montant)),
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    _FacturesListByClientScreen(
                                      clientName: clientName,
                                      factures: clientFactures,
                                    ),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) => FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Facture> _filterFactures(List<Facture> factures) {
    if (_filterState == 'paid') {
      return factures.where((f) => f.isPaid).toList();
    } else if (_filterState == 'unpaid') {
      return factures.where((f) => !f.isPaid).toList();
    }
    return factures;
  }

  Widget _buildStatisticsBar(
    FactureRepository repository,
    List<Facture> filteredFactures,
  ) {
    final paidAmount = filteredFactures
        .where((f) => f.isPaid)
        .fold<double>(0, (sum, f) => sum + f.montant);
    final unpaidAmount = filteredFactures
        .where((f) => !f.isPaid)
        .fold<double>(0, (sum, f) => sum + f.montant);
    final totalAmount = paidAmount + unpaidAmount;

    final formatter = NumberFormat.currency(
      locale: 'fr_MG',
      symbol: ' Ar',
      decimalDigits: 2,
    );

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatColumn('Total', formatter.format(totalAmount)),
                _StatColumn('Payé', formatter.format(paidAmount)),
                _StatColumn('Dû', formatter.format(unpaidAmount)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card pour afficher un client avec ses factures
class _ClientFacturesCard extends StatelessWidget {
  final String clientName;
  final int factureCount;
  final double totalAmount;
  final double paidAmount;
  final VoidCallback onTap;

  const _ClientFacturesCard({
    required this.clientName,
    required this.factureCount,
    required this.totalAmount,
    required this.paidAmount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unpaidAmount = totalAmount - paidAmount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$factureCount facture(s)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (paidAmount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Payé: ${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(paidAmount)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (unpaidAmount > 0) const SizedBox(width: 8),
                        if (unpaidAmount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Dû: ${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(unpaidAmount)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Écran pour afficher les factures d'un client
class _FacturesListByClientScreen extends StatelessWidget {
  final String clientName;
  final List<Facture> factures;

  const _FacturesListByClientScreen({
    required this.clientName,
    required this.factures,
  });

  @override
  Widget build(BuildContext context) {
    // Trier les factures par date croissante (plus anciennes en premier)
    final sortedFactures = List<Facture>.from(factures)
      ..sort((a, b) => a.dateTraitement.compareTo(b.dateTraitement));

    return Scaffold(
      appBar: AppBar(title: Text(clientName)),
      body: sortedFactures.isEmpty
          ? const EmptyStateWidget(
              title: 'Aucune facture',
              message: 'Aucune facture pour ce client',
              icon: Icons.receipt_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sortedFactures.length,
              itemBuilder: (context, index) {
                final facture = sortedFactures[index];
                return _FactureDetailCard(
                  facture: facture,
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            _FactureDetailScreen(facture: facture),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

/// Card pour afficher une facture
class _FactureDetailCard extends StatelessWidget {
  final Facture facture;
  final VoidCallback onTap;

  const _FactureDetailCard({required this.facture, required this.onTap});

  Color _getStatusBgColor(String etat) {
    if (etat.toLowerCase().contains('payée') ||
        etat.toLowerCase().contains('payé')) {
      return Colors.green.shade100;
    } else if (etat.toLowerCase().contains('à venir')) {
      return Colors.red.shade100;
    } else {
      return Colors.red.shade100;
    }
  }

  Color _getStatusTextColor(String etat) {
    if (etat.toLowerCase().contains('payée') ||
        etat.toLowerCase().contains('payé')) {
      return Colors.green.shade800;
    } else if (etat.toLowerCase().contains('à venir')) {
      return Colors.red.shade800;
    } else {
      return Colors.red.shade800;
    }
  }

  String _getStatusText(String etat) {
    if (etat.toLowerCase().contains('payée') ||
        etat.toLowerCase().contains('payé')) {
      return 'Payée';
    } else if (etat.toLowerCase().contains('à venir')) {
      return 'À venir';
    } else {
      return 'Non payée';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Facture #${facture.factureId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(facture.dateTraitement),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusBgColor(facture.etat),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getStatusText(facture.etat),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getStatusTextColor(facture.etat),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    facture.montantFormatted,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Écran détail d'une facture
class _FactureDetailScreen extends StatelessWidget {
  final Facture facture;

  const _FactureDetailScreen({required this.facture});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Facture #${facture.factureId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // TODO: Implémenter l'impression
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Impression en cours...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implémenter l'édition
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Édition en cours...')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations générales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations générales',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow('Facture', 'Facture #${facture.factureId}'),
                    _DetailRow(
                      'Date',
                      DateFormat('dd/MM/yyyy').format(facture.dateTraitement),
                    ),
                    _DetailRow('Client', facture.clientNom ?? 'Inconnu'),
                    _DetailRow(
                      'État',
                      facture.isPaid ? 'Payée' : 'Non payée',
                      isBold: !facture.isPaid,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Montants
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Montants',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow('Total', facture.montantFormatted, isBold: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DetailRow(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            value,
            style: isBold
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                : null,
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn(this.label, this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
