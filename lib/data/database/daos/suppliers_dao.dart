import 'package:bms/data/database/app_database.dart';
import 'package:bms/data/database/tables/payments_table.dart';
import 'package:bms/data/database/tables/suppliers_table.dart';
import 'package:drift/drift.dart';

part 'suppliers_dao.g.dart';

@DriftAccessor(tables: [Suppliers, PurchaseOrders, PurchaseOrderItems, Purchases, PurchaseItems, SupplierPayments])
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

  Future<List<Purchase>> getAllPurchases() =>
      (select(purchases)..orderBy([(p) => OrderingTerm.desc(p.createdAt)])).get();

  Future<List<Purchase>> getPurchasesBySupplier(String supplierId) =>
      (select(purchases)
            ..where((p) => p.supplierId.equals(supplierId))
            ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
          .get();

  Future<List<PurchaseItem>> getItemsForPurchase(String purchaseId) =>
      (select(purchaseItems)..where((i) => i.purchaseId.equals(purchaseId))).get();

  Future<List<SupplierPayment>> getPaymentsForSupplier(String supplierId) =>
      (select(supplierPayments)
            ..where((p) => p.supplierId.equals(supplierId))
            ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
          .get();

  Future<String> insertPO(PurchaseOrdersCompanion entry) =>
      into(purchaseOrders).insertReturning(entry).then((po) => po.id);

  Future<void> insertPOItems(List<PurchaseOrderItemsCompanion> items) =>
      batch((b) => b.insertAll(purchaseOrderItems, items));

  Future<List<PurchaseOrder>> getAllPOs() =>
      (select(purchaseOrders)..orderBy([(po) => OrderingTerm.desc(po.createdAt)])).get();

  Future<List<PurchaseOrder>> getPOsBySupplier(String supplierId) =>
      (select(purchaseOrders)
            ..where((po) => po.supplierId.equals(supplierId))
            ..orderBy([(po) => OrderingTerm.desc(po.createdAt)]))
          .get();

  Future<List<PurchaseOrderItem>> getPOItems(String poId) =>
      (select(purchaseOrderItems)..where((i) => i.poId.equals(poId))).get();

  Future<void> updatePOStatus(String poId, String status) =>
      (update(purchaseOrders)..where((po) => po.id.equals(poId)))
          .write(PurchaseOrdersCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ));

  Future<String> nextPoNumber() async {
    return transaction(() async {
      final maxExpr = purchaseOrders.poNumber.max();
      final row = await (selectOnly(purchaseOrders)..addColumns([maxExpr])).getSingle();
      final maxPo = row.read(maxExpr);

      int maxNumber = 0;
      if (maxPo != null) {
        final match = RegExp(r'PO-(\d+)').firstMatch(maxPo);
        if (match != null) maxNumber = int.tryParse(match.group(1)!) ?? 0;
      }

      return 'PO-${(maxNumber + 1).toString().padLeft(5, '0')}';
    });
  }

  Future<String> nextGrnNumber() async {
    return transaction(() async {
      final maxExpr = purchases.grnNumber.max();
      final row = await (selectOnly(purchases)..addColumns([maxExpr])).getSingle();
      final maxGrn = row.read(maxExpr);

      int maxNumber = 0;
      if (maxGrn != null) {
        final match = RegExp(r'GRN-(\d+)').firstMatch(maxGrn);
        if (match != null) maxNumber = int.tryParse(match.group(1)!) ?? 0;
      }

      return 'GRN-${(maxNumber + 1).toString().padLeft(5, '0')}';
    });
  }
}
