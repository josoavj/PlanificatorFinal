import 'package:flutter_test/flutter_test.dart';
import 'package:planificator/services/query_cache_service.dart';

void main() {
  late QueryCacheService cache;

  setUp(() {
    cache = QueryCacheService();
    cache.invalidateAll();
  });

  group('QueryCacheService - Basic Logic', () {
    test('set et get retournent les mêmes données', () {
      final key = 'test_key';
      final data = {'id': 1, 'name': 'Test'};

      cache.set(key, data);
      final retrieved = cache.get(key);

      expect(retrieved, equals(data));
    });

    test('get retourne null si la donnée est expirée', () async {
      final key = 'expired_key';
      final data = {'id': 1};

      // Set avec un TTL de 0 seconde (expire immédiatement)
      cache.set(key, data, ttl: Duration.zero);
      
      // Petit délai pour assurer l'expiration
      await Future.delayed(const Duration(milliseconds: 10));

      final retrieved = cache.get(key);
      expect(retrieved, isNull);
    });

    test('invalidateAll vide complètement le cache', () {
      cache.set('k1', 'v1');
      cache.set('k2', 'v2');
      
      cache.invalidateAll();
      
      expect(cache.get('k1'), isNull);
      expect(cache.get('k2'), isNull);
    });
  });

  group('QueryCacheService - Entity Invalidation', () {
    test('invalidateByEntity supprime uniquement les clés liées', () {
      cache.set('client_1', 'data1');
      cache.set('client_2', 'data2');
      cache.set('facture_1', 'data3');

      cache.invalidateByEntity('client');

      expect(cache.get('client_1'), isNull);
      expect(cache.get('client_2'), isNull);
      expect(cache.get('facture_1'), isNotNull); // Ne doit pas être supprimé
    });

    test('invalidateByEntity avec ID cible une entrée précise', () {
      cache.set('client_1', 'data1');
      cache.set('client_2', 'data2');

      cache.invalidateByEntity('client', entityId: 1);

      expect(cache.get('client_1'), isNull);
      expect(cache.get('client_2'), isNotNull); // Reste dans le cache
    });
  });
}
