import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../core/theme.dart';
import 'widgets/history_category_card.dart';
import 'history_client_list_screen.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  final List<Map<String, dynamic>> _sections = [
    {
      'title': 'Anti termites (AT)',
      'code': 'AT',
      'icon': Icons.bug_report_rounded,
      'color': Colors.purple,
    },
    {
      'title': 'Lutte antiparasitaire (PC)',
      'code': 'PC',
      'icon': Icons.pest_control_rounded,
      'color': Colors.orange,
    },
    {
      'title': 'Nettoyage Industriel (NI)',
      'code': 'NI',
      'icon': Icons.cleaning_services_rounded,
      'color': Colors.blue,
    },
    {
      'title': 'Ramassage Ordures (RO)',
      'code': 'RO',
      'icon': Icons.delete_sweep_rounded,
      'color': Colors.brown,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final repo = context.read<PlanningDetailsRepository>();
    // On charge d'abord les compteurs (ultra rapide)
    await repo.loadHistoryCategoryCounts();
    // On lance le chargement de la première page en fond si besoin
    if (repo.allTreatmentsComplete.isEmpty) {
      repo.loadHistoryPage(page: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<PlanningDetailsRepository>(
        builder: (context, repo, _) {
          // Utiliser les compteurs pré-chargés
          final Map<String, int> counts = repo.historyCategoryCounts;

          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1.8,
                        ),
                        itemCount: _sections.length,
                        itemBuilder: (context, index) {
                          final section = _sections[index];
                          final code = section['code'] as String;
                          final count = counts[code] ?? 0;

                          return HistoryCategoryCard(
                            title: section['title'] as String,
                            code: code,
                            icon: section['icon'] as IconData,
                            color: section['color'] as Color,
                            count: count,
                            onTap: () => _navigateToCategory(section, repo),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'history_refresh_main',
        onPressed: _loadData,
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.refresh_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HISTORIQUE DE SERVICE',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue, letterSpacing: 1.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Sélectionnez une catégorie',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
      ],
    );
  }

  void _navigateToCategory(Map<String, dynamic> section, PlanningDetailsRepository repo) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HistoryClientListScreen(
          title: section['title'] as String,
          code: section['code'] as String,
          repository: repo,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: SlideTransition(
            position: animation.drive(Tween(begin: const Offset(0.05, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))),
            child: child,
          ));
        },
      ),
    );
  }
}
