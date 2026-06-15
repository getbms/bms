import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/cheques/presentation/cheque_screen.dart';
import '../../features/customers/presentation/customers_screen.dart';
import '../../features/debtors/presentation/debtors_screen.dart';
import '../../features/invoices/presentation/invoices_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/petty_cash/presentation/petty_cash_screen.dart';
import '../../features/pos/presentation/pos_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/suppliers/presentation/suppliers_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/users/presentation/users_screen.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'route_guard.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(currentAuthStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: false,
    redirect: (context, state) => RouteGuard.redirect(
      state: state,
      authState: authState,
    ),
    routes: [
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
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 120),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fade = CurveTween(curve: Curves.easeIn).animate(animation);
        final slide = Tween<Offset>(begin: const Offset(0.015, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOut))
            .animate(animation);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );

abstract final class AppRoutes {
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
  static const String reports = '/reports';
  static const String users = '/users';
  static const String settings = '/settings';
}
