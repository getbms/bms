import 'package:bms/core/router/app_router.dart';
import 'package:bms/features/auth/domain/auth_state.dart';
import 'package:bms/licensing/license_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Role matrix:
///   developer - all routes
///   admin     - all except /users (user management)
///   cashier   - dashboard, pos, inventory (view), customers
// ignore: avoid_classes_with_only_static_members
abstract final class RouteGuard {
  static const Set<String> _publicRoutes = {AppRoutes.login};

  static const Set<String> _developerOnlyRoutes = {
    AppRoutes.users,
  };

  static const Set<String> _adminAndAboveOnlyRoutes = {
    AppRoutes.settings,
  };

  static const Set<String> _adminAndAboveRoutes = {
    AppRoutes.suppliers,
    AppRoutes.cheques,
    AppRoutes.pettyCash,
    AppRoutes.reports,
  };

  // Routes gated behind a license feature (pro or enterprise).
  static const Map<String, String> _featureGatedRoutes = {
    AppRoutes.reports:   'reports',
    AppRoutes.grn:       'grn',
    AppRoutes.cheques:   'cheques',
    AppRoutes.pettyCash: 'petty_cash',
    AppRoutes.debtors:   'debtors',
    AppRoutes.users:     'users',
  };

  static String? redirect({
    required GoRouterState state,
    required AuthState authState,
    required AsyncValue<LicenseState> license,
  }) {
    final location = state.matchedLocation;

    // Still loading license — stay on splash and wait for a rebuild.
    if (license.isLoading && !license.hasValue) {
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    }

    final lic = license.value ?? LicenseState.unlicensed;

    // License not usable — send to activation screen.
    if (!lic.isUsable) {
      return location == AppRoutes.activate ? null : AppRoutes.activate;
    }

    // License usable but on a gating screen — route by auth state.
    if (location == AppRoutes.activate || location == AppRoutes.splash) {
      return switch (authState) {
        Unauthenticated() => AppRoutes.login,
        Authenticated()   => AppRoutes.dashboard,
      };
    }

    final isPublic = _publicRoutes.contains(location);
    return switch (authState) {
      Unauthenticated() => isPublic ? null : AppRoutes.login,
      Authenticated(:final user) => _guardAuthenticated(
          location: location,
          isPublic: isPublic,
          role: user.role,
          features: lic.features,
        ),
    };
  }

  static String? _guardAuthenticated({
    required String location,
    required bool isPublic,
    required String role,
    required Set<String> features,
  }) {
    if (isPublic) return AppRoutes.dashboard;

    if (_developerOnlyRoutes.contains(location) && role != 'developer') {
      return AppRoutes.dashboard;
    }

    if (_adminAndAboveRoutes.contains(location) && role == 'cashier') {
      return AppRoutes.dashboard;
    }

    if (_adminAndAboveOnlyRoutes.contains(location) && role == 'cashier') {
      return AppRoutes.dashboard;
    }

    // Block routes whose required feature is absent from this license tier.
    final required = _featureGatedRoutes[location];
    if (required != null && !features.contains(required)) {
      return AppRoutes.dashboard;
    }

    return null;
  }
}
