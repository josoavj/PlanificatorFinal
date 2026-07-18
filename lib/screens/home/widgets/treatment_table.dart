import 'package:flutter/material.dart';

class TreatmentTable extends StatelessWidget {
  final String title;
  final bool isLoading;
  final List<Map<String, dynamic>> treatments;
  final String? errorMessage;

  const TreatmentTable({
    super.key,
    required this.title,
    required this.isLoading,
    required this.treatments,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(minHeight: 300, maxHeight: 600),
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (treatments.isNotEmpty) {
      return SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Nom')),
              DataColumn(label: Text('État')),
              DataColumn(label: Text('Axe')),
            ],
            rows: treatments.map((treatment) {
              final etat = treatment['etat'] ?? '';
              final bgColor = etat == 'Effectué'
                  ? Colors.green.shade50
                  : etat == 'À venir'
                  ? Colors.red.shade50
                  : Colors.white;
              final textColor = etat == 'Effectué'
                  ? Colors.green.shade700
                  : etat == 'À venir'
                  ? Colors.red.shade700
                  : Colors.black;

              return DataRow(
                color: WidgetStatePropertyAll(bgColor),
                cells: [
                  DataCell(
                    Text(
                      treatment['date'] ?? '',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      treatment['nom'] ?? '',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                  DataCell(
                    Text(
                      etat,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      treatment['axe'] ?? '',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      );
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Erreur: $errorMessage',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Aucun traitement',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }
}
