// Describes how a single SQLite table maps to MySQL for bidirectional sync.
//
// Column types drive MySQL DDL generation and MySQL→SQLite value parsing.
// Push (SQLite→MySQL) reads raw int/double/String from QueryRow.data and
// passes them as-is. Pull (MySQL→SQLite) reads strings from the MySQL
// client and casts them using SyncColumn.type.

enum SyncColumnType { text, integer, real }

class SyncColumn {
  const SyncColumn(this.name, this.type, {this.nullable = false, this.primaryKey = false});
  final String name;
  final SyncColumnType type;
  final bool nullable;
  final bool primaryKey;

  String get mysqlType => switch (type) {
        SyncColumnType.text    => 'LONGTEXT',
        SyncColumnType.integer => 'BIGINT',
        SyncColumnType.real    => 'DOUBLE',
      };

  dynamic parseFromMysql(String? raw) {
    if (raw == null) return null;
    return switch (type) {
      SyncColumnType.text    => raw,
      SyncColumnType.integer => int.tryParse(raw),
      SyncColumnType.real    => double.tryParse(raw),
    };
  }
}

class SyncTable {
  const SyncTable({
    required this.sqliteName,
    required this.columns,
    this.pushOnly = false,
  });

  final String sqliteName;
  final List<SyncColumn> columns;

  /// If true, rows are only pushed to MySQL and never pulled back.
  /// Used for immutable ledgers (audit_log, stock_movements).
  final bool pushOnly;

  String get mysqlName => sqliteName;

  SyncColumn get pk => columns.firstWhere((c) => c.primaryKey);

  String get mysqlCreateDdl {
    final colDefs = columns.map((c) {
      final nullable = c.nullable ? '' : ' NOT NULL';
      final pk       = c.primaryKey ? ' PRIMARY KEY' : '';
      return '`${c.name}` ${c.mysqlType}$nullable$pk';
    }).join(',\n  ');
    return 'CREATE TABLE IF NOT EXISTS `$mysqlName` (\n  $colDefs\n) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4';
  }

  List<String> get columnNames => columns.map((c) => c.name).toList();
}
