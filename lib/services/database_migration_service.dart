import 'database_service.dart';

class DatabaseMigrationService {
  final DatabaseService _database;

  DatabaseMigrationService({DatabaseService? database})
    : _database = database ?? DatabaseService();

  Future<void> migrate() async {
    await _database.execute('''
      CREATE TABLE IF NOT EXISTS SchemaMigration (
        version INT NOT NULL PRIMARY KEY,
        applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    final applied = await _database.query(
      'SELECT version FROM SchemaMigration ORDER BY version',
      null,
      false,
    );
    final versions = applied
        .map((row) => row['version'])
        .whereType<num>()
        .map((value) => value.toInt())
        .toSet();

    if (!versions.contains(1)) {
      await _addColumnIfMissing(
        'Account',
        'recovery_code_hash',
        'VARCHAR(255) NULL',
      );
      await _addColumnIfMissing(
        'Account',
        'recovery_code_created_at',
        'TIMESTAMP NULL',
      );
      await _database.execute(
        'INSERT INTO SchemaMigration (version) VALUES (1)',
      );
    }
    final index = await _database.query(
      'SELECT COUNT(*) AS count FROM INFORMATION_SCHEMA.STATISTICS '
      'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND INDEX_NAME = ?',
      ['Account', 'idx_account_recovery_code'],
      false,
    );
    if ((index.first['count'] as num?) == 0) {
      await _database.execute(
        'CREATE INDEX idx_account_recovery_code ON Account(recovery_code_hash)',
      );
    }
  }

  Future<void> _addColumnIfMissing(
    String table,
    String column,
    String definition,
  ) async {
    final rows = await _database.query(
      'SELECT COUNT(*) AS count FROM INFORMATION_SCHEMA.COLUMNS '
      'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?',
      [table, column],
      false,
    );
    final count = rows.first['count'];
    if (count is num && count == 0) {
      await _database.execute(
        'ALTER TABLE `$table` ADD COLUMN `$column` $definition',
      );
    }
  }
}
