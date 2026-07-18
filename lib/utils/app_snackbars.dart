import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';

class AppSnackBars {
  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppTheme.successGreen, Icons.check_circle_outline);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, AppTheme.errorRed, Icons.error_outline);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, AppTheme.infoBlue, Icons.info_outline);
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message, AppTheme.warningOrange, Icons.warning_amber_outlined);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    // Annuler le précédent toast s'il existe
    _timer?.cancel();
    if (_currentEntry != null) {
      try {
        _currentEntry?.remove();
      } catch (e) {
        // Ignorer si déjà supprimé
      }
      _currentEntry = null;
    }

    // Récupérer l'overlay au sommet (celui qui passe devant les dialogues)
    final overlay = Overlay.of(context, rootOverlay: true);
    
    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 60.0, // Apparaît en bas
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: _PremiumToast(
              message: message,
              color: color,
              icon: icon,
            ),
          ),
        ),
      ),
    );

    overlay.insert(_currentEntry!);

    // Auto-suppression après 3.5 secondes
    _timer = Timer(const Duration(milliseconds: 3500), () {
      if (_currentEntry != null) {
        _currentEntry?.remove();
        _currentEntry = null;
      }
    });
  }
}

class _PremiumToast extends StatefulWidget {
  final String message;
  final Color color;
  final IconData icon;

  const _PremiumToast({
    required this.message,
    required this.color,
    required this.icon,
  });

  @override
  State<_PremiumToast> createState() => _PremiumToastState();
}

class _PremiumToastState extends State<_PremiumToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final toastWidth = width > 600 ? 450.0 : width * 0.9;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Container(
          width: toastWidth,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
