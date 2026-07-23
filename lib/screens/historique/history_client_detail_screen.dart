import 'package:flutter/material.dart';
import '../../widgets/index.dart';
import 'widgets/history_intervention_tile.dart';
import 'widgets/history_detail_dialog.dart';

class HistoryClientDetailScreen extends StatelessWidget {
  final String clientName;
  final List<Map<String, dynamic>> interventions;

  const HistoryClientDetailScreen({
    super.key,
    required this.clientName,
    required this.interventions,
  });

  @override
  Widget build(BuildContext context) {
    // Groupement par type de service
    final Map<String, List<Map<String, dynamic>>> services = {};
    for (final i in interventions) {
      String type = i['traitement']?.toString() ?? 'Service';
      if (type.contains(' pour ')) type = type.split(' pour ').first.trim();
      services.putIfAbsent(type, () => []).add(i);
    }

    // TRI INTELLIGENT POUR CHAQUE SERVICE
    for (final key in services.keys) {
      services[key]!.sort((a, b) {
        final dateA = _parseDate(a);
        final dateB = _parseDate(b);
        final statusA = a['etat']?.toString().toLowerCase() ?? '';
        final statusB = b['etat']?.toString().toLowerCase() ?? '';

        final isDoneA = statusA.contains('effectué');
        final isDoneB = statusB.contains('effectué');

        // 1. Priorité aux passages réalisés (en haut)
        if (isDoneA != isDoneB) return isDoneA ? -1 : 1;

        if (dateA == null || dateB == null) return 0;

        // 2. Passé : le plus récent en premier (DESC)
        if (isDoneA) return dateB.compareTo(dateA);

        // 3. Futur : le plus proche en premier (ASC)
        return dateA.compareTo(dateB);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(clientName),
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: services.entries.map((entry) {
            return AppSection(
              title: entry.key,
              margin: const EdgeInsets.only(bottom: 32),
              showDividers: false,
              children: entry.value.map((i) {
                final dateStr = i['date_planification'] ?? i['date'];
                final date = dateStr != null ? DateTime.parse(dateStr.toString()) : DateTime.now();
                final etat = i['etat']?.toString() ?? 'À venir';
                
                return HistoryInterventionTile(
                  date: date,
                  status: etat,
                  onTap: () => _openInterventionDetail(context, i),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  DateTime? _parseDate(Map<String, dynamic> item) {
    try {
      final val = item['date_planification'] ?? item['date'];
      if (val is DateTime) return val;
      if (val != null) return DateTime.parse(val.toString());
    } catch (e) {
      // Ignorer
    }
    return null;
  }

  void _openInterventionDetail(BuildContext context, Map<String, dynamic> data) {
    HistoryDetailDialog.show(context, data);
  }
}
