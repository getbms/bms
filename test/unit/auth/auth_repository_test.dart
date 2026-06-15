import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRepository', () {
    group('login', () {
      test('returns UserModel on valid credentials', () async {
        // TODO(phase1): implement with MockUsersDao + MockFlutterSecureStorage
      });

      test('throws AuthException with invalidCredentials on wrong password', () async {
        // TODO(phase1): verify failed attempt counter is incremented
      });

      test('throws AuthException with accountLocked when lockout threshold reached', () async {
        // TODO(phase1): verify lock timestamp is set correctly
      });

      test('throws AuthException on inactive account', () async {
        // TODO(phase1): verify no lockout increment on disabled accounts
      });
    });

    group('restoreSession', () {
      test('returns null when no session exists in secure storage', () async {
        // TODO(phase1): verify storage.read returns null
      });

      test('clears session and returns null when stored user is deactivated', () async {
        // TODO(phase1): verify storage.delete is called
      });
    });
  });
}
