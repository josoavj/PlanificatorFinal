import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import '../../core/theme.dart';
import '../../models/index.dart';
import '../../repositories/index.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/index.dart';
import '../../utils/app_snackbars.dart';
import '../../utils/date_utils.dart' as date_utils;
import '../../utils/phone_formatter.dart';
import '../../utils/nif_stat_formatter.dart';
import '../../widgets/common/multi_phone_input.dart';

class ContratCreationDialog extends StatefulWidget {
  final int? clientId;
  const ContratCreationDialog({super.key, this.clientId});

  @override
  State<ContratCreationDialog> createState() => _ContratCreationDialogState();
}

class _ContratCreationDialogState extends State<ContratCreationDialog> {
  int _mainStep = 0;
  int _treatmentIndex = 0;
  bool _isSaving = false;

  // Controllers Contrat
  final _numeroContrat = TextEditingController();
  final _dateContrat = TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
  final _dateDebut = TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
  final _dateFin = TextEditingController();
  final _categorieContrat = TextEditingController(text: 'Nouveau');
  final _dureeContrat = TextEditingController(text: '12');
  bool _isDeterminee = true;

  // Controllers Client
  final _clientNom = TextEditingController();
  final _clientPrenom = TextEditingController();
  final _clientEmail = TextEditingController();
  final List<TextEditingController> _clientPhoneControllers = [TextEditingController()];
  final _clientAdresse = TextEditingController();
  final _clientCategorie = TextEditingController(text: 'Particulier');
  final _clientNif = TextEditingController();
  final _clientStat = TextEditingController();
  final _clientAxe = TextEditingController(text: 'Centre (C)');

  List<int> _selectedTreatments = [];
  List<TypeTraitement> _allTypeTraitements = [];

