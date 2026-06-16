import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/returns_table.dart';

part 'returns_dao.g.dart';

@DriftAccessor(tables: [SalesReturns, ReturnItems])
class ReturnsDao extends DatabaseAccessor<AppDatabase> with _$ReturnsDaoMixin {
  ReturnsDao(super.db);

  Future<String> nextReturnNumber() async {
    final maxExpr = salesReturns.returnNo.max();
    final row =
        await (selectOnly(salesReturns)..addColumns([maxExpr])).getSingle();
    final maxVal = row.read(maxExpr);
    int maxNumber = 0;
    if (maxVal != null) {
      final match = RegExp(r'RET-(\d+)').firstMatch(maxVal);
      if (match != null) maxNumber = int.tryParse(match.group(1)!) ?? 0;
    }
    return 'RET-${(maxNumber + 1).toString().padLeft(5, '0')}';
  }

  Future<SalesReturn> insertReturnWithItems(
    SalesReturnsCompanion entry,
    List<ReturnItemsCompanion> items,
  ) =>
      transaction(() async {
        final salesReturn = await into(salesReturns).insertReturning(entry);
        await batch((b) => b.insertAll(returnItems, items));
        return salesReturn;
      });

  Future<List<SalesReturn>> getForInvoice(String invoiceId) =>
      (select(salesReturns)
            ..where((r) => r.invoiceId.equals(invoiceId))
            ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
          .get();

  Future<List<ReturnItem>> getItemsForReturn(String returnId) =>
      (select(returnItems)
            ..where((i) => i.returnId.equals(returnId)))
          .get();
}
