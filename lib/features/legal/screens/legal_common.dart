import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/theme.dart';

const _legalSurface = Color(0xFFFFFFFF);
const _legalText = Color(0xFF424242);
const _legalMuted = Color(0xFF5C5C5C);
const _legalBorder = Color(0xFFE3E3E3);

BoxDecoration legalCardDecoration({double radius = 16}) {
  return BoxDecoration(
    color: _legalSurface,
    border: Border.all(color: _legalBorder),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 8)),
    ],
  );
}

class LegalRule {
  const LegalRule(this.title, this.description);
  final String title;
  final String description;
}

class LegalInfo {
  LegalInfo._();

  static const company = 'APEXNova Labs';
  static const editor = 'Josoa Vonjiniaina';
  static const version = '2.1.1';
  static const email = 'josoavonjiniaina13@gmail.com';
  static const location = 'Antananarivo, Madagascar';
  static const responseDelay = '10 jours ouvrables';
  static const lastUpdate = '2 Novembre 2026';
  static const copyright = '© 2026 APEXNova Labs · Licence MIT';
  static const repoUrl = 'https://github.com/josoavj/PlanificatorFinal';
  static const issuesUrl = '$repoUrl/issues';
  static const editorUrl = 'https://github.com/josoavj';

  static const regulations = [
    LegalRule(
      'RGPD (UE)',
      'Respecte les principes du Règlement Général sur la Protection des Données',
    ),
    LegalRule(
      'CCPA (Californie)',
      'Respecte les principes de la California Consumer Privacy Act',
    ),
    LegalRule(
      'PIPEDA (Canada)',
      'Respecte les principes de la loi canadienne sur la protection des renseignements personnels',
    ),
  ];
}

Future<void> openLegalLink(
  BuildContext context,
  Uri uri, {
  String? copyFallback,
}) async {
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (opened || !context.mounted) return;

  if (copyFallback != null) {
    await Clipboard.setData(ClipboardData(text: copyFallback));
    if (!context.mounted) return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(
        copyFallback != null
            ? 'Aucune application e-mail trouvée : adresse copiée.'
            : 'Impossible d’ouvrir le lien.',
      ),
    ),
  );
}

class LegalBadge {
  const LegalBadge(this.icon, this.text);
  final IconData icon;
  final String text;
}

class LegalPage extends StatelessWidget {
  const LegalPage({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.icon,
    required this.children,
    this.badges = const [],
  });

