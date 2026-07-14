import 'package:flutter/material.dart';
import '../core/theme.dart';

class AppSnackBars {
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();

    final width = MediaQuery.of(context).size.width;
    // Sur desktop, on limite la largeur pour l'effet "toast"
    final snackBarWidth = width > 600 ? 400.0 : width * 0.9;

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        width: snackBarWidth,
      ),
    );
  }
}
