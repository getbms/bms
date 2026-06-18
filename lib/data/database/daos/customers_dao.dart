import 'package:bms/data/database/app_database.dart';
import 'package:bms/data/database/tables/customers_table.dart';
import 'package:bms/data/database/tables/payments_table.dart';
import 'package:drift/drift.dart';

part 'customers_dao.g.dart';

@DriftAccessor(tables: [Customers, CustomerPayments])
class CustomersDao extends DatabaseAccessor<AppDatabase> with _$CustomersDaoMixin {
  CustomersDao(super.db);

  Stream<List<Customer>> watchAll() =>
      (select(customers)
            ..where((c) => c.isActive.equals(true))
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .watch();

  Future<Customer?> findById(String id) =>
      (select(customers)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<String> insert(CustomersCompanion entry) =>
      into(customers).insertReturning(entry).then((c) => c.id);

  Future<void> updateBalance(String customerId, double delta) async {
    final existing = await findById(customerId);
    if (existing == null) return;
    await (update(customers)..where((c) => c.id.equals(customerId))).write(
      CustomersCompanion(balance: Value(existing.balance + delta)),
    );
  }

  Future<void> updateDetails(CustomersCompanion entry) =>
      (update(customers)..where((c) => c.id.equals(entry.id.value))).write(entry);

  Future<void> recordPayment(CustomerPaymentsCompanion entry) =>
      into(customerPayments).insert(entry);

  Future<List<CustomerPayment>> getPaymentsForCustomer(String customerId) =>
      (select(customerPayments)
            ..where((p) => p.customerId.equals(customerId))
            ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
          .get();

  /// Customers with outstanding balance (for aging report).
  Future<List<Customer>> getDebtors() =>
      (select(customers)
            ..where((c) => c.balance.isBiggerThanValue(0))
            ..orderBy([(c) => OrderingTerm.desc(c.balance)]))
          .get();
}
