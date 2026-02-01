import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../repositories/index.dart';
import '../../models/index.dart';
import '../../core/theme.dart';
import '../../utils/number_formatter.dart';
import '../../services/logging_service.dart';

class FactureScreen extends StatefulWidget {
  const FactureScreen({Key? key}) : super(key: key);

  @override
  State<FactureScreen> createState() => _FactureScreenState();
}

class _FactureScreenState extends State<FactureScreen> {
  final TextEditingController _searchController = TextEditingController();
  final logger = createLoggerWithFileOutput(name: 'facture_screen');
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<FactureRepository>().loadAllFactures();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Facture> _filterFacturesBySearch(List<Facture> factures) {
    if (_searchQuery.isEmpty) return factures;

    return factures
        .where(
          (f) =>
              (f.clientNom?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false) ||
              (f.clientPrenom?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false) ||
              (f.typeTreatment?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false),
        )
        .toList();
  }

  /// Construit l'en-tête avec gradient et barre de recherche
  Widget _buildHeader(BuildContext context, List<Facture> factures) {
    final filteredFactures = _filterFacturesBySearch(factures);
    // Compter le nombre de traitements uniques
    final treatments = <String>{};
    for (final f in filteredFactures) {
      if (f.typeTreatment != null && f.typeTreatment!.isNotEmpty) {
        treatments.add(f.typeTreatment!);
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[600]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de recherche avec bouton d'actualisation
          Row(
            children: [
              // Barre de recherche
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par client ou traitement...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.2),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Bouton d'actualisation
              Tooltip(
                message: 'Actualiser',
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () {
                      _searchQuery = '';
                      _searchController.clear();
                      context.read<FactureRepository>().loadAllFactures();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Badges pour nombre de factures et traitements
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${filteredFactures.length} ${filteredFactures.length > 1 ? 'factures' : 'facture'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${treatments.length} ${treatments.length > 1 ? 'traitements' : 'traitement'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<FactureRepository>(
        builder: (context, factureRepo, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // En-tête avec gradient et barre de recherche
                _buildHeader(context, factureRepo.factures),

                // Liste des factures
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: factureRepo.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : factureRepo.errorMessage != null
                      ? Center(
                          child: Text(
                            'Erreur: ${factureRepo.errorMessage}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      : _buildFacturesList(factureRepo.factures),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFacturesList(List<Facture> factures) {
    final filteredFactures = _filterFacturesBySearch(factures);

    if (factures.isEmpty) {
      return const Center(child: Text('Aucune facture trouvée'));
    }

    if (filteredFactures.isEmpty) {
      return const Center(
        child: Text('Aucune facture ne correspond à votre recherche'),
      );
    }

    // Grouper par client + traitement pour une meilleure organisation
    final Map<String, List<Facture>> grouped = {};
    for (final facture in filteredFactures) {
      final key =
          '${facture.clientFullName} - ${facture.typeTreatment ?? 'N/A'}';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(facture);
    }

    // Trier alphabétiquement par clé (client - traitement) et par date décroissante dans chaque groupe
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    for (final key in sortedKeys) {
      grouped[key]!.sort((a, b) {
        return b.dateTraitement.compareTo(a.dateTraitement); // Récent d'abord
      });
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final facturesGroup = grouped[key]!;

        return _FactureGroupCard(
          title: key,
          factures: facturesGroup,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _FactureDetailScreen(
                  factures: facturesGroup,
                  groupTitle: key,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Card pour afficher un groupe de factures (client + traitement)
class _FactureGroupCard extends StatelessWidget {
  final String title;
  final List<Facture> factures;
  final VoidCallback onTap;

  const _FactureGroupCard({
    required this.title,
    required this.factures,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Calculer les montants
    int montantTotal = 0;
    int montantNonPaye = 0;
    for (final f in factures) {
      montantTotal += f.montant;
      if (f.etat != 'Payé') {
        montantNonPaye += f.montant;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: AppTheme.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${factures.length} facture(s)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Résumé des montants
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: $montantTotal Ar',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    'Non payé: $montantNonPaye Ar',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Écran détail des factures pour un groupe
class _FactureDetailScreen extends StatefulWidget {
  final List<Facture> factures;
  final String groupTitle;

  const _FactureDetailScreen({
    required this.factures,
    required this.groupTitle,
  });

  @override
  State<_FactureDetailScreen> createState() => _FactureDetailScreenState();
}

class _FactureDetailScreenState extends State<_FactureDetailScreen> {
  final logger = createLoggerWithFileOutput(name: 'facture_detail_screen');

  int _calculateTotalMontant(List<Facture> factures) {
    int total = 0;
    for (final facture in factures) {
      total += facture.montant;
    }
    return total;
  }

  int _calculateMontantNonPaye(List<Facture> factures) {
    int total = 0;
    for (final facture in factures) {
      if (facture.etat != 'Payé') {
        total += facture.montant;
      }
    }
    return total;
  }

  void _showModifierPrixDialog(Facture facture) {
    //  Vérifier si la facture est déjà payée
    if (facture.etat == 'Payé' || facture.etat == 'Payée') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            ' Impossible de modifier le prix d\'une facture payée',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final prixInitialCtrl = TextEditingController(
      text: facture.montant.toString(),
    );
    final prixNewCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modification de Prix'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations du traitement
                Text(
                  widget.groupTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: ${DateFormat('dd/MM/yyyy').format(facture.dateTraitement)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 16),

                // Prix initial (lecture seule)
                const Text(
                  'Prix Initial',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: prixInitialCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),

                // Nouveau prix
                const Text(
                  'Nouveau Prix',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: prixNewCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Ex: 50 000 ou 1500000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    helperText: 'Les espaces sont autorisés',
                  ),
                ),
                const SizedBox(height: 16),

                // Statut actuel
                Text(
                  'Statut: ${facture.etat}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
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
                if (prixNewCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez entrer un nouveau prix'),
                    ),
                  );
                  return;
                }

                try {
                  // Parser les montants en ignorant les espaces
                  final oldPrix = NumberFormatter.parseMontant(
                    prixInitialCtrl.text,
                  );
                  final newPrix = NumberFormatter.parseMontant(
                    prixNewCtrl.text,
                  );

                  // Validation: les montants doivent être positifs
                  if (newPrix <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Le montant doit être supérieur à 0'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  logger.i(
                    '💰 Changement de prix: $oldPrix → $newPrix pour facture ${facture.factureId}',
                  );

                  // Appeler la méthode majMontantEtHistorique pour mettre à jour
                  // la facture ET les factures postérieures du même traitement
                  final factureRepo = context.read<FactureRepository>();
                  final success = await factureRepo.majMontantEtHistorique(
                    facture.factureId,
                    oldPrix,
                    newPrix,
                  );

                  if (!mounted) return;

                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erreur lors de la modification'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Prix modifié avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  //  CORRECTION: Recharger les données directement sans délai arbitraire
                  if (mounted) {
                    await context.read<FactureRepository>().loadAllFactures();
                    // Rafraîchir l'écran détail
                    if (mounted) {
                      setState(() {});
                    }
                  }
                } catch (e) {
                  logger.e('Erreur modification prix: $e');
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Trier les factures par date croissante (plus anciennes en premier)
    final sortedFactures = List<Facture>.from(widget.factures);
    sortedFactures.sort((a, b) => a.dateTraitement.compareTo(b.dateTraitement));

    final montantTotal = _calculateTotalMontant(sortedFactures);
    final montantNonPaye = _calculateMontantNonPaye(sortedFactures);
    final montantPaye = montantTotal - montantNonPaye;

    return Scaffold(
      appBar: AppBar(title: Text(widget.groupTitle), elevation: 1),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Résumé des montants
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryCard(
                    label: 'Total',
                    amount: montantTotal,
                    color: Colors.blue,
                  ),
                  _SummaryCard(
                    label: 'Payé',
                    amount: montantPaye,
                    color: Colors.green,
                  ),
                  _SummaryCard(
                    label: 'Non Payé',
                    amount: montantNonPaye,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),

            // Liste des factures
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedFactures.length,
                itemBuilder: (context, index) {
                  final facture = sortedFactures[index];
                  return _FactureRow(
                    facture: facture,
                    onTapModifier: () => _showModifierPrixDialog(facture),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card pour afficher un résumé de montant
class _SummaryCard extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          '$amount Ar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Ligne de facture cliquable
class _FactureRow extends StatelessWidget {
  final Facture facture;
  final VoidCallback onTapModifier;

  const _FactureRow({required this.facture, required this.onTapModifier});

  Color _getStatusColor(String etat) {
    switch (etat.toLowerCase()) {
      case 'payé':
        return Colors.green;
      case 'payée':
        return Colors.green;
      case 'non payé':
        return Colors.red;
      case 'à venir':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool get _isPaid =>
      facture.etat.toLowerCase() == 'payé' ||
      facture.etat.toLowerCase() == 'payée';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: _isPaid ? null : onTapModifier,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(facture.dateTraitement),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _isPaid ? Colors.grey : Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${facture.montant} Ar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _isPaid ? Colors.grey : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(facture.etat).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          facture.etat,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(facture.etat),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (facture.referenceFacture != null &&
                  facture.referenceFacture!.isNotEmpty)
                Text(
                  'Réf: ${facture.referenceFacture}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
