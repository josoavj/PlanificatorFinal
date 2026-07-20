import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../utils/phone_formatter.dart';

class MultiPhoneInput extends StatefulWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final Function(int) onRemove;
  final String title;

  const MultiPhoneInput({
    super.key,
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
    this.title = 'Numéros de contact',
  });

  @override
  State<MultiPhoneInput> createState() => _MultiPhoneInputState();
}

class _MultiPhoneInputState extends State<MultiPhoneInput> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryBlue,
                letterSpacing: 1.2,
              ),
            ),
            if (widget.controllers.length < 3)
              TextButton.icon(
                onPressed: widget.onAdd,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                label: const Text(
                  'AJOUTER UN NUMÉRO',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...widget.controllers.asMap().entries.map((entry) {
          final idx = entry.key;
          final controller = entry.value;

          return Padding(
            padding: EdgeInsets.only(bottom: idx < widget.controllers.length - 1 ? 12 : 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    inputFormatters: [PhoneInputFormatter()],
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: '03X XX XXX XX',
                      prefixIcon: const Icon(Icons.phone_android_rounded, size: 18),
                      filled: true,
                      fillColor: isDark 
                          ? Colors.white.withValues(alpha: 0.03) 
                          : Colors.grey.withValues(alpha: 0.05),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                      ),
                    ),
                  ),
                ),
                if (idx > 0) ...[
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => widget.onRemove(idx),
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: AppTheme.errorRed.withValues(alpha: 0.7),
                    tooltip: 'Supprimer ce numéro',
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
