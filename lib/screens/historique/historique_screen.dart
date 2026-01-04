import 'package:flutter/material.dart';
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
      'title': 'Anti termites (AT)',
      'code': 'AT',
      'icon': Icons.bug_report,
      'color': Colors.purple,
      'count': 0,
    },
    {
      'title': 'Lutte antiparasitaire (PC)',
      'code': 'PC',
      'icon': Icons.pest_control,
      'color': Colors.orange,
      'count': 0,
    },
    {
      'title': 'Nettoyage Industriel (NI)',
      'code': 'NI',
      'icon': Icons.cleaning_services,
      'color': Colors.blue,
      'count': 0,
    },
    {
      'title': 'Ramassage Ordures (RO)',
      'code': 'RO',
      'icon': Icons.delete_sweep,
      'color': Colors.brown,
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'historique_refresh',
        onPressed: _loadData,
        tooltip: 'Actualiser',
        child: const Icon(Icons.refresh),
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

          // Compter les traitements par catégorie (utiliser les codes courts AT, PC, NI, RO)
          final Map<String, List<Map<String, dynamic>>> treatmentsByCode = {
            'AT': [],
            'PC': [],
            'NI': [],
            'RO': [],
          };

          for (final treatment in allTreatments) {
            var rawCategorie = _convertToString(
              treatment['categorieTraitement'],
            );
            // Normaliser la catégorie vers son code court
            var code = _normalizeCategoryCode(rawCategorie);
            if (treatmentsByCode.containsKey(code)) {
              treatmentsByCode[code]!.add(treatment);
            }
          }

          if (allTreatments.isEmpty) {
            return const EmptyStateWidget(
              title: 'Aucun traitement',
              message: 'Aucun traitement à afficher pour le moment',
              icon: Icons.history,
            );
          }

          return Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                children: _sections.map((section) {
                  final code = (section['code'] as String?) ?? 'PC';
                  final treatments = treatmentsByCode[code] ?? [];

                  return _CategoryButton(
                    label: code,
                    count: treatments.length,
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  _TreatmentListScreen(
                                    title:
                                        (section['title'] as String?) ?? 'N/A',
                                    code: code,
                                    treatments: treatments,
                                  ),
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
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  String _convertToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    if (value is bool) return value.toString();
    if (value is DateTime) return value.toString();
    if (value is List<int>) {
      try {
        return String.fromCharCodes(value);
      } catch (e) {
        return '';
      }
    }
    return value?.toString() ?? '';
  }

  /// Normaliser la catégorie brute vers son code court (AT, PC, NI, RO)
  String _normalizeCategoryCode(String rawCategorie) {
    if (rawCategorie.isEmpty) return 'PC'; // Par défaut

    // Chercher les codes en fonction du contenu exact
    final upper = rawCategorie.toUpperCase().trim();

    if (upper.startsWith('AT') || upper.contains('ANTI TERMITES')) return 'AT';
    if (upper.startsWith('NI') || upper.contains('NETTOYAGE')) return 'NI';
    if (upper.startsWith('RO') || upper.contains('RAMASSAGE')) return 'RO';
    if (upper.startsWith('PC') || upper.contains('ANTIPARASITAIRE'))
      return 'PC';

    return 'PC'; // Par défaut
  }
}

/// Écran pour afficher la liste des Traitement × Client d'une section
class _TreatmentListScreen extends StatelessWidget {
  final String title;
  final String code;
  final List<Map<String, dynamic>> treatments;

  const _TreatmentListScreen({
    required this.title,
    required this.code,
    required this.treatments,
  });

  @override
  Widget build(BuildContext context) {
    // Grouper par Traitement + Client (uniquement les info de base)
    final Map<String, List<Map<String, dynamic>>> treatmentClientGroups = {};

    for (final treatment in treatments) {
      final traitementName = _convertToString(treatment['traitement']);
      final clientName = _convertToString(treatment['client'] ?? '');
      final key = '$traitementName|$clientName';

      if (!treatmentClientGroups.containsKey(key)) {
        treatmentClientGroups[key] = [];
      }
      treatmentClientGroups[key]!.add(treatment);
    }

    final groupedList = treatmentClientGroups.entries.toList();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: groupedList.isEmpty
          ? const EmptyStateWidget(
              title: 'Aucun traitement',
              message: 'Aucun traitement dans cette section',
              icon: Icons.event_busy,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: groupedList.length,
              itemBuilder: (context, index) {
                final entry = groupedList[index];
                final parts = entry.key.split('|');
                final traitementName = parts[0];
                final clientName = parts[1];
                final allPlannings = entry.value;

                return _TreatmentClientCard(
                  traitement: traitementName,
                  client: clientName,
                  planningCount: allPlannings.length,
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            _PlanningListScreen(
                              title: '$traitementName - $clientName',
                              plannings: allPlannings,
                            ),
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

  String _convertToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    if (value is bool) return value.toString();
    if (value is DateTime) return value.toString();
    if (value is List<int>) {
      try {
        return String.fromCharCodes(value);
      } catch (e) {
        return '';
      }
    }
    return value?.toString() ?? '';
  }
}

/// Card pour afficher une combinaison Traitement × Client
class _TreatmentClientCard extends StatelessWidget {
  final String traitement;
  final String client;
  final int planningCount;
  final VoidCallback onTap;

  const _TreatmentClientCard({
    required this.traitement,
    required this.client,
    required this.planningCount,
    required this.onTap,
  });

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
                      traitement,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      client,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                        '$planningCount passage(s)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

/// Écran pour afficher la liste des plannings d'une combinaison Traitement × Client
class _PlanningListScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> plannings;

  const _PlanningListScreen({required this.title, required this.plannings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: plannings.isEmpty
          ? const EmptyStateWidget(
              title: 'Aucun planning',
              message: 'Aucun planning pour cette combinaison',
              icon: Icons.event_busy,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: plannings.length,
              itemBuilder: (context, index) {
                final planning = plannings[index];
                return _PlanningCard(
                  planning: planning,
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            _TreatmentDetailScreen(treatment: planning),
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

/// Card pour afficher un planning avec date et état
class _PlanningCard extends StatelessWidget {
  final Map<String, dynamic> planning;
  final VoidCallback onTap;

  const _PlanningCard({required this.planning, required this.onTap});

  String _convertToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    if (value is bool) return value.toString();
    if (value is DateTime) return value.toString();
    if (value is List<int>) {
      try {
        return String.fromCharCodes(value);
      } catch (e) {
        return '';
      }
    }
    return value?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final date = _convertToString(planning['date']);
    final etat = _convertToString(planning['etat']);
    final axe = _convertToString(planning['axe']);

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
                      date,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _DetailRow('État', etat)),
                        const SizedBox(width: 16),
                        Expanded(child: _DetailRow('Axe', axe)),
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

/// Card pour afficher un traitement en détail
class _TreatmentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> treatment;

  const _TreatmentDetailScreen({required this.treatment});

  String _convertToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    if (value is bool) return value.toString();
    if (value is DateTime) return value.toString();
    if (value is List<int>) {
      try {
        return String.fromCharCodes(value);
      } catch (e) {
        return '';
      }
    }
    return value?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final traitement = _convertToString(treatment['traitement']);
    final date = _convertToString(treatment['date']);
    final etat = _convertToString(treatment['etat']);
    final axe = _convertToString(treatment['axe']);

    return Scaffold(
      appBar: AppBar(title: Text(traitement)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé principal
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
                      'Traitement',
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      traitement,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow('Date de planification', date),
                    _DetailRow('État', etat),
                    _DetailRow('Axe', axe),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section: Historique
            Text(
              'Historique',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow('Créé le', date),
                    _DetailRow('Statut', etat),
                    _DetailRow('Dernier statut', etat),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section: Facturation
            Text(
              'Facturation',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Aucune facture actuellement'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Créer une facture'),
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
}

/// Row pour afficher un détail clé-valeur
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher un bouton de catégorie
class _CategoryButton extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onPressed;

  const _CategoryButton({
    required this.label,
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red[400],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count traitement(s)',
                style: TextStyle(color: Colors.black87, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
