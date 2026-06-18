import 'package:bms/core/router/app_router.dart';
import 'package:bms/features/auth/domain/auth_state.dart';
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

  static String? redirect({
    required GoRouterState state,
    required AuthState authState,
  }) {
    final isPublic = _publicRoutes.contains(state.matchedLocation);

    return switch (authState) {
      Unauthenticated() => isPublic ? null : AppRoutes.login,
      Authenticated(:final user) => _guardAuthenticated(
          location: state.matchedLocation,
          isPublic: isPublic,
          role: user.role,
        ),
    };
  }

  static String? _guardAuthenticated({
    required String location,
    required bool isPublic,
    required String role,
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

    return null;
  }
}
