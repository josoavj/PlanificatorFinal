import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../repositories/index.dart';
import '../../../models/client.dart';

class ClientListHeader extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final VoidCallback onRefresh;

  const ClientListHeader({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onRefresh,
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
                  focusNode: searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un client...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.white70),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white54 : Colors.white70),
                    suffixIcon: searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20), 
                            onPressed: () { 
                              searchController.clear(); 
                              onSearchChanged(''); 
                            }
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
                  onPressed: onRefresh
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
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1))
                ),
                child: Consumer<ClientRepository>(
                  builder: (context, repo, _) {
                    final count = _filterCount(repo.clients);
                    return Row(
                      children: [
                        const Icon(Icons.people_alt_rounded, color: Colors.white70, size: 14), 
                        const SizedBox(width: 8), 
                        Text(
                          '$count ${count > 1 ? 'clients' : 'client'}', 
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.w800, 
                            fontSize: 12, 
                            letterSpacing: 0.5
                          )
                        ),
                      ],
                    );
                  }
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _filterCount(List<Client> clients) {
    if (searchQuery.isEmpty) return clients.length;
    final q = searchQuery.toLowerCase();
    return clients.where((c) => 
      c.fullName.toLowerCase().contains(q) || 
      c.email.toLowerCase().contains(q) || 
      c.telephone.contains(q) || 
      c.adresse.toLowerCase().contains(q)
    ).length;
  }
}
