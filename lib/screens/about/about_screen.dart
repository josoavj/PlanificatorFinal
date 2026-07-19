import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../utils/app_snackbars.dart';
import '../../widgets/features_dialog.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        AppSnackBars.showError(context, 'Impossible d\'ouvrir: $url');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildModernHeader(colorScheme, isDark),
            const SizedBox(height: 70), // Espace pour l'avatar qui dépasse
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    _buildVisionSection(context, theme, colorScheme),
                    const SizedBox(height: 32),
                    _buildBenefitsSection(theme, colorScheme),
                    const SizedBox(height: 32),
                    _buildOrganizationSection(context, theme, colorScheme),
                    const SizedBox(height: 32),
                    _buildTeamSection(context, theme, colorScheme),
                    const SizedBox(height: 48),
                    _buildFooter(context, theme, colorScheme),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(ColorScheme colorScheme, bool isDark) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainer : AppTheme.primaryBlue,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(48),
            ),
          ),
        ),
        Positioned(
          top: 25,
          child: Column(
            children: [
              const Text(
                'Planificator',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'GESTION ET SUIVI DE PLANNING CLIENTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -45,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBg : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: Image.asset(
                'assets/Pictures/Logo Planificator.png',
                height: 110,
                width: 110,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisionSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Text(
          'Notre Vision',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Planificator est conçu pour transformer la gestion administrative en une expérience fluide et maîtrisée. Nous croyons que la clarté opérationnelle est le socle de la croissance durable pour toute entreprise de services.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Version v2.1.1 stable',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => FeaturesDialog.show(context),
          icon: const Icon(Icons.rocket_launch_outlined, size: 18),
          label: const Text('Découvrir toutes les fonctionnalités'),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            'L\'impact Planificator',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        _buildBenefitCard(
          icon: Icons.speed_outlined,
          title: 'Productivité Accrue',
          desc: 'Automatisez vos tâches répétitives et concentrez-vous sur vos clients.',
          color: Colors.blue,
        ),
        _buildBenefitCard(
          icon: Icons.shield_outlined,
          title: 'Sécurité Maximale',
          desc: 'Vos données restent sous votre contrôle, loin des nuages opaques.',
          color: Colors.green,
        ),
        _buildBenefitCard(
          icon: Icons.analytics_outlined,
          title: 'Visibilité Totale',
          desc: 'Suivez vos indicateurs de performance en temps réel.',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark 
                  ? AppTheme.glassBorder.withValues(alpha: 0.1) 
                  : Colors.grey.withValues(alpha: 0.25),
            ),
            boxShadow: isDark ? [] : AppTheme.mediumShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey[600], 
                          fontSize: 13,
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
    );
  }

  Widget _buildOrganizationSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            'Géré par',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark 
                  ? AppTheme.glassBorder.withValues(alpha: 0.1) 
                  : Colors.grey.withValues(alpha: 0.25),
            ),
            boxShadow: isDark ? [] : AppTheme.mediumShadow,
          ),
          child: Material(
            color: isDark ? AppTheme.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _launchURL(context, 'https://github.com/APEXNovaLabs'),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _buildAvatarWithFallback(
                      url: 'https://github.com/APEXNovaLabs.png',
                      fallbackIcon: Icons.business,
                      radius: 32,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'APEXNova Labs',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Équipe de développement spécialisée dans les solutions logicielles et mobiles',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : colorScheme.onSurfaceVariant,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.open_in_new_rounded, size: 20, color: colorScheme.primary.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            'L\'Équipe Core',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        _buildAuthorChip(
          context: context,
          name: 'Josoa VONJINIAINA',
          role: 'FullStack Developer',
          desc:
              'Expert en architecture Backend, passionné par l\'UI/UX et les performances système.',
          avatarUrl: 'https://github.com/josoavj.png',
          url: 'https://github.com/josoavj',
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 12),
        _buildAuthorChip(
          context: context,
          name: 'Maminirina ANDRIAMASINORO',
          role: 'FullStack Developer',
          desc:
              'Spécialiste en intégration fluide des processus métiers avec le backend.',
          avatarUrl: 'https://github.com/AinaMaminirina18.png',
          url: 'https://github.com/AinaMaminirina18',
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildAuthorChip({
    required BuildContext context,
    required String name,
    required String role,
    required String desc,
    required String avatarUrl,
    required String url,
    required ColorScheme colorScheme,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark 
              ? AppTheme.glassBorder.withValues(alpha: 0.1) 
              : Colors.grey.withValues(alpha: 0.25),
        ),
        boxShadow: isDark ? [] : AppTheme.softShadow,
      ),
      child: Material(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _launchURL(context, url),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildAvatarWithFallback(
                  url: avatarUrl,
                  fallbackIcon: Icons.person,
                  radius: 32,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        role,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.link_rounded, size: 20, color: colorScheme.primary.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarWithFallback({
    required String url,
    required IconData fallbackIcon,
    required double radius,
    required ColorScheme colorScheme,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
      child: ClipOval(
        child: Image.network(
          url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) =>
                  Icon(fallbackIcon, color: colorScheme.primary, size: radius),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: radius,
                height: radius,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          height: 1,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(
              Icons.code_rounded,
              'GitHub',
              () => _launchURL(
                context,
                'https://github.com/josoavj/PlanificatorFinal',
              ),
              colorScheme,
            ),
            _buildSocialIcon(
              Icons.email_outlined,
              'Support',
              () => _launchURL(context, 'mailto:support@planificator.app'),
              colorScheme,
            ),
            _buildSocialIcon(
              Icons.description_outlined,
              'Changelog',
              () => _launchURL(
                context,
                'https://github.com/josoavj/PlanificatorFinal/releases',
              ),
              colorScheme,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          '© 2025 APEXNova Labs. Tous droits réservés.',
          style: TextStyle(color: colorScheme.outline, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          'Fièrement propulsé par Flutter & MySQL',
          style: TextStyle(
            color: colorScheme.outline,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(
    IconData icon,
    String label,
    VoidCallback onTap,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: colorScheme.primary, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
