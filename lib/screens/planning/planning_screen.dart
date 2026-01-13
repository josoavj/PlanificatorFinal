import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planificator/models/planning_details.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../core/theme.dart';
import '../../services/logging_service.dart';
import 'signalement_dialog.dart';
import 'remark_dialog.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  /// Convertir une valeur dynamique en String
  String _convertToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int || value is double) return value.toString();
    if (value is DateTime) return value.toIso8601String();

    // Gérer les Blob (MySql driver)
    if (value.runtimeType.toString() == 'Blob') {
      try {
        if (value is List<int>) {
          return String.fromCharCodes(value);
        }
        return value.toString();
      } catch (e) {
        return '';
      }
    }

    return value.toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Charger TOUS les traitements (passés, présents, futurs) pour le calendrier
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context
          .read<PlanningDetailsRepository>()
          .loadAllTreatmentsComplete();
    });
  }

  List<String> _getEventsMarkers(
    DateTime day,
    List<Map<String, dynamic>> treatments,
  ) {
    final treatmentsForDay = _getTreatmentsForDay(day, treatments);
    // Retourner une liste de marqueurs (un par traitement)
    return List.generate(treatmentsForDay.length, (index) => 'event_$index');
  }

  List<Map<String, dynamic>> _getTreatmentsForDay(
    DateTime day,
    List<Map<String, dynamic>> treatments,
  ) {
    return treatments.where((treatment) {
      try {
        // ✅ CORRECTION: Utiliser 'date' (la colonne formatée par SQL) pour le filtrage
        final dateValue = treatment['date'];
        if (dateValue == null) return false;

        final dateStr = _convertToString(dateValue);
        if (dateStr.isEmpty) return false;

        // dateStr est au format YYYY-MM-DD (DATE_FORMAT depuis SQL)
        final parts = dateStr.split('-');
        if (parts.length != 3) return false;

        final treatmentDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );

        final normalizedDay = DateTime(day.year, day.month, day.day);
        return isSameDay(treatmentDate, normalizedDay);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'planning_refresh',
        onPressed: () async {
          await context
              .read<PlanningDetailsRepository>()
              .loadAllTreatmentsComplete();
        },
        tooltip: 'Actualiser',
        child: const Icon(Icons.refresh),
      ),
      body: Consumer<PlanningDetailsRepository>(
        builder: (context, detailsRepository, _) {
          final treatmentsForSelected = _getTreatmentsForDay(
            _selectedDay,
            detailsRepository.allTreatmentsComplete,
          );

          return SingleChildScrollView(
            child: Column(
              children: [
                // Calendrier
                Container(
                  padding: const EdgeInsets.all(8),
                  child: _buildCalendar(
                    detailsRepository.allTreatmentsComplete,
                  ),
                ),

                // Événements du jour
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        () {
                          final dateStr = DateFormat(
                            'EEEE dd MMMM yyyy',
                            'fr_FR',
                          ).format(_selectedDay);
                          // Mettre en majuscule le premier caractère du jour et du mois
                          final parts = dateStr.split(' ');
                          if (parts.isNotEmpty) {
                            // Majuscule du jour
                            parts[0] =
                                parts[0][0].toUpperCase() +
                                parts[0].substring(1);
                            // Majuscule du mois (généralement à l'index 2)
                            if (parts.length > 2) {
                              parts[2] =
                                  parts[2][0].toUpperCase() +
                                  parts[2].substring(1);
                            }
                          }
                          return parts.join(' ');
                        }(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (detailsRepository.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (detailsRepository.errorMessage != null)
                        Center(
                          child: Text(
                            'Erreur: ${detailsRepository.errorMessage}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      else if (treatmentsForSelected.isEmpty)
                        const Center(child: Text('Aucun traitement ce jour'))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: treatmentsForSelected.length,
                          itemBuilder: (context, index) {
                            final treatment = treatmentsForSelected[index];
                            return _PlanningCard(
                              treatment: treatment,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => _PlanningDetailScreen(
                                      treatment: treatment,
                                      planningDetailId:
                                          treatment['planning_detail_id'] ?? 0,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendar(List<Map<String, dynamic>> treatments) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TableCalendar(
          firstDay: DateTime(2024, 1, 1),
          lastDay: DateTime(
            2079,
            12,
            31,
          ), // A mettre à jour, si besoin, dans le futur.
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: (day) => _getEventsMarkers(day, treatments),
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: AppTheme.accentBlue,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: Theme.of(context).textTheme.titleLarge!,
          ),
        ),
      ),
    );
  }
}

/// Card cliquable pour afficher un planning
class _PlanningCard extends StatelessWidget {
  final Map<String, dynamic> treatment;
  final VoidCallback onTap;

  const _PlanningCard({required this.treatment, required this.onTap});

  String _convertToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int || value is double) return value.toString();
    if (value is DateTime) return value.toIso8601String();
    if (value is List<int>) {
      try {
        return String.fromCharCodes(value);
      } catch (e) {
        return '';
      }
    }
    return value.toString();
  }

  /// Formate le traitement en supprimant le prénom si c'est une Société/Organisation
  String _formatTraitement(String traitement, String? categorie) {
    if (categorie == 'Société' || categorie == 'Organisation') {
      final parts = traitement.split(' pour ');
      if (parts.length == 2) {
        final typeTraitement = parts[0].trim();
        final names = parts[1].trim().split(' ');
        String nomSociete;
        if (names.length > 2) {
          nomSociete = names.sublist(2).join(' ');
        } else if (names.length > 1) {
          nomSociete = names.last;
        } else {
          return traitement;
        }
        return '$typeTraitement pour $nomSociete';
      }
    }
    return traitement;
  }

  @override
  Widget build(BuildContext context) {
    final traitement = _convertToString(treatment['traitement']);
    final axe = _convertToString(treatment['axe']);
    final etat = _convertToString(treatment['etat']);
    final categorie = _convertToString(treatment['categorie']);

    // Formater le traitement selon la catégorie
    final traitementFormate = _formatTraitement(traitement, categorie);

    final isEffectue = etat.toLowerCase().contains('effectué');
    final bgColor = isEffectue ? Colors.green[50] : Colors.orange[50];
    final textColor = isEffectue ? Colors.green[900] : Colors.orange[900];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icône d'état
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEffectue ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEffectue ? Icons.check_circle : Icons.schedule,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Détails
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      traitementFormate,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Axe: $axe',
                          style: TextStyle(color: textColor, fontSize: 11),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isEffectue
                                ? Colors.green.shade200
                                : Colors.orange.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            etat,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Flèche
              Icon(Icons.arrow_forward_ios, size: 16, color: textColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// Écran détail d'un planning avec possibilité d'ajouter une remarque
class _PlanningDetailScreen extends StatefulWidget {
  final Map<String, dynamic> treatment;
  final int planningDetailId;

  const _PlanningDetailScreen({
    required this.treatment,
    required this.planningDetailId,
  });

  @override
  State<_PlanningDetailScreen> createState() => _PlanningDetailScreenState();
}

class _PlanningDetailScreenState extends State<_PlanningDetailScreen> {
  final TextEditingController _remarqueController = TextEditingController();
  final TextEditingController _problemeController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  String _convertToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int || value is double) return value.toString();
    if (value is DateTime) return value.toIso8601String();
    if (value is List<int>) {
      try {
        return String.fromCharCodes(value);
      } catch (e) {
        return '';
      }
    }
    return value.toString();
  }

  void _showRemarqueDialog() {
    final logger = createLoggerWithFileOutput(name: 'planning_screen');

    try {
      // Créer le PlanningDetails à partir du treatment map
      final planningDetail = PlanningDetails.fromJson(widget.treatment);

      logger.i('✅ PlanningDetails créé: ${planningDetail.planningDetailId}');

      // Création d'une facture valide
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Créer Facture'),
          content: const Text(
            'Une facture sera créée automatiquement pour cette date',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Créer la facture
                  final factureId = await context
                      .read<FactureRepository>()
                      .createFactureComplete(
                        planningDetailId: planningDetail.planningDetailId,
                        referenceFacture:
                            'FAC-${DateTime.now().millisecondsSinceEpoch}',
                        montant: 0,
                        mode: null,
                        etat: 'À venir',
                        axe: widget.treatment['axe'] ?? '',
                        dateTraitement: planningDetail.datePlanification,
                      );

                  if (factureId != -1) {
                    logger.i('✅ Facture créée: $factureId');

                    // Récupérer la vraie facture depuis la BD
                    final factureRepo = context.read<FactureRepository>();
                    final factures = await factureRepo
                        .getFacturesByPlanningDetail(
                          planningDetail.planningDetailId,
                        );

                    if (factures.isNotEmpty) {
                      final facture = factures.first;

                      Navigator.pop(ctx);

                      // Afficher le RemarqueDialog avec la vraie facture
                      showDialog(
                        context: context,
                        builder: (ctx2) => RemarqueDialog(
                          planningDetail: planningDetail,
                          facture: facture,
                          onSaved: () async {
                            logger.i('✅ Remarque enregistrée');

                            if (mounted) {
                              await context
                                  .read<PlanningDetailsRepository>()
                                  .loadAllTreatmentsComplete();
                              // Recharger aussi les factures pour les voir dans Factures
                              await context
                                  .read<FactureRepository>()
                                  .loadAllFactures();
                            }

                            if (mounted) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Remarque & Facture ajoutées avec succès',
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }

                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      );
                    } else {
                      throw Exception('Erreur création facture');
                    }
                  } else {
                    throw Exception('Erreur création facture');
                  }
                } catch (err) {
                  logger.e('❌ Erreur: $err');
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('❌ Erreur: $err')));
                }
              },
              child: const Text('Créer Facture'),
            ),
          ],
        ),
      );
    } catch (e) {
      logger.e('❌ Erreur ouverture dialog: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showSignalementDialog() {
    final logger = createLoggerWithFileOutput(name: 'planning_screen');

    try {
      // Créer le PlanningDetails à partir du treatment map
      final planningDetail = PlanningDetails.fromJson(widget.treatment);

      logger.i('✅ PlanningDetails créé: ${planningDetail.planningDetailId}');

      // Afficher le nouveau SignalementDialog moderne
      showDialog(
        context: context,
        builder: (ctx) => SignalementDialog(
          planningDetail: planningDetail,
          onSaved: () async {
            logger.i('✅ Signalement enregistré');

            if (mounted) {
              await context
                  .read<PlanningDetailsRepository>()
                  .loadAllTreatmentsComplete();
              // ✅ Recharger aussi les factures
              await context.read<FactureRepository>().loadAllFactures();
            }

            // Afficher le succès
            if (mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signalement enregistré avec succès'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }

            // Fermer l'écran de détail APRÈS le rechargement confirmé
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      );
    } catch (e) {
      logger.e('❌ Erreur ouverture dialog: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _remarqueController.dispose();
    _problemeController.dispose();
    super.dispose();
  }

  /// Formate le traitement en supprimant le titre et prénom si c'est une Société/Organisation
  String _formatTraitement(String traitement, String? categorie) {
    if (categorie == 'Société' || categorie == 'Organisation') {
      final parts = traitement.split(' pour ');
      if (parts.length == 2) {
        final typeTraitement = parts[0].trim();
        final names = parts[1].trim().split(' ');
        String nomSociete;
        if (names.length > 2) {
          nomSociete = names.sublist(2).join(' ');
        } else if (names.length > 1) {
          nomSociete = names.last;
        } else {
          return traitement;
        }
        return '$typeTraitement pour $nomSociete';
      }
    }
    return traitement;
  }

  @override
  Widget build(BuildContext context) {
    final traitement = _convertToString(widget.treatment['traitement']);
    final axe = _convertToString(widget.treatment['axe']);
    final etat = _convertToString(widget.treatment['etat']);
    final dateStr = _convertToString(widget.treatment['date']);
    final categorie = _convertToString(widget.treatment['categorie']);

    // Formater la date en "Lundi 07 Janvier 2026"
    String dateFormatee = dateStr;
    if (dateStr.isNotEmpty) {
      try {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final dateObj = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          final formatted = DateFormat(
            'EEEE dd MMMM yyyy',
            'fr_FR',
          ).format(dateObj);
          dateFormatee = formatted.isEmpty
              ? dateStr
              : formatted[0].toUpperCase() + formatted.substring(1);
        }
      } catch (e) {
        dateFormatee = dateStr;
      }
    }

    // Formater le traitement selon la catégorie
    final traitementFormate = _formatTraitement(traitement, categorie);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du Planning'),
        elevation: 1,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section infos planning
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: const Text(
                            'Informations du Planning',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _DetailRow('Traitement', traitementFormate),
                        _DetailRow('Date', dateFormatee),
                        _DetailRow('Axe', axe),
                        _DetailRow('État', etat),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Boutons centré et petit
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Bouton 1: Ajouter une Remarque
                  SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      onPressed: _showRemarqueDialog,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text(
                        'Ajouter une remarque',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Bouton 2: Signaler un Problème
                  SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      onPressed: _showSignalementDialog,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: Colors.redAccent,
                      ),
                      child: const Text(
                        'Signaler un problème',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
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

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 16),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
