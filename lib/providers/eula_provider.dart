import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

// EULA acceptance is not sensitive data - store as a plain marker file rather
// than in the Keychain to avoid macOS password prompts on every launch.
class EulaNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    if (kIsWeb) return true;
    try {
      return (await _markerFile()).existsSync();
    } catch (_) {
      return false;
    }
  }

  Future<void> accept() async {
    try {
      final file = await _markerFile();
      await file.writeAsString(DateTime.now().toUtc().toIso8601String());
    } catch (_) {
      return;
    }
    state = const AsyncData(true);
  }

  static Future<File> _markerFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/.eula_accepted');
  }
}

final eulaProvider = AsyncNotifierProvider<EulaNotifier, bool>(EulaNotifier.new);
