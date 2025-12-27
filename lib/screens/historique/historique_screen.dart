import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../widgets/index.dart';
import '../../core/theme.dart';
import '../../utils/date_helper.dart';

class HistoriqueScreen extends StatefulWidget {
  final int? clientId; // Si null, affiche tout l'historique
  final String? categorie; // Si spécifiée, filtre par catégorie

  const HistoriqueScreen({Key? key, this.clientId, this.categorie})
    : super(key: key);

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  final Map<String, IconData> _typeIcons = {
    'remarque': Icons.comment,
    'remarque_categorie': Icons.note,
    'facture': Icons.receipt,
    'client': Icons.person,
    'contrat': Icons.description,
    'paiement': Icons.attach_money,
  };

  final Map<String, Color> _typeColors = {
    'remarque': AppTheme.primaryBlue,
    'remarque_categorie': AppTheme.infoBlue,
    'facture': AppTheme.primaryBlue,
    'client': AppTheme.infoBlue,
    'contrat': AppTheme.successGreen,
    'paiement': AppTheme.successGreen,
  };

  @override
  void initState() {
    super.initState();
    // Charger les données au démarrage
    if (widget.categorie != null) {
      Future.microtask(() {
        context.read<HistoriqueRepository>().loadEventsByCategory(
          widget.categorie!,
        );
      });
    } else {
      Future.microtask(() {
        context.read<HistoriqueRepository>().loadAllEvents();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (widget.categorie != null) {
                context.read<HistoriqueRepository>().loadEventsByCategory(
                  widget.categorie!,
                );
              } else {
                context.read<HistoriqueRepository>().loadAllEvents();
              }
            },
          ),
        ],
      ),
      body: Consumer<HistoriqueRepository>(
        builder: (context, repository, _) {
          // État de chargement
          if (repository.isLoading) {
            return const LoadingWidget(
              message: 'Chargement de l\'historique...',
            );
          }

          // État d'erreur
          if (repository.errorMessage != null) {
            return ErrorDisplayWidget(
              message: repository.errorMessage!,
              onRetry: () {
                if (widget.categorie != null) {
                  repository.loadEventsByCategory(widget.categorie!);
                } else {
                  repository.loadAllEvents();
                }
              },
            );
          }

          final events = repository.events;

          // Pas de données
          if (events.isEmpty) {
            return const EmptyStateWidget(
              title: 'Aucun événement',
              message: 'Aucun événement à afficher pour le moment',
              icon: Icons.history,
            );
          }

          // Afficher la liste
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final previousEvent = index > 0 ? events[index - 1] : null;
              final isDayChange =
                  previousEvent == null ||
                  !isSameDay(event.date, previousEvent.date);

              return Column(
                children: [
                  if (isDayChange)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              DateHelper.format(event.date),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                    ),
                  _HistoriqueCard(
                    date: event.date,
                    title: event.type == 'remarque_categorie'
                        ? 'Remarque'
                        : event.type,
                    description: event.description,
                    icon: _typeIcons[event.type] ?? Icons.event,
                    color: _typeColors[event.type] ?? AppTheme.primaryBlue,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Widget pour afficher une card d'événement historique
class _HistoriqueCard extends StatelessWidget {
  final DateTime date;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _HistoriqueCard({
    required this.date,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline point
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Contenu
          Expanded(
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                        ),
                        Text(
                          _formatTime(date),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
}
