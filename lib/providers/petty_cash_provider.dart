import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/database/app_database.dart';
import '../features/auth/domain/auth_state.dart';
import 'auth_provider.dart';
import 'database_provider.dart';

typedef _DateRange = ({DateTime from, DateTime to});

// Manual NotifierProvider for date range — no codegen needed.
// Screens: ref.read(pettyCashDateRangeProvider.notifier).set(from, to)
final pettyCashDateRangeProvider =
    NotifierProvider<_PettyCashDateRangeNotifier, _DateRange>(
  _PettyCashDateRangeNotifier.new,
);

class _PettyCashDateRangeNotifier extends Notifier<_DateRange> {
  @override
  _DateRange build() {
    final now = DateTime.now();
    return (from: DateTime(now.year, now.month, 1), to: now);
  }

  void set(DateTime from, DateTime to) => state = (from: from, to: to);
}

// Manual FutureProvider — avoids riverpod_generator's Drift type issue.
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
  }) async {
    final id = _uuid.v7();
    await _ref.read(pettyCashDaoProvider).insert(PettyCashCompanion.insert(
          id: id,
          description: description,
          amount: amount,
          type: type,
          category: category,
          userId: _userId,
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

  Future<void> reject(String id) async {
    await _ref.read(pettyCashDaoProvider).reject(id);
    await _ref.read(auditLogDaoProvider).log(
          id: _uuid.v7(),
          entityType: 'petty_cash',
          entityId: id,
          action: 'reject',
          userId: _userId,
          userName: _userName,
          newValue: {'status': 'rejected'},
        );
  }
}

final pettyCashActionsProvider =
    Provider<PettyCashActions>((ref) => PettyCashActions(ref));
