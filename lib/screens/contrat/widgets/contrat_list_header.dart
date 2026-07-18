import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class ContratListHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final VoidCallback onRefresh;
  final int contratCount;

  const ContratListHeader({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.contratCount,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : AppTheme.primaryBlue,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32), 
          bottomRight: Radius.circular(32)
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un contrat...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.white70),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white54 : Colors.white70),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                            onPressed: () {
                              searchController.clear();
                              onSearchChanged('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15), 
                  borderRadius: BorderRadius.circular(16)
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                  onPressed: onRefresh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_rounded, color: Colors.white70, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      '$contratCount ${contratCount > 1 ? 'contrats' : 'contrat'}',
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.w800, 
                        fontSize: 12, 
                        letterSpacing: 0.5
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
