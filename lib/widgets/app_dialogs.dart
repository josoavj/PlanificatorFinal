import 'package:flutter/material.dart';
import 'dart:ui';
import '../core/theme.dart';

class AppDialogs {
  /// Affiche un dialogue avec un arrière-plan flouté
  static Future<T?> showBlurDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.1),
      builder: (BuildContext ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: builder(ctx),
        );
      },
    );
  }

  // Confirmation dialog simple
  static Future<bool?> confirmDelete(
    BuildContext context, {
    String title = 'Confirmation',
    String message = 'Êtes-vous sûr de vouloir supprimer ?',
  }) {
    return showBlurDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // Confirmation dialog générique
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
  }) {
    return showBlurDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // Input dialog simple
  static Future<String?> input(
    BuildContext context, {
    required String title,
    String? hint,
    String? initialValue,
    String inputLabel = 'Entrez une valeur',
    String confirmText = 'Confirmer',
  }) {
    final controller = TextEditingController(text: initialValue);

    return showBlurDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: inputLabel, hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // Info dialog
  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showBlurDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Error dialog
  static Future<void> error(
    BuildContext context, {
    required String message,
    String title = 'Erreur',
  }) {
    return showBlurDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Selection dialog (liste d'options)
  static Future<T?> selection<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required String Function(T) itemLabel,
    T? selectedItem,
  }) {
    return showBlurDialog<T>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: RadioGroup<T>(
            groupValue: selectedItem,
            onChanged: (value) {
              Navigator.of(ctx).pop(value);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items
                  .map(
                    (item) => RadioListTile<T>(
                      title: Text(itemLabel(item)),
                      value: item,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  // Loading dialog
  static void loading(
    BuildContext context, {
    String message = 'Chargement...',
  }) {
    showBlurDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  // Bottom sheet dialog
  static Future<T?> bottomSheet<T>(
    BuildContext context, {
    required Widget child,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) => child,
    );
  }
}
