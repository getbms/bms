import 'package:bms/data/database/app_database.dart';
import 'package:bms/features/auth/domain/auth_state.dart';
import 'package:bms/providers/auth_provider.dart';
import 'package:bms/providers/database_provider.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// Manual providers - riverpod_generator cannot serialize Drift-generated types
// in function signatures during the build phase, so we use the manual API.

final chequesMonthStreamProvider =
    StreamProvider.autoDispose.family<List<Cheque>, (int, int)>((ref, args) {
  final (year, month) = args;
  return ref.watch(chequesDaoProvider).watchByMonth(year, month);
});

final chequesUpcomingProvider = FutureProvider.autoDispose<List<Cheque>>(
    (ref) => ref.watch(chequesDaoProvider).getDueWithinDays(7));

class ChequeActions {
  ChequeActions(this._ref);
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

  Future<void> addCheque({
    required String type,
    required String partyId,
    required String partyType,
    required String partyName,
    required double amount,
    required DateTime dueDate,
    String? chequeNo,
    String? bank,
    String? notes,
  }) async {
    final id = _uuid.v7();
    await _ref.read(chequesDaoProvider).insert(ChequesCompanion.insert(
          id: id,
          type: type,
          partyId: partyId,
          partyType: partyType,
          partyName: partyName,
          amount: amount,
          dueDate: dueDate,
          chequeNo: Value(chequeNo),
          bank: Value(bank),
          notes: Value(notes),
          createdBy: _userId,
        ));
    await _ref.read(auditLogDaoProvider).log(
          id: _uuid.v7(),
          entityType: 'cheque',
          entityId: id,
          action: 'create',
          userId: _userId,
          userName: _userName,
          newValue: {
            'type': type,
            'partyName': partyName,
            'amount': amount,
            'dueDate': dueDate.toIso8601String(),
            'chequeNo': chequeNo,
            'bank': bank,
          },
        );
  }

  Future<void> updateStatus(String id, String status) async {
    final dao = _ref.read(chequesDaoProvider);
    final before = await dao.findById(id);
    await dao.updateStatus(id, status);
    await _ref.read(auditLogDaoProvider).log(
          id: _uuid.v7(),
          entityType: 'cheque',
          entityId: id,
          action: 'update',
          userId: _userId,
          userName: _userName,
          oldValue: before != null ? {'status': before.status} : null,
          newValue: {'status': status},
        );
  }
}

final chequeActionsProvider =
    Provider<ChequeActions>((ref) => ChequeActions(ref));
