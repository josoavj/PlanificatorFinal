import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AppSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsets? margin;
  final EdgeInsets? padding; // Nouveau : Contrôle du padding interne
  final Widget? headerAction;
  final Color? backgroundColor;
  final double radius;
  final bool showDividers; // Nouveau : Permet de désactiver les lignes de séparation

  const AppSection({
    super.key,
    required this.title,
    required this.children,
    this.margin,
    this.padding,
    this.headerAction,
    this.backgroundColor,
    this.radius = 24,
    this.showDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue,
                ),
              ),
              ?headerAction,
            ],
          ),
        ),
        Container(
          margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
          decoration: AppTheme.cardDecoration(context, radius: radius).copyWith(
            color: backgroundColor,
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: padding ?? EdgeInsets.zero, // Application du padding
              child: Column(
                children: List.generate(children.length, (index) {
                  return Column(
                    children: [
                      children[index],
                      if (showDividers && index < children.length - 1)
                        Divider(
                          height: 1,
                          indent: padding != null ? 0 : 60,
                          endIndent: padding != null ? 0 : 16,
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.05) 
                              : Colors.grey.withValues(alpha: 0.1),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
