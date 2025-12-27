import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/index.dart';
import '../../repositories/index.dart';
import '../../widgets/index.dart';
import '../../core/theme.dart';

class ContratScreen extends StatefulWidget {
  final int? clientId; // Si null, affiche tous les contrats

  const ContratScreen({Key? key, this.clientId}) : super(key: key);

  @override
  State<ContratScreen> createState() => _ContratScreenState();
}

class _ContratScreenState extends State<ContratScreen> {
  // Données fictives pour la démo
  final List<Contrat> _contrats = [
    Contrat(
      contratId: 1,
      clientId: 1,
      referenceContrat: 'REF-001',
      dateContrat: DateTime(2024, 1, 15),
      dateDebut: DateTime(2024, 2, 1),
      dateFin: DateTime(2024, 12, 31),
      statutContrat: 'Actif',
      dureeContrat: 12,
      duree: 10,
      categorie: 'PC',
    ),
    Contrat(
      contratId: 2,
      clientId: 1,
      referenceContrat: 'REF-002',
      dateContrat: DateTime(2024, 6, 20),
      dateDebut: DateTime(2024, 7, 1),
      dateFin: DateTime(2025, 6, 30),
      statutContrat: 'Actif',
      dureeContrat: 12,
      duree: 6,
      categorie: 'NI',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredContrats = widget.clientId != null
        ? _contrats.where((c) => c.clientId == widget.clientId).toList()
        : _contrats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des contrats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un contrat',
            onPressed: () => _showAddContratDialog(),
          ),
        ],
      ),
      body: filteredContrats.isEmpty
          ? const EmptyStateWidget(
              title: 'Aucun contrat',
              message: 'Aucun contrat trouvé. Créez-en un pour commencer.',
              icon: Icons.description_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filteredContrats.length,
              itemBuilder: (context, index) {
                final contrat = filteredContrats[index];
                return _ContratCard(
                  contrat: contrat,
                  onTap: () => _showContratDetails(contrat),
                );
              },
            ),
    );
  }

  void _showAddContratDialog() {
    final referenceContrat = TextEditingController();
    final dateContrat = TextEditingController();
    final dateDebut = TextEditingController();
    final dateFin = TextEditingController();
    final categorie = TextEditingController(text: 'PC');
    final statutContrat = TextEditingController(text: 'Actif');

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Récupérer le client pour afficher ses infos
            final clientRepository = context.read<ClientRepository>();
            final clients = clientRepository.clients;
            Client? selectedClient;

            if (widget.clientId != null) {
              try {
                selectedClient = clients.firstWhere(
                  (c) => c.clientId == widget.clientId,
                );
              } catch (e) {
                selectedClient = clients.isNotEmpty ? clients.first : null;
              }
            } else if (clients.isNotEmpty) {
              selectedClient = clients.first;
            }

            final isSociete = selectedClient?.categorie == 'Société';

            return AlertDialog(
              title: const Text('Ajouter un contrat'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Affichage des infos client
                    if (selectedClient != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Client: ${selectedClient.nom} ${selectedClient.prenom}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Catégorie: ${selectedClient.categorie}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (isSociete) ...[
                              const SizedBox(height: 6),
                              Text(
                                'NIF: ${selectedClient.nif}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'STAT: ${selectedClient.stat}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Référence contrat
                    TextField(
                      controller: referenceContrat,
                      decoration: const InputDecoration(
                        labelText: 'Référence',
                        hintText: 'Auto-générée',
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 12),
                    // Date du contrat
                    TextField(
                      controller: dateContrat,
                      decoration: const InputDecoration(
                        labelText: 'Date du contrat',
                        hintText: 'dd/MM/yyyy',
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          dateContrat.text = DateFormat(
                            'dd/MM/yyyy',
                          ).format(date);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Date de début
                    TextField(
                      controller: dateDebut,
                      decoration: const InputDecoration(
                        labelText: 'Date de début',
                        hintText: 'dd/MM/yyyy',
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          dateDebut.text = DateFormat(
                            'dd/MM/yyyy',
                          ).format(date);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Date de fin
                    TextField(
                      controller: dateFin,
                      decoration: const InputDecoration(
                        labelText: 'Date de fin',
                        hintText: 'dd/MM/yyyy',
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          dateFin.text = DateFormat('dd/MM/yyyy').format(date);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Catégorie
                    TextField(
                      controller: categorie,
                      decoration: const InputDecoration(labelText: 'Catégorie'),
                    ),
                    const SizedBox(height: 12),
                    // Statut
                    DropdownButtonFormField<String>(
                      initialValue: statutContrat.text,
                      decoration: const InputDecoration(labelText: 'Statut'),
                      items: ['Actif', 'Inactif', 'Terminé']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          statutContrat.text = value ?? 'Actif';
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (dateDebut.text.isEmpty ||
                        dateFin.text.isEmpty ||
                        dateContrat.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez remplir tous les champs'),
                        ),
                      );
                      return;
                    }

                    final dateContratParsed = DateFormat(
                      'dd/MM/yyyy',
                    ).parse(dateContrat.text);
                    final dateDebutParsed = DateFormat(
                      'dd/MM/yyyy',
                    ).parse(dateDebut.text);
                    final dateFinParsed = DateFormat(
                      'dd/MM/yyyy',
                    ).parse(dateFin.text);
                    final duree =
                        dateFinParsed.month -
                        dateDebutParsed.month +
                        12 * (dateFinParsed.year - dateDebutParsed.year);

                    context.read<ContratRepository>().createContrat(
                      clientId: widget.clientId ?? 1,
                      referenceContrat:
                          'REF-${DateTime.now().millisecondsSinceEpoch}',
                      dateContrat: dateContratParsed,
                      dateDebut: dateDebutParsed,
                      dateFin: dateFinParsed,
                      statutContrat: statutContrat.text,
                      duree: duree,
                      categorie: categorie.text,
                    );
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contrat créé')),
                    );
                  },
                  child: const Text('Créer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showContratDetails(Contrat contrat) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Contrat #${contrat.contratId}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Éditer'),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _showEditContratDialog(contrat);
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 18,
                              color: AppTheme.errorRed,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Supprimer',
                              style: TextStyle(color: AppTheme.errorRed),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Catégorie', contrat.categorie),
              _buildDetailRow('État', contrat.statutContrat),
              _buildDetailRow('Début', dateFormat.format(contrat.dateDebut)),
              _buildDetailRow('Fin', dateFormat.format(contrat.dateFin)),
              _buildDetailRow('Durée', '${contrat.dureeContrat} mois'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.pushNamed(
                      context,
                      '/factures',
                      arguments: {'contratId': contrat.contratId},
                    );
                  },
                  child: const Text('Voir factures du contrat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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

  void _showEditContratDialog(Contrat contrat) {
    final referenceContrat = TextEditingController(
      text: contrat.referenceContrat,
    );
    final dateContrat = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(contrat.dateContrat),
    );
    final dateDebut = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(contrat.dateDebut),
    );
    final dateFin = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(contrat.dateFin),
    );
    final duree = TextEditingController(text: contrat.duree.toString());
    final categorie = TextEditingController(text: contrat.categorie);
    final statutContrat = TextEditingController(text: contrat.statutContrat);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Éditer le contrat'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: referenceContrat,
                decoration: const InputDecoration(labelText: 'Référence'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateContrat,
                decoration: const InputDecoration(
                  labelText: 'Date du contrat',
                  hintText: 'dd/MM/yyyy',
                ),
                readOnly: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateDebut,
                decoration: const InputDecoration(
                  labelText: 'Date de début',
                  hintText: 'dd/MM/yyyy',
                ),
                readOnly: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateFin,
                decoration: const InputDecoration(
                  labelText: 'Date de fin',
                  hintText: 'dd/MM/yyyy',
                ),
                readOnly: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: duree,
                decoration: const InputDecoration(
                  labelText: 'Durée restante (mois)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categorie,
                decoration: const InputDecoration(labelText: 'Catégorie'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: statutContrat.text,
                decoration: const InputDecoration(labelText: 'Statut'),
                items: ['Actif', 'Inactif', 'Terminé']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  statutContrat.text = value ?? contrat.statutContrat;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedContrat = Contrat(
                contratId: contrat.contratId,
                clientId: contrat.clientId,
                referenceContrat: referenceContrat.text,
                dateContrat: DateFormat('dd/MM/yyyy').parse(dateContrat.text),
                dateDebut: contrat.dateDebut,
                dateFin: contrat.dateFin,
                statutContrat: statutContrat.text,
                dureeContrat: contrat.dureeContrat,
                duree: int.tryParse(duree.text) ?? contrat.duree,
                categorie: categorie.text,
              );

              context.read<ContratRepository>().updateContrat(updatedContrat);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contrat mis à jour')),
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

class _ContratCard extends StatelessWidget {
  final Contrat contrat;
  final VoidCallback onTap;

  const _ContratCard({Key? key, required this.contrat, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isActive =
        DateTime.now().isBefore(contrat.dateFin) &&
        DateTime.now().isAfter(contrat.dateDebut);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: isActive
                ? AppTheme.successGradient
                : AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isActive ? Icons.check_circle : Icons.description,
            color: Colors.white,
          ),
        ),
        title: Text('Contrat #${contrat.contratId}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Du ${dateFormat.format(contrat.dateDebut)} au ${dateFormat.format(contrat.dateFin)}',
            ),
            Text(
              isActive ? 'Actif' : 'Inactif',
              style: TextStyle(
                color: isActive
                    ? AppTheme.successGreen
                    : AppTheme.warningOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Text('${contrat.dureeContrat}M'),
        onTap: onTap,
      ),
    );
  }
}
