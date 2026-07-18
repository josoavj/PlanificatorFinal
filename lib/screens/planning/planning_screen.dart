import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planificator/models/planning_details.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../repositories/index.dart';
import '../../core/theme.dart';
import '../../widgets/app_dialogs.dart';
import 'widgets/signalement_dialog.dart';
import 'widgets/remark_dialog.dart';
import '../../utils/app_snackbars.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  final Map<String, List<Map<String, dynamic>>> _treatmentCache = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await context.read<PlanningDetailsRepository>().loadAllTreatmentsComplete();
    _treatmentCache.clear();
  }

  String _convertToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int || value is double) return value.toString();
    if (value is List<int>) { try { return String.fromCharCodes(value); } catch (e) { return ''; } }
    return value.toString();
  }

  List<Map<String, dynamic>> _getTreatmentsForDay(DateTime day, List<Map<String, dynamic>> treatments) {
    final dayKey = '${day.year}-${day.month}-${day.day}';
    if (_treatmentCache.containsKey(dayKey)) return _treatmentCache[dayKey]!;

    final result = treatments.where((t) {
      try {
        final dateStr = _convertToString(t['date']);
        if (dateStr.isEmpty) return false;
        final parts = dateStr.split('-');
        if (parts.length != 3) return false;
        final tDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        return isSameDay(tDate, DateTime(day.year, day.month, day.day));
      } catch (e) { return false; }
    }).toList();

    _treatmentCache[dayKey] = result;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(heroTag: 'planning_refresh', onPressed: () async { _treatmentCache.clear(); await context.read<PlanningDetailsRepository>().loadAllTreatmentsComplete(); }, tooltip: 'Actualiser', child: const Icon(Icons.refresh)),
      body: Consumer<PlanningDetailsRepository>(
        builder: (context, repo, _) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final treatments = _getTreatmentsForDay(_selectedDay, repo.allTreatmentsComplete);

          return SingleChildScrollView(
            child: Column(
              children: [
                _CalendarWidget(focusedDay: _focusedDay, selectedDay: _selectedDay, treatments: repo.allTreatmentsComplete, onDaySelected: (s, f) => setState(() { _selectedDay = s; _focusedDay = f; }), onPageChanged: (f) => _focusedDay = f, getTreatmentsForDay: _getTreatmentsForDay),
                Container(
                  padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: isDark ? AppTheme.darkBg : Colors.white),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Container(width: 4, height: 24, decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 12), Expanded(child: Text(_formatDateLong(_selectedDay), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 18)))]),
                      const SizedBox(height: 24),
                      if (treatments.isNotEmpty) ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: treatments.length, itemBuilder: (context, index) => _PlanningCard(treatment: treatments[index], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => _PlanningDetailScreen(treatment: treatments[index], planningDetailId: treatments[index]['planning_detail_id'] ?? 0)))))
                      else if (repo.isLoading) const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()))
                      else if (repo.errorMessage != null) Center(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Text('Erreur: ${repo.errorMessage}', style: const TextStyle(color: AppTheme.errorRed))))
                      else Center(child: Padding(padding: const EdgeInsets.all(40.0), child: Column(children: [Icon(Icons.event_busy_rounded, size: 48, color: isDark ? Colors.white24 : Colors.grey[300]), const SizedBox(height: 16), Text('Aucun traitement prévu pour ce jour', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[400], fontWeight: FontWeight.w500))]))),
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

  String _formatDateLong(DateTime date) {
    final str = DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(date);
    final parts = str.split(' ');
    if (parts.isNotEmpty) parts[0] = parts[0][0].toUpperCase() + parts[0].substring(1);
    if (parts.length > 2) parts[2] = parts[2][0].toUpperCase() + parts[2].substring(1);
    return parts.join(' ');
  }
}

