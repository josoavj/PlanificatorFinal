/// Smart Cache Manager pour Windows
///
/// Gère le cache des résultats de requête pour éviter
/// les reloads inutiles et améliorer la réactivité
///
/// Utilise une stratégie LRU (Least Recently Used) pour
/// éviter la saturation mémoire sur Windows
library;

import 'dart:developer' show log;

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  DateTime lastAccessed;
  int accessCount;

  CacheEntry({required this.data, required this.timestamp})
    : lastAccessed = DateTime.now(),
      accessCount = 0;

  bool isExpired(Duration ttl) {
    return DateTime.now().difference(timestamp) > ttl;
  }

  void markAccessed() {
    lastAccessed = DateTime.now();
    accessCount++;
  }
}

class SmartCacheManager<K, V> {
  final int maxSize;
  final Duration defaultTtl;
  final Map<K, CacheEntry<V>> _cache = {};

  SmartCacheManager({
    this.maxSize = 100,
    this.defaultTtl = const Duration(minutes: 10),
  });

  /// Récupérer depuis le cache
  V? get(K key, {bool markAccessed = true}) {
    final entry = _cache[key];

    if (entry == null) {
      return null;
    }

    if (entry.isExpired(defaultTtl)) {
      _cache.remove(key);
      return null;
    }

    if (markAccessed) {
      entry.markAccessed();
    }

    return entry.data;
  }

  /// Stocker dans le cache
  void set(K key, V value) {
    if (_cache.length >= maxSize) {
      _evictLRU();
    }

    _cache[key] = CacheEntry<V>(data: value, timestamp: DateTime.now());
  }

  /// Invalider une clé
  void invalidate(K key) {
    _cache.remove(key);
  }

  /// Invalider toutes les clés commençant par un préfixe
  void invalidatePrefix(String prefix) {
    if (K is String) {
      _cache.removeWhere((key, _) => (key as String).startsWith(prefix));
    }
  }

  /// Vider tout le cache
  void clear() {
    _cache.clear();
  }

  /// Éviction LRU (Least Recently Used)
  void _evictLRU() {
    if (_cache.isEmpty) return;

    final lruKey = _cache.entries
        .reduce(
          (a, b) => a.value.lastAccessed.isBefore(b.value.lastAccessed) ? a : b,
        )
        .key;

    _cache.remove(lruKey);
  }

  /// Statistiques du cache
  Map<String, dynamic> stats() => {
    'size': _cache.length,
    'maxSize': maxSize,
    'usage': _cache.values.map((e) => e.accessCount).fold(0, (a, b) => a + b),
    'avgAccessCount': _cache.isEmpty
        ? 0
        : _cache.values.map((e) => e.accessCount).fold(0, (a, b) => a + b) /
              _cache.length,
  };

  /// Enregistrer les stats
  void logStats() {
    final statsMap = stats();
    final size = statsMap['size'];
    final maxSize = statsMap['maxSize'];
    final usage = statsMap['usage'];
    final avg = (statsMap['avgAccessCount'] as double).toStringAsFixed(1);
    log('CACHE | Size: $size/$maxSize | Accesses: $usage | Avg: $avg');
  }
}

/// Cache Managers pour différentes ressources
class AppCacheManagers {
  static final client = SmartCacheManager<int, Map<String, dynamic>>(
    maxSize: 50,
    defaultTtl: const Duration(minutes: 15),
  );

  static final contrat = SmartCacheManager<int, Map<String, dynamic>>(
    maxSize: 50,
    defaultTtl: const Duration(minutes: 15),
  );

  static final search = SmartCacheManager<String, List<Map<String, dynamic>>>(
    maxSize: 30,
    defaultTtl: const Duration(minutes: 10),
  );

  static final planning = SmartCacheManager<String, List<Map<String, dynamic>>>(
    maxSize: 20,
    defaultTtl: const Duration(minutes: 5),
  );

  static void clearAll() {
    client.clear();
    contrat.clear();
    search.clear();
    planning.clear();
  }

  static void logAllStats() {
    log('CLIENT CACHE:');
    client.logStats();
    log('CONTRAT CACHE:');
    contrat.logStats();
    log('SEARCH CACHE:');
    search.logStats();
    log('PLANNING CACHE:');
    planning.logStats();
  }
}
