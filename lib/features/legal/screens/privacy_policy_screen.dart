import 'package:flutter/material.dart';
import 'legal_common.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalPage(
      eyebrow: 'POLITIQUE DE CONFIDENTIALITÉ',
      title: 'Protection et traitement des données',
      icon: Icons.shield_outlined,
      badges: const [
        LegalBadge(Icons.business_rounded, LegalInfo.company),
        LegalBadge(Icons.verified_outlined, 'Version ${LegalInfo.version}'),
        LegalBadge(Icons.event_outlined, LegalInfo.lastUpdate),
      ],
      children: [
        // Résumé
        const LegalSummaryCard(
          title: 'L’essentiel en 4 points',
          items: [
            LegalSummaryItem(
              Icons.lock_outline_rounded,
              'Mots de passe hachés (BCrypt)',
              'Vos mots de passe ne sont jamais stockés en clair.',
            ),
            LegalSummaryItem(
              Icons.block_rounded,
              'Aucune revente de données',
              'Vos fiches clients et contrats restent strictement privées.',
            ),
            LegalSummaryItem(
              Icons.file_download_outlined,
              'Export de vos données',
              'Récupérez vos données au format Excel à tout moment.',
            ),
            LegalSummaryItem(
              Icons.storage_rounded,
              'Données sur votre base MySQL',
              'Vous gardez le contrôle de l’endroit où elles sont stockées.',
            ),
          ],
        ),

        const SizedBox(height: 32),
        const LegalSectionTitle('Détail des engagements et des règles'),

        const LegalSectionCard(
          number: '01',
          icon: Icons.info_outline_rounded,
          title: 'Introduction et portée',
          content:
              'Chez ${LegalInfo.company}, la protection de vos données personnelles '
              'et professionnelles est une priorité. Cette politique décrit les '
              'pratiques de collecte, d’utilisation, de stockage et de protection '
              'des données lors de l’utilisation de la plateforme Planificator, '
              'éditée et maintenue par ${LegalInfo.editor}.',
        ),

        const LegalSectionCard(
          number: '02',
          icon: Icons.inventory_2_outlined,
          title: 'Informations collectées',
          bullets: [
            'Informations de compte : nom, prénom, e-mail, identifiant et mot de passe (haché avec BCrypt).',
            'Données opérationnelles : fiches clients, contrats, interventions de traitement, tarifs et historiques de factures.',
            'Paramètres et configuration : préférences de thème, configuration de connexion MySQL et paramètres de notifications.',
            'Journaux système : logs techniques d’erreurs locaux, destinés uniquement au débogage et à la stabilité.',
          ],
        ),

        const LegalSectionCard(
          number: '03',
          icon: Icons.query_stats_rounded,
          title: 'Utilisation des données',
          content:
              'Vos données servent uniquement au fonctionnement métier de votre entreprise :',
          bullets: [
            'Planification, génération et suivi des calendriers d’interventions.',
            'Émission et suivi de l’état de paiement des factures.',
            'Génération d’exports et de rapports au format Excel.',
            'Gestion de l’authentification et du contrôle d’accès par rôle.',
          ],
          note:
              'Vos données restent votre propriété. Elles ne sont ni revendues, ni louées, ni cédées à des tiers.',
        ),

        const LegalSectionCard(
          number: '04',
          icon: Icons.storage_rounded,
          title: 'Stockage et chiffrement',
          content:
              'Planificator repose sur une architecture de données contrôlée par l’utilisateur :',
          bullets: [
            'Base MySQL : vos données métier sont stockées sur votre base MySQL locale ou privée.',
            'Mots de passe : hachés de façon irréversible avec l’algorithme BCrypt.',
            'Identifiants de connexion : stockés de manière chiffrée via Secure Storage (DPAPI, Keystore ou Keychain selon le système).',
          ],
        ),

        const LegalSectionCard(
          number: '05',
          icon: Icons.lock_outline_rounded,
          title: 'Sécurité et protection',
          content:
              'Nous appliquons des mesures de sécurité techniques et organisationnelles :',
          bullets: [
            'Protection contre la force brute : limitation des tentatives de connexion (5 tentatives en 10 minutes).',
            'Masquage automatique des mots de passe et des hashs dans les journaux système.',
            'Requêtes SQL paramétrées et transactions atomiques pour protéger l’intégrité des données.',
            'Calculs lourds exécutés hors du fil d’interface pour garantir la stabilité.',
          ],
        ),

        const LegalSectionCard(
          number: '06',
          icon: Icons.verified_user_outlined,
          title: 'Vos droits et votre contrôle',
          bullets: [
            'Accès et rectification : modification de votre profil et de vos données métier.',
            'Export : récupération de vos données au format Excel à tout moment.',
            'Effacement : suppression de votre compte ou de vos données clients.',
          ],
        ),

        LegalSectionCard(
          number: '07',
          icon: Icons.balance_outlined,
          title: 'Conformité réglementaire',
          content:
              'Notre politique s’inspire des principes des réglementations internationales sur la protection des données :',
          bullets: [
            for (final r in LegalInfo.regulations)
              '${r.title} : ${r.description}',
          ],
        ),

        const SizedBox(height: 16),
        const LegalSectionTitle('Une question sur la confidentialité ?'),
        const LegalContactCard(),
      ],
    );
  }
}
