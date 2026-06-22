import 'package:bms/core/storage/session_storage.dart';
import 'package:bms/data/database/daos/audit_log_dao.dart';
import 'package:bms/data/database/daos/inventory_dao.dart';
import 'package:bms/data/database/daos/users_dao.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockUsersDao extends Mock implements UsersDao {}
class MockInventoryDao extends Mock implements InventoryDao {}
class MockAuditLogDao extends Mock implements AuditLogDao {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockSessionStorage extends Mock implements SessionStorage {}
