import 'package:bms/data/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() async => db.close());

  Future<String> _cheque({
    String id = 'chq1',
    String status = 'pending',
    required DateTime dueDate,
  }) =>
      db.chequesDao.insert(ChequesCompanion.insert(
        id: id,
        type: 'receivable',
        partyId: 'c1',
        partyType: 'customer',
        partyName: 'Alice',
        amount: 1000,
        dueDate: dueDate,
        createdBy: 'u1',
        status: Value(status),
      ));

  group('ChequesDao', () {
    group('insert + findById', () {
      test('returns cheque when found', () async {
        await _cheque(dueDate: DateTime.now().add(const Duration(days: 5)));
        final chq = await db.chequesDao.findById('chq1');
        expect(chq?.partyName, 'Alice');
      });

      test('returns null when not found', () async {
        expect(await db.chequesDao.findById('ghost'), isNull);
      });
    });

    group('getDueWithinDays', () {
      test('returns pending cheque due within window', () async {
        await _cheque(dueDate: DateTime.now().add(const Duration(days: 3)));
        final list = await db.chequesDao.getDueWithinDays(7);
        expect(list.length, 1);
      });

      test('excludes cheques due after window', () async {
        await _cheque(dueDate: DateTime.now().add(const Duration(days: 10)));
        final list = await db.chequesDao.getDueWithinDays(7);
        expect(list, isEmpty);
      });

      test('excludes non-pending cheques', () async {
        await _cheque(
          dueDate: DateTime.now().add(const Duration(days: 3)),
          status: 'cleared',
        );
        final list = await db.chequesDao.getDueWithinDays(7);
        expect(list, isEmpty);
      });
    });

    group('getOverdueCheques', () {
      test('returns pending cheque past due date', () async {
        await _cheque(dueDate: DateTime.now().subtract(const Duration(days: 2)));
        final list = await db.chequesDao.getOverdueCheques();
        expect(list.length, 1);
      });

      test('excludes cleared cheques', () async {
        await _cheque(
          dueDate: DateTime.now().subtract(const Duration(days: 2)),
          status: 'cleared',
        );
        final list = await db.chequesDao.getOverdueCheques();
        expect(list, isEmpty);
      });
    });

    group('deposit', () {
      test('sets status to deposited and records depositDate', () async {
        await _cheque(dueDate: DateTime.now().add(const Duration(days: 1)));
        final depositDate = DateTime.now();
        await db.chequesDao.deposit('chq1', depositDate: depositDate);
        final chq = await db.chequesDao.findById('chq1');
        expect(chq?.status, 'deposited');
        expect(chq?.depositDate, isNotNull);
      });
    });

    group('bounce', () {
      test('sets status to bounced with reason', () async {
        await _cheque(dueDate: DateTime.now().add(const Duration(days: 1)));
        await db.chequesDao.bounce('chq1',
            bounceDate: DateTime.now(), reason: 'Insufficient funds');
        final chq = await db.chequesDao.findById('chq1');
        expect(chq?.status, 'bounced');
        expect(chq?.bounceReason, 'Insufficient funds');
      });
    });

    group('represent', () {
      test('increments representationCount and resets to pending', () async {
        await _cheque(dueDate: DateTime.now().add(const Duration(days: 1)));
        await db.chequesDao.bounce('chq1',
            bounceDate: DateTime.now(), reason: 'NSF');
        await db.chequesDao.represent('chq1');
        final chq = await db.chequesDao.findById('chq1');
        expect(chq?.status, 'pending');
        expect(chq?.representationCount, 1);
        expect(chq?.bounceDate, isNull);
      });
    });

    group('clear', () {
      test('sets status to cleared', () async {
        await _cheque(dueDate: DateTime.now().add(const Duration(days: 1)));
        await db.chequesDao.clear('chq1');
        final chq = await db.chequesDao.findById('chq1');
        expect(chq?.status, 'cleared');
      });
    });
  });
}
