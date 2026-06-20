import 'package:bms/data/database/app_database.dart';
import 'package:bms/features/auth/domain/auth_state.dart';
import 'package:bms/providers/auth_provider.dart';
import 'package:bms/providers/database_provider.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'pos_provider.g.dart';

class CartItem {
  const CartItem({
    required this.product,
    required this.qty,
    required this.unitPrice,
    this.discountPct = 0,
  });

  final Product product;
  final double qty;
  final double unitPrice;
  final double discountPct;

  double get lineTotal => qty * unitPrice * (1 - discountPct / 100);

  CartItem copyWith({double? qty, double? unitPrice, double? discountPct}) => CartItem(
        product: product,
        qty: qty ?? this.qty,
        unitPrice: unitPrice ?? this.unitPrice,
        discountPct: discountPct ?? this.discountPct,
      );
}

class PosState {
  const PosState({
    this.items = const [],
    this.customer,
    this.paymentMethod = 'cash',
    this.amountTendered = 0,
    this.billDiscountPct = 0,
    this.isSubmitting = false,
    this.lastInvoiceNo,
  });

  final List<CartItem> items;
  final Customer? customer;
  final String paymentMethod;
  final double amountTendered;
  final double billDiscountPct;
  final bool isSubmitting;
  final String? lastInvoiceNo;

  double get subtotal => items.fold(0, (s, i) => s + i.lineTotal);
  double get discountAmount => subtotal * billDiscountPct / 100;
  double get total => subtotal - discountAmount;
  double get change => amountTendered - total;
  bool get isEmpty => items.isEmpty;

  PosState copyWith({
    List<CartItem>? items,
    Customer? Function()? customer,
    String? paymentMethod,
    double? amountTendered,
    double? billDiscountPct,
    bool? isSubmitting,
    String? Function()? lastInvoiceNo,
  }) =>
      PosState(
        items: items ?? this.items,
        customer: customer != null ? customer() : this.customer,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        amountTendered: amountTendered ?? this.amountTendered,
        billDiscountPct: billDiscountPct ?? this.billDiscountPct,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        lastInvoiceNo: lastInvoiceNo != null ? lastInvoiceNo() : this.lastInvoiceNo,
      );
}

@riverpod
class PosNotifier extends _$PosNotifier {
  final _uuid = const Uuid();

  @override
  PosState build() => const PosState();

  void addItem(Product product, {double qty = 1}) {
    if (qty <= 0) return;
    final items = List<CartItem>.from(state.items);
    final idx = items.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(qty: items[idx].qty + qty);
    } else {
      items.add(CartItem(product: product, qty: qty, unitPrice: product.sellPrice));
    }
    state = state.copyWith(items: items);
  }

  void removeItem(String productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.product.id != productId).toList(),
    );
  }

  void updateQty(String productId, double qty) {
    if (qty <= 0) {
      removeItem(productId);
      return;
    }
    state = state.copyWith(
      items: state.items
          .map((i) => i.product.id == productId ? i.copyWith(qty: qty) : i)
          .toList(),
    );
  }

  void updatePrice(String productId, double price) {
    state = state.copyWith(
      items: state.items
          .map((i) => i.product.id == productId ? i.copyWith(unitPrice: price) : i)
          .toList(),
    );
  }

  void setCustomer(Customer? customer) =>
      state = state.copyWith(customer: () => customer);

  void setPaymentMethod(String method) =>
      state = state.copyWith(paymentMethod: method);

  void setAmountTendered(double amount) =>
      state = state.copyWith(amountTendered: amount);

  void setLineDiscount(String productId, double pct) {
    state = state.copyWith(
      items: state.items
          .map((i) => i.product.id == productId ? i.copyWith(discountPct: pct.clamp(0, 100)) : i)
          .toList(),
    );
  }

  void setBillDiscount(double pct) =>
      state = state.copyWith(billDiscountPct: pct.clamp(0, 100));

  void clearCart() => state = const PosState();

  Future<String?> checkout() async {
    if (state.isEmpty) return null;

    state = state.copyWith(isSubmitting: true);

    try {
      final authState = ref.read(currentAuthStateProvider);
      final userId = authState is Authenticated ? authState.user.id : 'system';
      final userName = authState is Authenticated ? authState.user.name : 'system';

      final invoicesDao = ref.read(invoicesDaoProvider);
      final inventoryDao = ref.read(inventoryDaoProvider);
      final customersDao = ref.read(customersDaoProvider);
      final auditDao = ref.read(auditLogDaoProvider);

      final invoiceNo = await invoicesDao.nextInvoiceNumber();
      final invoiceId = _uuid.v7();

      final invoice = await invoicesDao.insertInvoice(InvoicesCompanion.insert(
        id: invoiceId,
        invoiceNo: invoiceNo,
        customerId: Value(state.customer?.id),
        subtotal: Value(state.subtotal),
        discountAmount: Value(state.discountAmount),
        total: Value(state.total),
        paymentType: Value(state.paymentMethod),
        userId: userId,
      ));

      await invoicesDao.insertItems(state.items
          .map((item) {
            final lineDiscountAmount = item.qty * item.unitPrice * item.discountPct / 100;
            return InvoiceItemsCompanion.insert(
              id: _uuid.v7(),
              invoiceId: invoiceId,
              productId: item.product.id,
              productName: item.product.name,
              qty: item.qty,
              unitPrice: item.unitPrice,
              discountPercent: Value(item.discountPct),
              discountAmount: Value(lineDiscountAmount),
              subtotal: item.lineTotal,
            );
          })
          .toList());

      for (final item in state.items) {
        final current = await inventoryDao.getStock(item.product.id);
        final newQty = (current?.qty ?? 0) - item.qty;
        await inventoryDao.upsertStock(StockCompanion(
          productId: Value(item.product.id),
          qty: Value(newQty < 0 ? 0 : newQty),
          updatedAt: Value(DateTime.now()),
        ));
        await inventoryDao.recordMovement(StockMovementsCompanion.insert(
          id: _uuid.v7(),
          type: 'out',
          productId: item.product.id,
          qty: item.qty,
          reason: const Value('sale'),
          userId: userId,
          refId: Value(invoiceId),
          refType: const Value('invoice'),
        ));
      }

      if (state.customer != null && state.paymentMethod == 'credit') {
        await customersDao.updateBalance(state.customer!.id, state.total);
      }

      await auditDao.log(
        id: _uuid.v7(),
        entityType: 'invoice',
        entityId: invoiceId,
        action: 'create',
        userId: userId,
        userName: userName,
        newValue: {
          'invoiceNo': invoiceNo,
          'subtotal': state.subtotal,
          'discountAmount': state.discountAmount,
          'total': state.total,
          'paymentMethod': state.paymentMethod,
          'itemCount': state.items.length,
          'customerId': state.customer?.id,
        },
      );

      state = PosState(lastInvoiceNo: invoice.invoiceNo);
      return invoice.invoiceNo;
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }
}
