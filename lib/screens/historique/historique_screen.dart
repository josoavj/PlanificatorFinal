import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/index.dart';
import '../../repositories/index.dart';
import '../../widgets/index.dart';
import '../../services/logging_service.dart';

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
    // CORRECTION: Charger TOUS les traitements (passés + futurs) pas juste les à venir
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
          // CORRECTION: Utiliser allTreatmentsComplete pour afficher TOUS les traitements
          final allTreatments = repository.allTreatmentsComplete;

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

          // Trier chaque catégorie par date (les données du repository sont déjà triées, mais re-trier pour sûr)
          for (final code in treatmentsByCode.keys) {
            treatmentsByCode[code]!.sort((a, b) {
              try {
                // Préférer date_planification (timestamp) plutôt que date (string formatée)
                final dateKeyA = a.containsKey('date_planification')
                    ? 'date_planification'
                    : a.containsKey('date')
                    ? 'date'
                    : null;
                final dateKeyB = b.containsKey('date_planification')
                    ? 'date_planification'
                    : b.containsKey('date')
                    ? 'date'
                    : null;

                if (dateKeyA == null || dateKeyB == null) return 0;

                DateTime? dateA;
                DateTime? dateB;

                try {
                  final dateValueA = a[dateKeyA];
                  dateA = dateValueA is DateTime
                      ? dateValueA
                      : DateTime.tryParse(dateValueA.toString());
                } catch (e) {
                  dateA = null;
                }

                try {
                  final dateValueB = b[dateKeyB];
                  dateB = dateValueB is DateTime
                      ? dateValueB
                      : DateTime.tryParse(dateValueB.toString());
                } catch (e) {
                  dateB = null;
                }

                if (dateA == null || dateB == null) return 0;
                return dateB.compareTo(dateA); // Décroissant
              } catch (e) {
                return 0;
              }
            });
          }

          // ✅ Afficher les données en priorité si présentes
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
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                ) => _TreatmentListScreen(
                                  title: (section['title'] as String?) ?? 'N/A',
                                  code: code,
                                  treatments: treatments,
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
                  }).toList(),
                ),
              ),
            );
          }

          // Afficher le spinner si chargement en cours
          if (repository.isLoading) {
            return const LoadingWidget(
              message: 'Chargement de l\'historique...',
            );
          }

          // Afficher l'erreur si présente
          if (repository.errorMessage != null) {
            return ErrorDisplayWidget(
              message: repository.errorMessage!,
              onRetry: _loadData,
            );
          }

          // Aucun traitement
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

  DateTime? _extractDate(Map<String, dynamic> item) {
    try {
      // Préférer date_planification (timestamp) plutôt que date (string formatée)
      final dateKey = item.containsKey('date_planification')
          ? 'date_planification'
          : item.containsKey('date')
          ? 'date'
          : null;
      if (dateKey == null) return null;

      final dateValue = item[dateKey];
      if (dateValue is DateTime) return dateValue;
      if (dateValue is String) return DateTime.tryParse(dateValue);
      return null;
    } catch (e) {
      return null;
    }
  }

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

    // Trier chaque groupe par date décroissante (plus récent en premier)
    for (final key in treatmentClientGroups.keys) {
      treatmentClientGroups[key]!.sort((a, b) {
        final dateA = _extractDate(a);
        final dateB = _extractDate(b);
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA); // Décroissant
      });
    }

    // Trier les groupes eux-mêmes par date la plus récente du groupe
    final groupedList = treatmentClientGroups.entries.toList();
    groupedList.sort((entryA, entryB) {
      final listA = entryA.value;
      final listB = entryB.value;

      final dateA = listA.isNotEmpty ? _extractDate(listA.first) : null;
      final dateB = listB.isNotEmpty ? _extractDate(listB.first) : null;

      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA); // Décroissant
    });

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
                              title: clientName.trim().isNotEmpty
                                  ? '$traitementName - ${clientName.trim()}'
                                  : traitementName,
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
    // Trier les plannings par date décroissante (plus récents en haut)
    final sortedPlannings = List<Map<String, dynamic>>.from(plannings);
    try {
      sortedPlannings.sort((a, b) {
        // Préférer date_planification (timestamp) plutôt que date (string formatée)
        final dateKeyA = a.containsKey('date_planification')
            ? 'date_planification'
            : a.containsKey('date')
            ? 'date'
            : null;
        final dateKeyB = b.containsKey('date_planification')
            ? 'date_planification'
            : b.containsKey('date')
            ? 'date'
            : null;

        if (dateKeyA == null || dateKeyB == null) {
          return 0;
        }

        // Convertir en DateTime pour un tri correct
        DateTime? dateTimeA;
        DateTime? dateTimeB;

        try {
          final dateValueA = a[dateKeyA];
          dateTimeA = dateValueA is DateTime
              ? dateValueA
              : DateTime.tryParse(dateValueA.toString());
        } catch (e) {
          dateTimeA = null;
        }

        try {
          final dateValueB = b[dateKeyB];
          dateTimeB = dateValueB is DateTime
              ? dateValueB
              : DateTime.tryParse(dateValueB.toString());
        } catch (e) {
          dateTimeB = null;
        }

        if (dateTimeA == null || dateTimeB == null) {
          return 0;
        }

        return dateTimeA.compareTo(
          dateTimeB,
        ); // Croissant: plus ancien en premier
      });
    } catch (e) {
      // Erreur lors du tri - on continue sans tri
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: sortedPlannings.isEmpty
          ? const EmptyStateWidget(
              title: 'Aucun planning',
              message: 'Aucun planning pour cette combinaison',
              icon: Icons.event_busy,
            )
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
    if (value is DateTime) {
      final dateStr = DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(value);
      // Mettre en majuscule le premier caractère du jour
      return dateStr[0].toUpperCase() + dateStr.substring(1);
    }
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
    final dateValue = planning['date'] is String
        ? DateTime.parse(planning['date'] as String)
        : planning['date'] as DateTime?;
    final date = _convertToString(dateValue);
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
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(child: _DetailRow('État', etat)),
                        const SizedBox(width: 8),
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

  /// Charger les remarques, signalements, factures et historique des prix pour ce traitement
  Future<Map<String, dynamic>> _loadDetails() async {
    try {
      final planningDetailId = widget.treatment['planning_detail_id'] as int?;
      if (planningDetailId == null) {
        return {
          'remarques': [],
          'signalements': [],
          'factures': [],
          'priceHistories': {},
        };
      }

      final remarqueRepo = context.read<RemarqueRepository>();
      final signalementRepo = context.read<SignalementRepository>();
      final factureRepo = context.read<FactureRepository>();

      final remarques = await remarqueRepo.getRemarques(planningDetailId);
      final signalements = await signalementRepo.getSignalements(
        planningDetailId,
      );
      final factures = await factureRepo.getFacturesByPlanningDetail(
        planningDetailId,
      );

      // Charger l'historique des prix pour chaque facture
      final Map<int, List<Map<String, dynamic>>> priceHistories = {};
      for (final facture in factures) {
        final history = await factureRepo.getPriceHistory(facture.factureId);
        if (history.isNotEmpty) {
          priceHistories[facture.factureId] = history;
        }
      }

      return {
        'remarques': remarques,
        'signalements': signalements,
        'factures': factures,
        'priceHistories': priceHistories,
      };
    } catch (e) {
      _logger.e('Erreur chargement détails: $e');
      return {
        'remarques': [],
        'signalements': [],
        'factures': [],
        'priceHistories': {},
      };
    }
  }

  String _convertToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    if (value is bool) return value.toString();
    if (value is DateTime) {
      final dateStr = DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(value);
      // Mettre en majuscule le premier caractère du jour
      return dateStr[0].toUpperCase() + dateStr.substring(1);
    }
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
    final traitement = _convertToString(widget.treatment['traitement']);
    final date = _convertToString(
      widget.treatment['date_planification'] ?? widget.treatment['date'],
    );
    final etat = _convertToString(widget.treatment['etat']);
    final axe = _convertToString(widget.treatment['axe']);

    return Scaffold(
      appBar: AppBar(title: Text(traitement)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          List<Remarque> remarques = [];
          List<Signalement> signalements = [];
          List<Facture> factures = [];
          Map<int, List<Map<String, dynamic>>> priceHistories = {};

          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            remarques = (snapshot.data!['remarques'] ?? []) as List<Remarque>;
            signalements =
                (snapshot.data!['signalements'] ?? []) as List<Signalement>;
            factures = (snapshot.data!['factures'] ?? []) as List<Facture>;
            priceHistories =
                (snapshot.data!['priceHistories'] ?? {})
                    as Map<int, List<Map<String, dynamic>>>;
          }

          return SingleChildScrollView(
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
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: Colors.grey[600]),
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

                // NOUVEAU: Section Remarques
                if (remarques.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remarques (${remarques.length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...remarques.map((remarque) {
                        // Déterminer l'état de paiement: utiliser l'état de la facture si elle existe
                        bool isPaid = false;
                        if (remarque.factureId != null) {
                          // Chercher la facture correspondante
                          final correspondingFacture =
                              factures.firstWhere(
                                    (f) => f.factureId == remarque.factureId,
                                    orElse: () => null as dynamic,
                                  )
                                  as Facture?;
                          if (correspondingFacture != null) {
                            isPaid = correspondingFacture.etat
                                .toLowerCase()
                                .contains('payé');
                          }
                        } else {
                          // Si pas de facture associée, utiliser le statut de la remarque
                          isPaid = remarque.estPayee;
                        }

                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (remarque.contenu?.isNotEmpty ?? false) ...[
                                  Text(
                                    'Contenu',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    remarque.contenu ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (remarque.probleme?.isNotEmpty ?? false) ...[
                                  Text(
                                    'Problème identifié',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    remarque.probleme ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (remarque.action?.isNotEmpty ?? false) ...[
                                  Text(
                                    'Action à prendre',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    remarque.action ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (remarque.modePaiement?.isNotEmpty ??
                                    false) ...[
                                  Text(
                                    'Mode de paiement',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    remarque.modePaiement ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (remarque.nomFacture?.isNotEmpty ??
                                    false) ...[
                                  Text(
                                    'N° Facture',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    remarque.nomFacture ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (remarque.datePayement?.isNotEmpty ??
                                    false) ...[
                                  Text(
                                    'Date de paiement',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    remarque.datePayement ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (remarque.etablissement?.isNotEmpty ??
                                    false) ...[
                                  Text(
                                    'Établissement',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    remarque.etablissement ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (remarque.numeroCheque?.isNotEmpty ??
                                    false) ...[
                                  Text(
                                    'N° Chèque',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    remarque.numeroCheque ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                // État du paiement: afficher l'état de la facture si elle existe
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPaid
                                        ? Colors.green.shade100
                                        : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isPaid ? 'PAYÉE' : 'NON PAYÉE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isPaid
                                          ? Colors.green.shade800
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],
                  ),

                // NOUVEAU: Section Signalements
                if (signalements.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signalements (${signalements.length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...signalements.map((signalement) {
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: signalement.type == 'avancement'
                                        ? Colors.green.shade100
                                        : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    signalement.type.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: signalement.type == 'avancement'
                                          ? Colors.green.shade800
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Motif',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  signalement.motif,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],
                  ),

                // NOUVEAU: Section Factures
                if (factures.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Factures (${factures.length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...factures.map((facture) {
                        final montantStr = facture.montant.toString();
                        final etatFacture = facture.etat;
                        final bgColor =
                            etatFacture.toLowerCase().contains('payée')
                            ? Colors.green.shade50
                            : Colors.orange.shade50;
                        final badgeColor =
                            etatFacture.toLowerCase().contains('payée')
                            ? Colors.green
                            : Colors.orange;

                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          color: bgColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Référence facture
                                if (facture.referenceFacture?.isNotEmpty ??
                                    false) ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Référence',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        facture.referenceFacture ?? '',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                // Montant
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Montant',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      '$montantStr Ar',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'État',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        etatFacture,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: badgeColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (facture.axe.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Axe',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        facture.axe,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                  // Mode de paiement
                                  if (facture.mode?.isNotEmpty ?? false) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Mode de paiement',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          facture.mode ?? '',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ],
                                  // Établissement payeur
                                  if (facture.etablissementPayeur?.isNotEmpty ??
                                      false) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Établissement',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          facture.etablissementPayeur ?? '',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ],
                                  // Date chèque
                                  if (facture.dateCheque != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Date du chèque',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          '${facture.dateCheque?.day}/${facture.dateCheque?.month}/${facture.dateCheque?.year}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ],
                                  // Numéro chèque
                                  if (facture.numeroCheque?.isNotEmpty ??
                                      false) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'N° du chèque',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          facture.numeroCheque ?? '',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                                // NOUVEAU: Historique des prix
                                if (priceHistories.containsKey(
                                      facture.factureId,
                                    ) &&
                                    priceHistories[facture.factureId]!
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Divider(color: Colors.grey[300]),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Changements de montant',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...priceHistories[facture.factureId]!.map((
                                    change,
                                  ) {
                                    final oldAmount = change['old_amount'] ?? 0;
                                    final newAmount = change['new_amount'] ?? 0;
                                    final changeDate = change['change_date'];
                                    final changedBy =
                                        change['changed_by'] ?? 'System';
                                    final dateParsed = changeDate is DateTime
                                        ? changeDate
                                        : DateTime.tryParse(
                                            changeDate.toString(),
                                          );

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '$oldAmount Ar',
                                                style: TextStyle(
                                                  color: Colors.red[700],
                                                  fontWeight: FontWeight.bold,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.arrow_right,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '$newAmount Ar',
                                                style: TextStyle(
                                                  color: Colors.green[700],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            dateParsed != null
                                                ? 'le ${dateParsed.day}/${dateParsed.month}/${dateParsed.year} à ${dateParsed.hour}:${dateParsed.minute.toString().padLeft(2, '0')}'
                                                : 'Date inconnue',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey[600],
                                                ),
                                          ),
                                          if (changedBy != 'System')
                                            Text(
                                              'par $changedBy',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Colors.grey[600],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 12),
                    ],
                  ),

                // Section: Message si rien
                if (remarques.isEmpty &&
                    signalements.isEmpty &&
                    factures.isEmpty)
                  Text(
                    'Aucune remarque, signalement ou facture',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
              ],
            ),
          );
        },
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
