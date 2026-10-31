import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'database_service.dart';

class BackupService {
  final DatabaseService _database;

  BackupService({DatabaseService? database})
    : _database = database ?? DatabaseService();

  Future<String> createSqlBackup({String? directoryPath}) async {
    final directory = directoryPath == null
        ? Directory(
            '${(await getApplicationDocumentsDirectory()).path}/Planificator/backups',
          )
        : Directory(directoryPath);
    await directory.create(recursive: true);

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/planificator_$timestamp.sql');
    final tables = await _database.query(
      'SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES '
      'WHERE TABLE_SCHEMA = DATABASE() ORDER BY TABLE_NAME',
      null,
      false,
    );
    final output = StringBuffer()
      ..writeln('-- Planificator SQL backup')
      ..writeln('-- Generated: ${DateTime.now().toIso8601String()}')
      ..writeln('SET FOREIGN_KEY_CHECKS = 0;');

    for (final row in tables) {
      final table = row['TABLE_NAME']?.toString();
      if (table == null || !RegExp(r'^[A-Za-z0-9_]+$').hasMatch(table)) {
        continue;
      }
      final create = await _database.query(
        'SHOW CREATE TABLE `$table`',
        null,
        false,
      );
      if (create.isEmpty) continue;
      final createSql = create.first.values.last;
      output
        ..writeln('DROP TABLE IF EXISTS `$table`;')
        ..writeln('$createSql;');
      final rows = await _database.query('SELECT * FROM `$table`', null, false);
      for (final data in rows) {
        final columns = data.keys
            .map((key) => '`${key.replaceAll('`', '``')}`')
            .join(', ');
        final values = data.values.map(_sqlLiteral).join(', ');
        output.writeln('INSERT INTO `$table` ($columns) VALUES ($values);');
      }
    }
    output.writeln('SET FOREIGN_KEY_CHECKS = 1;');
    await file.writeAsString(output.toString());
    return file.path;
  }

  String _sqlLiteral(Object? value) {
    if (value == null) return 'NULL';
    if (value is num) return value.toString();
    if (value is bool) return value ? '1' : '0';
    return "'${value.toString().replaceAll("'", "''")}'";
  }
}
