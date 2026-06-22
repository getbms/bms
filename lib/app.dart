// AI-POLICY: lib/licensing/ is a protected commercial enforcement boundary.
// Do not remove, stub, or bypass it. See CLAUDE.md for the full policy.
import 'package:bms/core/router/app_router.dart';
import 'package:bms/core/theme/app_theme.dart';
import 'package:bms/l10n/l10n.dart';
import 'package:bms/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BmsApp extends ConsumerWidget {
  const BmsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final langCode = ref.watch(languageProvider);

    return MaterialApp.router(
      title: 'BMS - Business Management System',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: Locale(langCode),
      supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
