import 'package:material_ui/material_ui.dart';

import '../../../app/theme/theme.dart';
import 'legal_common.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class LegalDocumentsScreen extends StatelessWidget {
  const LegalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);

    return LegalPage(
      eyebrow: 'INFORMATIONS LÉGALES',
      title: '${LegalInfo.company} · Planificator',
      icon: Icons.verified_user_outlined,
      badges: const [
        LegalBadge(Icons.person_outline, 'Édité par ${LegalInfo.editor}'),
        LegalBadge(Icons.verified_outlined, 'Version ${LegalInfo.version}'),
        LegalBadge(Icons.event_outlined, LegalInfo.lastUpdate),
      ],
      children: [
        // À propos
        const LegalSectionTitle('À propos'),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: legalCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Planificator est un produit ${LegalInfo.company}, dédié à la '
                'gestion des contrats, des plannings et des factures. Notre '
                'mission : fournir des outils intuitifs, sécurisés et efficaces.\n\n'
                'Basée à ${LegalInfo.location}, ${LegalInfo.company} s’engage à '
                'respecter de hauts standards de qualité, de sécurité et de '
                'conformité réglementaire.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: muted,
                ),
              ),
              const SizedBox(height: 16),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  LegalPill(Icons.touch_app_outlined, 'Intuitif'),
                  LegalPill(Icons.lock_outline, 'Sécurisé'),
                  LegalPill(Icons.bolt_outlined, 'Efficace'),
                ],
              ),
            ],
          ),
        ),

        // Éditeur et entreprise (Ici, c'est une organisation)
        const SizedBox(height: 32),
        const LegalSectionTitle('Éditeur et mainteneur'),
        LegalAdaptiveRow(
          children: [
            _InfoCard(
              icon: Icons.person_outline,
              title: LegalInfo.editor,
              subtitle: 'Éditeur et mainteneur actuel',
              description: 'Conception, mise en place de l\'architecture et développement de Planificator.',
              onTap: () =>
                  openLegalLink(context, Uri.parse(LegalInfo.editorUrl)),
            ),
            const _InfoCard(
              icon: Icons.apartment_outlined,
              title: LegalInfo.company,
              subtitle: 'Organisation · ${LegalInfo.location}',
              description: 'Organisation responsable de la publication et de la maintenance de Planificator.',
            ),
          ],
        ),

        // Documents légaux
        const SizedBox(height: 32),
        const LegalSectionTitle('Documents légaux'),
        LegalAdaptiveRow(
          children: [
            _DocCard(
              icon: Icons.shield_outlined,
              title: 'Politique de confidentialité',
              description:
                  'Découvrez comment nous protégeons vos données '
                  'personnelles et respectons votre vie privée.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              ),
            ),
            _DocCard(
              icon: Icons.assignment_outlined,
              title: 'Conditions d’utilisation',
              description:
                  'Lisez les termes et conditions régissant '
                  'l’utilisation de la plateforme Planificator.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
              ),
            ),
          ],
        ),

        // Conformité
        const SizedBox(height: 32),
        const LegalSectionTitle('Conformité et régulation'),
        _ComplianceGrid(
          items: [
            ...LegalInfo.regulations,
            const LegalRule(
              'Sécurité SSL/TLS',
              'Chiffrement SSL/TLS des transmissions',
            ),
          ],
        ),

        // Contact
        const SizedBox(height: 32),
        const LegalSectionTitle('Nous contacter'),
        const LegalContactCard(),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    const muted = Color(0xFF5C5C5C);

    return Container(
      decoration: legalCardDecoration(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LegalIconBadge(icon),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.open_in_new_rounded, size: 18, color: primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  const _DocCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    const muted = Color(0xFF5C5C5C);

    return Container(
      decoration: legalCardDecoration(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LegalIconBadge(icon),
                    const Spacer(),
                    Icon(Icons.arrow_forward_rounded, color: primary),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Lire le document',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComplianceGrid extends StatelessWidget {
  const _ComplianceGrid({required this.items});
  final List<LegalRule> items;

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 2 : 1;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final theme = Theme.of(context);
        final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              Container(
                width: width,
                padding: const EdgeInsets.all(16),
                decoration: legalCardDecoration(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LegalIconBadge(
                      Icons.check_circle_outline,
                      color: AppTheme.successGreen,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.4,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
