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
  bool _showSavedIndicator = false;
  Timer? _savedTimer;
  final ScrollController _scrollController = ScrollController();

  // Controllers Contrat
  final _numeroContrat = TextEditingController();
  final _dateContrat = TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
  final _dateDebut = TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
  final _dateFin = TextEditingController();
  final _categorieContrat = TextEditingController(text: 'Nouveau');
  final _dureeContrat = TextEditingController(text: '12');
  bool _isDeterminee = true;
  bool _groupInvoices = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTypeTraitements();
      _checkForSavedProgress();
    });
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
    _scrollController.dispose();
    _savedTimer?.cancel();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
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
      'groupInvoices': _groupInvoices,
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
    
    // Feedback visuel
    setState(() => _showSavedIndicator = true);
    _savedTimer?.cancel();
    _savedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSavedIndicator = false);
    });
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
        _groupInvoices = data['groupInvoices'] ?? false;
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

  /// Garantit que la configuration d'un service est initialisée avec des valeurs par défaut
  void _ensureTreatmentConfig(int tId) {
    if (!_treatmentConfig.containsKey(tId)) {
      _treatmentConfig[tId] = {
        'redondance': 1,
        'montant': '',
        'debut': _dateDebut.text,
        'mode': 'monthly'
      };
    } else {
      // Compléter si des clés manquent
      if (!_treatmentConfig[tId]!.containsKey('mode')) {
        _treatmentConfig[tId]!['mode'] = 'monthly';
      }
      if (!_treatmentConfig[tId]!.containsKey('debut')) {
        _treatmentConfig[tId]!['debut'] = _dateDebut.text;
      }
    }
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
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: _buildCurrentStep(),
                ),
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
          const SizedBox(width: 24),
          if (_showSavedIndicator)
            AnimatedOpacity(
              opacity: _showSavedIndicator ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 14),
                    SizedBox(width: 8),
                    Text(
                      'PROGRESSION ENREGISTRÉE',
                      style: TextStyle(color: AppTheme.successGreen, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
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
      _treatmentConfig[tId] = {
        'redondance': 1, 
        'montant': '', 
        'debut': _dateDebut.text,
        'mode': 'monthly' 
      };
    } else {
      // Sécurité si l'entrée existait déjà sans certains champs
      if (!_treatmentConfig[tId]!.containsKey('mode')) {
        _treatmentConfig[tId]!['mode'] = 'monthly';
      }
      if (!_treatmentConfig[tId]!.containsKey('redondance')) {
        _treatmentConfig[tId]!['redondance'] = 1;
      }
      if (!_treatmentConfig[tId]!.containsKey('debut')) {
        _treatmentConfig[tId]!['debut'] = _dateDebut.text;
      }
    }
    
    final String currentMode = _treatmentConfig[tId]!['mode'] ?? 'monthly';

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
        
        // SÉLECTEUR DE MODE (MENSUEL VS HEBDO) - Format Compact
        AppSection(
          title: 'Type de planification',
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Row(
              children: [
                _buildModeCard(
                  label: 'MENSUELLE / UNIQUE', 
                  icon: Icons.calendar_month_rounded, 
                  isActive: currentMode == 'monthly',
                  onTap: () => setState(() {
                    _treatmentConfig[tId]!['mode'] = 'monthly';
                    _treatmentConfig[tId]!['redondance'] = 1;
                  }),
                ),
                const SizedBox(width: 12),
                _buildModeCard(
                  label: 'HEBDOMADAIRE', 
                  icon: Icons.view_week_rounded, 
                  isActive: currentMode == 'weekly',
                  onTap: () => setState(() {
                    _treatmentConfig[tId]!['mode'] = 'weekly';
                    _treatmentConfig[tId]!['redondance'] = -1;
                  }),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 24),
        
        // SECTION FRÉQUENCE (ANIMÉE)
        AppSection(
          title: 'Détails de passage',
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
              'CHOISISSEZ LE RYTHME PRÉCIS',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.02, 0), 
                      end: Offset.zero
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildFrequencyGrid(tId, currentMode),
            ),
          ],
        ),
        
        // SECTION FACTURATION
        AppSection(
          title: 'Conditions financières',
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(24),
          children: [
            _buildGroupingToggle(),
            const SizedBox(height: 24),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cat = _clientCategorie.text;
    final isParticular = cat == 'Particulier';
    final isSociety = cat == 'Société';
    final duree = int.tryParse(_dureeContrat.text) ?? 12;

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

    // Calculs financiers globaux
    int grandTotal = 0;
    int totalPassages = 0;
    final List<Map<String, dynamic>> serviceDetails = [];

    for (final tId in _selectedTreatments) {
      final type = _allTypeTraitements.firstWhereOrNull((t) => t.id == tId);
      final config = _treatmentConfig[tId] ?? {};
      final int redondance = config['redondance'] ?? 1;
      final String debutStr = config['debut'] ?? _dateDebut.text;
      final treatmentStartDate = DateFormat('dd/MM/yyyy').parse(debutStr);
      final int montantUnitaire = int.tryParse(config['montant'].toString().replaceAll(' ', '')) ?? 0;

      final dates = date_utils.DateUtils.generatePlanningDates(
        dateDebut: treatmentStartDate, 
        dureeTraitement: duree, 
        redondance: redondance,
      );

      final int totalService = dates.length * montantUnitaire;
      grandTotal += totalService;
      totalPassages += dates.length;

      serviceDetails.add({
        'name': type?.type ?? 'Service inconnu',
        'rythme': _getFrequencyLabel(redondance),
        'debut': debutStr,
        'unitaire': montantUnitaire,
        'count': dates.length,
        'total': totalService,
      });
    }

    return Column(
      children: [
        // 1. IDENTITÉ ET CONTACTS
        AppSection(
          title: 'Identification du Client',
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(24),
          showDividers: false,
          children: [
            Row(
              children: [
                Expanded(child: AppInfoTile(icon: Icons.person_rounded, label: entityLabel, value: clientDisplay)),
                Expanded(child: AppInfoTile(icon: Icons.category_outlined, label: 'Catégorie', value: cat)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: AppInfoTile(icon: Icons.alternate_email_rounded, label: 'Email de contact', value: _clientEmail.text)),
                Expanded(child: AppInfoTile(icon: Icons.phone_android_rounded, label: 'Téléphone(s)', value: _clientPhoneControllers.map((c) => c.text).where((t) => t.isNotEmpty).join(' / '))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: AppInfoTile(icon: Icons.location_on_outlined, label: 'Adresse complète', value: _clientAdresse.text)),
                Expanded(child: AppInfoTile(icon: Icons.map_outlined, label: 'Axe / Secteur', value: _clientAxe.text)),
              ],
            ),
            if (isSociety) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: AppInfoTile(icon: Icons.description_outlined, label: 'NIF', value: NifStatFormatter.formatNif(_clientNif.text))),
                  Expanded(child: AppInfoTile(icon: Icons.badge_outlined, label: 'STAT', value: NifStatFormatter.formatStat(_clientStat.text))),
                ],
              ),
            ],
          ],
        ),

        const SizedBox(height: 32),

        // 2. RÉFÉRENCE CONTRAT
        AppSection(
          title: 'Détails du Contrat',
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(24),
          showDividers: false,
          children: [
            Row(
              children: [
                Expanded(child: AppInfoTile(icon: Icons.tag_rounded, label: 'Référence', value: _numeroContrat.text)),
                Expanded(child: AppInfoTile(icon: Icons.event_note_rounded, label: 'Signature', value: _dateContrat.text)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: AppInfoTile(icon: Icons.play_circle_outline_rounded, label: 'Début prestation', value: _dateDebut.text)),
                Expanded(child: AppInfoTile(icon: Icons.timer_outlined, label: 'Durée prévue', value: _isDeterminee ? '$duree mois' : 'Indéterminée')),
              ],
            ),
          ],
        ),

        const SizedBox(height: 32),

        // 3. SERVICES DÉTAILLÉS (EXTENSIBLES)
        AppSection(
          title: 'Prestations et Planification (${_selectedTreatments.length})',
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(vertical: 8),
          showDividers: false,
          children: [
            ...serviceDetails.map((s) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Material(
                color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.assignment_rounded, color: AppTheme.primaryBlue, size: 20),
                    ),
                    title: Text(
                      s['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${s['count']} passages prévus',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey[600]),
                    ),
                    trailing: Text(
                      '${NumberFormatter.formatMontant(s['total'] as int)} Ar',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(60, 0, 24, 20),
                    children: [
                      _buildSummaryRowCompact('Rythme de passage', s['rythme'] as String),
                      _buildSummaryRowCompact('Premier passage', s['debut'] as String),
                      _buildSummaryRowCompact('Coût unitaire', '${NumberFormatter.formatMontant(s['unitaire'] as int)} Ar'),
                      const SizedBox(height: 8),
                      Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
                      const SizedBox(height: 8),
                      _buildSummaryRowCompact('Total service', '${NumberFormatter.formatMontant(s['total'] as int)} Ar'),
                    ],
                  ),
                ),
              ),
            )),
          ],
        ),

        const SizedBox(height: 32),

        // 4. RÉSUMÉ FINANCIER GLOBAL
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                ? [AppTheme.primaryDark, AppTheme.primaryDark.withValues(alpha: 0.7)]
                : [AppTheme.primaryBlue, AppTheme.primaryBlue.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL GÉNÉRAL ESTIMÉ',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  Text(
                    '$totalPassages INTERVENTIONS',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Montant du contrat',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${NumberFormatter.formatMontant(grandTotal)} Ar',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Veuillez vérifier les informations ci-dessus avant de confirmer l\'enregistrement.',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRowCompact(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  String _getFrequencyLabel(int redondance) {
    switch (redondance) {
      case 0: return 'Une seule fois';
      case 1: return 'Mensuel';
      case 2: return 'Bimestriel';
      case 3: return 'Trimestriel';
      case 6: return 'Semestriel';
      case 12: return 'Annuel';
      case -1: return 'Hebdomadaire';
      case -2: return 'Toutes les 2 semaines';
      case -3: return '2 fois / semaine';
      case -4: return '3 fois / semaine';
      default: return 'Fréquence personnalisée';
    }
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

  Widget _buildFrequencyGrid(int tId, String mode) {
    final allFrequencies = [
      {'label': 'Une seule fois', 'value': 0, 'icon': Icons.looks_one_rounded, 'mode': 'both'},
      {'label': 'Mensuel', 'value': 1, 'icon': Icons.calendar_view_month_rounded, 'mode': 'monthly'},
      {'label': 'Bimestriel', 'value': 2, 'icon': Icons.exposure_plus_2_rounded, 'mode': 'monthly'},
      {'label': 'Trimestriel', 'value': 3, 'icon': Icons.date_range_rounded, 'mode': 'monthly'},
      {'label': 'Semestriel', 'value': 6, 'icon': Icons.event_note_rounded, 'mode': 'monthly'},
      {'label': 'Annuel', 'value': 12, 'icon': Icons.event_available_rounded, 'mode': 'monthly'},
      
      {'label': 'Hebdomadaire', 'value': -1, 'icon': Icons.repeat_rounded, 'mode': 'weekly'},
      {'label': '2 fois / semaine', 'value': -3, 'icon': Icons.flash_on_rounded, 'mode': 'weekly'},
      {'label': '3 fois / semaine', 'value': -4, 'icon': Icons.auto_awesome_rounded, 'mode': 'weekly'},
      {'label': 'Toutes les 2 semaines', 'value': -2, 'icon': Icons.update_rounded, 'mode': 'weekly'},
    ];

    final frequencies = allFrequencies.where((f) => f['mode'] == mode || f['mode'] == 'both').toList();
    int current = _treatmentConfig[tId]!['redondance'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      key: ValueKey(mode), // Crucial pour AnimatedSwitcher
      spacing: 12,
      runSpacing: 12,
      children: frequencies.map((f) {
        bool active = current == f['value'];
        return SizedBox(
          width: 175, 
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
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
                  boxShadow: active && !isDark ? [
                    BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))
                  ] : [],
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
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModeCard({
    required String label, 
    required IconData icon, 
    required bool isActive, 
    required VoidCallback onTap
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 16), // Hauteur réduite
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryBlue : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? AppTheme.primaryBlue : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15)),
                width: 1.2,
              ),
            ),
            child: Row( // Row au lieu de Column pour plus de compacité
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isActive ? Colors.white : AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    fontSize: 11, 
                    letterSpacing: 0.8,
                    color: isActive ? Colors.white : (isDark ? Colors.white70 : Colors.black87)
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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


  Widget _buildGroupingToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _groupInvoices 
            ? AppTheme.primaryBlue.withValues(alpha: 0.1) 
            : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _groupInvoices 
              ? AppTheme.primaryBlue 
              : (isDark ? AppTheme.glassBorder.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _groupInvoices ? AppTheme.primaryBlue : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _groupInvoices ? Icons.inventory_2_rounded : Icons.receipt_long_rounded, 
              color: Colors.white, 
              size: 20
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Facturation groupée par passage', 
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)
                ),
                Text(
                  'Une seule facture pour tous les services du même jour', 
                  style: TextStyle(fontSize: 10, color: Colors.grey)
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _groupInvoices, 
            activeTrackColor: AppTheme.primaryBlue, 
            onChanged: (v) => setState(() => _groupInvoices = v)
          ),
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
                    final tId = _selectedTreatments[_treatmentIndex];
                    _ensureTreatmentConfig(tId);
                    _treatmentDateController.text = _treatmentConfig[tId]!['debut'];
                  } else {
                    _mainStep--;
                    if (_mainStep == 2) {
                      _treatmentIndex = _selectedTreatments.length - 1;
                      final tId = _selectedTreatments[_treatmentIndex];
                      _ensureTreatmentConfig(tId);
                      _treatmentDateController.text = _treatmentConfig[tId]!['debut'];
                    }
                  }
                });
                _scrollToTop();
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
          final tId = _selectedTreatments[_treatmentIndex];
          _ensureTreatmentConfig(tId);
          _treatmentDateController.text = _treatmentConfig[tId]!['debut'];
        });
        _scrollToTop();
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
            _ensureTreatmentConfig(tId);
            _treatmentDateController.text = _treatmentConfig[tId]!['debut'];
          }
        }
      });
      _scrollToTop();
      _saveProgress();
    } else {
      _finalSave();
    }
  }

  Future<void> _finalSave() async {
    setState(() => _isSaving = true);
    try {
      final contratRepo = context.read<ContratRepository>();

      // Préparation du client
      final client = Client(
        clientId: 0, 
        nom: _clientNom.text, 
        prenom: _clientPrenom.text,
        email: _clientEmail.text, 
        telephone: PhoneFormatter.join(_clientPhoneControllers.map((c) => c.text).toList()),
        adresse: _clientAdresse.text, 
        nif: _clientNif.text, 
        stat: _clientStat.text,
        categorie: _clientCategorie.text,
        axe: _clientAxe.text, 
        dateAjout: DateTime.now(),
      );

      // Dates et Durée
      final dateC = DateFormat('dd/MM/yyyy').parse(_dateContrat.text);
      final dateD = DateFormat('dd/MM/yyyy').parse(_dateDebut.text);
      int duree = int.tryParse(_dureeContrat.text) ?? 12;
      DateTime? dateF = _isDeterminee ? DateTime(dateD.year, dateD.month + duree, dateD.day) : null;

      // APPEL À LA TRANSACTION UNIQUE
      final success = await contratRepo.saveFullContratTransaction(
        client: client, 
        referenceContrat: _numeroContrat.text, 
        dateContrat: dateC, 
        dateDebut: dateD, 
        dateFin: dateF,
        statutContrat: 'Actif', 
        duree: duree, 
        categorieContrat: _categorieContrat.text, 
        dureeStatus: _isDeterminee ? 'Déterminée' : 'Indéterminée', 
        selectedTreatmentIds: _selectedTreatments, 
        treatmentConfigs: _treatmentConfig,
        groupInvoicesByDate: _groupInvoices,
      );

      if (success && mounted) {
        await _clearSavedProgress();
        Navigator.pop(context, true);
        AppSnackBars.showSuccess(context, 'Contrat complet créé avec succès (Transaction OK)');
        // Recharger les listes si nécessaire (fait par le caller via le Navigator.pop(true))
      } else if (mounted) {
        AppSnackBars.showError(context, 'Échec de l\'enregistrement : ${contratRepo.errorMessage ?? 'Erreur inconnue'}');
      }
    } catch (e) {
      if (mounted) AppSnackBars.showError(context, 'Erreur technique : $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
