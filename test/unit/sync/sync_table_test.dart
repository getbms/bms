import 'package:bms/data/sync/sync_table.dart';
import 'package:flutter_test/flutter_test.dart';

// A minimal table used across all test cases.
const _table = SyncTable(
  sqliteName: 'products',
  columns: [
    SyncColumn('id', SyncColumnType.text, primaryKey: true),
    SyncColumn('name', SyncColumnType.text),
    SyncColumn('cost_price', SyncColumnType.real),
    SyncColumn('stock_qty', SyncColumnType.integer, nullable: true),
  ],
);

void main() {
  group('SyncColumn', () {
    group('parseFromMysql', () {
      test('returns null for null input regardless of type', () {
        expect(const SyncColumn('c', SyncColumnType.text).parseFromMysql(null), isNull);
        expect(const SyncColumn('c', SyncColumnType.integer).parseFromMysql(null), isNull);
        expect(const SyncColumn('c', SyncColumnType.real).parseFromMysql(null), isNull);
      });

      test('returns the raw string for text type', () {
        expect(
          const SyncColumn('c', SyncColumnType.text).parseFromMysql('hello world'),
          'hello world',
        );
      });

      test('parses integer string to int', () {
        expect(const SyncColumn('c', SyncColumnType.integer).parseFromMysql('42'), 42);
        expect(const SyncColumn('c', SyncColumnType.integer).parseFromMysql('0'), 0);
        expect(const SyncColumn('c', SyncColumnType.integer).parseFromMysql('-7'), -7);
      });

      test('returns null for unparseable integer string', () {
        expect(
          const SyncColumn('c', SyncColumnType.integer).parseFromMysql('not-a-number'),
          isNull,
        );
      });

      test('parses real string to double', () {
        expect(const SyncColumn('c', SyncColumnType.real).parseFromMysql('3.14'), 3.14);
        expect(const SyncColumn('c', SyncColumnType.real).parseFromMysql('0.0'), 0.0);
        expect(const SyncColumn('c', SyncColumnType.real).parseFromMysql('-1.5'), -1.5);
      });

      test('parses integer-valued real string to double', () {
        expect(const SyncColumn('c', SyncColumnType.real).parseFromMysql('100'), 100.0);
        expect(
          const SyncColumn('c', SyncColumnType.real).parseFromMysql('100'),
          isA<double>(),
        );
      });
    });

    group('mysqlType', () {
      test('maps text to LONGTEXT', () {
        expect(const SyncColumn('c', SyncColumnType.text).mysqlType, 'LONGTEXT');
      });

      test('maps integer to BIGINT', () {
        expect(const SyncColumn('c', SyncColumnType.integer).mysqlType, 'BIGINT');
      });

      test('maps real to DOUBLE', () {
        expect(const SyncColumn('c', SyncColumnType.real).mysqlType, 'DOUBLE');
      });
    });
  });

  group('SyncTable', () {
    group('pk', () {
      test('returns the column marked as primaryKey', () {
        expect(_table.pk.name, 'id');
        expect(_table.pk.primaryKey, isTrue);
      });
    });

    group('columnNames', () {
      test('returns all column names in declaration order', () {
        expect(_table.columnNames, ['id', 'name', 'cost_price', 'stock_qty']);
      });
    });

    group('mysqlName', () {
      test('equals sqliteName', () {
        expect(_table.mysqlName, _table.sqliteName);
      });
    });

    group('mysqlCreateDdl', () {
      late String ddl;

      setUpAll(() {
        ddl = _table.mysqlCreateDdl;
      });

      test('opens with CREATE TABLE IF NOT EXISTS and table name', () {
        expect(ddl, contains('CREATE TABLE IF NOT EXISTS `products`'));
      });

      test('closes with InnoDB utf8mb4 footer', () {
        expect(ddl, contains('ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'));
      });

      test('marks primary key column correctly', () {
        expect(ddl, contains('`id` LONGTEXT NOT NULL PRIMARY KEY'));
      });

      test('adds NOT NULL for non-nullable columns', () {
        expect(ddl, contains('`name` LONGTEXT NOT NULL'));
        expect(ddl, contains('`cost_price` DOUBLE NOT NULL'));
      });

      test('omits NOT NULL for nullable columns', () {
        // stock_qty is nullable — DDL should not have NOT NULL on it
        expect(ddl, isNot(contains('`stock_qty` BIGINT NOT NULL')));
        expect(ddl, contains('`stock_qty` BIGINT'));
      });
    });

    group('pushOnly', () {
      test('defaults to false', () {
        expect(_table.pushOnly, isFalse);
      });

      test('can be set to true', () {
        const t = SyncTable(
          sqliteName: 'audit_log',
          columns: [SyncColumn('id', SyncColumnType.text, primaryKey: true)],
          pushOnly: true,
        );
        expect(t.pushOnly, isTrue);
      });
    });
  });
}
