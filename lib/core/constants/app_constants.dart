abstract final class AppConstants {
  static const String appName = 'BMS';
  static const String appVersion = '1.0.0';

  // Auth
  static const String sessionKey = 'bms_session';
  static const int sessionTimeoutMinutes = 480; // 8 hours
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 15;

  // Pagination
  static const int defaultPageSize = 50;

  // Low stock fallback threshold (products carry their own reorder_level)
  static const int defaultReorderLevel = 10;

  // Cheque reminder schedule (days before due date)
  static const List<int> chequeReminderDaysBefore = [1, 3, 7];

  // Touch targets (WCAG AA minimum)
  static const double minTouchTargetSize = 48.0;

  // Layout
  static const double sidebarWidth = 240.0;
  static const double sidebarCollapsedWidth = 64.0;
  static const double sidebarBreakpoint = 900.0;
}
