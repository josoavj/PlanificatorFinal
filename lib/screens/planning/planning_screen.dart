import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../../repositories/index.dart';
import '../../core/theme.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({Key? key}) : super(key: key);

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
    // Charger les traitements planifiés depuis la base de données
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<PlanningDetailsRepository>()
          .loadUpcomingTreatmentsComplete();
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
        final dateValue = treatment['date'];
        final dateStr = _convertToString(dateValue);
        if (dateStr.isEmpty) return false;

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
      body: Consumer<PlanningDetailsRepository>(
        builder: (context, detailsRepository, _) {
          final treatmentsForSelected = _getTreatmentsForDay(
            _selectedDay,
            detailsRepository.upcomingTreatmentsComplete,
          );

          return SingleChildScrollView(
            child: Column(
              children: [
                // Calendrier
                Container(
                  padding: const EdgeInsets.all(8),
                  child: _buildCalendar(
                    detailsRepository.upcomingTreatmentsComplete,
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
                        DateFormat(
                          'EEEE dd MMMM yyyy',
                          'fr_FR',
                        ).format(_selectedDay),
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
          lastDay: DateTime(2026, 12, 31),
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

  @override
  Widget build(BuildContext context) {
    final traitement = _convertToString(treatment['traitement']);
    final axe = _convertToString(treatment['axe']);
    final etat = _convertToString(treatment['etat']);

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
                      traitement,
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
  late RemarqueRepository _remarqueRepository;
  final TextEditingController _remarqueController = TextEditingController();
  final TextEditingController _problemeController = TextEditingController();
  String _selectedModePaiement = 'Chèque';

  final List<String> _modePaiements = [
    'Chèque',
    'Espèce',
    'Virement',
    'Mobile Money',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _remarqueRepository = context.read<RemarqueRepository>();
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
    final remarqueCtrl = TextEditingController();
    String selectedMode = _selectedModePaiement;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter une Remarque'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: remarqueCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Entrez votre remarque...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mode de Paiement',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedMode,
                items: _modePaiements
                    .map(
                      (mode) =>
                          DropdownMenuItem(value: mode, child: Text(mode)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedMode = value;
                  }
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (remarqueCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer une remarque')),
                );
                return;
              }

              await _remarqueRepository.createRemarque(
                planningDetailsId: widget.planningDetailId,
                factureId: 0,
                contenu: remarqueCtrl.text,
                probleme: '',
                modePaiement: selectedMode,
              );

              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Remarque ajoutée avec succès'),
                  backgroundColor: Colors.green,
                ),
              );

              await Future.delayed(const Duration(milliseconds: 500));
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showSignalementDialog() {
    final motifCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
      text: widget.treatment['date'] ?? '',
    );
    String typeSignalement = 'décalage'; // 'avancement' ou 'décalage'
    bool changerRedondance = false;
    final logger = Logger();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Signaler un Problème'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type de signalement
              const Text(
                'Type de Signalement',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: typeSignalement,
                items: ['avancement', 'décalage']
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    typeSignalement = value;
                  }
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),

              // Motif
              const Text(
                'Motif',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: motifCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Décrivez le motif...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),

              // Date
              const Text(
                'Nouvelle Date',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dateCtrl,
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Sélectionnez une date',
                  suffixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),

              // Option: Changer redondance
              StatefulBuilder(
                builder: (ctx, setState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Appliquer à',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: const Text('Uniquement cette date'),
                              leading: Radio<bool>(
                                value: false,
                                groupValue: changerRedondance,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      changerRedondance = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: const Text('Tous les futurs'),
                              leading: Radio<bool>(
                                value: true,
                                groupValue: changerRedondance,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      changerRedondance = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (motifCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer un motif')),
                );
                return;
              }

              try {
                final signalementRepo = context.read<SignalementRepository>();

                // Parse la nouvelle date
                DateTime newDate = DateTime.now();
                try {
                  newDate = DateFormat('yyyy-MM-dd').parse(dateCtrl.text);
                } catch (e) {
                  newDate = DateTime.now();
                }

                if (changerRedondance) {
                  // Mode CHANGER: modifier tous les futurs
                  logger.i(
                    'Signalement CHANGER - motif: ${motifCtrl.text}, date: ${dateCtrl.text}',
                  );
                  await signalementRepo.modifierRedondance(
                    planningId: 1, // À obtenir du widget.treatment
                    planningDetailsId: widget.planningDetailId,
                    newRedondance: 1,
                  );
                } else {
                  // Mode GARDER: modifier uniquement cette date
                  logger.i(
                    'Signalement GARDER - motif: ${motifCtrl.text}, date: ${dateCtrl.text}',
                  );
                  await signalementRepo.modifierDatePlanning(
                    planningDetailsId: widget.planningDetailId,
                    newDate: newDate,
                  );
                }

                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Signalement enregistré avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );

                await Future.delayed(const Duration(milliseconds: 500));
                if (mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                logger.e('Erreur signalement: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _remarqueController.dispose();
    _problemeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final traitement = _convertToString(widget.treatment['traitement']);
    final axe = _convertToString(widget.treatment['axe']);
    final etat = _convertToString(widget.treatment['etat']);
    final date = _convertToString(widget.treatment['date']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du Planning'),
        elevation: 1,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section infos planning
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations du Planning',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow('Traitement', traitement),
                    _DetailRow('Date', date),
                    _DetailRow('Axe', axe),
                    _DetailRow('État', etat),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Section Actions principales
            const Text(
              'Actions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Bouton 1: Ajouter une Remarque
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showRemarqueDialog,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  'Ajouter une Remarque',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bouton 2: Signaler un Problème
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showSignalementDialog,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.orange,
                ),
                child: const Text(
                  'Signaler un Problème',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
