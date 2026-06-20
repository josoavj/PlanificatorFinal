import './logging_service.dart';

/// Gère le cache des requêtes SQL pour éviter les appels réseau inutiles.
class SmartCacheManager {
  static final SmartCacheManager _instance = SmartCacheManager._internal();
  factory SmartCacheManager() => _instance;
  SmartCacheManager._internal();

  final logger = createLoggerWithFileOutput(name: 'smart_cache_manager');

  // Stockage du cache : Map<Clé_Requête, Résultat>
  final Map<String, _CacheEntry> _cache = {};

  // Durée de vie par défaut du cache (ex: 5 minutes)
  Duration defaultTTL = const Duration(minutes: 5);

  /// Récupère une donnée du cache ou retourne null si expiré/inexistant
  List<Map<String, dynamic>>? get(String sql, List<dynamic>? params) {
    final key = _generateKey(sql, params);
    final entry = _cache[key];

    if (entry != null && !entry.isExpired) {
      logger.d('Cache HIT for: ${sql.substring(0, Math.min(30, sql.length))}...');
      return entry.data;
    }

    if (entry != null && entry.isExpired) {
      logger.d('Cache EXPIRED for key: $key');
      _cache.remove(key);
    }

    return null;
  }

  /// Ajoute des données au cache
  void set(String sql, List<dynamic>? params, List<Map<String, dynamic>> data, {Duration? ttl}) {
    final key = _generateKey(sql, params);
    _cache[key] = _CacheEntry(
      data: data,
      expiry: DateTime.now().add(ttl ?? defaultTTL),
    );
  }

  /// Invalide tout le cache (utile après un INSERT/UPDATE/DELETE massif)
  void invalidateAll() {
    _cache.clear();
    logger.i('Global cache invalidated');
  }

  /// Invalide spécifiquement les requêtes liées à une table
  void invalidateTable(String tableName) {
    final tableLower = tableName.toLowerCase();
    _cache.removeWhere((key, value) => key.toLowerCase().contains(tableLower));
    logger.d('Cache invalidated for table: $tableName');
  }

  String _generateKey(String sql, List<dynamic>? params) {
    return '$sql|${params?.join(',') ?? ''}';
  }
}

class _CacheEntry {
  final List<Map<String, dynamic>> data;
  final DateTime expiry;

  _CacheEntry({required this.data, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);
}

// Helper simple pour limiter la longueur des chaînes dans les logs
class Math {
  static int min(int a, int b) => a < b ? a : b;
}
