import 'package:bms/data/database/app_database.dart';
import 'package:bms/data/database/tables/invoices_table.dart';
import 'package:drift/drift.dart';

part 'invoices_dao.g.dart';

@DriftAccessor(tables: [Invoices, InvoiceItems, NoInvoiceSales])
class InvoicesDao extends DatabaseAccessor<AppDatabase> with _$InvoicesDaoMixin {
  InvoicesDao(super.db);

  Future<Invoice> insertInvoice(InvoicesCompanion entry) =>
      into(invoices).insertReturning(entry);

  Future<void> insertItems(List<InvoiceItemsCompanion> items) =>
      batch((b) => b.insertAll(invoiceItems, items));

  Future<Invoice?> findById(String id) =>
      (select(invoices)..where((i) => i.id.equals(id))).getSingleOrNull();

  Future<Invoice?> findByInvoiceNo(String no) =>
      (select(invoices)..where((i) => i.invoiceNo.equals(no))).getSingleOrNull();

  Future<List<InvoiceItem>> getItemsForInvoice(String invoiceId) =>
      (select(invoiceItems)..where((i) => i.invoiceId.equals(invoiceId))).get();

  Future<List<Invoice>> getByDateRange(DateTime from, DateTime to) =>
      (select(invoices)
            ..where((i) => i.createdAt.isBetweenValues(from, to))
            ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
          .get();

  Future<void> voidInvoice({
    required String id,
    required String reason,
    required String approvedBy,
  }) =>
      (update(invoices)..where((i) => i.id.equals(id))).write(
        InvoicesCompanion(
          status: const Value('void'),
          voidReason: Value(reason),
          voidApprovedBy: Value(approvedBy),
        ),
      );

  Future<void> insertNoInvoiceSale(NoInvoiceSalesCompanion entry) =>
      into(noInvoiceSales).insert(entry);

  Future<List<NoInvoiceSale>> getNoInvoiceSalesByDate(DateTime from, DateTime to) =>
      (select(noInvoiceSales)
            ..where((s) => s.createdAt.isBetweenValues(from, to))
            ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
          .get();

  /// Generates next sequential invoice number in format INV-YYYYMMDD-NNNN.
  Future<String> nextInvoiceNumber() async {
    final today = DateTime.now();
    final prefix =
        'INV-${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
    final count = await (select(invoices)
          ..where((i) => i.invoiceNo.like('$prefix%')))
        .get()
        .then((list) => list.length);
    return '$prefix-${(count + 1).toString().padLeft(4, '0')}';
  }
}
