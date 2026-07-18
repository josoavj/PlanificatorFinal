import 'package:flutter/material.dart';

class CategoryButton extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onPressed;
  final Color? color;

  const CategoryButton({
    super.key,
    required this.label,
    required this.count,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? Colors.red[400],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (color ?? Colors.red).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count traitement(s)',
                style: const TextStyle(color: Colors.black87, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