  final String eyebrow;
  final String title;
  final IconData icon;
  final List<LegalBadge> badges;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _LegalHeader(
            eyebrow: eyebrow,
            title: title,
            icon: icon,
            badges: badges,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(150, 24, 150, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...children,
                const SizedBox(height: 32),
                const LegalFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalHeader extends StatelessWidget {
  const _LegalHeader({
    required this.eyebrow,
    required this.title,
    required this.icon,
    required this.badges,
  });

  final String eyebrow;
  final String title;
  final IconData icon;
  final List<LegalBadge> badges;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      padding: const EdgeInsets.fromLTRB(150, 28, 150, 28),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (Navigator.of(context).canPop()) ...[
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    tooltip: 'Retour',
                  ),
                  const SizedBox(width: 4),
                ],
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  for (final b in badges)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(b.icon, color: Colors.white, size: 13),
                          const SizedBox(width: 6),
                          Text(
                            b.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LegalFooter extends StatelessWidget {
  const LegalFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);
    return Center(
      child: Column(
        children: [
          Text(
            LegalInfo.copyright,
            style: TextStyle(fontSize: 12, color: muted),
          ),
          const SizedBox(height: 4),
          Text(
            'Édité et maintenu par ${LegalInfo.editor}',
            style: TextStyle(fontSize: 12, color: muted),
          ),
          const SizedBox(height: 4),
          Text(
            'Dernière mise à jour le ${LegalInfo.lastUpdate}',
            style: TextStyle(fontSize: 11, color: muted.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

class LegalSectionTitle extends StatelessWidget {
  const LegalSectionTitle(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 20,
          height: 1.3,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class LegalIconBadge extends StatelessWidget {
  const LegalIconBadge(this.icon, {super.key, this.color});
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primaryBlue;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color == AppTheme.successGreen
            ? const Color(0xFFE6F4E7)
            : const Color(0xFFE3EEFA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: c, size: 20),
    );
  }
}

class LegalPill extends StatelessWidget {
  const LegalPill(this.icon, this.label, {super.key});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    const primary = AppTheme.primaryBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3EEFA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LegalAdaptiveRow extends StatelessWidget {
  const LegalAdaptiveRow({
    super.key,
    required this.children,
    this.breakpoint = 640,
  });
  final List<Widget> children;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(width: 16),
                  Expanded(child: children[i]),
                ],
              ],
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              children[i],
            ],
          ],
        );
      },
    );
  }
}

class LegalSectionCard extends StatelessWidget {
  const LegalSectionCard({
    super.key,
    required this.number,
    required this.icon,
    required this.title,
    this.content,
    this.bullets,
    this.note,
  });

  final String number;
  final IconData icon;
  final String title;
  final String? content;
  final List<String>? bullets;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    const body = _legalText;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: legalCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3EEFA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  number,
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icon, color: primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (content != null) ...[
            const SizedBox(height: 12),
            Text(
              content!,
              style: const TextStyle(fontSize: 14, height: 1.6, color: body),
            ),
          ],
          if (bullets != null) ...[
            const SizedBox(height: 12),
            for (final b in bullets!)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7, right: 10),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        b,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: body,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (note != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4E7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB7DDB9)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: AppTheme.successGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      note!,
                      style: theme.textTheme.bodySmall?.copyWith(
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
}

class LegalSummaryItem {
  const LegalSummaryItem(this.icon, this.title, this.description);
  final IconData icon;
  final String title;
  final String description;
}

class LegalSummaryCard extends StatelessWidget {
  const LegalSummaryCard({super.key, required this.title, required this.items});
  final String title;
  final List<LegalSummaryItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    const muted = _legalMuted;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: legalCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 16.0;
              final columns = constraints.maxWidth > 550 ? 2 : 1;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: 14,
                children: [
                  for (final it in items)
                    SizedBox(
                      width: width,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(it.icon, color: primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  it.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  it.description,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: muted,
                                    height: 1.4,
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
          ),
        ],
      ),
    );
  }
}

/// Carte de contact : e-mail (écrire / copier), adresse, support GitHub.
class LegalContactCard extends StatelessWidget {
  const LegalContactCard({super.key});

  Uri get _mailto => Uri.parse(
    'mailto:${LegalInfo.email}?subject=${Uri.encodeComponent('Planificator - Contact')}',
  );

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: LegalInfo.email));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Adresse e-mail copiée'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    const muted = _legalMuted;

    Widget row({
      required IconData icon,
      required String label,
      required String value,
      List<Widget> actions = const [],
    }) {
      return Row(
        children: [
          LegalIconBadge(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(color: muted),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...actions,
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: legalCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row(
            icon: Icons.email_outlined,
            label: 'E-mail',
            value: LegalInfo.email,
            actions: [
              IconButton(
                tooltip: 'Copier l’adresse',
                icon: Icon(Icons.copy_rounded, color: primary),
                onPressed: () => _copy(context),
              ),
              IconButton(
                tooltip: 'Envoyer un e-mail',
                icon: Icon(Icons.send_rounded, color: primary),
                onPressed: () => openLegalLink(
                  context,
                  _mailto,
                  copyFallback: LegalInfo.email,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          row(
            icon: Icons.location_on_outlined,
            label: 'Adresse',
            value: LegalInfo.location,
          ),
          const SizedBox(height: 14),
          row(
            icon: Icons.bug_report_outlined,
            label: 'Support et signalements',
            value: 'GitHub',
            actions: [
              IconButton(
                tooltip: 'Ouvrir les issues GitHub',
                icon: Icon(Icons.open_in_new_rounded, color: primary),
                onPressed: () =>
                    openLegalLink(context, Uri.parse(LegalInfo.issuesUrl)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const LegalPill(
            Icons.schedule,
            'Délai de réponse : ${LegalInfo.responseDelay}',
          ),
        ],
      ),
    );
  }
}
