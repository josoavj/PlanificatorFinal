import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class LegalDocumentsScreen extends StatelessWidget {
  const LegalDocumentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations Légales'),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue,
                    AppTheme.primaryBlue.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'APEXNova Labs',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Planificator v2.1.1',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Engagement envers la transparence et la conformité',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // À propos d'APEXNova Labs
            Text(
              'À propos d\'APEXNova Labs',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'APEXNova Labs est une entreprise technologique dédiée au développement '
              'de solutions innovantes pour la gestion d\'entreprise. Notre mission est '
              'de fournir des outils intuitifs, sécurisés et efficaces pour nos utilisateurs.\n\n'
              'Basée à Madagascar, nous nous engageons à respecter les plus hauts standards '
              'de qualité, de sécurité et de conformité réglementaire.',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 24),

            // Documents Légaux
            Text(
              'Documents Légaux',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Politique de Confidentialité
            _buildLegalCard(
              context,
              icon: Icons.shield_outlined,
              title: 'Politique de Confidentialité',
              description:
                  'Découvrez comment nous protégeons vos données personnelles '
                  'et respectons votre vie privée.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Conditions d'Utilisation
            _buildLegalCard(
              context,
              icon: Icons.assignment_outlined,
              title: 'Conditions d\'Utilisation',
              description:
                  'Lisez les termes et conditions régissant l\'utilisation '
                  'de l\'application Planificator.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Conformité
            Text(
              'Conformité & Régulation',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildComplianceItem(
              icon: Icons.check_circle_outline,
              title: 'RGPD (UE)',
              description:
                  'Conforme au Règlement Général sur la Protection des Données',
            ),
            _buildComplianceItem(
              icon: Icons.check_circle_outline,
              title: 'CCPA (Californie)',
              description: 'Conforme à la California Consumer Privacy Act',
            ),
            _buildComplianceItem(
              icon: Icons.check_circle_outline,
              title: 'PIPEDA (Canada)',
              description:
                  'Conforme à la Loi sur la Protection des Renseignements Personnels',
            ),
            _buildComplianceItem(
              icon: Icons.check_circle_outline,
              title: 'Sécurité SSL/TLS',
              description:
                  'Chiffrement end-to-end pour toutes les transmissions',
            ),

            const SizedBox(height: 32),

            // Contact
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nous Contacter',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildContactInfo(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: 'contact@apexnova-labs.com',
                  ),
                  const SizedBox(height: 8),
                  _buildContactInfo(
                    icon: Icons.location_on_outlined,
                    label: 'Adresse',
                    value: 'Madagascar',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Délai de réponse : 10 jours ouvrables',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    '© 2026 APEXNova Labs. Tous droits réservés.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dernière mise à jour : 15 janvier 2026',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryBlue, size: 32),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: AppTheme.primaryBlue,
          size: 20,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildComplianceItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.successGreen, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
