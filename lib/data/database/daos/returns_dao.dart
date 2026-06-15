import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/returns_table.dart';

part 'returns_dao.g.dart';

@DriftAccessor(tables: [SalesReturns, ReturnItems])
class ReturnsDao extends DatabaseAccessor<AppDatabase> with _$ReturnsDaoMixin {
  ReturnsDao(super.db);

  Future<SalesReturn> insertReturn(SalesReturnsCompanion entry) =>
      into(salesReturns).insertReturning(entry);

  Future<void> insertItems(List<ReturnItemsCompanion> items) =>
      batch((b) => b.insertAll(returnItems, items));

  Future<List<SalesReturn>> getForInvoice(String invoiceId) =>
      (select(salesReturns)
            ..where((r) => r.invoiceId.equals(invoiceId))
            ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
          .get();

  Future<List<ReturnItem>> getItemsForReturn(String returnId) =>
      (select(returnItems)
            ..where((i) => i.returnId.equals(returnId)))
          .get();

  Future<String> nextReturnNumber() async {
    final count = await select(salesReturns).get().then((l) => l.length);
    return 'RTN-${(count + 1).toString().padLeft(5, '0')}';
  }
}
