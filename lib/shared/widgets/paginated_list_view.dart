import 'package:flutter/material.dart';

/// Widget réutilisable pour listes paginées avec scroll listener
///
/// Utilise NotificationListener pour détecter quand l'utilisateur
/// scroll à 80% de la fin et charge la page suivante automatiquement
class PaginatedListView<T> extends StatelessWidget {
  final List<T> items;
  final IndexedWidgetBuilder itemBuilder;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final EdgeInsets padding;
  final Axis scrollDirection;
  final bool reverse;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo is ScrollEndNotification && !isLoading && hasMore) {
          final metrics = scrollInfo.metrics;
          // Charger quand on atteint 80% du scroll
          if (metrics.pixels >= metrics.maxScrollExtent * 0.8) {
            onLoadMore();
          }
        }
        return false;
      },
      child: ListView.builder(
        scrollDirection: scrollDirection,
        reverse: reverse,
        padding: padding,
        // +1 pour le spinner de chargement si isLoading
        itemCount: items.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          // Afficher spinner à la fin pendant chargement
          if (index == items.length) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: SizedBox(
                  height: 40,
                  width: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            );
          }
          return itemBuilder(context, index);
        },
      ),
    );
  }
}
