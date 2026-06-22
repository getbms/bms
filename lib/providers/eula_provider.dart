import 'package:bms/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EulaNotifier extends AsyncNotifier<bool> {
  static const _storage = FlutterSecureStorage();

  @override
  Future<bool> build() async {
    // On web we skip the EULA gate (demo/preview builds).
    if (kIsWeb) return true;

    try {
      final value = await _storage.read(key: AppConstants.eulaStorageKey);
      return value != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> accept() async {
    try {
      await _storage.write(
        key: AppConstants.eulaStorageKey,
        value: DateTime.now().toUtc().toIso8601String(),
      );
    } catch (_) {}
    state = const AsyncData(true);
  }
}

final eulaProvider = AsyncNotifierProvider<EulaNotifier, bool>(EulaNotifier.new);
