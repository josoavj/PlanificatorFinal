import 'package:flutter/material.dart';
import 'legal_common.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalPage(
      eyebrow: 'CONDITIONS D’UTILISATION',
      title: 'Le cadre d’utilisation de Planificator',
      icon: Icons.assignment_outlined,
      badges: const [
        LegalBadge(Icons.business_rounded, LegalInfo.company),
        LegalBadge(Icons.verified_outlined, 'Version ${LegalInfo.version}'),
        LegalBadge(Icons.event_outlined, LegalInfo.lastUpdate),
      ],
      children: [
        const LegalSummaryCard(
          title: 'L’essentiel du contrat',
          items: [
            LegalSummaryItem(
              Icons.workspace_premium_outlined,
              'Licence professionnelle',
              'Usage interne non exclusif de la plateforme.',
            ),
            LegalSummaryItem(
              Icons.shield_outlined,
              'Souveraineté des données',
              'Vos fiches clients restent votre propriété.',
            ),
            LegalSummaryItem(
              Icons.key_outlined,
              'Responsabilité des accès',
              'Protégez la confidentialité de vos identifiants.',
            ),
            LegalSummaryItem(
              Icons.gavel_rounded,
              'Droit applicable',
              'Les conditions sont régies par les lois malgaches.',
            ),
          ],
        ),
        const SizedBox(height: 32),
        const LegalSectionTitle('Termes du contrat de licence'),
        const LegalSectionCard(
          number: '01',
          icon: Icons.check_circle_outline_rounded,
          title: 'Acceptation des conditions',
          content:
              'En accédant et en utilisant Planificator (« la Plateforme »), '
              'vous acceptez de respecter ces conditions. Si vous ne les '
              'acceptez pas, n’utilisez pas la Plateforme.',
        ),
        const LegalSectionCard(
          number: '02',
          icon: Icons.workspace_premium_outlined,
          title: 'Licence d’utilisation professionnelle',
          content:
              '${LegalInfo.company} accorde une licence non exclusive, non '
              'transférable et révocable pour utiliser la Plateforme à des '
              'fins de gestion professionnelle.',
          bullets: [
            'Ne copiez, modifiez, rétro-ingénieriez ni désassemblez la Plateforme, sauf dans la mesure permise par la loi applicable.',
            'N’utilisez pas la Plateforme à des fins illégales ou non autorisées.',
            'Ne revendez pas, ne sous-louez pas et ne partagez pas l’accès avec des tiers non autorisés.',
          ],
        ),
        const LegalSectionCard(
          number: '03',
          icon: Icons.admin_panel_settings_outlined,
          title: 'Comptes et responsabilité',
          content:
              'Vous êtes responsable de la confidentialité de vos identifiants, '
              'de la protection de vos postes et de l’activité effectuée avec '
              'vos comptes.',
          bullets: [
            'Signalez immédiatement tout accès suspect à l’administrateur de votre organisation.',
            'Toute activité réalisée avec vos identifiants relève de votre responsabilité.',
            'Les comptes peuvent être suspendus ou résiliés en cas de violation des conditions applicables.',
          ],
        ),
        const LegalSectionCard(
          number: '04',
          icon: Icons.folder_shared_outlined,
          title: 'Propriété intellectuelle et données',
          content:
              'Les données métier saisies (clients, contrats, plannings et '
              'factures) restent la propriété de l’organisation qui les fournit. '
              'Les composants logiciels, marques et visuels Planificator sont '
              'attribués à ${LegalInfo.company} conformément aux licences et '
              'droits applicables.',
          note:
              'Les données métier ne sont pas vendues ni exploitées par l’éditeur à des fins commerciales.',
        ),
        const LegalSectionCard(
          number: '05',
          icon: Icons.shield_outlined,
          title: 'Disponibilité et limitation de responsabilité',
          content:
              'La Plateforme est fournie « telle quelle ». Des efforts '
              'raisonnables sont faits pour maintenir sa stabilité, mais '
              'l’éditeur ne garantit pas l’absence d’interruption ou d’erreur.',
          bullets: [
            'Défaillances liées à une infrastructure MySQL mal configurée.',
            'Pertes de données liées à l’absence de sauvegarde.',
            'Panne réseau ou matérielle indépendante de la Plateforme.',
          ],
        ),
        const LegalSectionCard(
          number: '06',
          icon: Icons.gavel_rounded,
          title: 'Droit applicable et juridiction',
          content:
              'Ces conditions sont régies par les lois de la République de '
              'Madagascar. Les parties privilégient une résolution amiable '
              'avant toute action devant les tribunaux compétents '
              'd’Antananarivo.',
        ),
        const SizedBox(height: 16),
        const LegalSectionTitle('Une question sur ces conditions ?'),
        const LegalContactCard(),
      ],
    );
  }
}
