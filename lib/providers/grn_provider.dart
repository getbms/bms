import 'package:bms/data/database/app_database.dart';
import 'package:bms/features/auth/domain/auth_state.dart';
import 'package:bms/providers/auth_provider.dart';
import 'package:bms/providers/database_provider.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final grnListProvider = FutureProvider.autoDispose<List<Purchase>>((ref) {
  return ref.watch(suppliersDaoProvider).getAllPurchases();
});

final grnBySupplierProvider =
    FutureProvider.autoDispose.family<List<Purchase>, String>((ref, supplierId) {
  return ref.watch(suppliersDaoProvider).getPurchasesBySupplier(supplierId);
});

final poListProvider = FutureProvider.autoDispose<List<PurchaseOrder>>((ref) {
  return ref.watch(suppliersDaoProvider).getAllPOs();
});

final poBySupplierProvider =
    FutureProvider.autoDispose.family<List<PurchaseOrder>, String>((ref, supplierId) {
  return ref.watch(suppliersDaoProvider).getPOsBySupplier(supplierId);
});

final poItemsProvider =
    FutureProvider.autoDispose.family<List<PurchaseOrderItem>, String>((ref, poId) {
  return ref.watch(suppliersDaoProvider).getPOItems(poId);
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
    this.linkedPoId,
    this.supplierInvoiceNo,
    this.supplierInvoiceAmount,
  });
  final Supplier? supplier;
  final List<GrnCartItem> items;
  final bool isSubmitting;
  final String? lastGrnNo;
  final String? linkedPoId;
  final String? supplierInvoiceNo;
  final double? supplierInvoiceAmount;

  double get total => items.fold(0, (s, i) => s + i.lineTotal);
  bool get canSubmit => supplier != null && items.isNotEmpty;

  GrnState copyWith({
    Supplier? Function()? supplier,
    List<GrnCartItem>? items,
    bool? isSubmitting,
    String? Function()? lastGrnNo,
    String? Function()? linkedPoId,
    String? Function()? supplierInvoiceNo,
    double? Function()? supplierInvoiceAmount,
  }) =>
      GrnState(
        supplier: supplier != null ? supplier() : this.supplier,
        items: items ?? this.items,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        lastGrnNo: lastGrnNo != null ? lastGrnNo() : this.lastGrnNo,
        linkedPoId: linkedPoId != null ? linkedPoId() : this.linkedPoId,
        supplierInvoiceNo:
            supplierInvoiceNo != null ? supplierInvoiceNo() : this.supplierInvoiceNo,
        supplierInvoiceAmount:
            supplierInvoiceAmount != null ? supplierInvoiceAmount() : this.supplierInvoiceAmount,
      );
}

class GrnNotifier extends Notifier<GrnState> {
  final _uuid = const Uuid();

  @override
  GrnState build() => const GrnState();

  void setSupplier(Supplier? supplier) =>
      state = state.copyWith(supplier: () => supplier);

  void setLinkedPO(String? poId) =>
      state = state.copyWith(linkedPoId: () => poId);

  void setSupplierInvoice({String? invoiceNo, double? amount}) {
    state = state.copyWith(
      supplierInvoiceNo: () => invoiceNo,
      supplierInvoiceAmount: () => amount,
    );
  }

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

    final supplier = state.supplier!;
    final items = List<GrnCartItem>.from(state.items);
    final total = state.total;
    final linkedPoId = state.linkedPoId;
    final supplierInvoiceNo = state.supplierInvoiceNo;
    final supplierInvoiceAmount = state.supplierInvoiceAmount;

    try {
      final authState = ref.read(currentAuthStateProvider);
      final userId = authState is Authenticated ? authState.user.id : 'system';
      final userName = authState is Authenticated ? authState.user.name : 'system';

      final db = ref.read(appDatabaseProvider);
      final suppliersDao = ref.read(suppliersDaoProvider);
      final inventoryDao = ref.read(inventoryDaoProvider);
      final auditDao = ref.read(auditLogDaoProvider);

      final grnNo = await db.transaction<String?>(() async {
        final grnNumber = await suppliersDao.nextGrnNumber();
        final purchaseId = _uuid.v7();

        await suppliersDao.insertPurchase(PurchasesCompanion.insert(
          id: purchaseId,
          supplierId: supplier.id,
          grnNumber: Value(grnNumber),
          total: Value(total),
          userId: userId,
          poId: Value(linkedPoId),
          supplierInvoiceNo: Value(supplierInvoiceNo),
          supplierInvoiceAmount: Value(supplierInvoiceAmount),
        ));

        await suppliersDao.insertPurchaseItems(
          items
              .map((i) => PurchaseItemsCompanion.insert(
                    id: _uuid.v7(),
                    purchaseId: purchaseId,
                    productId: i.product.id,
                    qty: i.qty,
                    costPrice: i.costPrice,
                  ))
              .toList(),
        );

        for (final item in items) {
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
          await inventoryDao.updateCostPrice(item.product.id, item.costPrice);
        }

        await suppliersDao.updateBalance(supplier.id, total);

        if (linkedPoId != null) {
          await suppliersDao.updatePOStatus(linkedPoId, 'received');
        }

        await auditDao.log(
          id: _uuid.v7(),
          entityType: 'grn',
          entityId: purchaseId,
          action: 'create',
          userId: userId,
          userName: userName,
          newValue: {
            'grnNo': grnNumber,
            'supplierId': supplier.id,
            'supplierName': supplier.name,
            'total': total,
            'itemCount': items.length,
            'poId': linkedPoId,
            'supplierInvoiceNo': supplierInvoiceNo,
          },
        );

        return grnNumber;
      });

      state = GrnState(lastGrnNo: grnNo);
      ref.invalidate(grnListProvider);
      ref.invalidate(poListProvider);
      return grnNo;
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }
}

