import 'package:bms/data/database/app_database.dart';
import 'package:bms/data/sync/sync_table.dart';
import 'package:bms/data/sync/sync_tables_registry.dart';
import 'package:bms/providers/settings_provider.dart';
import 'package:drift/drift.dart';
import 'package:mysql_client/exception.dart';
import 'package:mysql_client/mysql_client.dart';

class SyncException implements Exception {
  const SyncException(this.message);
  final String message;
  @override
  String toString() => 'SyncException: $message';
}

class SyncResult {
  const SyncResult({
    required this.pushed,
    required this.pulled,
    required this.errors,
  });
  final int pushed;
  final int pulled;
  final List<String> errors;
  bool get hasErrors => errors.isNotEmpty;
}

class SyncService {
  SyncService(this._db);

  final AppDatabase _db;

  // -------------------------------------------------------------------------
  // Connection test
  // -------------------------------------------------------------------------

  /// Returns null on success, error message on failure.
  Future<String?> testConnection(DbConnectionSettings s) async {
    MySQLConnection? conn;
    try {
      conn = await MySQLConnection.createConnection(
        host: s.host,
        port: s.port,
        userName: s.username,
        password: s.password,
        databaseName: s.database,
      );
      await conn.connect(timeoutMs: 5000);
      await conn.execute('SELECT 1');
      return null;
    } on MySQLClientException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      await conn?.close();
    }
  }

  // -------------------------------------------------------------------------
  // Full sync cycle
  // -------------------------------------------------------------------------

  Future<SyncResult> sync({
    required DbConnectionSettings settings,
    required DateTime lastPushAt,
    required DateTime lastPullAt,
  }) async {
    MySQLConnection? conn;
    int pushed = 0;
    int pulled = 0;
    final errors = <String>[];

    try {
      conn = await MySQLConnection.createConnection(
        host: settings.host,
        port: settings.port,
        userName: settings.username,
        password: settings.password,
        databaseName: settings.database,
      );
      await conn.connect();
      await _ensureSchema(conn);

      for (final table in kSyncTables) {
        try {
          pushed += await _pushTable(conn, table, since: lastPushAt);
          if (!table.pushOnly) {
            pulled += await _pullTable(conn, table, since: lastPullAt);
          }
        } catch (e) {
          errors.add('${table.sqliteName}: $e');
        }
      }
    } on MySQLClientException catch (e) {
      throw SyncException(e.message);
    } finally {
      await conn?.close();
    }

    return SyncResult(pushed: pushed, pulled: pulled, errors: errors);
  }

  // -------------------------------------------------------------------------
  // Schema bootstrap on MySQL
  // -------------------------------------------------------------------------

  Future<void> _ensureSchema(MySQLConnection conn) async {
    for (final table in kSyncTables) {
      await conn.execute(table.mysqlCreateDdl);
    }
  }

  // -------------------------------------------------------------------------
  // Push: SQLite → MySQL
  // -------------------------------------------------------------------------

  Future<int> _pushTable(
    MySQLConnection conn,
    SyncTable table, {
    required DateTime since,
  }) async {
    final sinceMs  = since.millisecondsSinceEpoch;
    final cols     = table.columnNames;
    final pkName   = table.pk.name;

    final hasUpdatedAt = cols.contains('updated_at');
    final hasCreatedAt = cols.contains('created_at');

    final String whereClause;
    final List<Variable> variables;
    if (hasUpdatedAt) {
      whereClause = 'WHERE "updated_at" > ? OR "created_at" > ?';
      variables   = [Variable.withInt(sinceMs), Variable.withInt(sinceMs)];
    } else if (hasCreatedAt) {
      whereClause = 'WHERE "created_at" > ?';
      variables   = [Variable.withInt(sinceMs)];
    } else {
      // No timestamp column — full push every cycle (small reference tables).
      whereClause = '';
      variables   = [];
    }

    final rows = await _db.customSelect(
      'SELECT ${cols.map((c) => '"$c"').join(', ')} '
      'FROM "${table.sqliteName}" $whereClause',
      variables: variables,
    ).get();

    if (rows.isEmpty) return 0;

    // Named params: :col_name → value map.
    final colPlaceholders = cols.map((c) => ':$c').join(', ');
    final updateClause    = cols
        .where((c) => c != pkName)
        .map((c) => '`$c` = VALUES(`$c`)')
        .join(', ');
    final sql =
        'INSERT INTO `${table.mysqlName}` '
        '(${cols.map((c) => '`$c`').join(', ')}) '
        'VALUES ($colPlaceholders) '
        'ON DUPLICATE KEY UPDATE $updateClause';

    for (final row in rows) {
      final params = <String, dynamic>{
        for (final c in cols) c: row.data[c],
      };
      await conn.execute(sql, params);
    }
    return rows.length;
  }

  // -------------------------------------------------------------------------
  // Pull: MySQL → SQLite
  // -------------------------------------------------------------------------

  Future<int> _pullTable(
    MySQLConnection conn,
    SyncTable table, {
    required DateTime since,
  }) async {
    final sinceMs  = since.millisecondsSinceEpoch;
    final cols     = table.columns;
    final colNames = cols.map((c) => c.name).toList();

    final hasUpdatedAt = colNames.contains('updated_at');
    final String whereClause;
    final Map<String, dynamic> params;
    if (hasUpdatedAt) {
      whereClause = 'WHERE `updated_at` > :since';
      params      = {'since': sinceMs};
    } else {
      // No timestamp — skip pull for push-only tables.
      return 0;
    }

    final result = await conn.execute(
      'SELECT ${colNames.map((c) => '`$c`').join(', ')} '
      'FROM `${table.mysqlName}` $whereClause',
      params,
    );

    if (result.numOfRows == 0) return 0;

    final placeholders = colNames.map((_) => '?').join(', ');
    final upsertSql    =
        'INSERT OR REPLACE INTO "${table.sqliteName}" '
        '(${colNames.map((c) => '"$c"').join(', ')}) '
        'VALUES ($placeholders)';

    int count = 0;
    for (final row in result.rows) {
      final values = cols
          .map((c) => c.parseFromMysql(row.colByName(c.name)))
          .toList();
      await _db.customStatement(upsertSql, values);
      count++;
    }
    return count;
  }
}
