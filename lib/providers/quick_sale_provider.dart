import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/database/app_database.dart';
import '../features/auth/domain/auth_state.dart';
import 'auth_provider.dart';
import 'database_provider.dart';

typedef _DateRange = ({DateTime from, DateTime to});

final quickSaleDateRangeProvider =
    NotifierProvider<_QuickSaleDateRangeNotifier, _DateRange>(
  _QuickSaleDateRangeNotifier.new,
);

class _QuickSaleDateRangeNotifier extends Notifier<_DateRange> {
  @override
  _DateRange build() {
    final now = DateTime.now();
    return (from: DateTime(now.year, now.month, 1), to: now);
  }

  void set(DateTime from, DateTime to) => state = (from: from, to: to);
}

final quickSalesListProvider = FutureProvider.autoDispose<List<NoInvoiceSale>>(
  (ref) {
    final range = ref.watch(quickSaleDateRangeProvider);
    return ref
        .watch(invoicesDaoProvider)
        .getNoInvoiceSalesByDate(range.from, range.to);
  },
);

class QuickSaleActions {
  QuickSaleActions(this._ref);
  final Ref _ref;
  final _uuid = const Uuid();

  String get _userId {
    final s = _ref.read(currentAuthStateProvider);
    return s is Authenticated ? s.user.id : 'system';
  }

  String get _userName {
    final s = _ref.read(currentAuthStateProvider);
    return s is Authenticated ? s.user.name : 'system';
  }

  Future<void> sell({
    required Product product,
    required double qty,
    required double price,
    String? notes,
  }) async {
    if (qty <= 0 || price <= 0) {
      throw ArgumentError('Quantity and price must be greater than zero');
    }

    final id = _uuid.v7();
    final inventoryDao = _ref.read(inventoryDaoProvider);
    final invoicesDao = _ref.read(invoicesDaoProvider);
    final auditDao = _ref.read(auditLogDaoProvider);

    await invoicesDao.insertNoInvoiceSale(NoInvoiceSalesCompanion.insert(
      id: id,
      productId: product.id,
      productName: product.name,
      qty: qty,
      price: price,
      userId: _userId,
      notes: Value(notes),
    ));

    final current = await inventoryDao.getStock(product.id);
    final currentQty = current?.qty ?? 0;
    final newQty = (currentQty - qty).clamp(0.0, double.infinity);
    final actualDeducted = currentQty - newQty;
    await inventoryDao.upsertStock(StockCompanion(
      productId: Value(product.id),
      qty: Value(newQty),
      updatedAt: Value(DateTime.now()),
    ));
    await inventoryDao.recordMovement(StockMovementsCompanion.insert(
      id: _uuid.v7(),
      type: 'out',
      productId: product.id,
      qty: actualDeducted,
      reason: const Value('quick_sale'),
      userId: _userId,
      refId: Value(id),
      refType: const Value('no_invoice_sale'),
    ));

    await auditDao.log(
      id: _uuid.v7(),
      entityType: 'no_invoice_sale',
      entityId: id,
      action: 'create',
      userId: _userId,
      userName: _userName,
      newValue: {
        'productId': product.id,
        'productName': product.name,
        'qty': qty,
        'price': price,
        'total': qty * price,
      },
    );
  }
}

final quickSaleActionsProvider =
    Provider<QuickSaleActions>((ref) => QuickSaleActions(ref));