  // Configuration par service
  final Map<int, Map<String, dynamic>> _treatmentConfig = {};
  final _treatmentDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTypeTraitements();
    _checkForSavedProgress();
  }

  @override
  void dispose() {
    _numeroContrat.dispose();
    _dateContrat.dispose();
    _dateDebut.dispose();
    _dateFin.dispose();
    _categorieContrat.dispose();
    _dureeContrat.dispose();
    _clientNom.dispose();
    _clientPrenom.dispose();
    _clientEmail.dispose();
    for (var controller in _clientPhoneControllers) {
      controller.dispose();
    }
    _treatmentDateController.dispose();
    _clientAdresse.dispose();
    _clientCategorie.dispose();
    _clientNif.dispose();
    _clientStat.dispose();
    _clientAxe.dispose();
    super.dispose();
  }

  Future<void> _loadTypeTraitements() async {
    final repo = context.read<TypeTraitementRepository>();
    await repo.loadAllTraitements();
    if (mounted) setState(() => _allTypeTraitements = repo.traitements);
  }

  Future<void> _checkForSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('contract_in_progress') == true && mounted) {
      final resume = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reprise de saisie'),
          content: const Text('Voulez-vous reprendre votre saisie précédente ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NON')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OUI')),
          ],
        ),
      );
      if (resume == true) {
        _loadSavedProgress();
      } else {
        _clearSavedProgress();
      }
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'ref': _numeroContrat.text,
      'dateC': _dateContrat.text,
      'dateD': _dateDebut.text,
      'isDet': _isDeterminee,
      'dateF': _dateFin.text,
      'cat': _categorieContrat.text,
      'dur': _dureeContrat.text,
      'selected': _selectedTreatments,
      'client': {
        'nom': _clientNom.text,
        'prenom': _clientPrenom.text,
        'email': _clientEmail.text,
        'tels': _clientPhoneControllers.map((c) => c.text).toList(),
        'adr': _clientAdresse.text,
        'cat': _clientCategorie.text,
        'nif': _clientNif.text,
        'stat': _clientStat.text,
        'axe': _clientAxe.text,
      }
    };
    await prefs.setString('contract_saved_data', jsonEncode(data));
    await prefs.setBool('contract_in_progress', true);
  }

  Future<void> _loadSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('contract_saved_data');
    if (json != null) {
      final data = jsonDecode(json);
      setState(() {
        _numeroContrat.text = data['ref'];
        _dateContrat.text = data['dateC'];
        _dateDebut.text = data['dateD'];
        _isDeterminee = data['isDet'];
        _dateFin.text = data['dateF'];
        _categorieContrat.text = data['cat'];
        _dureeContrat.text = data['dur'];
        _selectedTreatments = List<int>.from(data['selected']);
        final c = data['client'];
        _clientNom.text = c['nom'];
        _clientPrenom.text = c['prenom'];
        _clientEmail.text = c['email'];
        final List<String> tels = List<String>.from(c['tels'] ?? [c['tel'] ?? '']);
        _clientPhoneControllers.clear();
        for (var t in tels) {
          _clientPhoneControllers.add(TextEditingController(text: t));
        }
        if (_clientPhoneControllers.isEmpty) _clientPhoneControllers.add(TextEditingController());
        _clientAdresse.text = c['adr'];
        _clientCategorie.text = c['cat'];
        _clientNif.text = c['nif'] ?? '';
        _clientStat.text = c['stat'] ?? '';
        _clientAxe.text = c['axe'];
      });
    }
  }

  Future<void> _clearSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('contract_saved_data');
    await prefs.setBool('contract_in_progress', false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Container(
        width: 1000,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildStepper(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                child: SingleChildScrollView(child: _buildCurrentStep()),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 30, 40, 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.description_rounded, color: AppTheme.primaryBlue, size: 28),
          ),
          const SizedBox(width: 20),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Création de Contrat', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              Text('Paramétrez les services et planifications du client', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const Spacer(),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 30)),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final steps = ['Infos Contrat', 'Infos Client', 'Planifications', 'Validation'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
      child: Row(
        children: List.generate(steps.length, (i) {
          bool isActive = _mainStep == i;
          bool isDone = _mainStep > i;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isDone ? LinearGradient(colors: [Colors.green, Colors.green.shade700]) : (isActive ? LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.primaryDark]) : null),
                    color: !isDone && !isActive ? Colors.grey.withValues(alpha: 0.1) : null,
                  ),
                  child: Center(child: isDone ? const Icon(Icons.check, color: Colors.white, size: 18) : Text('${i + 1}', style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 12),
                Text(steps[i], style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.w900 : FontWeight.w500, color: isActive ? AppTheme.primaryBlue : Colors.grey)),
                if (i < steps.length - 1) Expanded(child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 20), color: isDone ? Colors.green : Colors.grey.withValues(alpha: 0.1))),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_mainStep) {
      case 0: return _buildStepContrat();
      case 1: return _buildStepClient();
      case 2: return _buildStepPlanning();
      case 3: return _buildStepValidation();
      default: return const SizedBox();
    }
  }

  Widget _buildStepContrat() {
    return Column(
      children: [
        AppSection(
          title: 'Référence et Validité',
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(24),
          showDividers: false,
          children: [
            _buildModernField(_numeroContrat, 'Numéro de Contrat (ex: REF-2026-001)', Icons.tag_rounded),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildModernDateField(_dateContrat, 'Date du contrat')),
                const SizedBox(width: 20),
                Expanded(child: _buildModernDateField(_dateDebut, 'Date de début de prestation')),
              ],
            ),
            const SizedBox(height: 20),
            _buildDureeToggle(),
          ],
        ),
        const SizedBox(height: 32),
        AppSection(
          title: 'Services à inclure',
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(24),
          children: [
            _buildServicePicker(),
          ],
        ),
      ],
    );
  }

  Widget _buildStepClient() {
    final cat = _clientCategorie.text;
    final isSociety = cat == 'Société';
    final isParticular = cat == 'Particulier';
    
    final String nomLabel;
    if (isParticular) {
      nomLabel = 'Nom';
    } else if (isSociety) {
      nomLabel = "Nom de l'entreprise";
    } else {
      nomLabel = "Nom de l'organisation";
    }
    
    final prenomLabel = isParticular ? 'Prénom' : 'Nom du Responsable';

    return Column(
      children: [
        AppSection(
          title: 'Type de client',
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(24),
          children: [_buildCategoryPicker()],
        ),
        const SizedBox(height: 32),
        AppSection(
          title: 'Identité du client',
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(24),
          showDividers: false,
          children: [
            Row(
              children: [
                Expanded(child: _buildModernField(_clientNom, nomLabel, Icons.person_outline_rounded)),
                const SizedBox(width: 20),
                Expanded(child: _buildModernField(_clientPrenom, prenomLabel, Icons.badge_outlined)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildModernField(_clientEmail, 'Email de contact', Icons.alternate_email_rounded)),
                const SizedBox(width: 20),
                Expanded(child: _buildClientExtraParams()),
              ],
            ),
            if (isSociety) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildModernField(
                      _clientNif, 
                      'NIF', 
                      Icons.description_outlined,
                      inputFormatters: [NifInputFormatter()],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildModernField(
                      _clientStat, 
                      'STAT', 
                      Icons.badge_outlined,
                      inputFormatters: [StatInputFormatter()],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            _buildModernField(_clientAdresse, 'Adresse complète', Icons.location_on_outlined),
            const SizedBox(height: 24),
            // NOUVELLE SECTION TÉLÉPHONES
            MultiPhoneInput(
              controllers: _clientPhoneControllers, 
              onAdd: () => setState(() => _clientPhoneControllers.add(TextEditingController())), 
              onRemove: (idx) => setState(() => _clientPhoneControllers.removeAt(idx)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepPlanning() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_selectedTreatments.isEmpty) return const Center(child: Text('Aucun service sélectionné'));
    
    final tId = _selectedTreatments[_treatmentIndex];
    final type = _allTypeTraitements.firstWhereOrNull((t) => t.id == tId);
    
    if (!_treatmentConfig.containsKey(tId)) {
      _treatmentConfig[tId] = {'redondance': 1, 'montant': '', 'debut': _dateDebut.text};
    }

    return Column(
      children: [
        // BANDEAU SERVICE
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBgSecondary : Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? AppTheme.glassBorder.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.settings_suggest_rounded, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration du service (${_treatmentIndex + 1}/${_selectedTreatments.length})', 
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type?.type ?? 'Service inconnu', 
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(12)),
                child: const Text('EN COURS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 10, letterSpacing: 1)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // SECTION FRÉQUENCE
        AppSection(
          title: 'Planification',
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(24),
          children: [
            _buildModernDateField(
              _treatmentDateController, 
              'Date du premier passage',
              onChanged: (v) => _treatmentConfig[tId]!['debut'] = v,
            ),
            const SizedBox(height: 24),
            const Text(
              'FRÉQUENCE DE PASSAGE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            _buildFrequencyGrid(tId),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // SECTION FACTURATION
        AppSection(
          title: 'Conditions financières',
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(24),
          children: [
            _buildModernField(
              null, 
              'Montant unitaire par passage (Net)', 
              Icons.payments_outlined, 
              isNumeric: true, 
              onChanged: (v) => _treatmentConfig[tId]!['montant'] = v,
              initialValue: _treatmentConfig[tId]!['montant'],
              inputFormatters: [AmountInputFormatter()],
              suffixIcon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(widthFactor: 1, child: Text('MGA / Ar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Les séparateurs de milliers s\'ajoutent automatiquement pendant la saisie.',
                style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepValidation() {
    final cat = _clientCategorie.text;
    final isParticular = cat == 'Particulier';
    final isSociety = cat == 'Société';

    final String entityLabel;
    if (isParticular) {
      entityLabel = 'Nom complet';
    } else if (isSociety) {
      entityLabel = "Nom de l'entreprise";
    } else {
      entityLabel = "Nom de l'organisation";
    }

    final clientDisplay = isParticular 
        ? '${_clientNom.text} ${_clientPrenom.text}' 
        : _clientNom.text;

    return Column(
      children: [
        AppSection(
          title: 'Récapitulatif Final',
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(24),
          children: [
            _buildSummaryRow('Catégorie Client', cat),
            _buildSummaryRow(entityLabel, clientDisplay),
            if (!isParticular) _buildSummaryRow('Responsable', _clientPrenom.text),
            _buildSummaryRow('Téléphone(s)', _clientPhoneControllers.map((c) => c.text).where((t) => t.isNotEmpty).join(' / ')),
            if (isSociety) ...[
              _buildSummaryRow('NIF', NifStatFormatter.formatNif(_clientNif.text)),
              _buildSummaryRow('STAT', NifStatFormatter.formatStat(_clientStat.text)),
            ],
            const Divider(height: 32),
            _buildSummaryRow('Référence Contrat', _numeroContrat.text),
            _buildSummaryRow('Durée', _isDeterminee ? '${_dureeContrat.text} mois' : 'Indéterminée'),
            _buildSummaryRow('Services', '${_selectedTreatments.length} services configurés'),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Voulez-vous valider et enregistrer ce contrat ?', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildModernField(TextEditingController? controller, String label, IconData icon, {bool isNumeric = false, Function(String)? onChanged, String? initialValue, List<TextInputFormatter>? inputFormatters, Widget? suffixIcon}) {
    return TextField(
      controller: controller ?? (initialValue != null ? TextEditingController(text: initialValue) : null),
      onChanged: onChanged,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryBlue),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(18),
      ),
    );
  }

  Widget _buildModernDateField(TextEditingController controller, String label, {Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final initialDate = DateFormat('dd/MM/yyyy').tryParse(controller.text) ?? DateTime.now();
        final d = await showDatePicker(
          context: context, 
          initialDate: initialDate, 
          firstDate: DateTime(2020), 
          lastDate: DateTime(2100)
        );
        if (d != null) {
          final formatted = DateFormat('dd/MM/yyyy').format(d);
          setState(() => controller.text = formatted);
          if (onChanged != null) onChanged(formatted);
        }
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_month_rounded, size: 20, color: AppTheme.primaryBlue),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(18),
      ),
    );
  }

  Widget _buildDureeToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppTheme.glassBorder.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.timer_outlined, color: AppTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 16),
          const Text('Contrat à durée déterminée ?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const Spacer(),
          Switch.adaptive(value: _isDeterminee, activeTrackColor: AppTheme.primaryBlue, onChanged: (v) => setState(() => _isDeterminee = v)),
          if (_isDeterminee) ...[
            const SizedBox(width: 20),
            SizedBox(
              width: 120, 
              child: _buildModernField(_dureeContrat, 'Mois', Icons.numbers, isNumeric: true)
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServicePicker() {
    return Wrap(
      spacing: 12, runSpacing: 12,
      children: _allTypeTraitements.map((t) {
        bool selected = _selectedTreatments.contains(t.id);
        return InkWell(
          onTap: () => setState(() => selected ? _selectedTreatments.remove(t.id) : _selectedTreatments.add(t.id!)),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primaryBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? AppTheme.primaryBlue : Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, size: 18, color: selected ? Colors.white : Colors.grey),
                const SizedBox(width: 10),
                Text(t.type, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: selected ? Colors.white : null)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFrequencyGrid(int tId) {
    final frequencies = [
      {'label': 'Hebdomadaire', 'value': -1, 'icon': Icons.repeat_rounded},
      {'label': '2 fois / semaine', 'value': -3, 'icon': Icons.flash_on_rounded},
      {'label': '3 fois / semaine', 'value': -4, 'icon': Icons.auto_awesome_rounded},
      {'label': 'Toutes les 2 semaines', 'value': -2, 'icon': Icons.update_rounded},
      {'label': 'Mensuel', 'value': 1, 'icon': Icons.calendar_view_month_rounded},
      {'label': 'Bimestriel', 'value': 2, 'icon': Icons.exposure_plus_2_rounded},
      {'label': 'Trimestriel', 'value': 3, 'icon': Icons.date_range_rounded},
      {'label': 'Semestriel', 'value': 6, 'icon': Icons.event_note_rounded},
      {'label': 'Annuel', 'value': 12, 'icon': Icons.event_available_rounded},
      {'label': 'Une seule fois', 'value': 0, 'icon': Icons.looks_one_rounded},
    ];
    int current = _treatmentConfig[tId]!['redondance'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: frequencies.map((f) {
        bool active = current == f['value'];
        return SizedBox(
          width: 175, // Largeur adaptée pour 10 items sur Desktop
          child: InkWell(
            onTap: () => setState(() => _treatmentConfig[tId]!['redondance'] = f['value']),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                color: active ? AppTheme.primaryBlue : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: active ? AppTheme.primaryBlue : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
              child: Column(
                children: [
                  Icon(f['icon'] as IconData, color: active ? Colors.white : AppTheme.primaryBlue, size: 24),
                  const SizedBox(height: 10),
                  Text(
                    f['label'] as String, 
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: 11, 
                      color: active ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      letterSpacing: 0.5
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildClientExtraParams() {
    return DropdownButtonFormField<String>(
      initialValue: _clientAxe.text,
      decoration: InputDecoration(
        labelText: 'Axe Géographique', 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        prefixIcon: const Icon(Icons.map_outlined, color: AppTheme.primaryBlue, size: 20),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05),
      ),
      items: ['Nord (N)', 'Sud (S)', 'Est (E)', 'Ouest (O)', 'Centre (C)'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: (v) => setState(() => _clientAxe.text = v!),
    );
  }

  Widget _buildCategoryPicker() {
    final categories = [
      {'label': 'Particulier', 'icon': Icons.person_rounded},
      {'label': 'Organisation', 'icon': Icons.account_balance_rounded},
      {'label': 'Société', 'icon': Icons.business_rounded},
    ];
    final current = _clientCategorie.text;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: categories.map((c) {
        bool active = current == c['label'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: InkWell(
              onTap: () => setState(() => _clientCategorie.text = c['label'] as String),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: active ? AppTheme.primaryBlue : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: active ? AppTheme.primaryBlue : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2)),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(c['icon'] as IconData, color: active ? Colors.white : AppTheme.primaryBlue, size: 28),
                    const SizedBox(height: 12),
                    Text(
                      c['label'] as String, 
                      style: TextStyle(
                        fontWeight: FontWeight.w900, 
                        fontSize: 13, 
                        color: active ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        letterSpacing: 0.5
                      )
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_mainStep > 0) 
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  if (_mainStep == 2 && _treatmentIndex > 0) {
                    _treatmentIndex--;
                    _treatmentDateController.text = _treatmentConfig[_selectedTreatments[_treatmentIndex]]!['debut'];
                  } else {
                    _mainStep--;
                    if (_mainStep == 2) {
                      _treatmentIndex = _selectedTreatments.length - 1;
                      _treatmentDateController.text = _treatmentConfig[_selectedTreatments[_treatmentIndex]]!['debut'];
                    }
                  }
                });
              }, 
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16), 
              label: const Text('PRÉCÉDENT'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20)),
            )
          else const SizedBox(),
          
          FilledButton.icon(
            onPressed: _isSaving ? null : _handleNext,
            icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(_mainStep == 3 ? Icons.check_circle_outline_rounded : Icons.arrow_forward_ios_rounded, size: 18),
            label: Text(_mainStep == 3 ? 'ENREGISTRER LE CONTRAT' : 'CONTINUER'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20), backgroundColor: _mainStep == 3 ? Colors.green : AppTheme.primaryBlue),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    if (_mainStep == 0) {
      if (_numeroContrat.text.isEmpty || _selectedTreatments.isEmpty) {
        AppSnackBars.showError(context, 'Veuillez remplir la référence et choisir au moins un service.');
        return;
      }
    }
    if (_mainStep == 1) {
      if (_clientNom.text.isEmpty) {
        AppSnackBars.showError(context, 'Le nom du client est obligatoire.');
        return;
      }
    }
    if (_mainStep == 2) {
      if (_treatmentIndex < _selectedTreatments.length - 1) {
        setState(() {
          _treatmentIndex++;
          _treatmentDateController.text = _treatmentConfig[_selectedTreatments[_treatmentIndex]]!['debut'];
        });
        return;
      }
    }

    if (_mainStep < 3) {
      setState(() {
        _mainStep++;
        if (_mainStep == 2) {
          _treatmentIndex = 0;
          if (_selectedTreatments.isNotEmpty) {
            final tId = _selectedTreatments[0];
            if (!_treatmentConfig.containsKey(tId)) {
              _treatmentConfig[tId] = {'redondance': 1, 'montant': '', 'debut': _dateDebut.text};
            }
            _treatmentDateController.text = _treatmentConfig[tId]!['debut'];
          }
        }
      });
      _saveProgress();
    } else {
      _finalSave();
    }
  }

  Future<void> _finalSave() async {
    setState(() => _isSaving = true);
    try {
      final clientRepo = context.read<ClientRepository>();
      final contratRepo = context.read<ContratRepository>();
      final planningRepo = context.read<PlanningRepository>();
      final detailsRepo = context.read<PlanningDetailsRepository>();
      final factureRepo = context.read<FactureRepository>();

      // 1. Créer le client
      final newClient = Client(
        clientId: 0, nom: _clientNom.text, prenom: _clientPrenom.text,
        email: _clientEmail.text, 
        telephone: PhoneFormatter.join(_clientPhoneControllers.map((c) => c.text).toList()),
        adresse: _clientAdresse.text, nif: _clientNif.text, stat: _clientStat.text,
        categorie: _clientCategorie.text,
        axe: _clientAxe.text, dateAjout: DateTime.now(),
      );
      final cId = await clientRepo.createClient(newClient);

      // 2. Créer le contrat
      final dateC = DateFormat('dd/MM/yyyy').parse(_dateContrat.text);
      final dateD = DateFormat('dd/MM/yyyy').parse(_dateDebut.text);
      DateTime? dateF;
      int duree = int.tryParse(_dureeContrat.text) ?? 12;
      if (_isDeterminee) {
        dateF = DateTime(dateD.year, dateD.month + duree, dateD.day);
      }

      final contratId = await contratRepo.createContrat(
        clientId: cId, referenceContrat: _numeroContrat.text,
        dateContrat: dateC, dateDebut: dateD, dateFin: dateF,
        statutContrat: 'Actif', duree: duree,
        categorie: _categorieContrat.text, dureeStatus: _isDeterminee ? 'Déterminée' : 'Indéterminée',
      );

      // 3. Créer les traitements et plannings
      for (final tId in _selectedTreatments) {
        final traitId = await contratRepo.createTraitement(contratId: contratId, typeTraitementId: tId);
        final config = _treatmentConfig[tId]!;
        final treatmentStartDate = DateFormat('dd/MM/yyyy').parse(config['debut']);
        
        final planningId = await planningRepo.createPlanning(
          traitementId: traitId, 
          dateDebutPlanification: treatmentStartDate,
          moisDebut: treatmentStartDate.month, 
          dureeTraitement: duree, 
          redondance: config['redondance'],
        );

        final dates = date_utils.DateUtils.generatePlanningDates(
          dateDebut: treatmentStartDate, 
          dureeTraitement: duree, 
          redondance: config['redondance'],
        );

        for (final d in dates) {
          final detail = await detailsRepo.createPlanningDetails(planningId, d);
          if (detail != null) {
            await factureRepo.createFactureComplete(
              planningDetailId: detail.planningDetailId, referenceFacture: '',
              montant: int.tryParse(config['montant'].toString().replaceAll(' ', '')) ?? 0,
              etat: 'À venir', axe: _clientAxe.text, dateTraitement: d,
            );
          }
        }
      }

      await _clearSavedProgress();
      if (mounted) {
        Navigator.pop(context, true);
        AppSnackBars.showSuccess(context, 'Contrat créé avec succès !');
      }
    } catch (e) {
      if (mounted) AppSnackBars.showError(context, 'Erreur lors de l\'enregistrement : $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
