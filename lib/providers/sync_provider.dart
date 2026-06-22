import 'dart:async';

import 'package:bms/data/sync/sync_service.dart';
import 'package:bms/providers/database_provider.dart';
import 'package:bms/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kLastPushKey = 'bms.sync.last_push_at';
const _kLastPullKey = 'bms.sync.last_pull_at';
const _syncInterval = Duration(seconds: 30);
// Epoch zero means "sync everything" on first run.
final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

// -------------------------------------------------------------------------
// State
// -------------------------------------------------------------------------

enum SyncStatus { idle, syncing, success, error, disabled }

class SyncState {
  const SyncState({
    required this.status,
    this.lastSyncAt,
    this.lastError,
    this.pendingPush = 0,
    this.lastPulled = 0,
  });

  final SyncStatus status;
  final DateTime? lastSyncAt;
  final String? lastError;
  final int pendingPush;
  final int lastPulled;

  static const initial = SyncState(status: SyncStatus.idle);

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncAt,
    String? lastError,
    int? pendingPush,
    int? lastPulled,
  }) =>
      SyncState(
        status: status ?? this.status,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        lastError: lastError ?? this.lastError,
        pendingPush: pendingPush ?? this.pendingPush,
        lastPulled: lastPulled ?? this.lastPulled,
      );
}

// -------------------------------------------------------------------------
// Notifier
// -------------------------------------------------------------------------

class SyncNotifier extends Notifier<SyncState> {
  Timer? _timer;
  static const _storage = FlutterSecureStorage();

  @override
  SyncState build() {
    final settings = ref.watch(dbConnectionSettingsProvider);
    if (settings.isLocalSqlite) {
      _timer?.cancel();
      return const SyncState(status: SyncStatus.disabled);
    }
    _schedulePeriodicSync(settings);
    ref.onDispose(() => _timer?.cancel());
    return SyncState.initial;
  }

  void _schedulePeriodicSync(dynamic settings) {
    _timer?.cancel();
    _timer = Timer.periodic(_syncInterval, (_) => _runSync());
    // Run immediately on first connect.
    Future.microtask(_runSync);
  }

  Future<void> syncNow() => _runSync();

  Future<void> _runSync() async {
    final settings = ref.read(dbConnectionSettingsProvider);
    if (settings.isLocalSqlite) return;

    // Prevent overlapping sync executions
    if (state.status == SyncStatus.syncing) return;

    state = state.copyWith(status: SyncStatus.syncing);

    try {
      final lastPushAt = await _readTimestamp(_kLastPushKey);
      final lastPullAt = await _readTimestamp(_kLastPullKey);

      final service = SyncService(ref.read(appDatabaseProvider));
      final result  = await service.sync(
        settings: settings,
        lastPushAt: lastPushAt,
        lastPullAt: lastPullAt,
      );

      final now = DateTime.now().toUtc();

      if (result.hasErrors) {
        state = state.copyWith(
          status: SyncStatus.error,
          lastSyncAt: now,
          lastError: result.errors.first,
          pendingPush: result.pushed,
          lastPulled: result.pulled,
        );
      } else {
        await _saveTimestamp(_kLastPushKey, now);
        await _saveTimestamp(_kLastPullKey, now);
        state = SyncState(
          status: SyncStatus.success,
          lastSyncAt: now,
          pendingPush: result.pushed,
          lastPulled: result.pulled,
        );
      }
    } on SyncException catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        lastError: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        lastError: e.toString(),
      );
    }
  }

  Future<DateTime> _readTimestamp(String key) async {
    try {
      final raw = await _storage.read(key: key);
      if (raw != null) return DateTime.parse(raw);
    } catch (_) {}
    return _epoch;
  }

  Future<void> _saveTimestamp(String key, DateTime dt) async {
    try {
      await _storage.write(key: key, value: dt.toIso8601String());
    } catch (_) {}
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);

// Convenience providers consumed by the settings UI.
final syncStatusProvider = Provider<SyncStatus>((ref) => ref.watch(syncProvider).status);
final lastSyncAtProvider  = Provider<DateTime?>((ref) => ref.watch(syncProvider).lastSyncAt);
