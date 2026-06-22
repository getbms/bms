import 'package:bms/providers/eula_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Enforces a minimum splash duration on desktop, first launch only.
// - Web: skip immediately (no splash delay on browser builds).
// - Desktop, EULA already accepted (returning user): skip immediately.
// - Desktop, first launch (EULA not yet accepted): hold for 2.5 s.
final splashReadyProvider = FutureProvider<void>((ref) async {
  if (kIsWeb) return;

  final eulaAccepted = await ref.read(eulaProvider.future);
  if (!eulaAccepted) {
    await Future.delayed(const Duration(milliseconds: 2500));
  }
});
