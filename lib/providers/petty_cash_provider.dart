import 'package:bms/data/database/app_database.dart';
import 'package:bms/features/auth/domain/auth_state.dart';
import 'package:bms/providers/auth_provider.dart';
import 'package:bms/providers/database_provider.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

typedef _DateRange = ({DateTime from, DateTime to});

// Manual NotifierProvider for date range - no codegen needed.
final pettyCashDateRangeProvider =
    NotifierProvider<_PettyCashDateRangeNotifier, _DateRange>(
  _PettyCashDateRangeNotifier.new,
);

class _PettyCashDateRangeNotifier extends Notifier<_DateRange> {
  @override
  _DateRange build() {
    final now = DateTime.now();
    return (from: DateTime(now.year, now.month), to: now);
  }

  void set(DateTime from, DateTime to) => state = (from: from, to: to);
}

// Manual FutureProvider - avoids riverpod_generator's Drift type issue.
final pettyCashEntriesProvider = FutureProvider.autoDispose<List<PettyCashEntry>>(
  (ref) {
    final range = ref.watch(pettyCashDateRangeProvider);
    return ref.watch(pettyCashDaoProvider).getByDateRange(range.from, range.to);
  },
);

class PettyCashActions {
  PettyCashActions(this._ref);
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

  Future<void> addEntry({
    required String description,
    required double amount,
    required String type,
    required String category,
    String? receiptPhotoPath,
  }) async {
    final id = _uuid.v7();
    await _ref.read(pettyCashDaoProvider).insert(PettyCashCompanion.insert(
          id: id,
          description: description,
          amount: amount,
          type: type,
          category: category,
          userId: _userId,
          receiptPhotoPath: Value(receiptPhotoPath),
        ));
    await _ref.read(auditLogDaoProvider).log(
          id: _uuid.v7(),
          entityType: 'petty_cash',
          entityId: id,
          action: 'create',
          userId: _userId,
          userName: _userName,
          newValue: {
            'description': description,
            'amount': amount,
            'type': type,
            'category': category,
          },
        );
  }

  Future<void> approve(String id) async {
    await _ref.read(pettyCashDaoProvider).approve(id, _userId);
    await _ref.read(auditLogDaoProvider).log(
          id: _uuid.v7(),
          entityType: 'petty_cash',
          entityId: id,
          action: 'approve',
          userId: _userId,
          userName: _userName,
          newValue: {'status': 'approved'},
        );
  }

  Future<void> reject(String id, {String? notes}) async {
    await _ref.read(pettyCashDaoProvider).reject(id, notes: notes);
    await _ref.read(auditLogDaoProvider).log(
          id: _uuid.v7(),
          entityType: 'petty_cash',
          entityId: id,
          action: 'reject',
          userId: _userId,
          userName: _userName,
          newValue: {'status': 'rejected', 'notes': notes},
        );
  }
}

final pettyCashActionsProvider =
    Provider<PettyCashActions>((ref) => PettyCashActions(ref));
