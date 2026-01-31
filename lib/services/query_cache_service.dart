import 'dart:async';
import '../services/logging_service.dart';

/// Service de cache en mémoire pour les requêtes SQL fréquentes
///
/// Optimisation pour Windows en évitant les requêtes répétitives.
/// Utilisé principalement pour les données qui changent rarement:
/// - Listes de clients
/// - Listes de contrats
/// - Lookups (client by ID, etc.)
class QueryCacheService {
  static final QueryCacheService _instance = QueryCacheService._internal();
  final logger = createLoggerWithFileOutput(name: 'query_cache_service');

  final Map<String, CacheEntry> _cache = {};
  Timer? _cleanupTimer;

  // Configuration
  static const Duration defaultTTL = Duration(minutes: 15);
  static const int maxCacheSize = 100;

  QueryCacheService._internal() {
    _initializeCleanup();
  }

  factory QueryCacheService() {
    return _instance;
  }

  /// Initialise le nettoyage automatique du cache chaque minute
  void _initializeCleanup() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _removeExpiredEntries();
    });
  }

  /// Récupère une valeur du cache si elle existe et n'est pas expirée
  dynamic get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired()) {
      _cache.remove(key);
      return null;
    }

    return entry.data;
  }

  /// Stocke une valeur dans le cache (liste de maps ou map unique)
  void set(String key, dynamic data, {Duration ttl = defaultTTL}) {
    // Ne pas cacher les résultats vides
    if (data == null) return;
    if (data is List && data.isEmpty) return;

    // Limiter la taille du cache
    if (_cache.length >= maxCacheSize) {
      final oldestKey = _cache.entries
          .reduce(
            (a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b,
          )
          .key;
      _cache.remove(oldestKey);
      logger.i('Cache limit reached, removed oldest entry: $oldestKey');
    }

    _cache[key] = CacheEntry(data: data, expiresAt: DateTime.now().add(ttl));

    final dataSize = data is List ? data.length : 1;
    logger.d('Cache SET: $key ($dataSize rows, TTL: ${ttl.inSeconds}s)');
  }

  /// Invalide une clé spécifique du cache
  void invalidate(String key) {
    _cache.remove(key);
    logger.d('Cache INVALIDATED: $key');
  }

  /// Invalide toutes les entrées du cache (après modification de données)
  void invalidateAll() {
    _cache.clear();
    logger.i('Cache CLEARED completely');
  }

  /// Invalide les caches liés à une entité spécifique
  void invalidateByEntity(String entityType, {int? entityId}) {
    final keysToRemove = <String>[];

    for (final key in _cache.keys) {
      if (entityId != null) {
        // Invalider les entrées spécifiques à l'entité
        if (key.contains('${entityType}_$entityId')) {
          keysToRemove.add(key);
        }
      } else {
        // Invalider tous les caches de ce type d'entité
        if (key.startsWith(entityType)) {
          keysToRemove.add(key);
        }
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    logger.d(
      'Cache invalidated for entity: $entityType${entityId != null ? '_$entityId' : '_all'}',
    );
  }

  /// Retire les entrées expirées du cache
  void _removeExpiredEntries() {
    final expiredKeys = _cache.entries
        .where((entry) => entry.value.isExpired())
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      logger.d('Removed ${expiredKeys.length} expired cache entries');
    }
  }

  /// Obtient les statistiques du cache
  Map<String, dynamic> getStats() {
    return {
      'totalEntries': _cache.length,
      'maxSize': maxCacheSize,
      'entries': _cache.entries
          .map(
            (e) => {
              'key': e.key,
              'rows': e.value.data.length,
              'expiresIn': e.value.expiresAt
                  .difference(DateTime.now())
                  .inSeconds,
            },
          )
          .toList(),
    };
  }

  /// Nettoie les ressources (appelé à la fermeture de l'app)
  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
    logger.i('QueryCacheService disposed');
  }
}

/// Classe interne pour représenter une entrée du cache
class CacheEntry {
  final dynamic data; // List<Map<String, dynamic>> ou Map<String, dynamic>
  final DateTime timestamp = DateTime.now();
  final DateTime expiresAt;

  CacheEntry({required this.data, required this.expiresAt});

  bool isExpired() => DateTime.now().isAfter(expiresAt);
}

/// Utilitaires pour générer des clés de cache cohérentes
class CacheKeys {
  static String clientsList() => 'clients_list';
  static String client(int clientId) => 'client_$clientId';
  static String clientsByAxe(String axe) => 'clients_axe_$axe';

  static String contratsList() => 'contrats_list';
  static String contrat(int contratId) => 'contrat_$contratId';
  static String contratsByClient(int clientId) => 'contrats_client_$clientId';

  static String factursList() => 'factures_list';
  static String facture(int factureId) => 'facture_$factureId';

  static String planningsList() => 'planning_list';
  static String planning(int planningId) => 'planning_$planningId';

  static String typeTraitementsList() => 'type_traitements_list';
}
