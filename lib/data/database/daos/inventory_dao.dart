import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/products_table.dart';

part 'inventory_dao.g.dart';

@DriftAccessor(tables: [Products, Categories, Stock, StockMovements, ProductUnits])
class InventoryDao extends DatabaseAccessor<AppDatabase> with _$InventoryDaoMixin {
  InventoryDao(super.db);

  // Products

  Stream<List<Product>> watchAll({bool activeOnly = true}) =>
      (select(products)
            ..where((p) => activeOnly ? p.isActive.equals(true) : const Constant(true))
            ..orderBy([(p) => OrderingTerm.asc(p.name)]))
          .watch();

  Future<Product?> findByBarcode(String barcode) =>
      (select(products)..where((p) => p.barcode.equals(barcode))).getSingleOrNull();

  Future<Product?> findById(String id) =>
      (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<String> insertProduct(ProductsCompanion entry) =>
      into(products).insertReturning(entry).then((p) => p.id);

  Future<void> updateProduct(ProductsCompanion entry) =>
      (update(products)..where((p) => p.id.equals(entry.id.value))).write(entry);

  Stream<List<Product>> watchAllProducts() =>
      (select(products)..orderBy([(p) => OrderingTerm.asc(p.name)])).watch();

  Future<List<Category>> getCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm.asc(c.name)])).get();

  Future<String> insertCategory(CategoriesCompanion entry) =>
      into(categories).insertReturning(entry).then((c) => c.id);

  // Stock -- data class is StockLevel (@DataClassName), companion remains StockCompanion

  Future<StockLevel?> getStock(String productId) =>
      (select(stock)..where((s) => s.productId.equals(productId))).getSingleOrNull();

  Stream<List<StockLevel>> watchLowStock() {
    final query = select(stock).join([
      innerJoin(products, products.id.equalsExp(stock.productId)),
    ]);
    // Compare qty (real) against reorderLevel (int) via expression cast
    query.where(stock.qty.isSmallerOrEqualValue(0) |
        CustomExpression<bool>('stock.qty <= products.reorder_level'));
    return query.watch().map(
          (rows) => rows.map((r) => r.readTable(stock)).toList(),
        );
  }

  Future<void> upsertStock(StockCompanion entry) =>
      into(stock).insertOnConflictUpdate(entry);

  // Stock movements

  Future<void> recordMovement(StockMovementsCompanion entry) =>
      into(stockMovements).insert(entry);

  Future<List<StockMovement>> getMovementsForProduct(String productId) =>
      (select(stockMovements)
            ..where((m) => m.productId.equals(productId))
            ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
          .get();

  Future<void> updateCostPrice(String productId, double costPrice) =>
      (update(products)..where((p) => p.id.equals(productId))).write(
        ProductsCompanion(costPrice: Value(costPrice)),
      );

  Stream<List<StockLevel>> watchAllStock() =>
      (select(stock)..orderBy([(s) => OrderingTerm.asc(s.productId)])).watch();
}
