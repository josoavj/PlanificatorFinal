import 'package:flutter/material.dart';
import '../../core/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                      // Carte "L'essentiel en 4 points" (Résumé exécutif)
                      _buildExecutiveSummary(context, isDark),

                      const SizedBox(height: 32),

                      _buildSectionTitle(context, 'Détails des Engagements & Règles'),

                      const SizedBox(height: 16),

                      // Section 1: Introduction
                      _buildSectionCard(
                        context,
                        isDark: isDark,
                        number: '01',
                        icon: Icons.info_outline_rounded,
                        title: 'Introduction & Portée',
                        content:
                            'Chez APEXNova Labs, la protection de vos données personnelles et professionnelles est une priorité fondamentale. '
                            'Cette politique de confidentialité décrit en détail les pratiques de collecte, d\'utilisation, de stockage et de protection des données '
                            'mises en œuvre lors de l\'utilisation de la plateforme Planificator.',
                      ),

                      // Section 2: Informations collectées
                      _buildSectionCard(
                        context,
                        isDark: isDark,
                        number: '02',
                        icon: Icons.inventory_2_outlined,
                        title: 'Informations Collectées',
                        bullets: const [
                          'Informations de compte : Nom, prénom, email, identifiant et mot de passe (haché avec BCrypt).',
                          'Données opérationnelles : Fiches clients, contrats, interventions de traitement, tarifs et historiques de factures.',
                          'Paramètres & Configuration : Préférences de thème, configuration de connexion MySQL et paramètres de notifications.',
                          'Journaux système & Logs : Logs techniques d\'erreurs locales destinés exclusivement au débogage et à la stabilité.',
                        ],
                      ),

                      // Section 3: Utilisation des données
                      _buildSectionCard(
                        context,
                        isDark: isDark,
                        number: '03',
                        icon: Icons.query_stats_rounded,
                        title: 'Utilisation des Données',
                        content:
                            'Vos données sont exploitées exclusivement pour le fonctionnement métier de votre entreprise :',
                        bullets: const [
                          'Planification, génération et suivi des calendriers d\'interventions.',
                          'Émission et suivi de l\'état de paiement des factures.',
                          'Génération d\'exports et de rapports analytiques au format Excel.',
                          'Gestion de l\'authentification et du contrôle d\'accès par rôle.',
                        ],
                        highlightNote:
                            'Toutes vos données restent strictement votre propriété. Elles ne sont jamais revendues, louées ou cédées à des tiers.',
                      ),

                      // Section 4: Stockage & Chiffrement
                      _buildSectionCard(
                        context,
                        isDark: isDark,
                        number: '04',
                        icon: Icons.storage_rounded,
                        title: 'Stockage & Chiffrement',
                        content:
                            'Planificator repose sur une architecture de données contrôlée par l\'utilisateur :',
                        bullets: const [
                          'Base de Données MySQL : Vos données métier sont stockées sur votre base MySQL locale ou privée.',
                          'Chiffrement des Mots de Passe : Les mots de passe des comptes sont irréversiblement hachés via l\'algorithme BCrypt.',
                          'Identifiants Sécurisés : Les clés et tokens système sont stockés de manière chiffrée via Secure Storage (DPAPI/Keystore/Keychain).',
                        ],
                      ),

                      // Section 5: Sécurité des Données
                      _buildSectionCard(
                        context,
                        isDark: isDark,
                        number: '05',
                        icon: Icons.security_rounded,
                        title: 'Sécurité & Protection',
                        content:
                            'Nous appliquons des mesures de sécurité administratives, techniques et physiques rigoureuses :\n\n'
                            '• Protection contre le brute-force grâce à un limiteur de tentatives de connexion (Rate Limiting).\n'
                            '• Masquage automatique des secrets et hachages dans les fichiers de journaux système.\n'
                            '• Exécution isolée des requêtes SQL pour éviter les blocages de l\'interface et garantir la stabilité.',
                      ),

                      // Section 6: Vos Droits
                      _buildSectionCard(
                        context,
                        isDark: isDark,
                        number: '06',
                        icon: Icons.verified_user_outlined,
                        title: 'Vos Droits & Contrôle',
                        bullets: const [
                          'Droit d\'accès & de rectification : Modification autonome de votre profil et de vos données métier.',
                          'Droit à l\'exportation : Récupération intégrale de vos données en format ouvert Excel à tout moment.',
                          'Droit à l\'effacement : Suppression définitive de votre compte ou de vos données clients.',
                        ],
                      ),

                      // Section 7: Conformité Réglementaire
                      _buildSectionCard(
                        context,
                        isDark: isDark,
                        number: '07',
                        icon: Icons.gavel_rounded,
                        title: 'Conformité Réglementaire',
                        content:
                            'Notre politique respecte les principes directeurs des réglementations internationales sur la protection des données :\n\n'
                            '• RGPD (Règlement Général sur la Protection des Données - Union Européenne)\n'
                            '• CCPA (California Consumer Privacy Act)\n'
                            '• PIPEDA (Loi sur la protection des renseignements personnels - Canada)',
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
                    Icons.shield_outlined,
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
                        'POLITIQUE DE CONFIDENTIALITÉ',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Protection & Traitement des Données',
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
                'L\'Essentiel en 4 Points',
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
                    icon: Icons.lock_outline_rounded,
                    title: 'Mots de passe hachés BCrypt',
                    desc: 'Vos identifiants ne sont jamais stockés en clair.',
                  ),
                  _buildSummaryTile(
                    isWide: isWide,
                    icon: Icons.block_rounded,
                    title: 'Zéro revente de données',
                    desc: 'Vos fiches clients et contrats restent strictly privés.',
                  ),
                  _buildSummaryTile(
                    isWide: isWide,
                    icon: Icons.file_download_outlined,
                    title: 'Exportation souveraine',
                    desc: 'Récupérez vos fichiers Excel complets à tout moment.',
                  ),
                  _buildSummaryTile(
                    isWide: isWide,
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Conformité RGPD & CCPA',
                    desc: 'Respect strict des normes internationales de vie privée.',
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
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppTheme.successGreen, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      highlightNote,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successGreen,
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
                  'Questions sur la confidentialité ?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Écrivez à support@apexnova-labs.com ou contact@apexnova-labs.com. Réponses sous 10 jours ouvrés.',
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
