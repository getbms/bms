import 'package:bms/data/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() async => db.close());

  Future<String> _cust({
    String id = 'c1',
    String name = 'Alice Corp',
    double balance = 0,
    bool active = true,
  }) =>
      db.customersDao.insert(CustomersCompanion.insert(
        id: id,
        name: name,
        balance: Value(balance),
        isActive: Value(active),
      ));

  group('CustomersDao', () {
    group('insert + findById', () {
      test('returns customer when id exists', () async {
        await _cust();
        final c = await db.customersDao.findById('c1');
        expect(c?.name, 'Alice Corp');
      });

      test('returns null when id not found', () async {
        expect(await db.customersDao.findById('ghost'), isNull);
      });
    });

    group('watchAll', () {
      test('excludes inactive customers', () async {
        await _cust(id: 'c1', active: true);
        await _cust(id: 'c2', name: 'Bob Inc', active: false);
        final list = await db.customersDao.watchAll().first;
        expect(list.length, 1);
        expect(list.first.id, 'c1');
      });
    });

    group('updateBalance', () {
      test('positive delta increases balance', () async {
        await _cust(balance: 100);
        await db.customersDao.updateBalance('c1', 50);
        final c = await db.customersDao.findById('c1');
        expect(c?.balance, 150);
      });

      test('negative delta decreases balance', () async {
        await _cust(balance: 200);
        await db.customersDao.updateBalance('c1', -80);
        final c = await db.customersDao.findById('c1');
        expect(c?.balance, 120);
      });

      test('no-op when customer not found', () async {
        await expectLater(db.customersDao.updateBalance('ghost', 100), completes);
      });
    });

    group('recordPayment + getPaymentsForCustomer', () {
      setUp(() async => _cust());

      test('returns payments for customer in descending order', () async {
        final t1 = DateTime(2024, 1, 1, 10, 0);
        final t2 = DateTime(2024, 1, 1, 11, 0);
        await db.customersDao.recordPayment(CustomerPaymentsCompanion.insert(
          id: 'pay1', customerId: 'c1', amount: 100, userId: 'u1',
          createdAt: Value(t1),
        ));
        await db.customersDao.recordPayment(CustomerPaymentsCompanion.insert(
          id: 'pay2', customerId: 'c1', amount: 200, userId: 'u1',
          createdAt: Value(t2),
        ));
        final payments = await db.customersDao.getPaymentsForCustomer('c1');
        expect(payments.length, 2);
        expect(payments.first.id, 'pay2');
      });

      test('returns empty list for customer with no payments', () async {
        final payments = await db.customersDao.getPaymentsForCustomer('c1');
        expect(payments, isEmpty);
      });
    });

    group('getDebtors', () {
      test('returns customers with balance > 0, sorted desc', () async {
        await _cust(id: 'c1', name: 'Debtor A', balance: 500);
        await _cust(id: 'c2', name: 'Debtor B', balance: 1000);
        await _cust(id: 'c3', name: 'Paid Up', balance: 0);
        final debtors = await db.customersDao.getDebtors();
        expect(debtors.length, 2);
        expect(debtors.first.balance, 1000);
      });
    });
  });
}
