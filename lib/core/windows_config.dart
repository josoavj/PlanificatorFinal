/// Windows Performance Configuration
///
/// Configure les optimisations spécifiques à Windows pour Planificator
///
/// Comprend:
/// - Paramètres de cache
/// - Limites de pagination
/// - Stratégies de virtualisation
/// - Tuning d'UI threads
library;

import 'dart:developer' show log;

class WindowsPerformanceConfig {
  /// Limite d'items par page pour éviter lag
  static const int pageSize = 30;

  /// Taille du cache en mémoire pour recherches
  static const int maxSearchCacheSize = 50;

  /// Durée cache pour requêtes identiques
  static const Duration queryCacheDuration = Duration(minutes: 5);

  /// Timeout pour les opérations database
  static const Duration databaseTimeout = Duration(seconds: 60);

  /// Nombre max d'items à afficher sans virtualisation
  static const int maxItemsWithoutVirtualization = 50;

  /// Délai debounce pour recherche (ms)
  static const int searchDebounceMs = 300;

  /// Limite d'items à afficher dans liste sans scrolling
  static const int maxListItemsInExpandedArea = 20;

  /// Utiliser cached network images
  static const bool enableImageCaching = true;

  /// Profondeur max de FutureBuilder imbriqués
  static const int maxNestedFutureBuilders = 2;

  /// Activer lazy loading sur initState
  static const bool enableLazyLoading = true;

  /// Taille max du cache Builder
  static const int maxCacheSize = 100;

  /// Purger cache après N navigations
  static const int purgeAfterNavigations = 10;

  /// Mode Release build required
  static const bool optimizedModeOnly = true;

  /// Debug logs pour Windows optimization
  static const bool debugWindowsPerformance = false;

  static String get summary =>
      '''
====================================================================
          WINDOWS PERFORMANCE OPTIMIZATION CONFIG
====================================================================

  Page Size: $pageSize items/page
  Search Debounce: ${searchDebounceMs}ms
  Cache Duration: ${queryCacheDuration.inMinutes} minutes
  DB Timeout: ${databaseTimeout.inSeconds}s
  Max List Items: $maxListItemsInExpandedArea (no scroll)
  Max Nested Futures: $maxNestedFutureBuilders

  Lazy Loading: ${enableLazyLoading ? 'ENABLED' : 'DISABLED'}
  Image Caching: ${enableImageCaching ? 'ENABLED' : 'DISABLED'}
  Optimized Mode: ${optimizedModeOnly ? 'REQUIRED' : 'OPTIONAL'}

====================================================================
  ''';
}

/// Category d'optimisations à appliquer
enum OptimizationType {
  futureBuilderCaching, // Cache les results de FutureBuilder
  pageScrolling, // Utilise la pagination pour listes
  lazyLoading, // Charge les données à la demande
  imageOptimization, // Optimise les images
  searchDebounce, // Ajoute debounce à la recherche
  listVirtualization, // Virtualise les grandes listes
  consumerOptimization, // Optimise les Consumer widgets
  memoryManagement, // Gère la mémoire proprement
}

/// Tracking des optimisations appliquées
class OptimizationTracker {
  static final Set<String> _applied = {};

  /// Marquer une optimisation comme appliquée
  static void mark(String screenName, OptimizationType type) {
    _applied.add('$screenName::${type.name}');
  }

  /// Vérifier si une optimisation est appliquée
  static bool isApplied(String screenName, OptimizationType type) {
    return _applied.contains('$screenName::${type.name}');
  }

  /// Enregistrer les optimisations appliquées
  static void logApplied() {
    if (WindowsPerformanceConfig.debugWindowsPerformance) {
      log('Applied Optimizations:');
      for (final item in _applied) {
        log('  - $item');
      }
    }
  }
}
