import 'package:flutter/material.dart';
import '../../core/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

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
                  'APEXNova Labs (ci-après "l\'Entreprise") s\'engage à respecter votre vie privée. '
                  'Cette Politique de Confidentialité explique comment nous collectons, utilisons, '
                  'divulguons et sauvegardons vos informations lorsque vous utilisez notre application mobile Planificator.',
            ),
            _buildSection(
              title: '2. Informations que Nous Collectons',
              content:
                  'Nous collectons les informations suivantes :\n\n'
                  '• Informations de compte : Nom, email, mot de passe (hachés)\n'
                  '• Données professionnelles : Informations sur les clients, contrats et traitements\n'
                  '• Données de configuration : Préférences d\'application et paramètres utilisateur\n'
                  '• Données de connexion : Adresse IP, dates/heures d\'accès, navigateur utilisé\n'
                  '• Fichiers téléchargés/exportés : Factures, rapports et données Excel générés\n\n'
                  'Ces informations sont collectées directement auprès de vous lors de l\'inscription, '
                  'de l\'utilisation de l\'application, ou via des technologies de suivi automatisées.',
            ),
            _buildSection(
              title: '3. Utilisation de Vos Informations',
              content:
                  'Nous utilisons les informations collectées pour :\n\n'
                  '• Fournir, maintenir et améliorer nos services\n'
                  '• Traiter vos transactions et envoyer les informations associées\n'
                  '• Vous envoyer des mises à jour de sécurité et des notifications importantes\n'
                  '• Répondre à vos demandes, questions et préoccupations\n'
                  '• Générer des rapports et des analyses pour améliorer la performance\n'
                  '• Respecter les obligations légales et réglementaires\n'
                  '• Prévenir la fraude et assurer la sécurité de l\'application\n\n'
                  'Nous NE vendrons, ne louerons et ne partagerons JAMAIS vos informations personnelles '
                  'avec des tiers sans votre consentement explicite, sauf si la loi l\'exige.',
            ),
            _buildSection(
              title: '4. Sécurité des Données',
              content:
                  'Nous mettons en œuvre des mesures de sécurité techniques et organisationnelles '
                  'pour protéger vos informations personnelles contre la perte, le vol, l\'accès non autorisé, '
                  'la divulgation, la modification et la destruction.\n\n'
                  'Mesures incluent :\n'
                  '• Chiffrement SSL/TLS pour les transmissions de données\n'
                  '• Hachage sécurisé des mots de passe (bcrypt/argon2)\n'
                  '• Authentification multi-facteurs disponibles\n'
                  '• Firewall et protection contre les attaques DDoS\n'
                  '• Audits de sécurité réguliers\n\n'
                  'Cependant, aucune méthode de transmission sur Internet n\'est 100% sécurisée. '
                  'Nous ne pouvons donc pas garantir une sécurité absolue.',
            ),
            _buildSection(
              title: '5. Rétention des Données',
              content:
                  'Nous conservons vos informations personnelles tant que nécessaire pour :\n\n'
                  '• Fournir nos services\n'
                  '• Respecter nos obligations légales\n'
                  '• Résoudre les litiges\n'
                  '• Appliquer nos accords\n\n'
                  'Vous pouvez demander la suppression de vos données à tout moment. '
                  'Nous supprimerons vos informations dans un délai de 30 jours, '
                  'sauf si nous sommes tenues de les conserver pour des raisons légales.',
            ),
            _buildSection(
              title: '6. Vos Droits et Choix',
              content:
                  'Conformément à la réglementation (RGPD, CCPA, etc.), vous avez le droit de :\n\n'
                  '• Accéder à vos données personnelles\n'
                  '• Rectifier les informations inexactes\n'
                  '• Supprimer vos données (droit à l\'oubli)\n'
                  '• Exporter vos données (portabilité)\n'
                  '• Retirer votre consentement à tout moment\n'
                  '• Vous opposer au traitement de vos données\n'
                  '• Recevoir une copie de votre contrat de données\n\n'
                  'Pour exercer ces droits, veuillez nous contacter à : contact@apexnova-labs.com',
            ),
            _buildSection(
              title: '7. Cookies et Technologies de Suivi',
              content:
                  'Planificator n\'utilise pas de cookies de suivi publicitaires. '
                  'Nous utilisons uniquement :\n\n'
                  '• Tokens de session : Pour maintenir votre authentification\n'
                  '• Données locales : Préférences sauvegardées sur votre appareil\n'
                  '• Analytiques : Compter les sessions et diagnostiquer les erreurs\n\n'
                  'Vous pouvez contrôler ces paramètres dans les paramètres de votre appareil mobile.',
            ),
            _buildSection(
              title: '8. Partage de Données',
              content:
                  'Nous partageons vos données uniquement :\n\n'
                  '• Avec nos fournisseurs de services (hébergement, support technique)\n'
                  '• Avec les autorités si exigé par la loi\n'
                  '• Avec votre consentement explicite\n\n'
                  'Tous nos fournisseurs de services sont tenus de respecter des accords de confidentialité '
                  'strictes et d\'utiliser vos données uniquement selon nos instructions.',
            ),
            _buildSection(
              title: '9. Liens Externes',
              content:
                  'Planificator peut contenir des liens vers des sites Web externes. '
                  'Nous ne sommes pas responsables des politiques de confidentialité de ces sites. '
                  'Nous vous encourageons à lire leurs politiques avant de partager vos informations.',
            ),
            _buildSection(
              title: '10. Modifications de Cette Politique',
              content:
                  'APEXNova Labs se réserve le droit de modifier cette Politique de Confidentialité à tout moment. '
                  'Nous vous notifierons par email ou par une notification dans l\'application en cas de modifications substantielles. '
                  'Votre utilisation continue de l\'application après ces modifications constitue votre acceptation '
                  'de la politique révisée.',
            ),
            _buildSection(
              title: '11. Conformité avec les Lois',
              content:
                  'Cette Politique de Confidentialité est conforme à :\n\n'
                  '• RGPD (Règlement Général sur la Protection des Données)\n'
                  '• CCPA (California Consumer Privacy Act)\n'
                  '• PIPEDA (Loi de protection des renseignements personnels et les documents électroniques)\n'
                  '• Autres lois locales applicables\n\n'
                  'Si vous nous contactez depuis un État ou un pays spécifique, '
                  'nous respecterons les lois qui s\'y appliquent.',
            ),
            _buildSection(
              title: '12. Nous Contacter',
              content:
                  'Si vous avez des questions concernant cette Politique de Confidentialité, '
                  'nos pratiques de confidentialité, ou si vous souhaitez exercer vos droits, '
                  'veuillez nous contacter à :\n\n'
                  'APEXNova Labs\n'
                  'Email : contact@apexnova-labs.com\n'
                  'Ou via : josoavonjinaina@gmail.com\n'
                  'Adresse : Antananarivo, Madagascar\n'
                  'Téléphone : Disponible sur demande\n\n'
                  'Nous répondrons à votre demande dans un délai de 10 jours ouvrables.',
            ),
            _buildSection(
              title: '13. Déclaration du Responsable de Données',
              content:
                  'Le responsable du traitement de vos données est APEXNova Labs. '
                  'Nous avons nommé un délégué à la protection des données (DPO) qui supervise '
                  'nos pratiques de confidentialité et assure la conformité avec les lois applicables.',
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
