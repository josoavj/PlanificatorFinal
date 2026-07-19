import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/index.dart';
import '../../repositories/index.dart';
import '../../widgets/index.dart';
import '../../services/logging_service.dart';
import 'widgets/category_button.dart';
import 'widgets/treatment_client_card.dart';

class HistoriqueScreen extends StatefulWidget {
  final int? clientId; // Si null, affiche tout l'historique
  final String? categorie; // Si spécifiée, filtre par catégorie

  const HistoriqueScreen({super.key, this.clientId, this.categorie});

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
  void initState() {
    super.initState();
    _planningDetailsRepo = context.read<PlanningDetailsRepository>();
    // Charger les données après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await _planningDetailsRepo.loadAllTreatmentsComplete();
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
          final allTreatments = repository.allTreatmentsComplete;

          final Map<String, List<Map<String, dynamic>>> treatmentsByCode = {
            'AT': [],
            'PC': [],
            'NI': [],
            'RO': [],
          };

          for (final treatment in allTreatments) {
            var rawCategorie = _convertToString(treatment['categorieTraitement']);
            var code = _normalizeCategoryCode(rawCategorie);
            if (treatmentsByCode.containsKey(code)) {
              treatmentsByCode[code]!.add(treatment);
            }
          }

          for (final code in treatmentsByCode.keys) {
            treatmentsByCode[code]!.sort((a, b) {
              try {
                final dateKeyA = a.containsKey('date_planification') ? 'date_planification' : a.containsKey('date') ? 'date' : null;
                final dateKeyB = b.containsKey('date_planification') ? 'date_planification' : b.containsKey('date') ? 'date' : null;

                if (dateKeyA == null || dateKeyB == null) return 0;

                DateTime? dateA;
                DateTime? dateB;

                try {
                  final dateValueA = a[dateKeyA];
                  dateA = dateValueA is DateTime ? dateValueA : DateTime.tryParse(dateValueA.toString());
                } catch (e) { dateA = null; }

                try {
                  final dateValueB = b[dateKeyB];
                  dateB = dateValueB is DateTime ? dateValueB : DateTime.tryParse(dateValueB.toString());
                } catch (e) { dateB = null; }

                if (dateA == null || dateB == null) return 0;
                return dateB.compareTo(dateA);
              } catch (e) { return 0; }
            });
          }

          if (allTreatments.isNotEmpty) {
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
                    final code = section['code'] as String;
                    final treatments = treatmentsByCode[code] ?? [];

                    return CategoryButton(
                      label: code,
                      count: treatments.length,
                      color: section['color'] as Color?,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _TreatmentListScreen(
                              title: section['title'] as String,
                              code: code,
                              treatments: treatments,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            );
          }

          if (repository.isLoading) {
            return const LoadingWidget(message: 'Chargement de l\'historique...');
          }

          if (repository.errorMessage != null) {
            return ErrorDisplayWidget(message: repository.errorMessage!, onRetry: _loadData);
          }

          return const EmptyStateWidget(
            title: 'Aucun traitement',
            message: 'Aucun traitement à afficher pour le moment',
            icon: Icons.history,
          );
        },
      ),
    );
  }

  String _convertToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  String _normalizeCategoryCode(String rawCategorie) {
    if (rawCategorie.isEmpty) return 'PC';
    final upper = rawCategorie.toUpperCase().trim();
    if (upper.startsWith('AT') || upper.contains('ANTI TERMITES')) return 'AT';
    if (upper.startsWith('NI') || upper.contains('NETTOYAGE')) return 'NI';
    if (upper.startsWith('RO') || upper.contains('RAMASSAGE')) return 'RO';
    return 'PC';
  }
}

class _TreatmentListScreen extends StatelessWidget {
  final String title;
  final String code;
  final List<Map<String, dynamic>> treatments;

  const _TreatmentListScreen({
    required this.title,
    required this.code,
    required this.treatments,
  });

