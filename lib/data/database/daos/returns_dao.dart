import 'package:bms/data/database/app_database.dart';
import 'package:bms/data/database/tables/returns_table.dart';
import 'package:drift/drift.dart';

part 'returns_dao.g.dart';

@DriftAccessor(tables: [SalesReturns, ReturnItems])
class ReturnsDao extends DatabaseAccessor<AppDatabase> with _$ReturnsDaoMixin {
  ReturnsDao(super.db);

  // Generates the next return number atomically. Must be called inside a
  // transaction to prevent duplicates under concurrent access.
  Future<String> _nextReturnNumber() async {
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

  // Inserts a return and its line items atomically, generating the return
  // number inside the transaction to prevent duplicates.
  Future<SalesReturn> insertReturnWithItems(
    SalesReturnsCompanion entry,
    List<ReturnItemsCompanion> items,
  ) =>
      transaction(() async {
        final returnNo = await _nextReturnNumber();
        final salesReturn = await into(salesReturns).insertReturning(
          entry.copyWith(returnNo: Value(returnNo)),
        );
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
