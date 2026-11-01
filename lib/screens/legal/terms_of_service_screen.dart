import 'package:flutter/material.dart';
import '../../core/theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête Moderne avec Dégradé, Icône et Bouton Retour
            _buildHeader(context, isDark, colorScheme),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Carte "L'essentiel en 4 points"
                      _buildExecutiveSummary(context, isDark),

                      const SizedBox(height: 32),

                      _buildSectionTitle(context, 'Termes du Contrat de Licence'),

                      const SizedBox(height: 16),

                      // Section 1: Acceptation
                      _buildSectionCard(
                        context,
                        isDark: isDark,
                        number: '01',
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Acceptation des Conditions',
                        content:
                            'En accédant et en utilisant la plateforme Planificator (ci-après "la Plateforme"), '
                            'vous acceptez sans réserve de respecter les présentes Conditions d\'Utilisation. '
                            'Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser la Plateforme.',
                      ),

                      // Section 2: Licence
                      _buildSectionCard(
                        context,
                        isDark: isDark,
                        number: '02',
                        icon: Icons.workspace_premium_outlined,
                        title: 'Licence d\'Utilisation Métier',
                        content:
                            'APEXNova Labs vous accorde une licence non exclusive, non transférable et révocable '
                            'pour utiliser la Plateforme à des fins de gestion professionnelle d\'entreprise.',
                        bullets: const [
                          'Interdiction de copier, modifier, rétro-ingénierer ou désassembler la Plateforme.',
                          'Interdiction d\'utiliser la Plateforme à des fins illégales ou non autorisées.',
                          'Interdiction de revendre, sous-louer ou partager l\'accès avec des tiers non autorisés.',
                        ],
                      ),

                      // Section 3: Comptes & Authentification
                      _buildSectionCard(
                        context,
                        isDark: isDark,
                        number: '03',
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Comptes & Responsabilité',
                        content:
                            'Vous êtes pleinement responsable du maintien de la confidentialité de vos identifiants et mots de passe :',
                        bullets: const [
                          'Toute activité réalisée sous vos identifiants relève de votre responsabilité exclusive.',
                          'Vous devez informer immédiatement APEXNova Labs de tout accès ou soupçon d\'accès non autorisé.',
                          'APEXNova Labs se réserve le droit de suspendre ou résilier les comptes en cas de violation des conditions.',
                        ],
                      ),

                      // Section 4: Données & Propriété
                      _buildSectionCard(
                        context,
                        isDark: isDark,
                        number: '04',
                        icon: Icons.folder_shared_outlined,
                        title: 'Propriété Intellectuelle & Données',
                        content:
                            'Vos données métier (clients, contrats, factures, plannings) restent votre propriété exclusive. '
                            'Planificator et l\'ensemble de ses composants logiciels, marques et visuels sont la propriété exclusive d\'APEXNova Labs.',
                        highlightNote:
                            'Aucune donnée métier n\'est vendue ou exploitée à des fins commerciales par APEXNova Labs.',
                      ),

                      // Section 5: Limitation de Responsabilité
                      _buildSectionCard(
                        context,
                        isDark: isDark,
                        number: '05',
                        icon: Icons.shield_outlined,
                        title: 'Limitation de Responsabilité',
                        content:
                            'La Plateforme est fournie "telle quelle". APEXNova Labs met en œuvre tous les moyens raisonnables '
                            'pour assurer la continuité et la stabilité du service, mais ne saurait être tenu responsable en cas de :',
                        bullets: const [
                          'Dysfonctionnement ou mauvaise configuration de l\'infrastructure serveur/base de données de l\'utilisateur.',
                          'Pertes de données liées à une absence de sauvegarde locale par l\'utilisateur.',
                          'Interruptions imprévisibles de réseau ou pannes matérielles de l\'appareil hôte.',
                        ],
                      ),

                      // Section 6: Loi Applicable
                      _buildSectionCard(
                        context,
                        isDark: isDark,
                        number: '06',
                        icon: Icons.gavel_rounded,
                        title: 'Droit Applicable & Juridiction',
                        content:
                            'Les présentes Conditions d\'Utilisation sont régies par les lois de la République de Madagascar. '
                            'En cas de litige relatif à l\'interprétation ou à l\'exécution du présent contrat, '
                            'une résolution à l\'amiable sera privilégiée avant toute action devant les tribunaux compétents d\'Antananarivo.',
                      ),

                      const SizedBox(height: 32),

                      // Contact & Pied de page
                      _buildContactFooter(context, isDark),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 24, 32),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Bouton Retour simple, sans cadre, pleinement à gauche en bord de page
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                  tooltip: 'Retour',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: const Icon(
                    Icons.gavel_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CONDITIONS D\'UTILISATION',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Contrat d\'Utilisation de la Plateforme',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildBadge(Icons.business_rounded, 'APEXNova Labs'),
                _buildBadge(Icons.verified_outlined, 'Version 2.1.1'),
                _buildBadge(Icons.event_outlined, '31 octobre 2026'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveSummary(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.accentBlue.withValues(alpha: 0.12) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.accentBlue.withValues(alpha: 0.3) : Colors.blue.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryBlue, size: 22),
              const SizedBox(width: 10),
              const Text(
                'L\'Essentiel du Contrat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 550;
              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _buildSummaryTile(
                    isWide: isWide,
                    icon: Icons.workspace_premium_outlined,
                    title: 'Licence professionnelle',
                    desc: 'Usage interne non exclusif de la plateforme.',
                  ),
                  _buildSummaryTile(
                    isWide: isWide,
                    icon: Icons.shield_outlined,
                    title: 'Souveraineté des données',
                    desc: 'Vos fiches clients restent 100% votre propriété.',
                  ),
                  _buildSummaryTile(
                    isWide: isWide,
                    icon: Icons.key_outlined,
                    title: 'Responsabilité des accès',
                    desc: 'Protéger la confidentialité de vos identifiants.',
                  ),
                  _buildSummaryTile(
                    isWide: isWide,
                    icon: Icons.gavel_rounded,
                    title: 'Droit applicatif',
                    desc: 'Soumis aux lois de la République de Madagascar.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile({required bool isWide, required IconData icon, required String title, required String desc}) {
    return SizedBox(
      width: isWide ? 240 : double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required bool isDark,
    required String number,
    required IconData icon,
    required String title,
    String? content,
    List<String>? bullets,
    String? highlightNote,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.glassBorder.withValues(alpha: 0.1) : Colors.grey.shade200,
        ),
        boxShadow: isDark ? [] : AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icon, color: AppTheme.primaryBlue, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          if (content != null) ...[
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: isDark ? Colors.white70 : Colors.grey.shade800,
              ),
            ),
          ],
          if (bullets != null) ...[
            const SizedBox(height: 12),
            Column(
              children: bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.arrow_right_rounded, color: AppTheme.primaryBlue, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ],
          if (highlightNote != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: AppTheme.primaryBlue, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      highlightNote,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactFooter(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBgSecondary : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppTheme.glassBorder.withValues(alpha: 0.1) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.contact_support_outlined, color: AppTheme.primaryBlue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Des questions sur les Conditions d\'Utilisation ?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Contactez l\'équipe juridique d\'APEXNova Labs à contact@apexnova-labs.com.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
