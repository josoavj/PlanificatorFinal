import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/client.dart';
import '../../../repositories/index.dart';
import '../../../utils/app_snackbars.dart';
import '../../../widgets/index.dart';
import '../../../core/theme.dart';
import '../../../utils/nif_stat_formatter.dart';
import '../../../utils/phone_formatter.dart';
import '../../../widgets/common/multi_phone_input.dart';
import 'client_details_dialog.dart';

class ClientEditDialog extends StatefulWidget {
  final Client client;
  final VoidCallback onDataChanged;

  const ClientEditDialog({
    super.key,
    required this.client,
    required this.onDataChanged,
  });

  static void show(BuildContext context, Client client, VoidCallback onDataChanged) {
    AppDialogs.showBlurDialog(
      context: context,
      builder: (ctx) => ClientEditDialog(
        client: client,
        onDataChanged: onDataChanged,
      ),
    );
  }

  @override
  State<ClientEditDialog> createState() => _ClientEditDialogState();
}

class _ClientEditDialogState extends State<ClientEditDialog> {
  late TextEditingController nomController;
  late TextEditingController prenomController;
  late TextEditingController emailController;
  late List<TextEditingController> phoneControllers;
  late TextEditingController adresseController;
  late String selectedAxe;
  late String selectedCategorie;
  late TextEditingController nifController;
  late TextEditingController statController;

  @override
  void initState() {
    super.initState();
    nomController = TextEditingController(text: widget.client.nom);
    prenomController = TextEditingController(text: widget.client.prenom);
    emailController = TextEditingController(text: widget.client.email);
    
    final List<String> tels = PhoneFormatter.split(widget.client.telephone);
    phoneControllers = tels.map((t) => TextEditingController(text: t)).toList();
    if (phoneControllers.isEmpty) phoneControllers.add(TextEditingController());
    
    adresseController = TextEditingController(text: widget.client.adresse);
    selectedAxe = widget.client.axe;
    selectedCategorie = widget.client.categorie;
    nifController = TextEditingController(text: widget.client.nif);
    statController = TextEditingController(text: widget.client.stat);
  }

  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    emailController.dispose();
    for (var c in phoneControllers) {
      c.dispose();
    }
    adresseController.dispose();
    nifController.dispose();
    statController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier les informations du client'),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('INFORMATIONS PERSONNELLES'),
              _buildEditField('Nom', nomController),
              _buildEditField(
                selectedCategorie == 'Société' || selectedCategorie == 'Organisation'
                    ? 'Responsable' : 'Prénom',
                prenomController,
              ),
              Row(
                children: [
                  Expanded(child: _buildEditField('Email', emailController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildAxisDropdown((value) => setState(() => selectedAxe = value), selectedAxe)),
                ],
              ),
              const SizedBox(height: 8),
              MultiPhoneInput(
                title: 'Numéros de téléphone',
                controllers: phoneControllers, 
                onAdd: () => setState(() => phoneControllers.add(TextEditingController())), 
                onRemove: (idx) => setState(() => phoneControllers.removeAt(idx)),
              ),
              const SizedBox(height: 16),
              _buildEditField('Adresse', adresseController),
              const SizedBox(height: 16),

              _buildSectionHeader('CATÉGORIE & INFOS'),
              _buildCategoryDropdown((value) {
                setState(() {
                  selectedCategorie = value;
                  if (value == 'Particulier') {
                    nifController.clear();
                    statController.clear();
                  }
                });
              }, selectedCategorie),

              if (selectedCategorie == 'Société') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue[200]!)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Informations Fiscales', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700], fontSize: 13)),
                      const SizedBox(height: 12),
                      _buildEditField('NIF', nifController, inputFormatters: [NifInputFormatter()]),
                      _buildEditField('STAT', statController, inputFormatters: [StatInputFormatter()]),
                    ],
                  ),
                ),
              ],

              if (selectedCategorie == 'Organisation') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber[200]!)),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Les infos fiscales ne sont pas requises pour les organisations.', style: TextStyle(fontSize: 12, color: Colors.amber[700]))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            ClientDetailsDialog.show(context, widget.client, widget.onDataChanged);
          },
          child: const Text('ANNULER'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.save, size: 18),
          label: const Text('Enregistrer'),
          onPressed: () async {
            if (nomController.text.isNotEmpty && prenomController.text.isNotEmpty) {
              final updatedClient = Client(
                clientId: widget.client.clientId,
                nom: nomController.text,
                prenom: prenomController.text,
                email: emailController.text,
                telephone: PhoneFormatter.join(phoneControllers.map((c) => c.text).toList()),
                adresse: adresseController.text,
                categorie: selectedCategorie,
                nif: nifController.text,
                stat: statController.text,
                axe: selectedAxe,
                dateAjout: widget.client.dateAjout,
                treatmentCount: widget.client.treatmentCount,
              );

              await context.read<ClientRepository>().updateClient(updatedClient);
              await context.read<ClientRepository>().loadClients();
              widget.onDataChanged();
              if (mounted) {
                Navigator.of(context).pop();
                AppSnackBars.showSuccess(context, ' Client modifié avec succès');
              }
            } else {
              AppSnackBars.showWarning(context, ' Veuillez remplir les champs obligatoires');
            }
          },
        ),
      ],
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {List<TextInputFormatter>? inputFormatters}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller, 
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label, 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), 
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
        )
      ),
    );
  }

  Widget _buildAxisDropdown(Function(String) onChanged, String selectedValue) {
    final axes = ['Nord (N)', 'Sud (S)', 'Est (E)', 'Ouest (O)', 'Centre (C)'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      initialValue: selectedValue, 
      decoration: InputDecoration(
        labelText: 'Axe', 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)), 
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        prefixIcon: const Icon(Icons.map_outlined, color: AppTheme.primaryBlue, size: 20),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05),
      ), 
      items: axes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), 
      onChanged: (v) { if (v != null) onChanged(v); }
    );
  }

  Widget _buildCategoryDropdown(Function(String) onChanged, String selectedValue) {
    final categories = ['Particulier', 'Organisation', 'Société'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(initialValue: selectedValue, decoration: InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)), items: categories.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) { if (v != null) onChanged(v); }),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 12), child: Row(children: [
      Container(width: 4, height: 14, decoration: BoxDecoration(color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue)),
    ]));
  }
}
