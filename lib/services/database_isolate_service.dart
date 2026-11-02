import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mysql1/mysql1.dart';
import './logging_service.dart';

/// Classe pour représenter une requête à exécuter dans un isolate
class DatabaseQuery {
  final String sql;
  final List<dynamic>? params;
  final String type;
  final String host;
  final int port;
  final String user;
  final String password;
  final String database;

  DatabaseQuery({
    required this.sql,
    this.params,
    required this.type,
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
  });
}

/// Classe pour représenter le résultat de l'exécution
class DatabaseResult {
  final List<Map<String, dynamic>>? rows;
  final int? insertId;
  final String? error;
  final bool success;

  DatabaseResult({this.rows, this.insertId, this.error, required this.success});
}

/// Fonction exécutée dans le compute pour effectuer la requête
Future<DatabaseResult> _executeDatabaseQueryInCompute(
  DatabaseQuery query,
) async {
  try {
    final connection =
        await MySqlConnection.connect(
          ConnectionSettings(
            host: query.host,
            port: query.port,
            user: query.user,
            password: query.password,
            db: query.database,
          ),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () =>
              throw TimeoutException('Timeout connexion après 10 secondes'),
        );

    try {
      if (query.type == 'query') {
        final results = await connection
            .query(query.sql, query.params)
            .timeout(
              const Duration(seconds: 45),
              onTimeout: () =>
                  throw TimeoutException('Timeout requête après 45 secondes'),
            );

        List<Map<String, dynamic>> rows = [];
        for (var row in results) {
          Map<String, dynamic> map = {};
          for (var i = 0; i < row.length; i++) {
            final fieldName = results.fields[i].name ?? 'field_$i';
            map[fieldName] = row[i];
          }
          rows.add(map);
        }

        return DatabaseResult(rows: rows, success: true);
      } else if (query.type == 'insert') {
        final result = await connection
            .query(query.sql, query.params)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () =>
                  throw TimeoutException('Timeout insert après 30 secondes'),
            );

        return DatabaseResult(insertId: result.insertId ?? 0, success: true);
      } else if (query.type == 'execute') {
        await connection
            .query(query.sql, query.params)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () =>
                  throw TimeoutException('Timeout execute après 30 secondes'),
            );

        return DatabaseResult(success: true);
      }

      return DatabaseResult(
        error: 'Type de requête inconnu: ${query.type}',
        success: false,
      );
    } finally {
      await connection.close();
    }
  } catch (e) {
    return DatabaseResult(error: e.toString(), success: false);
  }
}

/// Service pour exécuter les requêtes de base de données dans des isolates
class DatabaseIsolateService {
  static const String logSource = 'database_isolate_service';
  static final logger = createLoggerWithFileOutput(name: logSource);

  /// Exécute une requête SELECT dans un isolate
  static Future<List<Map<String, dynamic>>> executeQuery(
    String sql,
    List<dynamic>? params,
    String host,
    int port,
    String user,
    String password,
    String database,
  ) async {
    final query = DatabaseQuery(
      sql: sql,
      params: params,
      type: 'query',
      host: host,
      port: port,
      user: user,
      password: password,
      database: database,
    );

    final result = await compute(_executeDatabaseQueryInCompute, query);

    if (!result.success) {
      logger.e('Erreur isolate query: ${result.error}');
      throw Exception(result.error ?? 'Erreur inconnue lors de la requête');
    }

    return result.rows ?? [];
  }

  /// Exécute une requête INSERT dans un isolate
  static Future<int> executeInsert(
    String sql,
    List<dynamic>? params,
    String host,
    int port,
    String user,
    String password,
    String database,
  ) async {
    final query = DatabaseQuery(
      sql: sql,
      params: params,
      type: 'insert',
      host: host,
      port: port,
      user: user,
      password: password,
      database: database,
    );

    final result = await compute(_executeDatabaseQueryInCompute, query);

    if (!result.success) {
      logger.e('Erreur isolate insert: ${result.error}');
      throw Exception(result.error ?? 'Erreur inconnue lors de l\'insertion');
    }

    return result.insertId ?? 0;
  }

  /// Exécute une requête UPDATE/DELETE dans un isolate
  static Future<void> executeUpdate(
    String sql,
    List<dynamic>? params,
    String host,
    int port,
    String user,
    String password,
    String database,
  ) async {
    final query = DatabaseQuery(
      sql: sql,
      params: params,
      type: 'execute',
      host: host,
      port: port,
      user: user,
      password: password,
      database: database,
    );

    final result = await compute(_executeDatabaseQueryInCompute, query);

    if (!result.success) {
      logger.e('Erreur isolate execute: ${result.error}');
      throw Exception(result.error ?? 'Erreur inconnue lors de l\'exécution');
    }
  }
}