final grnProvider = NotifierProvider<GrnNotifier, GrnState>(GrnNotifier.new);

// ---- PO creation ----

class PoCartItem {
  const PoCartItem({
    required this.product,
    required this.orderedQty,
    required this.costPrice,
  });
  final Product product;
  final double orderedQty;
  final double costPrice;
  double get lineTotal => orderedQty * costPrice;

  PoCartItem copyWith({double? orderedQty, double? costPrice}) => PoCartItem(
        product: product,
        orderedQty: orderedQty ?? this.orderedQty,
        costPrice: costPrice ?? this.costPrice,
      );
}

class PoFormState {
  const PoFormState({
    this.supplier,
    this.items = const [],
    this.notes,
    this.isSubmitting = false,
    this.lastPoNumber,
  });
  final Supplier? supplier;
  final List<PoCartItem> items;
  final String? notes;
  final bool isSubmitting;
  final String? lastPoNumber;

  double get total => items.fold(0, (s, i) => s + i.lineTotal);
  bool get canSubmit => supplier != null && items.isNotEmpty;

  PoFormState copyWith({
    Supplier? Function()? supplier,
    List<PoCartItem>? items,
    String? Function()? notes,
    bool? isSubmitting,
    String? Function()? lastPoNumber,
  }) =>
      PoFormState(
        supplier: supplier != null ? supplier() : this.supplier,
        items: items ?? this.items,
        notes: notes != null ? notes() : this.notes,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        lastPoNumber: lastPoNumber != null ? lastPoNumber() : this.lastPoNumber,
      );
}

class PoNotifier extends Notifier<PoFormState> {
  final _uuid = const Uuid();

  @override
  PoFormState build() => const PoFormState();

  void setSupplier(Supplier? s) => state = state.copyWith(supplier: () => s);
  void setNotes(String? notes) => state = state.copyWith(notes: () => notes);

  void addItem(Product product) {
    final items = List<PoCartItem>.from(state.items);
    final idx = items.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(orderedQty: items[idx].orderedQty + 1);
    } else {
      items.add(PoCartItem(product: product, orderedQty: 1, costPrice: product.costPrice));
    }
    state = state.copyWith(items: items);
  }

  void updateItem(String productId, {double? orderedQty, double? costPrice}) {
    state = state.copyWith(
      items: state.items.map((i) {
        if (i.product.id != productId) return i;
        return i.copyWith(orderedQty: orderedQty, costPrice: costPrice);
      }).toList(),
    );
  }

  void removeItem(String productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.product.id != productId).toList(),
    );
  }

  void reset() => state = const PoFormState();

  Future<String?> submit() async {
    if (!state.canSubmit) return null;
    state = state.copyWith(isSubmitting: true);

    final supplier = state.supplier!;
    final items = List<PoCartItem>.from(state.items);
    final total = state.total;

    try {
      final authState = ref.read(currentAuthStateProvider);
      final userId = authState is Authenticated ? authState.user.id : 'system';
      final userName = authState is Authenticated ? authState.user.name : 'system';

      final db = ref.read(appDatabaseProvider);
      final suppliersDao = ref.read(suppliersDaoProvider);
      final auditDao = ref.read(auditLogDaoProvider);

      final poId = _uuid.v7();
      final poNumber = await db.transaction<String>(() async {
        final number = await suppliersDao.nextPoNumber();

        await suppliersDao.insertPO(PurchaseOrdersCompanion.insert(
          id: poId,
          supplierId: supplier.id,
          poNumber: number,
          total: Value(total),
          notes: Value(state.notes),
          createdBy: userId,
        ));

        await suppliersDao.insertPOItems(
          items
              .map((i) => PurchaseOrderItemsCompanion.insert(
                    id: _uuid.v7(),
                    poId: poId,
                    productId: i.product.id,
                    orderedQty: i.orderedQty,
                    costPrice: i.costPrice,
                  ))
              .toList(),
        );

        return number;
      });

      await auditDao.log(
        id: _uuid.v7(),
        entityType: 'purchase_order',
        entityId: poId,
        action: 'create',
        userId: userId,
        userName: userName,
        newValue: {
          'poNumber': poNumber,
          'supplierId': supplier.id,
          'supplierName': supplier.name,
          'total': total,
          'itemCount': items.length,
        },
      );

      state = PoFormState(lastPoNumber: poNumber);
      ref.invalidate(poListProvider);
      return poNumber;
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }
}

final poProvider = NotifierProvider<PoNotifier, PoFormState>(PoNotifier.new);
