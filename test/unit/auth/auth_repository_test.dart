import 'package:bcrypt/bcrypt.dart';
import 'package:bms/core/constants/app_constants.dart';
import 'package:bms/core/errors/app_exception.dart';
import 'package:bms/data/database/app_database.dart';
import 'package:bms/data/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

User user({
  String id = 'user-1',
  String username = 'alice',
  bool isActive = true,
  int failedAttempts = 0,
  DateTime? lockedUntil,
  String? hash,
}) =>
    User(
      id: id,
      name: 'Alice',
      username: username,
      passwordHash: hash ?? BCrypt.hashpw('password123', BCrypt.gensalt(logRounds: 4)),
      role: 'cashier',
      isActive: isActive,
      failedAttempts: failedAttempts,
      lockedUntil: lockedUntil,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

void main() {
  late MockUsersDao dao;
  late MockSessionStorage storage;
  late AuthRepository repo;

  setUpAll(() {
    registerFallbackValue(const UsersCompanion());
  });

  setUp(() {
    dao = MockUsersDao();
    storage = MockSessionStorage();
    repo = AuthRepository(usersDao: dao, sessionStorage: storage);

    when(() => dao.incrementFailedAttempts(any())).thenAnswer((_) async {});
    when(() => dao.lockAccount(any(), any())).thenAnswer((_) async {});
    when(() => dao.resetFailedAttempts(any())).thenAnswer((_) async {});
    when(() => dao.recordLogin(any())).thenAnswer((_) async {});
    when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
  });

  group('AuthRepository', () {
    group('login', () {
      test('returns UserModel and writes session on valid credentials', () async {
        final u = user();
        when(() => dao.findByUsername('alice')).thenAnswer((_) async => u);

        final model = await repo.login('alice', 'password123');

        expect(model.id, 'user-1');
        expect(model.username, 'alice');
        verify(() => dao.resetFailedAttempts('user-1')).called(1);
        verify(() => dao.recordLogin('user-1')).called(1);
        verify(
          () => storage.write(
            key: AppConstants.sessionKey,
            value: 'user-1',
          ),
        ).called(1);
      });

      test('trims and lowercases username before lookup', () async {
        final u = user();
        when(() => dao.findByUsername('alice')).thenAnswer((_) async => u);

        await repo.login('  ALICE  ', 'password123');

        verify(() => dao.findByUsername('alice')).called(1);
      });

      test('throws invalidCredentials when user not found', () async {
        when(() => dao.findByUsername(any())).thenAnswer((_) async => null);

        expect(
          () => repo.login('unknown', 'password123'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.code,
              'code',
              AuthErrorCode.invalidCredentials,
            ),
          ),
        );
      });

      test('throws unauthorized on inactive account without incrementing failures', () async {
        when(() => dao.findByUsername('alice'))
            .thenAnswer((_) async => user(isActive: false));

        await expectLater(
          () => repo.login('alice', 'password123'),
          throwsA(
            isA<AuthException>().having((e) => e.code, 'code', AuthErrorCode.unauthorized),
          ),
        );

        verifyNever(() => dao.incrementFailedAttempts(any()));
      });

      test('throws accountLocked when lockedUntil is in the future', () async {
        final locked = user(lockedUntil: DateTime.now().add(const Duration(hours: 1)));
        when(() => dao.findByUsername('alice')).thenAnswer((_) async => locked);

        await expectLater(
          () => repo.login('alice', 'password123'),
          throwsA(
            isA<AuthException>().having((e) => e.code, 'code', AuthErrorCode.accountLocked),
          ),
        );
      });

      test('allows login when lockedUntil is in the past', () async {
        final expired = user(lockedUntil: DateTime.now().subtract(const Duration(minutes: 1)));
        when(() => dao.findByUsername('alice')).thenAnswer((_) async => expired);

        final model = await repo.login('alice', 'password123');
        expect(model.id, 'user-1');
      });

      test('increments failed attempts and throws invalidCredentials on wrong password', () async {
        when(() => dao.findByUsername('alice')).thenAnswer((_) async => user());

        await expectLater(
          () => repo.login('alice', 'wrong'),
          throwsA(
            isA<AuthException>().having((e) => e.code, 'code', AuthErrorCode.invalidCredentials),
          ),
        );

        verify(() => dao.incrementFailedAttempts('user-1')).called(1);
        verifyNever(() => dao.lockAccount(any(), any()));
      });

      test('locks account when failed attempts reach the threshold', () async {
        final almostLocked = user(failedAttempts: AppConstants.maxLoginAttempts - 1);
        when(() => dao.findByUsername('alice')).thenAnswer((_) async => almostLocked);

        await expectLater(
          () => repo.login('alice', 'wrong'),
          throwsA(isA<AuthException>()),
        );

        verify(() => dao.incrementFailedAttempts('user-1')).called(1);
        verify(() => dao.lockAccount('user-1', any())).called(1);
      });
    });

    group('restoreSession', () {
      test('returns null when no session key in storage', () async {
        when(() => storage.read(key: AppConstants.sessionKey))
            .thenAnswer((_) async => null);

        final result = await repo.restoreSession();

        expect(result, isNull);
        verifyNever(() => dao.findById(any()));
      });

      test('returns UserModel when session and user are valid', () async {
        when(() => storage.read(key: AppConstants.sessionKey))
            .thenAnswer((_) async => 'user-1');
        when(() => dao.findById('user-1')).thenAnswer((_) async => user());

        final model = await repo.restoreSession();

        expect(model?.id, 'user-1');
      });

      test('clears session and returns null when stored user is inactive', () async {
        when(() => storage.read(key: AppConstants.sessionKey))
            .thenAnswer((_) async => 'user-1');
        when(() => dao.findById('user-1'))
            .thenAnswer((_) async => user(isActive: false));

        final result = await repo.restoreSession();

        expect(result, isNull);
        verify(() => storage.delete(key: AppConstants.sessionKey)).called(1);
      });

      test('clears session and returns null when stored user no longer exists', () async {
        when(() => storage.read(key: AppConstants.sessionKey))
            .thenAnswer((_) async => 'user-99');
        when(() => dao.findById('user-99')).thenAnswer((_) async => null);

        final result = await repo.restoreSession();

        expect(result, isNull);
        verify(() => storage.delete(key: AppConstants.sessionKey)).called(1);
      });
    });

    group('changePassword', () {
      test('throws NotFoundException when user does not exist', () async {
        when(() => dao.findById('ghost')).thenAnswer((_) async => null);

        await expectLater(
          () => repo.changePassword(
            userId: 'ghost',
            currentPassword: 'old',
            newPassword: 'new',
          ),
          throwsA(isA<NotFoundException>()),
        );
      });

      test('throws invalidCredentials when current password is wrong', () async {
        when(() => dao.findById('user-1')).thenAnswer((_) async => user());

        await expectLater(
          () => repo.changePassword(
            userId: 'user-1',
            currentPassword: 'wrong',
            newPassword: 'new',
          ),
          throwsA(
            isA<AuthException>().having((e) => e.code, 'code', AuthErrorCode.invalidCredentials),
          ),
        );
      });

      test('updates hash and records change on valid current password', () async {
        when(() => dao.findById('user-1')).thenAnswer((_) async => user());
        when(() => dao.updateUser(any())).thenAnswer((_) async => true);
        when(() => dao.recordPasswordChange(any())).thenAnswer((_) async {});

        await repo.changePassword(
          userId: 'user-1',
          currentPassword: 'password123',
          newPassword: 'newPass!',
        );

        verify(() => dao.updateUser(any())).called(1);
        verify(() => dao.recordPasswordChange('user-1')).called(1);
      });
    });
  });
}
