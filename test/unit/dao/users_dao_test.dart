import 'package:bms/data/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/test_database.dart';

void main() {
  group('UsersDao', () {
    late AppDatabase db;
    setUp(() { db = openTestDatabase(); });
    tearDown(() async { await db.close(); });

    UsersCompanion seedUser({
      String id = 'u1',
      String name = 'Alice',
      String username = 'alice',
      String passwordHash = 'hash1',
      bool isActive = true,
    }) =>
        UsersCompanion.insert(
          id: id,
          name: name,
          username: username,
          passwordHash: passwordHash,
          isActive: Value(isActive),
        );

    test('insertUser + findByUsername: found returns user', () async {
      await db.usersDao.insertUser(seedUser());
      final result = await db.usersDao.findByUsername('alice');
      expect(result, isNotNull);
      expect(result?.username, 'alice');
    });

    test('findByUsername: not found returns null', () async {
      final result = await db.usersDao.findByUsername('nobody');
      expect(result, isNull);
    });

    test('findById: found returns user', () async {
      await db.usersDao.insertUser(seedUser());
      final result = await db.usersDao.findById('u1');
      expect(result, isNotNull);
      expect(result?.id, 'u1');
    });

    test('findById: not found returns null', () async {
      final result = await db.usersDao.findById('missing');
      expect(result, isNull);
    });

    test('findAll activeOnly=true excludes inactive', () async {
      await db.usersDao.insertUser(seedUser());
      await db.usersDao.insertUser(seedUser(id: 'u2', username: 'bob', isActive: false));
      final result = await db.usersDao.findAll();
      // developer seed user (active) is also present in test DB
      expect(result.any((u) => u.id == 'u1'), isTrue);
      expect(result.any((u) => u.id == 'u2'), isFalse);
      expect(result.every((u) => u.isActive), isTrue);
    });

    test('findAll activeOnly=false returns all', () async {
      await db.usersDao.insertUser(seedUser());
      await db.usersDao.insertUser(seedUser(id: 'u2', username: 'bob', isActive: false));
      final result = await db.usersDao.findAll(activeOnly: false);
      // developer seed user also present in test DB
      expect(result.any((u) => u.id == 'u1'), isTrue);
      expect(result.any((u) => u.id == 'u2'), isTrue);
    });

    test('incrementFailedAttempts increases count by 1', () async {
      await db.usersDao.insertUser(seedUser());
      await db.usersDao.incrementFailedAttempts('u1');
      final result = await db.usersDao.findById('u1');
      expect(result?.failedAttempts, 1);
    });

    test('resetFailedAttempts sets count to 0', () async {
      await db.usersDao.insertUser(seedUser());
      await db.usersDao.incrementFailedAttempts('u1');
      await db.usersDao.incrementFailedAttempts('u1');
      await db.usersDao.resetFailedAttempts('u1');
      final result = await db.usersDao.findById('u1');
      expect(result?.failedAttempts, 0);
    });

    test('lockAccount sets lockedUntil correctly', () async {
      await db.usersDao.insertUser(seedUser());
      final until = DateTime(2030);
      await db.usersDao.lockAccount('u1', until);
      final result = await db.usersDao.findById('u1');
      expect(result?.lockedUntil, equals(until));
    });

    test('setActive(false) disables user', () async {
      await db.usersDao.insertUser(seedUser());
      await db.usersDao.setActive('u1', active: false);
      final result = await db.usersDao.findById('u1');
      expect(result?.isActive, false);
    });

    test('setActive(true) re-enables user', () async {
      await db.usersDao.insertUser(seedUser(isActive: false));
      await db.usersDao.setActive('u1', active: true);
      final result = await db.usersDao.findById('u1');
      expect(result?.isActive, true);
    });

    test('recordLogin sets lastLoginAt to non-null', () async {
      await db.usersDao.insertUser(seedUser());
      await db.usersDao.recordLogin('u1');
      final result = await db.usersDao.findById('u1');
      expect(result?.lastLoginAt, isNotNull);
    });

    test('recordPasswordChange sets passwordChangedAt to non-null', () async {
      await db.usersDao.insertUser(seedUser());
      await db.usersDao.recordPasswordChange('u1');
      final result = await db.usersDao.findById('u1');
      expect(result?.passwordChangedAt, isNotNull);
    });

    test('updateUser changes passwordHash', () async {
      await db.usersDao.insertUser(seedUser());
      await db.usersDao.updateUser(
        const UsersCompanion(id: Value('u1'), passwordHash: Value('newhash')),
      );
      final result = await db.usersDao.findById('u1');
      expect(result?.passwordHash, 'newhash');
    });
  });
}
