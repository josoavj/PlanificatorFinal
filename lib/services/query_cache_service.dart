import 'dart:async';
import '../services/logging_service.dart';

/// Service de cache unifié pour les requêtes SQL et les entités.
///
/// Optimisation pour Windows en évitant les requêtes répétitives.
/// Gère deux types de cache :
/// 1. Cache basé sur les requêtes SQL (bas niveau)
/// 2. Cache basé sur les entités (haut niveau - ex: client_1)
class QueryCacheService {
  static final QueryCacheService _instance = QueryCacheService._internal();
  final logger = createLoggerWithFileOutput(name: 'query_cache_service');

  final Map<String, CacheEntry> _cache = {};
  Timer? _cleanupTimer;

  // Configuration
  static const Duration defaultTTL = Duration(minutes: 15);
  static const int maxCacheSize = 200; // Augmenté car unifié

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

  // --- NIVEAU ENTITÉ (Haut niveau) ---

  /// Récupère une valeur du cache par clé sémantique
  dynamic get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired()) {
      _cache.remove(key);
      return null;
    }

    return entry.data;
  }

  /// Stocke une valeur dans le cache par clé sémantique
  void set(String key, dynamic data, {Duration ttl = defaultTTL}) {
    if (data == null) return;
    if (data is List && data.isEmpty) return;

    _enforceMaxSize();

    _cache[key] = CacheEntry(data: data, expiresAt: DateTime.now().add(ttl));

    final dataSize = data is List ? data.length : 1;
    logger.d('Cache SET (Entity): $key ($dataSize rows, TTL: ${ttl.inSeconds}s)');
  }

  // --- NIVEAU SQL (Bas niveau) ---

  /// Récupère le résultat d'une requête SQL brute du cache
  List<Map<String, dynamic>>? getQuery(String sql, List<dynamic>? params) {
    final key = _generateSqlKey(sql, params);
    final data = get(key);
    if (data != null && data is List<Map<String, dynamic>>) {
      logger.d('Cache HIT (SQL): ${sql.substring(0, _min(30, sql.length))}...');
      return data;
    }
    return null;
  }

  /// Stocke le résultat d'une requête SQL brute dans le cache
  void setQuery(String sql, List<dynamic>? params, List<Map<String, dynamic>> data, {Duration ttl = const Duration(minutes: 5)}) {
    final key = _generateSqlKey(sql, params);
    set(key, data, ttl: ttl);
  }

  // --- INVALIDATION ---

  /// Invalide une clé spécifique
  void invalidate(String key) {
    _cache.remove(key);
    logger.d('Cache INVALIDATED: $key');
  }

  /// Invalide tout le cache
  void invalidateAll() {
    _cache.clear();
    logger.i('Cache CLEARED completely');
  }

  /// Invalide les caches liés à une entité spécifique
  void invalidateByEntity(String entityType, {int? entityId}) {
    final keysToRemove = <String>[];
    final typeLower = entityType.toLowerCase();

    for (final key in _cache.keys) {
      if (entityId != null) {
        if (key.contains('${entityType}_$entityId')) {
          keysToRemove.add(key);
        }
      } else {
        // Invalide à la fois les clés sémantiques et les requêtes SQL contenant le nom de l'entité/table
        if (key.startsWith(entityType) || key.toLowerCase().contains(typeLower)) {
          keysToRemove.add(key);
        }
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    logger.d('Cache invalidated for entity: $entityType${entityId != null ? '_$entityId' : '_all'}');
  }

  // --- INTERNES ---

  void _enforceMaxSize() {
    if (_cache.length >= maxCacheSize) {
      final oldestKey = _cache.entries
          .reduce((a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b)
          .key;
      _cache.remove(oldestKey);
      logger.i('Cache limit reached, removed oldest entry: $oldestKey');
    }
  }

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

  String _generateSqlKey(String sql, List<dynamic>? params) {
    return 'sql|${sql.hashCode}|${params?.join(',') ?? ''}';
  }

  int _min(int a, int b) => a < b ? a : b;

  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
    logger.i('QueryCacheService disposed');
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime timestamp = DateTime.now();
  final DateTime expiresAt;

  CacheEntry({required this.data, required this.expiresAt});

  bool isExpired() => DateTime.now().isAfter(expiresAt);
}

class CacheKeys {
  static String clientsList([int? page]) => page != null ? 'clients_list_page_$page' : 'clients_list';
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
