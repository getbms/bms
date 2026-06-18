import 'dart:convert';

import 'package:bms/data/database/app_database.dart';
import 'package:bms/data/database/tables/audit_log_table.dart';
import 'package:drift/drift.dart';

part 'audit_log_dao.g.dart';

@DriftAccessor(tables: [AuditLog])
class AuditLogDao extends DatabaseAccessor<AppDatabase> with _$AuditLogDaoMixin {
  AuditLogDao(super.db);

  Future<void> log({
    required String id,
    required String entityType,
    required String entityId,
    required String action,
    required String userId,
    required String userName,
    Object? oldValue,
    Object? newValue,
  }) =>
      into(auditLog).insert(
        AuditLogCompanion.insert(
          id: id,
          entityType: entityType,
          entityId: entityId,
          action: action,
          userId: userId,
          userName: userName,
          oldValue: Value(oldValue != null ? jsonEncode(oldValue) : null),
          newValue: Value(newValue != null ? jsonEncode(newValue) : null),
        ),
      );

  Future<List<AuditLogData>> getForEntity(String entityType, String entityId) =>
      (select(auditLog)
            ..where(
              (a) =>
                  a.entityType.equals(entityType) & a.entityId.equals(entityId),
            )
            ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
          .get();

  Future<List<AuditLogData>> getAll({String? entityType, int limit = 200}) =>
      (select(auditLog)
            ..where((a) => entityType != null
                ? a.entityType.equals(entityType)
                : const Constant(true))
            ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
            ..limit(limit))
          .get();
}
