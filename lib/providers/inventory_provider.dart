import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/repositories/inventory_repository.dart';
import 'database_provider.dart';

part 'inventory_provider.g.dart';

@Riverpod(keepAlive: true)
InventoryRepository inventoryRepository(Ref ref) => InventoryRepository(
      inventoryDao: ref.watch(inventoryDaoProvider),
      auditLogDao: ref.watch(auditLogDaoProvider),
    );
