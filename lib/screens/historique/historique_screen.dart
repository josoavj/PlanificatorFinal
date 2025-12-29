import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../widgets/index.dart';

class HistoriqueScreen extends StatefulWidget {
  final int? clientId; // Si null, affiche tout l'historique
  final String? categorie; // Si spécifiée, filtre par catégorie

  const HistoriqueScreen({Key? key, this.clientId, this.categorie})
    : super(key: key);

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  late PlanningDetailsRepository _planningDetailsRepo;

  final List<Map<String, dynamic>> _sections = [
    {
      'title': 'En attente',
      'etat': 'en attente',
      'icon': Icons.schedule,
      'color': Colors.orange,
      'count': 0,
    },
    {
      'title': 'En cours',
      'etat': 'en cours',
      'icon': Icons.hourglass_top,
      'color': Colors.blue,
      'count': 0,
    },
    {
      'title': 'Terminé',
      'etat': 'terminé',
      'icon': Icons.check_circle,
      'color': Colors.green,
      'count': 0,
    },
    {
      'title': 'Annulé',
      'etat': 'annulé',
      'icon': Icons.cancel,
      'color': Colors.red,
      'count': 0,
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _planningDetailsRepo = context.read<PlanningDetailsRepository>();
    _loadData();
  }

  void _loadData() {
    _planningDetailsRepo.loadUpcomingTreatmentsComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Consumer<PlanningDetailsRepository>(
        builder: (context, repository, _) {
          if (repository.isLoading) {
            return const LoadingWidget(
              message: 'Chargement de l\'historique...',
            );
          }

          if (repository.errorMessage != null) {
            return ErrorDisplayWidget(
              message: repository.errorMessage!,
              onRetry: _loadData,
            );
          }

          final allTreatments = repository.upcomingTreatmentsComplete;

          // Compter les traitements par état
          final Map<String, List<Map<String, dynamic>>> treatmentsByState = {
            'en attente': [],
            'en cours': [],
            'terminé': [],
            'annulé': [],
          };

          for (final treatment in allTreatments) {
            final etat = _convertToString(treatment['etat']).toLowerCase();
            if (treatmentsByState.containsKey(etat)) {
              treatmentsByState[etat]!.add(treatment);
            }
          }

          if (allTreatments.isEmpty) {
            return const EmptyStateWidget(
              title: 'Aucun traitement',
              message: 'Aucun traitement à afficher pour le moment',
              icon: Icons.history,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _sections.length,
            itemBuilder: (context, index) {
              final section = _sections[index];
              final etat = section['etat'] as String;
              final treatments = treatmentsByState[etat] ?? [];

              return _SectionCard(
                title: section['title'] as String,
                etat: etat,
                icon: section['icon'] as IconData,
                color: section['color'] as Color,
                count: treatments.length,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _TreatmentListScreen(
                        title: section['title'] as String,
                        etat: etat,
                        treatments: treatments,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _convertToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is DateTime) return value.toString();
    if (value is List<int>) {
      return String.fromCharCodes(value);
    }
    return value.toString();
  }
}

/// Card pour afficher une section d'état
class _SectionCard extends StatelessWidget {
  final String title;
  final String etat;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  const _SectionCard({
    required this.title,
    required this.etat,
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count traitement(s)',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Écran pour afficher la liste complète des traitements d'une section
class _TreatmentListScreen extends StatelessWidget {
  final String title;
  final String etat;
  final List<Map<String, dynamic>> treatments;

  const _TreatmentListScreen({
    required this.title,
    required this.etat,
    required this.treatments,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: treatments.isEmpty
          ? const EmptyStateWidget(
              title: 'Aucun traitement',
              message: 'Aucun traitement dans cette section',
              icon: Icons.event_busy,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: treatments.length,
              itemBuilder: (context, index) {
                final treatment = treatments[index];
                return _TreatmentCard(
                  treatment: treatment,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            _TreatmentDetailScreen(treatment: treatment),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

/// Card pour afficher un traitement
class _TreatmentCard extends StatelessWidget {
  final Map<String, dynamic> treatment;
  final VoidCallback onTap;

  const _TreatmentCard({required this.treatment, required this.onTap});

  String _convertToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is DateTime) return value.toString();
    if (value is List<int>) {
      return String.fromCharCodes(value);
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final traitement = _convertToString(treatment['traitement']);
    final axe = _convertToString(treatment['axe']);
    final clientName = _convertToString(treatment['client_name']);
    final redondance = _convertToString(treatment['redondance']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          traitement,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Axe: $axe',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Client: $clientName',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Freq: $redondance',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.blue[700]),
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
}

/// Écran de détail d'un traitement - affiche historique des passages
class _TreatmentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> treatment;

  const _TreatmentDetailScreen({required this.treatment});

  String _convertToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is DateTime) return value.toString();
    if (value is List<int>) {
      return String.fromCharCodes(value);
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final traitement = _convertToString(treatment['traitement']);
    final axe = _convertToString(treatment['axe']);
    final etat = _convertToString(treatment['etat']);
    final clientName = _convertToString(treatment['client_name']);
    final redondance = _convertToString(treatment['redondance']);
    final date = treatment['date'];

    return Scaffold(
      appBar: AppBar(title: Text(traitement)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations principales
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations du traitement',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow('Type', traitement),
                    _DetailRow('Axe', axe),
                    _DetailRow('Client', clientName),
                    _DetailRow('Fréquence', redondance),
                    _DetailRow('État', etat, valueColor: _getStateColor(etat)),
                    _DetailRow(
                      'Dernière date',
                      date != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(
                              DateTime.tryParse(date.toString()) ??
                                  DateTime.now(),
                            )
                          : 'N/A',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Historique des passages
            Text(
              'Historique des passages',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Détails des passages disponibles',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStateColor(String etat) {
    switch (etat.toLowerCase()) {
      case 'en attente':
        return Colors.orange;
      case 'en cours':
        return Colors.blue;
      case 'terminé':
        return Colors.green;
      case 'annulé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// Row pour afficher un détail clé-valeur
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
