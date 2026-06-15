import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/repositories/auth_repository.dart';
import '../features/auth/domain/auth_state.dart';
import 'database_provider.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(Ref ref) => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      mOptions: MacOsOptions(useDataProtectionKeyChain: false),
    );

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepository(
      usersDao: ref.watch(usersDaoProvider),
      secureStorage: ref.watch(secureStorageProvider),
    );

@riverpod
class AuthStateNotifier extends _$AuthStateNotifier {
  @override
  Future<AuthState> build() async {
    final repo = ref.watch(authRepositoryProvider);
    final user = await repo.restoreSession();
    return user != null
        ? AuthState.authenticated(user: user)
        : const AuthState.unauthenticated();
  }

  Future<void> login(String username, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).login(username, password);
      return AuthState.authenticated(user: user);
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).clearSession();
    state = const AsyncData(AuthState.unauthenticated());
  }
}

/// Convenience: flat AuthState (not wrapped in AsyncValue) for router.
@riverpod
AuthState currentAuthState(Ref ref) {
  return ref.watch(authStateProvider).maybeWhen(
        data: (s) => s,
        orElse: () => const AuthState.unauthenticated(),
      );
}
