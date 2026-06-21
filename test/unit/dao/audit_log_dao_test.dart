import 'package:bms/data/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() async => db.close());

  Future<void> _log({
    String id = 'al1',
    String entityType = 'product',
    String entityId = 'p1',
    String action = 'create',
    String userId = 'u1',
    String userName = 'Admin',
    Object? newValue,
  }) =>
      db.auditLogDao.log(
        id: id,
        entityType: entityType,
        entityId: entityId,
        action: action,
        userId: userId,
        userName: userName,
        newValue: newValue,
      );

  group('AuditLogDao', () {
    group('log + getForEntity', () {
      test('entry is found by entityType and entityId', () async {
        await _log();
        final entries = await db.auditLogDao.getForEntity('product', 'p1');
        expect(entries.length, 1);
        expect(entries.first.action, 'create');
      });

      test('filters by both entityType and entityId', () async {
        await _log(id: 'al1', entityType: 'product', entityId: 'p1');
        await _log(id: 'al2', entityType: 'invoice', entityId: 'inv-1');
        final entries = await db.auditLogDao.getForEntity('product', 'p1');
        expect(entries.length, 1);
        expect(entries.first.id, 'al1');
      });

      test('returns entries in descending createdAt order', () async {
        final t1 = DateTime(2024, 1, 1, 10, 0, 0);
        final t2 = DateTime(2024, 1, 1, 11, 0, 0);
        await db.into(db.auditLog).insert(AuditLogCompanion(
          id: const Value('al1'),
          entityType: const Value('product'),
          entityId: const Value('p1'),
          action: const Value('create'),
          userId: const Value('u1'),
          userName: const Value('Admin'),
          createdAt: Value(t1),
        ));
        await db.into(db.auditLog).insert(AuditLogCompanion(
          id: const Value('al2'),
          entityType: const Value('product'),
          entityId: const Value('p1'),
          action: const Value('update'),
          userId: const Value('u1'),
          userName: const Value('Admin'),
          createdAt: Value(t2),
        ));
        final entries = await db.auditLogDao.getForEntity('product', 'p1');
        expect(entries.first.id, 'al2');
      });
    });

    group('getAll', () {
      setUp(() async {
        for (var i = 1; i <= 5; i++) {
          await _log(id: 'al$i', entityId: 'p$i');
        }
      });

      test('returns all entries when no filter', () async {
        final entries = await db.auditLogDao.getAll();
        // +1 for the developer seed entry created during DB migration
        expect(entries.length, 6);
      });

      test('filters by entityType when provided', () async {
        await _log(id: 'inv1', entityType: 'invoice', entityId: 'inv-1');
        final entries = await db.auditLogDao.getAll(entityType: 'invoice');
        expect(entries.length, 1);
        expect(entries.first.entityType, 'invoice');
      });

      test('respects limit parameter', () async {
        final entries = await db.auditLogDao.getAll(limit: 3);
        expect(entries.length, 3);
      });
    });

    group('log with values', () {
      test('stores newValue as non-null when provided', () async {
        await _log(newValue: {'name': 'Widget', 'price': 100});
        final entries = await db.auditLogDao.getForEntity('product', 'p1');
        expect(entries.first.newValue, isNotNull);
      });

      test('stores null newValue when not provided', () async {
        await _log();
        final entries = await db.auditLogDao.getForEntity('product', 'p1');
        expect(entries.first.newValue, isNull);
      });
    });
  });
}
