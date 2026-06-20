import 'package:bms/data/database/app_database.dart';
import 'package:bms/features/auth/domain/auth_state.dart';
import 'package:bms/providers/auth_provider.dart';
import 'package:bms/providers/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final invoiceReturnsProvider =
    FutureProvider.autoDispose.family<List<SalesReturn>, String>(
  (ref, invoiceId) =>
      ref.watch(returnsDaoProvider).getForInvoice(invoiceId),
);

class InvoiceFilter {
  const InvoiceFilter({
    required this.dateRange,
    this.status,
    this.query = '',
  });

  final DateTimeRange dateRange;
  final String? status; // null = all
  final String query;

  InvoiceFilter copyWith({
    DateTimeRange? dateRange,
    Object? status = _sentinel,
    String? query,
  }) =>
      InvoiceFilter(
        dateRange: dateRange ?? this.dateRange,
        status: status == _sentinel ? this.status : status as String?,
        query: query ?? this.query,
      );

  static const _sentinel = Object();
}

class InvoiceFilterNotifier extends Notifier<InvoiceFilter> {
  @override
  InvoiceFilter build() {
    final now = DateTime.now();
    return InvoiceFilter(
      dateRange: DateTimeRange(
        start: DateTime(now.year, now.month),
        end: now,
      ),
    );
  }

  void update(InvoiceFilter next) => state = next;
}

final invoiceFilterProvider =
    NotifierProvider<InvoiceFilterNotifier, InvoiceFilter>(InvoiceFilterNotifier.new);

typedef InvoiceRow = ({Invoice invoice, String? customerName});

final invoicesListProvider = FutureProvider.autoDispose<List<InvoiceRow>>((ref) async {
  final filter = ref.watch(invoiceFilterProvider);
  final dao = ref.watch(invoicesDaoProvider);
  final customersDao = ref.watch(customersDaoProvider);

  final to = DateTime(
    filter.dateRange.end.year,
    filter.dateRange.end.month,
    filter.dateRange.end.day,
    23, 59, 59,
  );

  final invoices = await dao.getByDateRange(filter.dateRange.start, to);

  final customerIds = invoices
      .where((i) => i.customerId != null)
      .map((i) => i.customerId!)
      .toSet();
  final customerMap = <String, String>{};
  for (final id in customerIds) {
    final c = await customersDao.findById(id);
    if (c != null) customerMap[id] = c.name;
  }

  List<InvoiceRow> rows = invoices
      .map((i) => (
            invoice: i,
            customerName: i.customerId != null ? customerMap[i.customerId!] : null,
          ))
      .toList();

  final statusFilter = filter.status;
  if (statusFilter != null) {
    rows = rows.where((r) => r.invoice.status == statusFilter).toList();
  }

  final q = filter.query.toLowerCase();
  if (q.isNotEmpty) {
    rows = rows
        .where((r) =>
            r.invoice.invoiceNo.toLowerCase().contains(q) ||
            (r.customerName?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  return rows;
});

typedef InvoiceDetail = ({Invoice invoice, List<InvoiceItem> items, Customer? customer});

final invoiceDetailProvider =
    FutureProvider.autoDispose.family<InvoiceDetail, String>((ref, invoiceId) async {
  final dao = ref.watch(invoicesDaoProvider);
  final customersDao = ref.watch(customersDaoProvider);

  final invoice = await dao.findById(invoiceId);
  if (invoice == null) throw Exception('Invoice $invoiceId not found');

  final items = await dao.getItemsForInvoice(invoiceId);
  final customer =
      invoice.customerId != null ? await customersDao.findById(invoice.customerId!) : null;

  return (invoice: invoice, items: items, customer: customer);
});

typedef InvoiceSummary = ({double total, double collected, int count});

final invoiceSummaryProvider = Provider.autoDispose<InvoiceSummary>((ref) {
  final listAsync = ref.watch(invoicesListProvider);
  return listAsync.when(
    data: (rows) {
      final active = rows.where((r) => r.invoice.status != 'void').toList();
      return (
        total: active.fold(0, (s, r) => s + r.invoice.total),
        collected: active.fold(0, (s, r) => s + r.invoice.paidAmount),
        count: active.length,
      );
    },
    loading: () => (total: 0.0, collected: 0.0, count: 0),
    error: (_, _) => (total: 0.0, collected: 0.0, count: 0),
  );
});

class InvoiceActions {
  InvoiceActions(this._ref);
  final Ref _ref;

  String get _actorName {
    final s = _ref.read(currentAuthStateProvider);
    return s is Authenticated ? s.user.name : 'unknown';
  }

  Future<void> voidInvoice({
    required String invoiceId,
    required String reason,
  }) =>
      _ref.read(invoicesDaoProvider).voidInvoice(
            id: invoiceId,
            reason: reason,
            approvedBy: _actorName,
          );
}

final invoiceActionsProvider =
    Provider<InvoiceActions>((ref) => InvoiceActions(ref));
