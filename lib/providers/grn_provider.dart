import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/database/app_database.dart';
import '../features/auth/domain/auth_state.dart';
import 'auth_provider.dart';
import 'database_provider.dart';

final grnListProvider = FutureProvider.autoDispose<List<Purchase>>((ref) {
  return ref.watch(suppliersDaoProvider).getAllPurchases();
});

final grnBySupplierProvider =
    FutureProvider.autoDispose.family<List<Purchase>, String>((ref, supplierId) {
  return ref.watch(suppliersDaoProvider).getPurchasesBySupplier(supplierId);
});

class GrnCartItem {
  const GrnCartItem({
    required this.product,
    required this.qty,
    required this.costPrice,
  });
  final Product product;
  final double qty;
  final double costPrice;
  double get lineTotal => qty * costPrice;

  GrnCartItem copyWith({double? qty, double? costPrice}) => GrnCartItem(
        product: product,
        qty: qty ?? this.qty,
        costPrice: costPrice ?? this.costPrice,
      );
}

class GrnState {
  const GrnState({
    this.supplier,
    this.items = const [],
    this.isSubmitting = false,
    this.lastGrnNo,
  });
  final Supplier? supplier;
  final List<GrnCartItem> items;
  final bool isSubmitting;
  final String? lastGrnNo;

  double get total => items.fold(0, (s, i) => s + i.lineTotal);
  bool get canSubmit => supplier != null && items.isNotEmpty;

  GrnState copyWith({
    Supplier? Function()? supplier,
    List<GrnCartItem>? items,
    bool? isSubmitting,
    String? Function()? lastGrnNo,
  }) =>
      GrnState(
        supplier: supplier != null ? supplier() : this.supplier,
        items: items ?? this.items,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        lastGrnNo: lastGrnNo != null ? lastGrnNo() : this.lastGrnNo,
      );
}

class GrnNotifier extends Notifier<GrnState> {
  final _uuid = const Uuid();

  @override
  GrnState build() => const GrnState();

  void setSupplier(Supplier? supplier) =>
      state = state.copyWith(supplier: () => supplier);

  void addItem(Product product) {
    final items = List<GrnCartItem>.from(state.items);
    final idx = items.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(qty: items[idx].qty + 1);
    } else {
      items.add(GrnCartItem(product: product, qty: 1, costPrice: product.costPrice));
    }
    state = state.copyWith(items: items);
  }

  void updateItem(String productId, {double? qty, double? costPrice}) {
    state = state.copyWith(
      items: state.items.map((i) {
        if (i.product.id != productId) return i;
        return i.copyWith(qty: qty, costPrice: costPrice);
      }).toList(),
    );
  }

  void removeItem(String productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.product.id != productId).toList(),
    );
  }

  void reset() => state = const GrnState();

  Future<String?> confirm() async {
    if (!state.canSubmit) return null;
    state = state.copyWith(isSubmitting: true);

    try {
      final authState = ref.read(currentAuthStateProvider);
      final userId = authState is Authenticated ? authState.user.id : 'system';
      final userName = authState is Authenticated ? authState.user.name : 'system';

      final suppliersDao = ref.read(suppliersDaoProvider);
      final inventoryDao = ref.read(inventoryDaoProvider);
      final auditDao = ref.read(auditLogDaoProvider);

      final grnNo = await suppliersDao.nextGrnNumber();
      final purchaseId = _uuid.v7();

      await suppliersDao.insertPurchase(PurchasesCompanion.insert(
        id: purchaseId,
        supplierId: state.supplier!.id,
        grnNumber: Value(grnNo),
        total: Value(state.total),
        userId: userId,
      ));

      await suppliersDao.insertPurchaseItems(
        state.items
            .map((i) => PurchaseItemsCompanion.insert(
                  id: _uuid.v7(),
                  purchaseId: purchaseId,
                  productId: i.product.id,
                  qty: i.qty,
                  costPrice: i.costPrice,
                ))
            .toList(),
      );

      // Stock in + update cost price
      for (final item in state.items) {
        final current = await inventoryDao.getStock(item.product.id);
        final newQty = (current?.qty ?? 0) + item.qty;
        await inventoryDao.upsertStock(StockCompanion(
          productId: Value(item.product.id),
          qty: Value(newQty),
          updatedAt: Value(DateTime.now()),
        ));
        await inventoryDao.recordMovement(StockMovementsCompanion.insert(
          id: _uuid.v7(),
          type: 'in',
          productId: item.product.id,
          qty: item.qty,
          reason: const Value('grn'),
          userId: userId,
          refId: Value(purchaseId),
          refType: const Value('purchase'),
        ));
        // Update cost price on product
        await inventoryDao.updateCostPrice(item.product.id, item.costPrice);
      }

      // Update supplier balance
      await suppliersDao.updateBalance(state.supplier!.id, state.total);

      await auditDao.log(
        id: _uuid.v7(),
        entityType: 'grn',
        entityId: purchaseId,
        action: 'create',
        userId: userId,
        userName: userName,
        newValue: {
          'grnNo': grnNo,
          'supplierId': state.supplier!.id,
          'supplierName': state.supplier!.name,
          'total': state.total,
          'itemCount': state.items.length,
        },
      );

      state = GrnState(lastGrnNo: grnNo);
      return grnNo;
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }
}

final grnProvider = NotifierProvider<GrnNotifier, GrnState>(GrnNotifier.new);
