import 'package:bms/data/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() async => db.close());

  Future<String> entry({
    String id = 'pc1',
    String type = 'expense',
    String status = 'pending',
    double amount = 500,
  }) =>
      db.pettyCashDao.insert(PettyCashCompanion.insert(
        id: id,
        type: type,
        amount: amount,
        category: 'office',
        description: 'Pens',
        userId: 'u1',
        status: Value(status),
      ));

  group('PettyCashDao', () {
    group('insert + getByDateRange', () {
      test('returns entry within date range', () async {
        final now = DateTime.now();
        await db.pettyCashDao.insert(PettyCashCompanion.insert(
          id: 'pc1',
          type: 'expense',
          amount: 200,
          category: 'transport',
          description: 'Fuel',
          userId: 'u1',
          createdAt: Value(now),
        ));
        final list = await db.pettyCashDao.getByDateRange(
          now.subtract(const Duration(hours: 1)),
          now.add(const Duration(hours: 1)),
        );
        expect(list.length, 1);
        expect(list.first.description, 'Fuel');
      });

      test('excludes entries outside range', () async {
        final past = DateTime.now().subtract(const Duration(days: 2));
        await db.pettyCashDao.insert(PettyCashCompanion.insert(
          id: 'pc1',
          type: 'expense',
          amount: 100,
          category: 'office',
          description: 'Tape',
          userId: 'u1',
          createdAt: Value(past),
        ));
        final list = await db.pettyCashDao.getByDateRange(
          DateTime.now().subtract(const Duration(hours: 1)),
          DateTime.now(),
        );
        expect(list, isEmpty);
      });
    });

    group('getPendingApprovals', () {
      test('returns only pending entries', () async {
        await entry();
        await entry(id: 'pc2', status: 'approved');
        await entry(id: 'pc3', status: 'rejected');
        final list = await db.pettyCashDao.getPendingApprovals();
        expect(list.length, 1);
        expect(list.first.id, 'pc1');
      });

      test('returns empty when no pending entries', () async {
        await entry(status: 'approved');
        expect(await db.pettyCashDao.getPendingApprovals(), isEmpty);
      });
    });

    group('approve', () {
      test('changes status to approved and records approvedBy', () async {
        await entry();
        await db.pettyCashDao.approve('pc1', 'manager');
        final pending = await db.pettyCashDao.getPendingApprovals();
        expect(pending, isEmpty);

        final all = await db.pettyCashDao
            .getByDateRange(DateTime(2000), DateTime(2100));
        expect(all.first.status, 'approved');
        expect(all.first.approvedBy, 'manager');
        expect(all.first.approvedAt, isNotNull);
      });
    });

    group('reject', () {
      test('changes status to rejected', () async {
        await entry();
        await db.pettyCashDao.reject('pc1', notes: 'Duplicate');
        final all = await db.pettyCashDao
            .getByDateRange(DateTime(2000), DateTime(2100));
        expect(all.first.status, 'rejected');
        expect(all.first.approvalNotes, 'Duplicate');
      });

      test('reject without notes sets null approvalNotes', () async {
        await entry();
        await db.pettyCashDao.reject('pc1');
        final all = await db.pettyCashDao
            .getByDateRange(DateTime(2000), DateTime(2100));
        expect(all.first.status, 'rejected');
        expect(all.first.approvalNotes, isNull);
      });
    });
  });
}