class _CalendarWidget extends StatelessWidget {
  final DateTime focusedDay; final DateTime selectedDay; final List<Map<String, dynamic>> treatments; final Function(DateTime, DateTime) onDaySelected; final Function(DateTime) onPageChanged; final Function(DateTime, List<Map<String, dynamic>>) getTreatmentsForDay;
  const _CalendarWidget({required this.focusedDay, required this.selectedDay, required this.treatments, required this.onDaySelected, required this.onPageChanged, required this.getTreatmentsForDay});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16), decoration: AppTheme.cardDecoration(context, radius: 28),
      child: Material(color: Colors.transparent, child: Padding(padding: const EdgeInsets.all(12), child: TableCalendar(firstDay: DateTime(2024), lastDay: DateTime(2079, 12, 31), focusedDay: focusedDay, locale: 'fr_FR', startingDayOfWeek: StartingDayOfWeek.monday, selectedDayPredicate: (day) => isSameDay(selectedDay, day), onDaySelected: onDaySelected, onPageChanged: onPageChanged, eventLoader: (day) => List.generate(getTreatmentsForDay(day, treatments).length, (index) => 'e'), calendarStyle: CalendarStyle(selectedDecoration: BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]), todayDecoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: AppTheme.primaryBlue)), todayTextStyle: TextStyle(color: isDark ? Colors.white : AppTheme.primaryBlue, fontWeight: FontWeight.bold), markerDecoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle), markersMaxCount: 3, defaultTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black87), weekendTextStyle: TextStyle(color: isDark ? AppTheme.accentBlue : Colors.blue.shade700), outsideTextStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400)), headerStyle: HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17), leftChevronIcon: Icon(Icons.chevron_left_rounded, color: isDark ? Colors.white : Colors.black87), rightChevronIcon: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white : Colors.black87)), daysOfWeekStyle: DaysOfWeekStyle(weekdayStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12), weekendStyle: TextStyle(color: isDark ? AppTheme.accentBlue : Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 12))))),
    );
  }
}

class _PlanningCard extends StatelessWidget {
  final Map<String, dynamic> treatment; final VoidCallback onTap;
  const _PlanningCard({required this.treatment, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trait = treatment['traitement']?.toString() ?? '';
    final axe = treatment['axe']?.toString() ?? '';
    final etat = treatment['etat']?.toString() ?? '';
    final isEffectue = etat.toLowerCase().contains('effectué');
    final statusColor = isEffectue ? (isDark ? AppTheme.darkSuccess : AppTheme.successGreen) : (isDark ? AppTheme.darkWarning : AppTheme.warningOrange);

    return Container(
      margin: const EdgeInsets.only(bottom: 16), decoration: AppTheme.cardDecoration(context, radius: 24),
      child: Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(24), child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Container(width: 6, decoration: BoxDecoration(color: statusColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)))), const SizedBox(width: 16), Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(trait, style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 8), Row(children: [Icon(Icons.location_on_outlined, size: 14, color: isDark ? Colors.white38 : Colors.grey), const SizedBox(width: 4), Text('Axe: $axe', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500))])]))), Center(child: Padding(padding: const EdgeInsets.only(right: 16), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(isEffectue ? Icons.check_circle_rounded : Icons.pending_actions_rounded, color: statusColor, size: 14), const SizedBox(width: 6), Text(etat.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5))]))))])))),
    );
  }
}

class _PlanningDetailScreen extends StatefulWidget {
  final Map<String, dynamic> treatment; final int planningDetailId;
  const _PlanningDetailScreen({required this.treatment, required this.planningDetailId});
  @override
  State<_PlanningDetailScreen> createState() => _PlanningDetailScreenState();
}

