import 'dart:async';

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/logger.dart';
import '../database/app_database.dart';
import '../database/daos/users_dao.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository({required UsersDao usersDao, required FlutterSecureStorage secureStorage})
      : _dao = usersDao,
        _storage = secureStorage;

  final UsersDao _dao;
  final FlutterSecureStorage _storage;

  Future<UserModel> login(String username, String password) async {
    final user = await _dao.findByUsername(username.trim().toLowerCase());

    if (user == null) {
      throw const AuthException(
        'Invalid username or password',
        code: AuthErrorCode.invalidCredentials,
      );
    }

    if (!user.isActive) {
      throw const AuthException(
        'Account is disabled',
        code: AuthErrorCode.unauthorized,
      );
    }

    if (user.lockedUntil != null && user.lockedUntil!.isAfter(DateTime.now())) {
      throw AuthException(
        'Account locked. Try again after ${user.lockedUntil!.toLocal()}',
        code: AuthErrorCode.accountLocked,
      );
    }

    final isValid = BCrypt.checkpw(password, user.passwordHash);

    if (!isValid) {
      await _dao.incrementFailedAttempts(user.id);
      if (user.failedAttempts + 1 >= AppConstants.maxLoginAttempts) {
        final lockUntil = DateTime.now().add(
          const Duration(minutes: AppConstants.lockoutDurationMinutes),
        );
        await _dao.lockAccount(user.id, lockUntil);
        appLogger.w('Account locked', error: {'userId': user.id});
      }
      throw const AuthException(
        'Invalid username or password',
        code: AuthErrorCode.invalidCredentials,
      );
    }

    await _dao.resetFailedAttempts(user.id);

    final model = UserModel(
      id: user.id,
      name: user.name,
      username: user.username,
      role: user.role,
      isActive: user.isActive,
    );

    // Persist session to secure storage
    await _storage.write(key: AppConstants.sessionKey, value: user.id);
    appLogger.i('Login', error: {'userId': user.id, 'role': user.role});

    return model;
  }

  Future<UserModel?> restoreSession() async {
    final userId = await _storage.read(key: AppConstants.sessionKey);
    if (userId == null) return null;

    final user = await _dao.findById(userId);
    if (user == null || !user.isActive) {
      await clearSession();
      return null;
    }

    return UserModel(
      id: user.id,
      name: user.name,
      username: user.username,
      role: user.role,
      isActive: user.isActive,
    );
  }

  Future<void> clearSession() async {
    await _storage.delete(key: AppConstants.sessionKey);
  }

  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = await _dao.findById(userId);
    if (user == null) throw NotFoundException('User', userId);

    if (!BCrypt.checkpw(currentPassword, user.passwordHash)) {
      throw const AuthException(
        'Current password is incorrect',
        code: AuthErrorCode.invalidCredentials,
      );
    }

    final newHash = BCrypt.hashpw(newPassword, BCrypt.gensalt(logRounds: 12));
    await _dao.update(UsersCompanion(
      id: Value(userId),
      passwordHash: Value(newHash),
      updatedAt: Value(DateTime.now()),
    ));
  }
}
