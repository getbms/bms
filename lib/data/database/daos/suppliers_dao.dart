import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/payments_table.dart';
import '../tables/suppliers_table.dart';

part 'suppliers_dao.g.dart';

@DriftAccessor(tables: [Suppliers, Purchases, PurchaseItems, SupplierPayments])
class SuppliersDao extends DatabaseAccessor<AppDatabase> with _$SuppliersDaoMixin {
  SuppliersDao(super.db);

  Stream<List<Supplier>> watchAll() =>
      (select(suppliers)
            ..where((s) => s.isActive.equals(true))
            ..orderBy([(s) => OrderingTerm.asc(s.name)]))
          .watch();

  Future<Supplier?> findById(String id) =>
      (select(suppliers)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<String> insert(SuppliersCompanion entry) =>
      into(suppliers).insertReturning(entry).then((s) => s.id);

  Future<void> updateBalance(String supplierId, double delta) async {
    final existing = await findById(supplierId);
    if (existing == null) return;
    await (update(suppliers)..where((s) => s.id.equals(supplierId))).write(
      SuppliersCompanion(balance: Value(existing.balance + delta)),
    );
  }

  Future<void> updateDetails(SuppliersCompanion entry) =>
      (update(suppliers)..where((s) => s.id.equals(entry.id.value))).write(entry);

  Future<String> insertPurchase(PurchasesCompanion entry) =>
      into(purchases).insertReturning(entry).then((p) => p.id);

  Future<void> insertPurchaseItems(List<PurchaseItemsCompanion> items) =>
      batch((b) => b.insertAll(purchaseItems, items));

  Future<void> recordPayment(SupplierPaymentsCompanion entry) =>
      into(supplierPayments).insert(entry);
}