  DateTime? _extractDate(Map<String, dynamic> item) {
    try {
      final dateKey = item.containsKey('date_planification') ? 'date_planification' : item.containsKey('date') ? 'date' : null;
      if (dateKey == null) return null;
      final dateValue = item[dateKey];
      if (dateValue is DateTime) return dateValue;
      if (dateValue is String) return DateTime.tryParse(dateValue);
      return null;
    } catch (e) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String, dynamic>>> treatmentClientGroups = {};

    for (final treatment in treatments) {
      final traitementName = treatment['traitement']?.toString() ?? '';
      final clientName = treatment['client']?.toString() ?? '';
      final key = '$traitementName|$clientName';

      if (!treatmentClientGroups.containsKey(key)) {
        treatmentClientGroups[key] = [];
      }
      treatmentClientGroups[key]!.add(treatment);
    }

    for (final key in treatmentClientGroups.keys) {
      treatmentClientGroups[key]!.sort((a, b) {
        final dateA = _extractDate(a);
        final dateB = _extractDate(b);
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });
    }

    final groupedList = treatmentClientGroups.entries.toList();
    groupedList.sort((entryA, entryB) {
      final listA = entryA.value;
      final listB = entryB.value;
      final dateA = listA.isNotEmpty ? _extractDate(listA.first) : null;
      final dateB = listB.isNotEmpty ? _extractDate(listB.first) : null;
      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA);
    });

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: groupedList.isEmpty
          ? const EmptyStateWidget(title: 'Aucun traitement', message: 'Aucun traitement dans cette section', icon: Icons.event_busy)
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: groupedList.length,
              itemBuilder: (context, index) {
                final entry = groupedList[index];
                final parts = entry.key.split('|');
                final traitementName = parts[0];
                final clientName = parts[1];
                final allPlannings = entry.value;

                return TreatmentClientCard(
                  traitement: traitementName,
                  client: clientName,
                  planningCount: allPlannings.length,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _PlanningListScreen(
                          title: clientName.trim().isNotEmpty ? '$traitementName - ${clientName.trim()}' : traitementName,
                          plannings: allPlannings,
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

class _PlanningListScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> plannings;

  const _PlanningListScreen({required this.title, required this.plannings});

  @override
  Widget build(BuildContext context) {
    final sortedPlannings = List<Map<String, dynamic>>.from(plannings);
    try {
      sortedPlannings.sort((a, b) {
        final dateKeyA = a.containsKey('date_planification') ? 'date_planification' : a.containsKey('date') ? 'date' : null;
        final dateKeyB = b.containsKey('date_planification') ? 'date_planification' : b.containsKey('date') ? 'date' : null;
        if (dateKeyA == null || dateKeyB == null) return 0;
        DateTime? dateTimeA = a[dateKeyA] is DateTime ? a[dateKeyA] : DateTime.tryParse(a[dateKeyA].toString());
        DateTime? dateTimeB = b[dateKeyB] is DateTime ? b[dateKeyB] : DateTime.tryParse(b[dateKeyB].toString());
        if (dateTimeA == null || dateTimeB == null) return 0;
        return dateTimeB.compareTo(dateTimeA);
      });
    } catch (e) {
      // Ignorer l'erreur de tri
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: sortedPlannings.isEmpty
          ? const EmptyStateWidget(title: 'Aucun planning', message: 'Aucun planning pour cette combinaison', icon: Icons.event_busy)
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sortedPlannings.length,
              itemBuilder: (context, index) {
                final planning = sortedPlannings[index];
                return _PlanningCard(
                  planning: planning,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => _TreatmentDetailScreen(treatment: planning)),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _PlanningCard extends StatelessWidget {
  final Map<String, dynamic> planning;
  final VoidCallback onTap;

  const _PlanningCard({required this.planning, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateValue = planning['date'] is String ? DateTime.parse(planning['date'] as String) : planning['date'] as DateTime?;
    final date = dateValue != null ? DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(dateValue) : 'Date inconnue';
    final etat = planning['etat']?.toString() ?? '';
    final axe = planning['axe']?.toString() ?? '';

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
                    Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(child: _DetailRow(label: 'État', value: etat)),
                        const SizedBox(width: 8),
                        Expanded(child: _DetailRow(label: 'Axe', value: axe)),
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

class _TreatmentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> treatment;
  const _TreatmentDetailScreen({required this.treatment});
  @override
  State<_TreatmentDetailScreen> createState() => _TreatmentDetailScreenState();
}

class _TreatmentDetailScreenState extends State<_TreatmentDetailScreen> {
  late Future<Map<String, dynamic>> _detailsFuture;
  final _logger = createLoggerWithFileOutput(name: 'traitement_detail_dialog');

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadDetails();
  }

  Future<Map<String, dynamic>> _loadDetails() async {
    try {
      final planningDetailId = widget.treatment['planning_detail_id'] as int?;
      if (planningDetailId == null) return {'remarques': [], 'signalements': [], 'factures': [], 'priceHistories': {}};
      final remarqueRepo = context.read<RemarqueRepository>();
      final signalementRepo = context.read<SignalementRepository>();
      final factureRepo = context.read<FactureRepository>();
      final remarques = await remarqueRepo.getRemarques(planningDetailId);
      final signalements = await signalementRepo.getSignalements(planningDetailId);
      final factures = await factureRepo.getFacturesByPlanningDetail(planningDetailId);
      final Map<int, List<Map<String, dynamic>>> priceHistories = {};
      for (final facture in factures) {
        final history = await factureRepo.getPriceHistory(facture.factureId);
        if (history.isNotEmpty) priceHistories[facture.factureId] = history;
      }
      return {'remarques': remarques, 'signalements': signalements, 'factures': factures, 'priceHistories': priceHistories};
    } catch (e) {
      _logger.e('Erreur chargement détails: $e');
      return {'remarques': [], 'signalements': [], 'factures': [], 'priceHistories': {}};
    }
  }

  @override
  Widget build(BuildContext context) {
    final traitement = widget.treatment['traitement']?.toString() ?? '';
    final dateValue = widget.treatment['date_planification'] ?? widget.treatment['date'];
    final dateStr = dateValue is DateTime ? DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(dateValue) : dateValue.toString();
    final etat = widget.treatment['etat']?.toString() ?? '';
    final axe = widget.treatment['axe']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(traitement)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));

          final remarques = (snapshot.data?['remarques'] ?? []) as List<Remarque>;
          final signalements = (snapshot.data?['signalements'] ?? []) as List<Signalement>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Traitement', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text(traitement, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _DetailRow(label: 'Date', value: dateStr),
                        _DetailRow(label: 'État', value: etat),
                        _DetailRow(label: 'Axe', value: axe),
                      ],
                    ),
                  ),
                ),
                if (remarques.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Remarques', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ...remarques.map((r) => Card(
                    margin: const EdgeInsets.only(top: 12),
                    child: ListTile(title: Text(r.contenu ?? ''), subtitle: Text(r.probleme ?? '')),
                  )),
                ],
                if (signalements.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Signalements', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ...signalements.map((s) => Card(
                    margin: const EdgeInsets.only(top: 12),
                    child: ListTile(title: Text(s.type.toUpperCase()), subtitle: Text(s.motif)),
                  )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
