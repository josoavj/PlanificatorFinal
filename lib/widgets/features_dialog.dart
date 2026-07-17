import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'app_dialogs.dart';

class FeaturesDialog {
  static void show(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppDialogs.showBlurDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: isDark ? AppTheme.darkBgSecondary : Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arsenal Planificator',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'La maîtrise au service de votre planning',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildFeatureGroup('Gestion & Contrats', [
                      _buildFeatureTile(
                        Icons.people_alt_outlined,
                        'Base Clients Intelligente',
                        'Catégorisation dynamique (Société/Particulier) et historique complet.',
                      ),
                      _buildFeatureTile(
                        Icons.assignment_outlined,
                        'Suivi des Contrats',
                        'Gestion des durées, des prix par axe et génération automatique des interventions.',
                      ),
                      _buildFeatureTile(
                        Icons.calendar_month_outlined,
                        'Calendrier Interactif',
                        'Vue globale des traitements avec marqueurs d\'état et navigation fluide.',
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildFeatureGroup('Opérations & Finance', [
                      _buildFeatureTile(
                        Icons.receipt_long_outlined,
                        'Facturation Automatisée',
                        'Génération de factures liées aux interventions et suivi des règlements.',
                      ),
                      _buildFeatureTile(
                        Icons.warning_amber_rounded,
                        'Gestion des Signalements',
                        'Traçabilité immédiate des problèmes rencontrés lors des interventions.',
                      ),
                      _buildFeatureTile(
                        Icons.file_download_outlined,
                        'Exports Professionnels',
                        'Générez des rapports Excel complets pour votre comptabilité.',
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildFeatureGroup('Technologie & Sécurité', [
                      _buildFeatureTile(
                        Icons.storage_rounded,
                        'Souveraineté des Données',
                        'Stockage local sur votre serveur MySQL pour un contrôle total.',
                      ),
                      _buildFeatureTile(
                        Icons.lock_outline,
                        'Sécurité Robuste',
                        'Chiffrement des mots de passe avec BCrypt et gestion des sessions sécurisée.',
                      ),
                      _buildFeatureTile(
                        Icons.devices_outlined,
                        'Multi-Plateforme Native',
                        'Optimisé pour Windows et Linux avec support des raccourcis clavier.',
                      ),
                    ]),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Compris, c\'est efficace !',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildFeatureGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  static Widget _buildFeatureTile(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
