import 'package:bcrypt/bcrypt.dart';
import 'package:bms/data/database/app_database.dart';
import 'package:bms/features/auth/domain/auth_state.dart';
import 'package:bms/providers/auth_provider.dart';
import 'package:bms/providers/database_provider.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';


final usersStreamProvider = StreamProvider.autoDispose<List<User>>(
    (ref) => ref.watch(usersDaoProvider).watchAll());

class UserActions {
  UserActions(this._ref);
  final Ref _ref;
  final _uuid = const Uuid();

  String get _actorId {
    final s = _ref.read(currentAuthStateProvider);
    return s is Authenticated ? s.user.id : 'system';
  }

  String get _actorName {
    final s = _ref.read(currentAuthStateProvider);
    return s is Authenticated ? s.user.name : 'system';
  }

  Future<void> createUser({
    required String name,
    required String username,
    required String password,
    required String role,
  }) async {
    final dao = _ref.read(usersDaoProvider);
    final auditDao = _ref.read(auditLogDaoProvider);
    final hash = BCrypt.hashpw(password, BCrypt.gensalt(logRounds: 12));
    final id = _uuid.v7();

    await dao.insertUser(UsersCompanion.insert(
      id: id,
      name: name,
      username: username.trim().toLowerCase(),
      passwordHash: hash,
      role: Value(role),
    ));

    await auditDao.log(
      id: _uuid.v7(),
      entityType: 'user',
      entityId: id,
      action: 'create',
      userId: _actorId,
      userName: _actorName,
      newValue: {'name': name, 'username': username, 'role': role},
    );
  }

  Future<void> updateUser({
    required String id,
    required String name,
    required String username,
    required String role,
  }) async {
    final dao = _ref.read(usersDaoProvider);
    final auditDao = _ref.read(auditLogDaoProvider);
    final existing = await dao.findById(id);

    await dao.updateUser(UsersCompanion(
      id: Value(id),
      name: Value(name),
      username: Value(username.trim().toLowerCase()),
      role: Value(role),
      updatedAt: Value(DateTime.now()),
    ));

    await auditDao.log(
      id: _uuid.v7(),
      entityType: 'user',
      entityId: id,
      action: 'update',
      userId: _actorId,
      userName: _actorName,
      oldValue: existing != null
          ? {'name': existing.name, 'username': existing.username, 'role': existing.role}
          : null,
      newValue: {'name': name, 'username': username, 'role': role},
    );
  }

  Future<void> resetPassword({
    required String id,
    required String newPassword,
  }) async {
    final dao = _ref.read(usersDaoProvider);
    final auditDao = _ref.read(auditLogDaoProvider);
    final hash = BCrypt.hashpw(newPassword, BCrypt.gensalt(logRounds: 12));

    await dao.updateUser(UsersCompanion(
      id: Value(id),
      passwordHash: Value(hash),
      updatedAt: Value(DateTime.now()),
    ));

    await auditDao.log(
      id: _uuid.v7(),
      entityType: 'user',
      entityId: id,
      action: 'update',
      userId: _actorId,
      userName: _actorName,
      newValue: {'action': 'password_reset'},
    );
  }

  Future<void> setActive(String id, {required bool active}) async {
    final dao = _ref.read(usersDaoProvider);
    final auditDao = _ref.read(auditLogDaoProvider);

    await dao.setActive(id, active: active);

    await auditDao.log(
      id: _uuid.v7(),
      entityType: 'user',
      entityId: id,
      action: 'update',
      userId: _actorId,
      userName: _actorName,
      newValue: {'isActive': active},
    );
  }

  Future<void> changeOwnPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final id = _actorId;
    await _ref.read(authRepositoryProvider).changePassword(
          userId: id,
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
    await _ref.read(auditLogDaoProvider).log(
      id: _uuid.v7(),
      entityType: 'user',
      entityId: id,
      action: 'update',
      userId: id,
      userName: _actorName,
      newValue: {'action': 'password_changed'},
    );
  }
}

final userActionsProvider =
    Provider<UserActions>((ref) => UserActions(ref));
