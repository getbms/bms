import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openAppDatabaseConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'bms_local.sqlite'));
    // One-time migration: drift_flutter previously defaulted to Documents/.
    // Copy the legacy file on first launch if the new location is empty.
    if (!file.existsSync()) {
      final docsDir = await getApplicationDocumentsDirectory();
      final legacy = File(p.join(docsDir.path, 'bms_local.sqlite'));
      if (legacy.existsSync()) {
        await legacy.copy(file.path);
        // Copy WAL sidecars so committed-but-uncheckpointed data is not lost.
        // SQLite replays and checkpoints the WAL automatically on next open.
        for (final suffix in ['-wal', '-shm']) {
          final sidecar = File('${legacy.path}$suffix');
          if (sidecar.existsSync()) {
            await sidecar.copy('${file.path}$suffix');
          }
        }
      }
    }
    return NativeDatabase.createInBackground(file);
  });
}
