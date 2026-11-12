import 'package:material_ui/material_ui.dart';
import 'package:planificator/features/catalogue/repositories/type_traitement_repository.dart';
import 'package:planificator/features/planning/repositories/planning_details_repository.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/theme.dart';
import 'widgets/history_category_card.dart';
import 'history_client_list_screen.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  final List<Map<String, dynamic>> _sections = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final repo = context.read<PlanningDetailsRepository>();
    final catalog = context.read<TypeTraitementRepository>();
    await catalog.loadAllTraitements();
    if (!mounted) return;
    setState(() {
      _sections
        ..clear()
        ..addAll(
          catalog.categories.asMap().entries.map(
            (entry) => {
              'title': entry.value.name,
              'code': entry.value.name,
              'icon': _categoryIcon(entry.key),
              'color': _categoryColor(entry.key),
            },
          ),
        );
    });
    // On charge d'abord les compteurs (ultra rapide)
    await repo.loadHistoryCategoryCounts();
    // On lance le chargement de la première page en fond si besoin
    if (repo.allTreatmentsComplete.isEmpty) {
      repo.loadHistoryPage();
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
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 1.8,
                            ),
                        itemCount: _sections.length,
                        itemBuilder: (context, index) {
                          final section = _sections[index];
                          final category = section['code'] as String;
                          final count = counts[category] ?? 0;

                          return HistoryCategoryCard(
                            title: section['title'] as String,
                            code: category,
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

  IconData _categoryIcon(int index) {
    const icons = [
      Icons.pest_control_rounded,
      Icons.cleaning_services_rounded,
      Icons.bug_report_rounded,
      Icons.delete_sweep_rounded,
    ];
    return icons[index % icons.length];
  }

  Color _categoryColor(int index) {
    const colors = [
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.brown,
      Colors.teal,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HISTORIQUE DE SERVICE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryBlue,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sélectionnez une catégorie',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  void _navigateToCategory(
    Map<String, dynamic> section,
    PlanningDetailsRepository repo,
  ) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            HistoryClientListScreen(
              title: section['title'] as String,
              code: section['code'] as String,
              repository: repo,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(
                Tween(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
