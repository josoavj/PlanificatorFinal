import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AppInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const AppInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Icon(
        icon, 
        color: isDark ? AppTheme.accentBlue : AppTheme.primaryBlue, 
        size: 22
      ),
      title: Text(
        label, 
        style: TextStyle(
          fontSize: 11, 
          color: isDark ? Colors.white54 : Colors.grey[600], 
          fontWeight: FontWeight.bold
        )
      ),
      subtitle: Text(
        value.isNotEmpty ? value : '-',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
