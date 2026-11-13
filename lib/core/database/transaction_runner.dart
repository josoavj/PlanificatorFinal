import 'package:mysql1/mysql1.dart';

import 'database_service.dart';

typedef TransactionAction<T> = Future<T> Function(MySqlConnection connection);

class TransactionRunner {
  final DatabaseService database;

  const TransactionRunner(this.database);

  Future<T> run<T>(TransactionAction<T> action) {
    return database.transaction(action);
  }
}
