import 'package:flutter/material.dart';
import '../../core/theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conditions d\'Utilisation'),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              'Conditions d\'Utilisation',
              'APEXNova Labs - Planificator',
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Acceptation des Conditions',
              content:
                  'En accédant et en utilisant l\'application Planificator (ci-après "l\'Application"), '
                  'vous acceptez de respecter et d\'être lié par ces Conditions d\'Utilisation. '
                  'Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser l\'Application.',
            ),
            _buildSection(
              title: '2. Licence d\'Utilisation',
              content:
                  'APEXNova Labs vous accorde une licence non exclusive, non transférable et révocable '
                  'pour utiliser l\'Application à des fins professionnelles et personnelles légitimes.\n\n'
                  'Vous vous engagez à :\n'
                  '• Ne pas copier, modifier ou créer des ouvrages dérivés\n'
                  '• Ne pas désassembler, décompiler ou ingénierie inverse\n'
                  '• Ne pas utiliser l\'Application pour des activités illégales\n'
                  '• Ne pas revendre ou louer l\'Application\n'
                  '• Ne pas transférer la licence à des tiers',
            ),
            _buildSection(
              title: '3. Comptes et Authentification',
              content:
                  'Vous êtes responsable du maintien de la confidentialité de votre mot de passe '
                  'et de votre compte. Vous acceptez :\n\n'
                  '• Toutes les activités qui se produisent sous votre compte\n'
                  '• Notifier immédiatement APEXNova Labs de tout accès non autorisé\n'
                  '• De fournir des informations exactes et à jour\n'
                  '• De ne pas partager votre compte avec d\'autres\n\n'
                  'APEXNova Labs se réserve le droit de suspendre ou de terminer les comptes '
                  'qui enfreignent ces conditions.',
            ),
            _buildSection(
              title: '4. Utilisation Acceptable',
              content:
                  'Vous acceptez de ne pas :\n\n'
                  '• Publier du contenu offensant, diffamatoire ou illégal\n'
                  '• Harceler, menacer ou abuser d\'autres utilisateurs\n'
                  '• Violer les droits d\'auteur ou de propriété intellectuelle\n'
                  '• Vous engager dans le phishing ou le vol d\'identité\n'
                  '• Introduire des virus, vers ou code malveillant\n'
                  '• Contourner les mesures de sécurité\n'
                  '• Faire du spam ou du marketing non autorisé\n'
                  '• Accéder à des données d\'autres utilisateurs\n'
                  '• Utiliser des bots ou des automatisations non autorisées',
            ),
            _buildSection(
              title: '5. Contenu Utilisateur',
              content:
                  'Vous détenez la propriété de tout contenu que vous créez ou téléchargez. '
                  'En le mettant à disposition via l\'Application, vous accordez à APEXNova Labs '
                  'une licence mondiale, royale-free et perpétuelle pour :\n\n'
                  '• Héberger et stocker votre contenu\n'
                  '• Analyser vos données pour améliorer le service\n'
                  '• Générer des rapports agrégés et anonymisés\n\n'
                  'Nous ne vendrons ni ne partagerons votre contenu personnel sans consentement.',
            ),
            _buildSection(
              title: '6. Propriété Intellectuelle',
              content:
                  'L\'Application et tout son contenu (logos, textes, graphiques, code) '
                  'sont la propriété exclusive d\'APEXNova Labs ou de ses fournisseurs. '
                  'Tous les droits d\'auteur, brevets et droits de propriété intellectuelle sont réservés.\n\n'
                  'Vous n\'avez aucun droit de copier, reproduire ou distribuer ce contenu '
                  'sans autorisation écrite préalable.',
            ),
            _buildSection(
              title: '7. Limitation de Responsabilité',
              content:
                  'L\'Application est fournie "telle quelle" sans garanties de toute sorte. '
                  'APEXNova Labs ne sera pas responsable de :\n\n'
                  '• Les pertes directes, indirectes ou consécutives\n'
                  '• Les perte de données ou d\'informations\n'
                  '• Les dommages causés par des logiciels malveillants\n'
                  '• Les interruptions de service non prévisibles\n'
                  '• Les erreurs de l\'utilisateur\n\n'
                  'La responsabilité totale d\'APEXNova Labs ne dépassera pas le montant '
                  'que vous avez payé pour l\'Application au cours des 12 derniers mois.',
            ),
            _buildSection(
              title: '8. Exonération de Garantie',
              content:
                  'L\'APPLICATION EST FOURNIE "TEL QUE" SANS GARANTIE D\'AUCUNE SORTE. '
                  'APEXNOVA LABS REJETTE EXPRESSÉMENT TOUTE GARANTIE, EXPRESSE OU IMPLICITE, '
                  'NOTAMMENT CELLES DE QUALITÉ MARCHANDE, D\'ADAPTATION À UN USAGE PARTICULIER '
                  'ET D\'ABSENCE DE CONTREFAÇON.',
            ),
            _buildSection(
              title: '9. Indemnisation',
              content:
                  'Vous acceptez de dégager, défendre et indemniser APEXNova Labs et ses '
                  'dirigeants, employés et agents contre toute réclamation, dommage ou frais '
                  'résultant de votre violation de ces conditions ou de votre utilisation de l\'Application.',
            ),
            _buildSection(
              title: '10. Résiliation',
              content:
                  'APEXNova Labs peut résilier votre accès à l\'Application à tout moment, '
                  'sans avertissement préalable, si vous :\n\n'
                  '• Violez ces conditions\n'
                  '• Engagez des activités illégales\n'
                  '• Abusez du service\n'
                  '• Mettez en danger la sécurité ou les droits d\'autres utilisateurs\n\n'
                  'Vous pouvez résilier votre compte à tout moment en utilisant les paramètres de l\'Application.',
            ),
            _buildSection(
              title: '11. Modifications des Services',
              content:
                  'APEXNova Labs se réserve le droit de :\n\n'
                  '• Modifier ou améliorer l\'Application\n'
                  '• Ajouter ou supprimer des fonctionnalités\n'
                  '• Changer les conditions de service\n'
                  '• Suspendre ou arrêter le service\n\n'
                  'Nous vous notifierons des changements substantiels par email ou via l\'Application.',
            ),
            _buildSection(
              title: '12. Loi Applicable',
              content:
                  'Ces Conditions d\'Utilisation sont régies par les lois '
                  'de Madagascar, sans égard aux principes de conflit de lois. '
                  'Tout litige sera soumis aux tribunaux compétents de Madagascar.',
            ),
            _buildSection(
              title: '13. Droit Applicable et Juridiction',
              content:
                  'Si l\'une quelconque de ces conditions est jugée invalide ou inapplicable, '
                  'les conditions restantes demeurent en vigueur. L\'absence d\'application '
                  'd\'une condition ne constitue pas une renonciation à celle-ci.',
            ),
            _buildSection(
              title: '14. Intégralité du Accord',
              content:
                  'Ces Conditions d\'Utilisation, ainsi que notre Politique de Confidentialité, '
                  'constituent l\'accord complet entre vous et APEXNova Labs concernant l\'utilisation '
                  'de l\'Application. Tous les accords antérieurs sont annulés et remplacés par ces conditions.',
            ),
            _buildSection(
              title: '15. Nous Contacter',
              content:
                  'Pour toute question concernant ces Conditions d\'Utilisation, '
                  'veuillez nous contacter :\n\n'
                  'APEXNova Labs\n'
                  'Email : contact@apexnova-labs.com\n'
                  'Adresse : Antananarivo, Madagascar\n'
                  'Nous répondrons à votre demande dans un délai de 10 jours ouvrables.',
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
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