class _PlanningDetailScreenState extends State<_PlanningDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trait = widget.treatment['traitement']?.toString() ?? '';
    final axe = widget.treatment['axe']?.toString() ?? '';
    final etat = widget.treatment['etat']?.toString() ?? '';
    final isEffectue = etat.toLowerCase().contains('effectué');
    final statusColor = isEffectue ? (isDark ? AppTheme.darkSuccess : AppTheme.successGreen) : (isDark ? AppTheme.darkWarning : AppTheme.warningOrange);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          _buildHeader(context, statusColor), const SizedBox(height: 70),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(children: [
            _buildDetailSection(context, title: 'Détails du Traitement', children: [_buildDetailTile(context, Icons.medical_services_outlined, 'Service', trait), _buildDetailTile(context, Icons.map_outlined, 'Axe / Secteur', axe), _buildDetailTile(context, Icons.info_outline_rounded, 'État actuel', etat, valueColor: statusColor)]),
            const SizedBox(height: 32),
            _buildDetailSection(context, title: 'Actions disponibles', children: [_buildActionTile(context, icon: Icons.edit_note_rounded, title: 'Ajouter une remarque', subtitle: 'Noter des précisions ou créer une facture', color: AppTheme.primaryBlue, onTap: _showRemarqueDialog), _buildActionTile(context, icon: Icons.report_problem_outlined, title: 'Signaler un problème', subtitle: 'Enregistrer une anomalie durant le traitement', color: isDark ? AppTheme.darkError : AppTheme.errorRed, onTap: _showSignalementDialog)]),
          ])),
        ]),
      ),
    );
  }

  void _showRemarqueDialog() {
    final pd = PlanningDetails.fromJson(widget.treatment);
    AppDialogs.showBlurDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(title: const Text('Créer Facture'), content: const Text('Une facture sera créée automatiquement pour cette date'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')), ElevatedButton(onPressed: () async {
      final fId = await context.read<FactureRepository>().createFactureComplete(planningDetailId: pd.planningDetailId, referenceFacture: 'FAC-${DateTime.now().millisecondsSinceEpoch}', montant: 0, etat: 'À venir', axe: widget.treatment['axe'] ?? '', dateTraitement: pd.datePlanification);
      if (fId != -1) {
        final factures = await context.read<FactureRepository>().getFacturesByPlanningDetail(pd.planningDetailId);
        if (factures.isNotEmpty) {
          if (mounted) Navigator.pop(ctx);
          if (mounted) AppDialogs.showBlurDialog(context: context, builder: (ctx2) => RemarqueDialog(planningDetail: pd, facture: factures.first, onSaved: () async { await context.read<PlanningDetailsRepository>().loadAllTreatmentsComplete(); await context.read<FactureRepository>().loadAllFactures(); AppSnackBars.showSuccess(context, 'Remarque ajoutée'); Navigator.of(context).pop(); }));
        }
      }
    }, child: const Text('Créer Facture'))]));
  }

  void _showSignalementDialog() {
    final pd = PlanningDetails.fromJson(widget.treatment);
    AppDialogs.showBlurDialog(context: context, builder: (ctx) => SignalementDialog(planningDetail: pd, onSaved: () async { await context.read<PlanningDetailsRepository>().loadAllTreatmentsComplete(); await context.read<FactureRepository>().loadAllFactures(); AppSnackBars.showSuccess(context, 'Signalement enregistré'); Navigator.of(context).pop(); }));
  }

  Widget _buildHeader(BuildContext context, Color statusColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
      Container(height: 230, width: double.infinity, decoration: BoxDecoration(color: isDark ? Theme.of(context).colorScheme.surfaceContainer : AppTheme.primaryBlue, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(48)))),
      Positioned(top: 40, left: 8, child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24))),
      Positioned(bottom: -45, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: isDark ? AppTheme.darkCardBg : Colors.white, shape: BoxShape.circle, boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))]), child: Container(width: 100, height: 100, decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Icons.calendar_today_rounded, size: 48, color: AppTheme.primaryBlue))))
    ]);
  }

  Widget _buildDetailSection(BuildContext context, {required String title, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Text(title.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue, fontSize: 10))), Container(decoration: AppTheme.cardDecoration(context, radius: 24), child: Column(children: children))]);
  }

  Widget _buildDetailTile(BuildContext context, IconData icon, String label, String value, {Color? valueColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(leading: Icon(icon, color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue, size: 22), title: Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600], fontWeight: FontWeight.bold)), subtitle: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: valueColor)), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4));
  }

  Widget _buildActionTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)), title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)), subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600])), trailing: const Icon(Icons.chevron_right_rounded, size: 20), onTap: onTap);
  }
}
