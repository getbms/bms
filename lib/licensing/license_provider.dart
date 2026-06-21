import 'package:bms/licensing/device_id.dart';
import 'package:bms/licensing/license_constants.dart';
import 'package:bms/licensing/license_model.dart';
import 'package:bms/licensing/license_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ---------------------------------------------------------------------------
// Service provider
// ---------------------------------------------------------------------------

final licenseServiceProvider = Provider<LicenseService>(
  (_) => LicenseService(),
);

// ---------------------------------------------------------------------------
// Device ID provider (cached in secure storage across restarts)
// ---------------------------------------------------------------------------

final deviceIdProvider = FutureProvider<String>((ref) async {
  const storage = FlutterSecureStorage();
  final cached = await storage.read(key: kLicDeviceId);
  if (cached != null) return cached;
  final id = await computeDeviceId();
  await storage.write(key: kLicDeviceId, value: id);
  return id;
});

// ---------------------------------------------------------------------------
// License state notifier
// ---------------------------------------------------------------------------

class LicenseNotifier extends AsyncNotifier<LicenseState> {
  @override
  Future<LicenseState> build() async {
    final service  = ref.watch(licenseServiceProvider);
    final cached   = await service.loadCachedState();

    // If we have a usable cached state, try to refresh in the background
    // so the app starts instantly and validates silently.
    if (cached.isUsable) {
      _refreshInBackground(service);
      return cached;
    }

    return cached;
  }

  void _refreshInBackground(LicenseService service) {
    Future.microtask(() async {
      try {
        final jwt = await service.readStoredJwt();
        if (jwt == null) return;
        final deviceId = await ref.read(deviceIdProvider.future);
        final fresh = await service.validateOnline(jwt, deviceId);
        state = AsyncData(fresh);
      } catch (_) {
        // Swallow — background refresh failure is non-fatal.
      }
    });
  }

  // Called from ActivationScreen after the user enters a key.
  // Throws LicenseException (or generic Exception) on failure so the screen
  // can display the error — does NOT store an AsyncError in state.
  Future<void> activate(String key) async {
    state = const AsyncLoading();
    try {
      final service  = ref.read(licenseServiceProvider);
      final deviceId = await ref.read(deviceIdProvider.future);
      final result   = await service.activate(key, deviceId);
      state = AsyncData(result);
    } catch (e) {
      state = const AsyncData(LicenseState.unlicensed);
      rethrow;
    }
  }

  // Called from the settings screen to release this device slot.
  Future<void> deactivate() async {
    final service = ref.read(licenseServiceProvider);
    final jwt     = await service.readStoredJwt();
    if (jwt == null) return;
    final deviceId = await ref.read(deviceIdProvider.future);
    await service.deactivate(jwt, deviceId);
    state = const AsyncData(LicenseState.unlicensed);
  }

  // Force an online re-validation (e.g. pull-to-refresh on settings).
  Future<void> revalidate() async {
    final service  = ref.read(licenseServiceProvider);
    final jwt      = await service.readStoredJwt();
    if (jwt == null) {
      state = const AsyncData(LicenseState.unlicensed);
      return;
    }
    final deviceId = await ref.read(deviceIdProvider.future);
    final fresh    = await service.validateOnline(jwt, deviceId);
    state = AsyncData(fresh);
  }
}

final licenseProvider = AsyncNotifierProvider<LicenseNotifier, LicenseState>(
  LicenseNotifier.new,
);

// ---------------------------------------------------------------------------
// Derived providers — consumed throughout the app
// ---------------------------------------------------------------------------

final allowedFeaturesProvider = Provider<Set<String>>((ref) {
  return ref.watch(licenseProvider).value?.features ?? {};
});

final licenseTierProvider = Provider<LicenseTier>((ref) {
  return ref.watch(licenseProvider).value?.tier ?? LicenseTier.free;
});

final licenseStatusProvider = Provider<LicenseStatus>((ref) {
  if (ref.watch(licenseProvider).isLoading) return LicenseStatus.checking;
  return ref.watch(licenseProvider).value?.status ??
      LicenseStatus.unlicensed;
});
