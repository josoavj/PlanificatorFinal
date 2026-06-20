import 'package:flutter/material.dart';
import '../../core/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Politique de Confidentialité'),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              'Politique de Confidentialité',
              'APEXNova Labs - Planificator',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Introduction',
              content:
                  'Chez APEXNova Labs, nous respectons votre vie privée. Cette politique explique comment nous collectons, utilisons, '
                  'divulguons et sauvegardons vos informations lorsque vous utilisez notre plateforme Planificator.',
            ),
            _buildSection(
              title: '2. Informations que nous collectons',
              content:
                  'Nous collectons les types d\'informations suivants :\n\n'
                  '• Informations de compte : Nom, email, nom d\'utilisateur et mot de passe (haché).\n'
                  '• Données opérationnelles : Détails sur vos clients, contrats, factures et plannings.\n'
                  '• Données de configuration : Préférences de la plateforme et paramètres utilisateur.\n'
                  '• Logs techniques : Informations sur les erreurs et l\'utilisation pour le débogage.',
            ),
            _buildSection(
              title: '3. Comment nous utilisons vos informations',
              content:
                  'Vos informations sont utilisées pour :\n\n'
                  '• Fournir, exploiter et maintenir la plateforme\n'
                  '• Améliorer et personnaliser votre expérience\n'
                  '• Comprendre comment vous utilisez la plateforme\n'
                  '• Développer de nouvelles fonctionnalités\n'
                  '• Communiquer avec vous pour le support\n'
                  '• Prévenir la fraude et assurer la sécurité de la plateforme\n\n'
                  'Toutes vos données métier restent privées et ne sont jamais vendues à des tiers.',
            ),
            _buildSection(
              title: '4. Stockage des Données',
              content:
                  'La plateforme utilise une base de données MySQL pour stocker vos informations. '
                  'Les identifiants de connexion sont chiffrés localement sur votre appareil via Secure Storage (DPAPI/Keystore/Keychain). '
                  'Les mots de passe des utilisateurs sont hachés avec l\'algorithme BCrypt.',
            ),
            _buildSection(
              title: '5. Sécurité des Données',
              content:
                  'Nous utilisons des mesures de sécurité administratives, techniques et physiques pour protéger vos informations personnelles. '
                  'Bien que nous ayons pris des mesures raisonnables, aucune mesure de sécurité n\'est parfaite ou impénétrable.',
            ),
            _buildSection(
              title: '6. Partage d\'Informations',
              content:
                  'Nous ne partageons vos informations que dans les cas suivants :\n\n'
                  '• Conformité légale : Si la loi l\'exige.\n'
                  '• Protection des droits : Pour protéger nos droits, notre vie privée, notre sécurité ou notre propriété.',
            ),
            _buildSection(
              title: '7. Vos Droits',
              content:
                  'Vous avez le droit de :\n\n'
                  '• Accéder à vos données personnelles\n'
                  '• Rectifier des données inexactes\n'
                  '• Demander la suppression de votre compte\n'
                  '• Exporter vos données via les fonctionnalités d\'export Excel de la plateforme.',
            ),
            _buildSection(
              title: '8. Modifications de cette Politique',
              content:
                  'Nous pouvons mettre à jour cette politique de confidentialité de temps en temps. '
                  'Nous vous notifierons par email ou par une notification dans la plateforme en cas de changements substantiels. '
                  'Votre utilisation continue de la plateforme après ces modifications constitue votre acceptation de la nouvelle politique.',
            ),
            _buildSection(
              title: '9. Contact',
              content:
                  'Si vous avez des questions sur cette politique, contactez-nous à support@apexnova-labs.com.',
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dernière mise à jour',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '15 janvier 2026',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Version 2.1.1',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey.shade700,
            ),
          ),
          const Divider(height: 32, color: Colors.grey),
        ],
      ),
    );
  }
}
