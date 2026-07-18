import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../services/database_service.dart';
import '../../../widgets/app_dialogs.dart';

class ProfileListDialog extends StatelessWidget {
  const ProfileListDialog({super.key});

  static void show(BuildContext context) {
    AppDialogs.showBlurDialog(
      context: context,
      builder: (ctx) => const ProfileListDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Liste des profils'),
      contentPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchAllProfiles(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
              if (snapshot.hasError) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 32, color: Colors.red), const SizedBox(height: 8), Text('Erreur: ${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))]));

              final profiles = snapshot.data ?? [];
              if (profiles.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Aucun profil trouvé')));

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: profiles.map((profile) {
                  final isAdmin = profile['type_compte'] == 'Administrateur';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: isAdmin ? Colors.blue[50] : Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: isAdmin ? Colors.blue[300]! : Colors.grey[300]!)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('${profile['nom'] ?? ''} ${profile['prenom'] ?? ''}'.trim(), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isAdmin ? Colors.blue[900] : Colors.black87))),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isAdmin ? AppTheme.successGreen : AppTheme.primaryBlue, borderRadius: BorderRadius.circular(12)), child: Text(isAdmin ? 'Admin' : 'Utilisateur', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Email: ${profile['email'] ?? 'N/A'}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        Text('ID: ${profile['id_compte'] ?? 'N/A'}', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'monospace')),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
      actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer'))],
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllProfiles() async {
    return await DatabaseService().query('SELECT id_compte, nom, prenom, email, type_compte FROM Account ORDER BY nom, prenom ASC');
  }
}
