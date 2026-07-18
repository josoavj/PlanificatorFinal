import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../repositories/index.dart';
import '../../models/index.dart';
import '../../core/theme.dart';
import '../../services/logging_service.dart';
import 'widgets/facture_price_dialog.dart';

class FactureScreen extends StatefulWidget {
  const FactureScreen({super.key});

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
    final q = _searchQuery.toLowerCase();
    return factures.where((f) => (f.clientNom?.toLowerCase().contains(q) ?? false) || (f.clientPrenom?.toLowerCase().contains(q) ?? false) || (f.typeTreatment?.toLowerCase().contains(q) ?? false)).toList();
  }

  Widget _buildHeader(BuildContext context, List<Facture> factures) {
    final filtered = _filterFacturesBySearch(factures);
    final groupKeys = <String>{};
    for (final f in filtered) {
      groupKeys.add('${f.clientFullName} - ${f.typeTreatment ?? 'N/A'}');
    }

    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue[600]!, Colors.blue[400]!], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par client ou traitement...', hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true, fillColor: Colors.white.withValues(alpha: 0.2),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 12),
              Container(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12)), child: IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () { _searchQuery = ''; _searchController.clear(); context.read<FactureRepository>().loadAllFactures(); })),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildHeaderBadge('${filtered.length} ${filtered.length > 1 ? 'factures' : 'facture'}'),
              const SizedBox(width: 12),
              _buildHeaderBadge('${groupKeys.length} ${groupKeys.length > 1 ? 'traitements' : 'traitement'}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(String text) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(20)), child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<FactureRepository>(
        builder: (context, factureRepo, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, factureRepo.factures),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: factureRepo.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : factureRepo.errorMessage != null
                      ? Center(child: Text('Erreur: ${factureRepo.errorMessage}', style: const TextStyle(color: Colors.red)))
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
    final filtered = _filterFacturesBySearch(factures);
    if (factures.isEmpty) return const Center(child: Text('Aucune facture trouvée'));
    if (filtered.isEmpty) return const Center(child: Text('Aucune facture ne correspond à votre recherche'));

    final Map<String, List<Facture>> grouped = {};
    for (final f in filtered) {
      final key = '${f.clientFullName} - ${f.typeTreatment ?? 'N/A'}';
      grouped.putIfAbsent(key, () => []).add(f);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    for (final k in sortedKeys) {
      grouped[k]!.sort((a, b) => b.dateTraitement.compareTo(a.dateTraitement));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final group = grouped[key]!;
        return _FactureGroupCard(
          title: key, factures: group,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => _FactureDetailScreen(factures: group, groupTitle: key))),
        );
      },
    );
  }
}

class _FactureGroupCard extends StatelessWidget {
  final String title;
  final List<Facture> factures;
  final VoidCallback onTap;
  const _FactureGroupCard({required this.title, required this.factures, required this.onTap});

  @override
  Widget build(BuildContext context) {
    int total = 0; int unpaid = 0;
    for (final f in factures) { total += f.montant; if (f.etat != 'Payé') unpaid += f.montant; }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.receipt_long, color: AppTheme.primaryBlue, size: 24)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text('${factures.length} facture(s)', style: const TextStyle(fontSize: 12, color: Colors.grey))])),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total: $total Ar', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)), Text('Non payé: $unpaid Ar', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange))]),
            ],
          ),
        ),
      ),
    );
  }
}

class _FactureDetailScreen extends StatefulWidget {
  final List<Facture> factures;
  final String groupTitle;
  const _FactureDetailScreen({required this.factures, required this.groupTitle});
  @override
  State<_FactureDetailScreen> createState() => _FactureDetailScreenState();
}

class _FactureDetailScreenState extends State<_FactureDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final sorted = List<Facture>.from(widget.factures)..sort((a, b) => a.dateTraitement.compareTo(b.dateTraitement));
    int total = 0; int unpaid = 0;
    for (final f in sorted) { total += f.montant; if (f.etat != 'Payé') unpaid += f.montant; }
    final paid = total - unpaid;

    return Scaffold(
      appBar: AppBar(title: Text(widget.groupTitle), elevation: 1),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16), color: Colors.blue[50],
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_SummaryCard(label: 'Total', amount: total, color: Colors.blue), _SummaryCard(label: 'Payé', amount: paid, color: Colors.green), _SummaryCard(label: 'Non Payé', amount: unpaid, color: Colors.orange)]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: sorted.length, itemBuilder: (context, index) => _FactureRow(facture: sorted[index], onTapModifier: () => FacturePriceDialog.show(context, sorted[index], widget.groupTitle, () => setState(() {})))),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label; final int amount; final Color color;
  const _SummaryCard({required this.label, required this.amount, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 4), Text('$amount Ar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))]);
  }
}

class _FactureRow extends StatelessWidget {
  final Facture facture;
  final VoidCallback onTapModifier;
  const _FactureRow({required this.facture, required this.onTapModifier});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthRepository>().isAdmin;
    final isPaid = facture.etat.toLowerCase() == 'payé' || facture.etat.toLowerCase() == 'payée';
    final statusColor = isPaid ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: (isPaid || !isAdmin) ? null : onTapModifier,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('dd/MM/yyyy').format(facture.dateTraitement), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isPaid ? Colors.grey : Colors.black)),
                  Row(
                    children: [
                      Text('${facture.montant} Ar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isPaid ? Colors.grey : Colors.black)),
                      if (isAdmin && !isPaid) ...[const SizedBox(width: 8), const Icon(Icons.edit, size: 14, color: Colors.blue)],
                      const SizedBox(width: 12),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)), child: Text(facture.etat, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor))),
                    ],
                  ),
                ],
              ),
              if (facture.referenceFacture != null && facture.referenceFacture!.isNotEmpty) ...[const SizedBox(height: 8), Text('Réf: ${facture.referenceFacture}', style: const TextStyle(fontSize: 12, color: Colors.grey))],
            ],
          ),
        ),
      ),
    );
  }
}
