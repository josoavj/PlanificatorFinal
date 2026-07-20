import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/index.dart';
import '../../repositories/index.dart';
import '../../utils/app_snackbars.dart';
import '../../widgets/index.dart';
import '../../core/theme.dart';
import '../../utils/nif_stat_formatter.dart';
import '../../utils/phone_formatter.dart';
import '../../widgets/common/multi_phone_input.dart';

class ClientDetailScreen extends StatefulWidget {
  final int clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  late Client? _client;
  bool _isEditing = false;

  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late List<TextEditingController> _phoneControllers;
  late TextEditingController _adresseController;
  late TextEditingController _categorieController;
  late TextEditingController _nifController;
  late TextEditingController _statController;
  late TextEditingController _axeController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadClient();
  }

  void _initializeControllers() {
    _nomController = TextEditingController();
    _prenomController = TextEditingController();
    _emailController = TextEditingController();
    _phoneControllers = [TextEditingController()];
    _adresseController = TextEditingController();
    _categorieController = TextEditingController();
    _nifController = TextEditingController();
    _statController = TextEditingController();
    _axeController = TextEditingController();
  }

  void _loadClient() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientRepository>().loadClient(widget.clientId);
    });
  }

  void _updateControllers(Client client) {
    _nomController.text = client.nom;
    _prenomController.text = client.prenom;
    _emailController.text = client.email;
    final List<String> tels = PhoneFormatter.split(client.telephone);
    _phoneControllers = tels.map((t) => TextEditingController(text: t)).toList();
    if (_phoneControllers.isEmpty) _phoneControllers.add(TextEditingController());
    _adresseController.text = client.adresse;
    _categorieController.text = client.categorie;
    _nifController.text = client.nif;
    _statController.text = client.stat;
    _axeController.text = client.axe;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_isEditing,
      onPopInvokedWithResult: (didPop, result) async {
        if (_isEditing && !didPop) {
          final confirmed = await AppDialogs.confirm(
            context,
            title: 'Abandon des modifications',
            message: 'Êtes-vous sûr de vouloir abandonner vos modifications ?',
            confirmText: 'Oui, quitter',
            cancelText: 'Non, continuer',
          );
          if (confirmed == true && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        body: Consumer<ClientRepository>(
          builder: (context, repository, _) {
            _client = repository.currentClient;

            if (repository.isLoading) {
              return const LoadingWidget();
            }

            if (repository.errorMessage != null) {
              return ErrorDisplayWidget(
                message: repository.errorMessage!,
                onRetry: _loadClient,
              );
            }

            if (_client == null) {
              return const EmptyStateWidget(
                title: 'Client non trouvé',
                message: 'Le client demandé n\'existe pas',
              );
            }

            if (!_isEditing) {
              _updateControllers(_client!);
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  if (!_isEditing) ...[
                    _buildHeader(context, _client!, isDark),
                    const SizedBox(height: 70),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: _buildViewMode(context, _client!),
                      ),
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildEditMode(),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Client client, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 230,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainer : AppTheme.primaryBlue,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(48)),
          ),
        ),
        // Bouton Retour en haut à gauche (Simplifié)
        Positioned(
          top: 40,
          left: 8,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
          ),
        ),
        // Menu Actions en haut à droite
        Positioned(
          top: 40,
          right: 8,
          child: Consumer<AuthRepository>(
            builder: (context, auth, _) {
              return Theme(
                data: Theme.of(context).copyWith(
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                child: PopupMenuButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Éditer le profil'),
                        ],
                      ),
                      onTap: () {
                        setState(() => _isEditing = true);
                      },
                    ),
                    if (auth.isAdmin)
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.delete_rounded, size: 18, color: AppTheme.errorRed),
                            SizedBox(width: 8),
                            Text(
                              'Supprimer le client',
                              style: TextStyle(color: AppTheme.errorRed),
                            ),
                          ],
                        ),
                        onTap: () => _deleteClient(),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 60,
          child: Column(
            children: [
              Text(
                client.fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.category_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      client.categorie.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -45,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBg : Colors.white,
              shape: BoxShape.circle,
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: AppTheme.primaryBlue,
              child: Text(
                client.fullName.isNotEmpty ? client.fullName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewMode(BuildContext context, Client client) {
    final List<String> tels = PhoneFormatter.split(client.telephone);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informations de contact
        AppSection(
          title: 'Coordonnées de contact',
          margin: EdgeInsets.zero,
          children: [
            AppInfoTile(icon: Icons.email_outlined, label: 'Adresse Email', value: client.email),
            ...tels.asMap().entries.map((e) => AppInfoTile(
              icon: Icons.phone_outlined, 
              label: e.key == 0 ? 'Téléphone' : 'Téléphone ${e.key + 1}', 
              value: PhoneFormatter.format(e.value),
            )),
            AppInfoTile(icon: Icons.location_on_outlined, label: 'Adresse physique', value: client.adresse),
          ],
        ),
        const SizedBox(height: 24),

        // Informations professionnelles
        AppSection(
          title: 'Détails Professionnels',
          margin: EdgeInsets.zero,
          children: [
            AppInfoTile(icon: Icons.business_center_outlined, label: 'Catégorie', value: client.categorie),
            AppInfoTile(icon: Icons.description_outlined, label: 'NIF', value: NifStatFormatter.formatNif(client.nif)),
            AppInfoTile(icon: Icons.badge_outlined, label: 'STAT', value: NifStatFormatter.formatStat(client.stat)),
            AppInfoTile(icon: Icons.map_outlined, label: 'Axe / Secteur', value: client.axe),
          ],
        ),
        const SizedBox(height: 32),

        // Actions rapides
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToFactures(context, client.clientId),
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('Voir factures', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToContrats(context, client.clientId),
                icon: const Icon(Icons.assignment_rounded),
                label: const Text('Voir contrats', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildEditMode() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _isEditing = false),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              const SizedBox(width: 8),
              Text(
                'Éditer le client',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nomController,
            decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(Icons.person_outline)),
            validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _prenomController,
            decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.person_outline)),
            validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildModernField(_emailController, 'Email de contact', Icons.alternate_email_rounded),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _axeController.text,
                  decoration: InputDecoration(
                    labelText: 'Axe Géographique', 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    prefixIcon: const Icon(Icons.map_outlined, color: AppTheme.primaryBlue, size: 20),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05),
                  ),
                  items: ['Nord (N)', 'Sud (S)', 'Est (E)', 'Ouest (O)', 'Centre (C)'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _axeController.text = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          MultiPhoneInput(
            controllers: _phoneControllers, 
            onAdd: () => setState(() => _phoneControllers.add(TextEditingController())), 
            onRemove: (idx) => setState(() => _phoneControllers.removeAt(idx)),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _adresseController,
            decoration: const InputDecoration(labelText: 'Adresse', prefixIcon: Icon(Icons.location_on_outlined)),
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _categorieController,
            decoration: const InputDecoration(labelText: 'Catégorie', prefixIcon: Icon(Icons.category_outlined)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nifController,
            inputFormatters: [NifInputFormatter()],
            decoration: const InputDecoration(labelText: 'NIF', prefixIcon: Icon(Icons.description_outlined)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _statController,
            inputFormatters: [StatInputFormatter()],
            decoration: const InputDecoration(labelText: 'STAT', prefixIcon: Icon(Icons.badge_outlined)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _axeController,
            decoration: const InputDecoration(labelText: 'Axe', prefixIcon: Icon(Icons.map_outlined)),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isEditing = false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveClient,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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

  void _saveClient() {
    if (_formKey.currentState!.validate()) {
      final updated = _client!.copyWith(
        nom: _nomController.text,
        prenom: _prenomController.text,
        email: _emailController.text,
        telephone: PhoneFormatter.join(_phoneControllers.map((c) => c.text).toList()),
        adresse: _adresseController.text,
        categorie: _categorieController.text,
        nif: _nifController.text,
        stat: _statController.text,
        axe: _axeController.text,
      );

      context
          .read<ClientRepository>()
          .updateClient(updated)
          .then((_) {
            if (mounted) {
              setState(() => _isEditing = false);
              AppSnackBars.showSuccess(context, 'Client modifié avec succès');
            }
          })
          .catchError((error) {
            if (mounted) {
              AppSnackBars.showError(context, error.toString());
            }
          });
    }
  }

  void _deleteClient() async {
    final authRepo = context.read<AuthRepository>();
    if (!authRepo.isAdmin) {
      AppSnackBars.showError(context, 'Droits administrateur requis');
      return;
    }

    final confirmed = await AppDialogs.confirmDelete(context);
    if (confirmed == true && mounted) {
      final nav = Navigator.of(context);
      context
          .read<ClientRepository>()
          .deleteClient(_client!.clientId, isAdmin: authRepo.isAdmin)
          .then((success) {
            if (mounted && success) {
              nav.pop(true);
              AppSnackBars.showSuccess(context, 'Client supprimé');
            }
          })
          .catchError((error) {
            if (mounted) {
              AppSnackBars.showError(context, error.toString());
            }
          });
    }
  }

  void _navigateToFactures(BuildContext context, int clientId) {
    context.read<FactureRepository>().loadFacturesForClient(clientId);
    Navigator.of(context).pushNamed('/factures');
  }

  void _navigateToContrats(BuildContext context, int clientId) {
    Navigator.of(context).pushNamed('/contrats');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    for (var c in _phoneControllers) {
      c.dispose();
    }
    _adresseController.dispose();
    _categorieController.dispose();
    _nifController.dispose();
    _statController.dispose();
    _axeController.dispose();
    super.dispose();
  }
}
