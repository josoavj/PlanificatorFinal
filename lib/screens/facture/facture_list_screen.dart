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

    // Charger les factures
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.clientId != null) {
        _factureRepository.loadFacturesForClient(widget.clientId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des factures'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (widget.clientId != null) {
                _factureRepository.loadFacturesForClient(widget.clientId!);
              }
            },
          ),
        ],
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

              // Liste des factures
              Expanded(
                child: ListView.builder(
                  itemCount: filteredFactures.length,
                  itemBuilder: (context, index) {
                    final facture = filteredFactures[index];
                    return _FactureCard(
                      facture: facture,
                      onTap: () =>
                          _showFactureDetails(context, facture, repository),
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

  void _showFactureDetails(
    BuildContext context,
    Facture facture,
    FactureRepository repository,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Facture #${facture.factureId}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Chip(
                    label: Text(facture.isPaid ? 'Payée' : 'Non payée'),
                    backgroundColor: facture.isPaid
                        ? Colors.green[100]
                        : Colors.orange[100],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Client
              if (facture.clientFullName != 'N/A')
                _buildDetailRow('Client', facture.clientFullName),

              // Type de traitement
              if (facture.typeTreatment != null)
                _buildDetailRow('Traitement', facture.typeTreatment!),

              // Date de planification
              if (facture.datePlanification != null)
                _buildDetailRow(
                  'Date planification',
                  _formatDate(facture.datePlanification!),
                ),

              // État du planning
              if (facture.etatPlanning != null)
                _buildDetailRow('État planning', facture.etatPlanning!),

              const SizedBox(height: 12),

              // Facture details
              _buildDetailRow(
                'Date facture',
                _formatDate(facture.dateTraitement),
              ),
              _buildDetailRow(
                'Montant',
                facture.montantFormatted,
                isBold: true,
              ),

              // Mode de paiement si payée
              if (facture.isPaid && facture.mode != null)
                _buildDetailRow('Mode paiement', facture.mode!),

              // Numéro chèque si applicable
              if (facture.numeroCheque != null)
                _buildDetailRow('Chèque #', facture.numeroCheque!),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showPriceModificationDialog(
                          context,
                          facture,
                          repository,
                        );
                      },
                      child: const Text('Modifier le prix'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: facture.isPaid
                          ? null
                          : () {
                              repository.markAsPaid(facture.factureId);
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Marquée comme payée'),
                                ),
                              );
                            },
                      child: const Text('Marquer payée'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPriceModificationDialog(
    BuildContext context,
    Facture facture,
    FactureRepository repository,
  ) {
    final priceController = TextEditingController(
      text: facture.montant.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Modifier le prix'),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            label: const Text('Nouveau montant'),
            suffix: const Text('Ar'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final newPrice = double.tryParse(priceController.text);
              if (newPrice != null && newPrice > 0) {
                repository.updateFacturePrice(
                  facture.factureId,
                  newPrice.toInt(),
                );
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prix mis à jour')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Montant invalide')),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

class _FactureCard extends StatelessWidget {
  final Facture facture;
  final VoidCallback onTap;

  const _FactureCard({Key? key, required this.facture, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: Icon(
          Icons.receipt,
          color: facture.isPaid ? Colors.green : Colors.orange,
        ),
        title: Text('Facture #${facture.factureId}'),
        subtitle: Text(DateFormat('dd/MM/yyyy').format(facture.dateTraitement)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              facture.montantFormatted,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              facture.isPaid ? 'Payée' : 'Non payée',
              style: TextStyle(
                fontSize: 12,
                color: facture.isPaid ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        onTap: onTap,
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
