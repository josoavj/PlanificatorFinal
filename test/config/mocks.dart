import 'package:mockito/mockito.dart';
import 'package:planificator/services/database_service.dart';
import 'package:mysql1/mysql1.dart';

// Mock partagé pour DatabaseService
class MockDatabaseService extends Mock implements DatabaseService {
  bool _mockIsConnected = true;

  @override
  bool get isConnected => _mockIsConnected;

  set isConnected(bool value) => _mockIsConnected = value;
  
  @override
  Future<Map<String, dynamic>?> queryOne(String? sql, {List<dynamic>? params, bool? useCache = true}) =>
      super.noSuchMethod(Invocation.method(#queryOne, [sql], {#params: params, #useCache: useCache}), 
      returnValue: Future<Map<String, dynamic>?>.value());

  @override
  Future<List<Map<String, dynamic>>> query(String? sql, [List? params, bool? useCache = true]) =>
      super.noSuchMethod(Invocation.method(#query, [sql, params, useCache]), 
      returnValue: Future<List<Map<String, dynamic>>>.value([]));

  @override
  Future<void> execute(String? sql, [List<dynamic>? params]) =>
      super.noSuchMethod(Invocation.method(#execute, [sql, params]), 
      returnValue: Future<void>.value());

  @override
  Future<int> insert(String? sql, [List<dynamic>? params]) =>
      super.noSuchMethod(Invocation.method(#insert, [sql, params]), 
      returnValue: Future<int>.value(0));

  @override
  Future<T> transaction<T>(Future<T> Function(MySqlConnection conn)? action) {
    return super.noSuchMethod(
      Invocation.method(#transaction, [action]),
      returnValue: _getFutureDefaultValue<T>(),
    );
  }

  Future<T> _getFutureDefaultValue<T>() async {
    if (T == bool) return true as T;
    if (T == int) return 0 as T;
    // Pour Future<void>, null est acceptable si on cast correctement
    return null as T;
  }
}
