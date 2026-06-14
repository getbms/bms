import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/database/app_database.dart';
import '../features/auth/domain/auth_state.dart';
import 'auth_provider.dart';
import 'database_provider.dart';

// Manual providers — avoids riverpod_generator's Drift type serialization issue.

final suppliersStreamProvider = StreamProvider.autoDispose<List<Supplier>>(
    (ref) => ref.watch(suppliersDaoProvider).watchAll());

class SupplierActions {
  SupplierActions(this._ref);
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

  Future<String> addSupplier({
    required String name,
    String? phone,
    String? address,
    String? paymentTerms,
  }) async {
    final id = _uuid.v7();
    await _ref.read(suppliersDaoProvider).insert(SuppliersCompanion.insert(
          id: id,
          name: name,
          phone: Value(phone),
          address: Value(address),
          paymentTerms: Value(paymentTerms),
        ));
    await _ref.read(auditLogDaoProvider).log(
          id: _uuid.v7(),
          entityType: 'supplier',
          entityId: id,
          action: 'create',
          userId: _userId,
          userName: _userName,
          newValue: {'name': name, 'phone': phone, 'address': address},
        );
    return id;
  }

  Future<void> updateSupplier({
    required String supplierId,
    required String name,
    String? phone,
    String? address,
    String? paymentTerms,
  }) async {
    await _ref.read(suppliersDaoProvider).updateDetails(SuppliersCompanion(
          id: Value(supplierId),
          name: Value(name),
          phone: Value(phone),
          address: Value(address),
          paymentTerms: Value(paymentTerms),
        ));
    await _ref.read(auditLogDaoProvider).log(
          id: _uuid.v7(),
          entityType: 'supplier',
          entityId: supplierId,
          action: 'update',
          userId: _userId,
          userName: _userName,
          newValue: {'name': name, 'phone': phone, 'address': address},
        );
  }

  Future<void> recordPayment({
    required String supplierId,
    required double amount,
    required String method,
    String? notes,
  }) async {
    final paymentId = _uuid.v7();
    final dao = _ref.read(suppliersDaoProvider);
    await dao.recordPayment(SupplierPaymentsCompanion.insert(
      id: paymentId,
      supplierId: supplierId,
      amount: amount,
      method: Value(method),
      notes: Value(notes),
      userId: _userId,
    ));
    await dao.updateBalance(supplierId, -amount);
    await _ref.read(auditLogDaoProvider).log(
          id: _uuid.v7(),
          entityType: 'supplier_payment',
          entityId: supplierId,
          action: 'create',
          userId: _userId,
          userName: _userName,
          newValue: {'paymentId': paymentId, 'amount': amount, 'method': method},
        );
  }
}

final supplierActionsProvider =
    Provider<SupplierActions>((ref) => SupplierActions(ref));
