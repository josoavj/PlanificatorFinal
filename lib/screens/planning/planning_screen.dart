import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planificator/models/planning_details.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../core/theme.dart';
import '../../services/logging_service.dart';
import '../../widgets/app_dialogs.dart';
import 'signalement_dialog.dart';
import 'remark_dialog.dart';
import '../../utils/app_snackbars.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  // Cache pour les traitements par jour
  final Map<String, List<Map<String, dynamic>>> _treatmentCache = {};
  String? _cachedTreatmentsKey;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();

    // Charger les données après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // Charger TOUS les traitements (passés, présents, futurs) pour le calendrier
    await context.read<PlanningDetailsRepository>().loadAllTreatmentsComplete();
    // Vider le cache quand les données changent
    _treatmentCache.clear();
    _cachedTreatmentsKey = null;
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

  List<Map<String, dynamic>> _getTreatmentsForDay(
    DateTime day,
    List<Map<String, dynamic>> treatments,
  ) {
    final dayKey = '${day.year}-${day.month}-${day.day}';

    // Vérifier si les données sont en cache
    if (_cachedTreatmentsKey == dayKey && _treatmentCache.containsKey(dayKey)) {
      return _treatmentCache[dayKey]!;
    }

    // Calculer et cacher les traitements pour ce jour
    final result = treatments.where((treatment) {
      try {
        //  CORRECTION: Utiliser 'date' (la colonne formatée par SQL) pour le filtrage
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

    _treatmentCache[dayKey] = result;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'planning_refresh',
        onPressed: () async {
          _treatmentCache.clear();
          _cachedTreatmentsKey = null;
          await context
              .read<PlanningDetailsRepository>()
              .loadAllTreatmentsComplete();
        },
        tooltip: 'Actualiser',
        child: const Icon(Icons.refresh),
      ),
      body: Consumer<PlanningDetailsRepository>(
        builder: (context, detailsRepository, _) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final treatmentsForSelected = _getTreatmentsForDay(
            _selectedDay,
            detailsRepository.allTreatmentsComplete,
          );

          return SingleChildScrollView(
            child: Column(
              children: [
                // Calendrier - extrait dans un widget séparé pour éviter les rebuilds
                _CalendarWidget(
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  treatments: detailsRepository.allTreatmentsComplete,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  getTreatmentsForDay: _getTreatmentsForDay,
                ),

                // Événements du jour
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBg : Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
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
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (treatmentsForSelected.isNotEmpty)
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
                        )
                      else if (detailsRepository.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (detailsRepository.errorMessage != null)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Erreur: ${detailsRepository.errorMessage}',
                              style: const TextStyle(color: AppTheme.errorRed),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_busy_rounded,
                                  size: 48,
                                  color: isDark ? Colors.white24 : Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun traitement prévu pour ce jour',
                                  style: TextStyle(
                                    color: isDark ? Colors.white38 : Colors.grey[400],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
}

/// Widget séparé du calendrier pour éviter les rebuilds inutiles
class _CalendarWidget extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<Map<String, dynamic>> treatments;
  final Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final Function(DateTime focusedDay) onPageChanged;
  final Function(DateTime, List<Map<String, dynamic>>) getTreatmentsForDay;

  const _CalendarWidget({
    required this.focusedDay,
    required this.selectedDay,
    required this.treatments,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.getTreatmentsForDay,
  });

  List<String> _getEventsMarkers(DateTime day) {
    final treatmentsForDay = getTreatmentsForDay(day, treatments);
    return List.generate(treatmentsForDay.length, (index) => 'event_$index');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context, radius: 28),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: TableCalendar(
            firstDay: DateTime(2024),
            lastDay: DateTime(2079, 12, 31),
            focusedDay: focusedDay,
            locale: 'fr_FR',
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            onDaySelected: onDaySelected,
            onPageChanged: onPageChanged,
            eventLoader: _getEventsMarkers,
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              todayDecoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryBlue),
              ),
              todayTextStyle: TextStyle(
                color: isDark ? Colors.white : AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
              markerDecoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              defaultTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black87),
              weekendTextStyle: TextStyle(color: isDark ? AppTheme.accentBlue : Colors.blue.shade700),
              outsideTextStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              leftChevronIcon: Icon(Icons.chevron_left_rounded, color: isDark ? Colors.white : Colors.black87),
              rightChevronIcon: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white : Colors.black87),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12),
              weekendStyle: TextStyle(color: isDark ? AppTheme.accentBlue : Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 12),
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final traitement = _convertToString(treatment['traitement']);
    final axe = _convertToString(treatment['axe']);
    final etat = _convertToString(treatment['etat']);
    final categorie = _convertToString(treatment['categorie']);

    // Formater le traitement selon la catégorie
    final traitementFormate = _formatTraitement(traitement, categorie);

    final isEffectue = etat.toLowerCase().contains('effectué');
    
    final statusColor = isEffectue 
        ? (isDark ? AppTheme.darkSuccess : AppTheme.successGreen)
        : (isDark ? AppTheme.darkWarning : AppTheme.warningOrange);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration(context, radius: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barre de statut latérale
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Contenu
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          traitementFormate,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: isDark ? Colors.white38 : Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Axe: $axe',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.grey[600], 
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Badge d'état
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isEffectue ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                            color: statusColor,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            etat.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
  void dispose() {
    _remarqueController.dispose();
    _problemeController.dispose();
    super.dispose();
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

      logger.i(' PlanningDetails créé: ${planningDetail.planningDetailId}');

      // Création d'une facture valide
      AppDialogs.showBlurDialog(
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
                        etat: 'À venir',
                        axe: widget.treatment['axe'] ?? '',
                        dateTraitement: planningDetail.datePlanification,
                      );

                  if (factureId != -1) {
                    logger.i(' Facture créée: $factureId');

                    // Récupérer la vraie facture depuis la BD
                    final factureRepo = context.read<FactureRepository>();
                    final factures = await factureRepo
                        .getFacturesByPlanningDetail(
                          planningDetail.planningDetailId,
                        );

                    if (factures.isNotEmpty) {
                      final facture = factures.first;

                      if (mounted) Navigator.pop(ctx);

                      // Afficher le RemarqueDialog avec la vraie facture
                      if (mounted) {
                        AppDialogs.showBlurDialog(
                          context: context,
                          builder: (ctx2) => RemarqueDialog(
                            planningDetail: planningDetail,
                            facture: facture,
                            onSaved: () async {
                              logger.i(' Remarque enregistrée');

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
                                AppSnackBars.showSuccess(
                                  context,
                                  'Remarque & Facture ajoutées avec succès',
                                );
                              }

                              if (mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        );
                      }
                    } else {
                      throw Exception('Erreur récupération facture');
                    }
                  } else {
                    throw Exception('Erreur création facture');
                  }
                } catch (err) {
                  logger.e(' Erreur: $err');
                  if (mounted) Navigator.pop(ctx);
                  if (mounted) AppSnackBars.showError(context, ' Erreur: $err');
                }
              },
              child: const Text('Créer Facture'),
            ),
          ],
        ),
      );
    } catch (e) {
      logger.e(' Erreur ouverture dialog: $e');
      AppSnackBars.showError(context, 'Erreur: $e');
    }
  }

  void _showSignalementDialog() {
    final logger = createLoggerWithFileOutput(name: 'planning_screen');

    try {
      // Créer le PlanningDetails à partir du treatment map
      final planningDetail = PlanningDetails.fromJson(widget.treatment);

      logger.i(' PlanningDetails créé: ${planningDetail.planningDetailId}');

      // Afficher le nouveau SignalementDialog moderne
      AppDialogs.showBlurDialog(
        context: context,
        builder: (ctx) => SignalementDialog(
          planningDetail: planningDetail,
          onSaved: () async {
            logger.i(' Signalement enregistré');

            if (mounted) {
              await context
                  .read<PlanningDetailsRepository>()
                  .loadAllTreatmentsComplete();
              //  Recharger aussi les factures
              await context.read<FactureRepository>().loadAllFactures();
            }

            // Afficher le succès
            if (mounted) {
              AppSnackBars.showSuccess(context, 'Signalement enregistré avec succès');
            }

            // Fermer l'écran de détail APRÈS le rechargement confirmé
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      );
    } catch (e) {
      logger.e(' Erreur ouverture dialog: $e');
      AppSnackBars.showError(context, 'Erreur: $e');
    }
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
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

    final traitementFormate = _formatTraitement(traitement, categorie);
    final isEffectue = etat.toLowerCase().contains('effectué');
    final statusColor = isEffectue 
        ? (isDark ? AppTheme.darkSuccess : AppTheme.successGreen)
        : (isDark ? AppTheme.darkWarning : AppTheme.warningOrange);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Immersif (Style Profile/About)
            _buildHeader(context, dateFormatee, statusColor, colorScheme, isDark),
            const SizedBox(height: 70), // Espace pour l'icône qui dépasse
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    // Bloc Informations
                    _buildDetailSection(
                      context,
                      title: 'Détails du Traitement',
                      children: [
                        _buildDetailTile(context, Icons.medical_services_outlined, 'Service', traitementFormate),
                        _buildDetailTile(context, Icons.map_outlined, 'Axe / Secteur', axe),
                        _buildDetailTile(context, Icons.info_outline_rounded, 'État actuel', etat, valueColor: statusColor),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Bloc Actions
                    _buildDetailSection(
                      context,
                      title: 'Actions disponibles',
                      children: [
                        _buildActionTile(
                          context,
                          icon: Icons.edit_note_rounded,
                          title: 'Ajouter une remarque',
                          subtitle: 'Noter des précisions ou créer une facture',
                          color: AppTheme.primaryBlue,
                          onTap: _showRemarqueDialog,
                        ),
                        _buildActionTile(
                          context,
                          icon: Icons.report_problem_outlined,
                          title: 'Signaler un problème',
                          subtitle: 'Enregistrer une anomalie durant le traitement',
                          color: isDark ? AppTheme.darkError : AppTheme.errorRed,
                          onTap: _showSignalementDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String date, Color statusColor, ColorScheme colorScheme, bool isDark) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 230,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainer : AppTheme.primaryBlue,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(48)),
          ),
        ),
        // Bouton Retour en haut à gauche (Simplifié)
        Positioned(
          top: 40,
          left: 8,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
          ),
        ),
        Positioned(
          top: 50,
          child: Column(
            children: [
              const Text(
                'Traitement du',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Text(
                      'TRAITEMENT PLANIFIÉ',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -45,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBg : Colors.white,
              shape: BoxShape.circle,
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.calendar_today_rounded, size: 48, color: AppTheme.primaryBlue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(BuildContext context, {required String title, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue,
            ),
          ),
        ),
        Container(
          decoration: AppTheme.cardDecoration(context, radius: 24),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: List.generate(children.length, (index) {
                return Column(
                  children: [
                    children[index],
                    if (index < children.length - 1)
                      Divider(
                        height: 1,
                        indent: 60,
                        endIndent: 16,
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTile(BuildContext context, IconData icon, String label, String value, {Color? valueColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue, size: 22),
      title: Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600], fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: valueColor)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildActionTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600])),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
