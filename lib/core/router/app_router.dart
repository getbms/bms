import 'package:bms/core/router/route_guard.dart';
import 'package:bms/features/auth/presentation/login_screen.dart';
import 'package:bms/features/cheques/presentation/cheque_screen.dart';
import 'package:bms/features/customers/presentation/customers_screen.dart';
import 'package:bms/features/dashboard/presentation/dashboard_screen.dart';
import 'package:bms/features/debtors/presentation/debtors_screen.dart';
import 'package:bms/features/grn/presentation/grn_screen.dart';
import 'package:bms/features/inventory/presentation/inventory_screen.dart';
import 'package:bms/features/invoices/presentation/invoices_screen.dart';
import 'package:bms/features/petty_cash/presentation/petty_cash_screen.dart';
import 'package:bms/features/pos/presentation/pos_screen.dart';
import 'package:bms/features/quick_sales/presentation/quick_sales_screen.dart';
import 'package:bms/features/reports/presentation/reports_screen.dart';
import 'package:bms/features/settings/presentation/settings_screen.dart';
import 'package:bms/features/suppliers/presentation/suppliers_screen.dart';
import 'package:bms/features/users/presentation/users_screen.dart';
import 'package:bms/licensing/activation_screen.dart';
import 'package:bms/licensing/license_provider.dart';
import 'package:bms/providers/auth_provider.dart';
import 'package:bms/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

class _RouterNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final notifier = _RouterNotifier();

  ref.listen(currentAuthStateProvider, (_, _) => notifier.notify());
  ref.listen(licenseProvider, (_, _) => notifier.notify());
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) => RouteGuard.redirect(
      state: state,
      authState: ref.read(currentAuthStateProvider),
      license: ref.read(licenseProvider),
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => _fadePage(state, const _SplashPage()),
      ),
      GoRoute(
        path: AppRoutes.activate,
        name: 'activate',
        pageBuilder: (context, state) =>
            _fadePage(state, const ActivationScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _fadePage(state, const LoginScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) => _fadePage(state, const DashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.pos,
            name: 'pos',
            pageBuilder: (context, state) => _fadePage(state, const PosScreen()),
          ),
          GoRoute(
            path: AppRoutes.invoices,
            name: 'invoices',
            pageBuilder: (context, state) => _fadePage(state, const InvoicesScreen()),
          ),
          GoRoute(
            path: AppRoutes.inventory,
            name: 'inventory',
            pageBuilder: (context, state) => _fadePage(state, const InventoryScreen()),
          ),
          GoRoute(
            path: AppRoutes.customers,
            name: 'customers',
            pageBuilder: (context, state) => _fadePage(state, const CustomersScreen()),
          ),
          GoRoute(
            path: AppRoutes.debtors,
            name: 'debtors',
            pageBuilder: (context, state) => _fadePage(state, const DebtorsScreen()),
          ),
          GoRoute(
            path: AppRoutes.suppliers,
            name: 'suppliers',
            pageBuilder: (context, state) => _fadePage(state, const SuppliersScreen()),
          ),
          GoRoute(
            path: AppRoutes.cheques,
            name: 'cheques',
            pageBuilder: (context, state) => _fadePage(state, const ChequeScreen()),
          ),
          GoRoute(
            path: AppRoutes.pettyCash,
            name: 'pettyCash',
            pageBuilder: (context, state) => _fadePage(state, const PettyCashScreen()),
          ),
          GoRoute(
            path: AppRoutes.quickSales,
            name: 'quickSales',
            pageBuilder: (context, state) => _fadePage(state, const QuickSalesScreen()),
          ),
          GoRoute(
            path: AppRoutes.grn,
            name: 'grn',
            pageBuilder: (context, state) => _fadePage(state, const GrnScreen()),
          ),
          GoRoute(
            path: AppRoutes.reports,
            name: 'reports',
            pageBuilder: (context, state) => _fadePage(state, const ReportsScreen()),
          ),
          GoRoute(
            path: AppRoutes.users,
            name: 'users',
            pageBuilder: (context, state) => _fadePage(state, const UsersScreen()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (context, state) => _fadePage(state, const SettingsScreen()),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
}

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurveTween(curve: Curves.easeOut).animate(animation);
        final slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic))
            .animate(animation);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      ),
    );
  }
}

abstract final class AppRoutes {
  static const String splash   = '/';
  static const String activate = '/activate';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String pos = '/pos';
  static const String invoices = '/invoices';
  static const String inventory = '/inventory';
  static const String customers = '/customers';
  static const String debtors = '/debtors';
  static const String suppliers = '/suppliers';
  static const String cheques = '/cheques';
  static const String pettyCash = '/petty-cash';
  static const String quickSales = '/quick-sales';
  static const String grn = '/grn';
  static const String reports = '/reports';
  static const String users = '/users';
  static const String settings = '/settings';
}
