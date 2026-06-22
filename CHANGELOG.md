# Changelog

All notable changes to BMS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Fixed
- EULA screen now always displays in English regardless of the selected app language; all UI strings (title, buttons, checkbox, dialogs) are hardcoded English so the legal agreement is consistent across locales
- Replaced placeholder briefcase icon in EULA header with the actual BMS SVG logo
- Expanded EULA from 10 to 15 sections: added Definitions, License Tiers, Indemnification, Severability, and Contact clauses; all existing sections fleshed out with full legal language covering IP ownership, license key enforcement, data privacy, warranty disclaimer, liability cap, and governing law
- Window title bar now reads "BMS - Business Management System" on both macOS (via AppInfo.xcconfig) and Windows (via Runner.rc); Flutter MaterialApp title updated to match

### Added
- MySQL sync engine: bidirectional SQLite-to-MySQL sync running as a 30-second background interval when a MySQL connection is configured; SQLite remains the primary local-first store; MySQL is the shared hub for multi-terminal and cloud-backup scenarios
- `SyncService` with per-table push (SQLite to MySQL) and pull (MySQL to SQLite) using `updated_at` as the change cursor; last-write-wins conflict resolution
- `SyncNotifier` Riverpod provider tracking sync status (idle / syncing / success / error) and last-sync timestamp; persisted across restarts via secure storage
- `sync_tables_registry.dart` registering all 20 syncable tables in FK-safe dependency order with column type descriptors for DDL generation and MySQL value parsing; `audit_log` and `stock_movements` are push-only
- Real MySQL connection test in Settings replacing the previous placeholder toast; test button now connects, runs `SELECT 1`, and reports success or the actual error
- Sync status bar in the DB connection settings card: live status icon, last-synced timestamp, and Sync Now button
- `CLAUDE.md` repo-level contributor guide with explicit AI assistant policy for the licensing module
- `.cursorrules` and `.github/copilot-instructions.md` extending the licensing protection policy to Cursor and GitHub Copilot
- `// AI-POLICY:` header comments in `main.dart`, `app.dart`, `app_router.dart`, `app_scaffold.dart`, `route_guard.dart`, `license_service.dart`, and `license_provider.dart` so the policy is present in every file an AI reads first
- `lib/licensing/license_integrity.dart` imported by `main.dart` as a compile-time structural lock; deleting `lib/licensing/` causes a build failure regardless of instruction files
- Licensing layer: server-validated JWT-based commercial license enforcement gating all app access and feature tiers (free / pro / enterprise)
- Activation screen for desktop builds; web builds receive full enterprise access unconditionally (preview mode)
- `RouteGuard` license redirects: unlicensed state redirects to `/activate` before login; pro/enterprise feature routes blocked at router level via `_featureGatedRoutes` map
- Sidebar nav feature gating: nav items hidden by tier via `allowedFeaturesProvider`
- Grace period: 7-day offline grace when JWT expires and the server is unreachable; amber banner shown during grace period
- Device fingerprinting via `device_info_plus` with SHA-256 hashing; platform-specific fields per target (Android, iOS, Windows, macOS, Linux, web)

### Changed
- Schema bumped to v8: `updated_at` added to `invoices`, `invoice_items`, `no_invoice_sales`, `customer_payments`, `supplier_payments`, `sales_returns`; `deleted_at` added to `invoices` for soft-delete sync support
- `mysql_client` added as a dependency for MySQL connectivity

### Fixed
- All `flutter_secure_storage` calls wrapped in try/catch to prevent IndexedDB exceptions on web from surfacing as false network errors in the activation screen
- Activation error message now includes the actual exception details instead of a generic "Could not connect" string

---

### Added
- Full internationalisation (i18n): ~470 ARB keys across `app_en.arb`, `app_si.arb`, and `app_ta.arb`; all screens and shared widgets migrated from hardcoded English strings to `context.l10n.*` calls
- Sinhala (si) and Tamil (ta) translations for every user-facing string including parameterised strings (invoice number, GRN number, discrepancy amount, aging buckets)
- Poppins font (Regular / Medium / SemiBold / Bold) bundled in `assets/fonts/` and set as the app-wide typeface, replacing the placeholder Inter reference

### Changed
- Sidebar nav and bottom nav labels now re-evaluate on every build via `_buildSections(context)` / `_buildItems(context)`, fixing locale-change not reflecting in nav labels without a restart
- `ConfirmationDialog.confirmLabel` / `cancelLabel` made nullable; default falls back to `context.l10n.confirm` / `context.l10n.cancel` so the dialog localises automatically without callers changing
- `BmsSearchField.hintText` and `BmsFilterRow.searchHint` made nullable; default falls back to `context.l10n.search`
- Duplicate ARB key `change` (POS cash-change display) renamed to `posChange` to avoid collision with the general-purpose `change` (modify) key; si/ta receive correct distinct translations

### Fixed
- PO creation race condition: `nextPoNumber()` call and subsequent `insertPO` / `insertPOItems` now execute inside a single `db.transaction()`, matching the existing GRN atomic pattern
- `purchases.po_id` missing FK constraint: column now declares `.references(PurchaseOrders, #id, onDelete: KeyAction.setNull)`; schema bumped to v7 with a `TableMigration(purchases)` step so existing databases are recreated with the constraint
- Wrong Sinhala translations: `walkIn` was "ගෙදර" (home) corrected to "සෘජු ගනුදෙනු"; `roleCashier` was "කෙළිය" (game) corrected to "කේෂියර්"
- Hardcoded "Connection settings saved" snackbar in settings screen replaced with `context.l10n.connectionSettingsSaved`
- Hardcoded "Invalid number" validator message in suppliers screen replaced with `context.l10n.invalidNumber`

### Added
- Dashboard KPI drill-down navigation: tapping "Today's Sales" filters invoices to today, "Low Stock" opens inventory pre-filtered to low-stock items, "Total Receivables" goes to the Debtors screen
- User management: last login timestamp and password-changed-at timestamp recorded and displayed in the user detail sheet
- User self-service password change: any user can change their own password from the user detail sheet (current password required)
- Petty cash rejection notes: managers can enter an optional reason when rejecting a petty cash request; reason is displayed in the entry list
- Petty cash approval timestamp: `approvedAt` recorded on both approve and reject actions
- Cheque lifecycle tracking: deposit date, bounce date, bounce reason, and re-presentation count columns added; full event timeline shown in cheque detail sheet
- Cheque actions: Deposit (with date picker), Bounce (date + optional reason), Re-present (resets to pending, increments counter), Clear
- Purchase Orders: create POs with supplier, line items (qty + cost), notes, and auto-generated PO number (PO-00001 format); PO list with status badges (Draft / Sent / Partial / Received / Cancelled) in a dedicated GRN tab
- GRN supplier invoice linking: optional supplier invoice number and invoice amount fields on GRN confirmation; discrepancy warning shown when invoice amount differs from received total
- GRN to PO linking: open GRNs can be linked to an existing PO; confirming a GRN automatically marks the linked PO as received
- Language switching wired to `MaterialApp.locale`: selecting English / Sinhala / Tamil in Settings now applies the locale to the entire app immediately; preference persisted across sessions
- Database connection settings (developer role): choose between SQLite (local, default), MySQL local, or MySQL remote; MySQL connection fields (host, port, database name, username, password) stored securely; settings persist across sessions; MySQL sync engine planned for a future release

### Fixed
- Web platform: replaced `flutter_secure_storage` with an in-memory `SessionStorage` wrapper on web to avoid `window.crypto.subtle.generateKey()` failure in sandboxed / non-HTTPS contexts
- Language preference was saved to storage but never applied to `MaterialApp`; language switching now takes effect immediately without a restart

- Debtors screen: tap any debtor to open a detail sheet showing outstanding balance, credit limit, payment history, and a "Record Payment" button
- Customer payment recording: amount, payment method (cash/card/bank transfer/cheque), and optional notes; updates balance immediately
- Supplier detail sheet: payment history section listing past payments with method, notes, amount, and date
- In-app notification bell in sidebar header (desktop) and floating top-right (mobile) with red badge count
- Alerts panel: overdue cheques, cheques due within 7 days, low-stock products, and customers exceeding credit limit -- pull-to-refresh supported
- CSV export on all three Reports tabs: P&L (date, revenue, COGS, gross profit, margin), Stock Valuation (product, qty, unit cost, total value), Debtor Aging (customer, balance, bucket) -- shares via system share sheet
- Responsive dashboard KPI grid: 2 columns on phones (<480px), 3 on tablets (<840px), 4 on desktop (>=840px)
- Lint CI workflow running `flutter analyze --fatal-infos --fatal-warnings` on every push and PR

### Changed
- Gross Profit value on MTD Performance card changed from mint green to white for consistency with the blue card background
- Save Store Info button in Settings moved to bottom-right of the Store Info section
- Language selector in Settings converted from `DecoratedBox` to `Material` to prevent invisible ink-splash assertion
- All relative imports in `lib/` converted to `package:bms/` URIs

### Fixed
- 446 lint warnings resolved: package imports, `prefer_const_constructors`, `avoid_redundant_argument_values`, `prefer_int_literals`, `directives_ordering`, `unnecessary_underscores`, `avoid_dynamic_calls`, deprecated `Radio.groupValue`/`onChanged` (migrated to `RadioGroup`), positional boolean parameters, and type errors introduced by over-aggressive int-literal substitution

### Added
- Login screen BMS SVG logo from `assets/images/bms_logo.svg` with dynamic copyright footer (`DateTime.now().year`)
- POS fractional quantity support for weight/volume unit types (`kg`, `g`, `l`, `ml`) - product card tap opens qty dialog with decimal input, stepper uses unit-appropriate increments (0.25 for kg/l, 50 for g/ml), cart displays formatted decimal quantities
- Dashboard 30-day revenue trend line chart with dual series (Revenue solid, Gross Profit dashed) and gradient fill below each line
- Dashboard 7-day grouped bar chart showing Revenue vs Gross Profit side by side per day
- Dashboard MTD card sub-metrics: Gross Profit, Margin %, and Avg Order Value
- Empty state views on Reports screen for P&L (no data), Stock (no stock on hand), and Debtor Aging (all clear) tabs - 88px icon circle, bold title, muted subtitle
- Reports screen with three tabs: P&L, Stock Valuation, and Debtor Aging
- P&L tab - date range picker, revenue/COGS/gross profit/margin summary cards, daily revenue bar chart with horizontal scrolling for wide ranges
- Stock Valuation tab - total stock value card, per-product value list sorted by value with relative progress bar
- Debtor Aging tab - donut chart splitting outstanding balances into 0-30d / 31-60d / 61-90d / 90+ buckets with per-customer aging badge
- Dashboard 7-day revenue bar chart showing last seven days with day-of-week labels
- Dashboard month-to-date sales card with percentage growth vs previous month
- Dashboard payment method donut chart (cash / card / cheque / credit / mixed) for the current month
- `ReportsDao` - plain DAO class providing `getDailySales`, `getStockValuation`, and `getDebtorAging` using Drift typed join queries; no code-gen required
- `DailySales`, `StockValuationRow`, `DebtorAgingRow` data classes with computed properties (grossProfit, agingBucket, daysPastDue)
- CodeQL Advanced workflow scanning GitHub Actions workflows with `security-extended` and `security-and-quality` query suites
- Dependabot configuration for both `pub` and `github-actions` ecosystems with grouped minor/patch updates and co-dependent package groups (drift, riverpod, freezed, go_router)

### Changed
- Dashboard KPI cards redesigned with left accent stripe, value-first hierarchy (large bold value at bottom, muted label at top, small icon bubble top-right), shadow instead of border
- Dashboard KPI card grid `childAspectRatio` increased to 3 for shorter cards with tighter padding
- Dashboard AppBar title split into "Dashboard" headline and date subtitle in white70 - no em-dash separator
- Dashboard 30-day trend replaces the previous 7-day bar chart; provider now fetches 30 days of daily sales with gross profit
- P&L bar chart replaced fixed-width horizontal scroll with a full-width `BarChart` that fills available screen width; zero-revenue day bars rendered in border gray
- P&L summary grid replaced `GridView.count` (fixed aspect ratio causing oversized cards on desktop) with `Column` of `Row(Expanded, Expanded)` pairs for content-driven card height
- `InventoryRepository.adjustStock()` accepts optional `movementType` parameter so callers can record `return_in` movements instead of the default `in`
- `InvoiceDetailScreen` action row switched from `Row` to `Wrap` to handle three buttons without overflow on narrow screens
- Dashboard provider expanded to fetch 7-day trend, payment mix, MTD sales, and last-month sales in a single parallel await using Dart 3 record `.wait`
- Reports screen replaced placeholder card with full three-tab report suite
- `nextGrnNumber()` in `SuppliersDao` replaced full-table scan with a single `MAX()` aggregate query; O(n) -> O(log n) on the unique index

### Fixed
- Dashboard line chart tooltip text color changed to white - previously used `AppColors.primary` and `AppColors.success` which had poor contrast on the dark tooltip background
- Gross Profit value color on MTD blue card changed to `Color(0xFF69F0AE)` (light mint) for legibility against the primary blue gradient
- Input field label and hint font size reduced to 13sp globally via `InputDecorationTheme` - was inheriting a larger size that looked oversized in dense fields
- Code Quality CI workflow now parses `flutter analyze` output for `error` level issues instead of relying on exit code, which behaved inconsistently between macOS and Linux runners
- `subosito/flutter-action` action pinned to immutable commit hash to satisfy CodeQL unpinned-action finding
- `dart pub audit` removed from CI; command does not exist in Dart 3.12
- Quick Sales - no-invoice cash sale with automatic stock deduction and ledger entry
- GRN (Goods Receipt Note) - supplier picker, product line items, qty/cost editing, stock-in on confirm, cost price update, purchase history tab
- Petty Cash - daily float card, receipt photo capture (camera and gallery), approval workflow, category chips
- POS line-item percentage discount and bill-level discount
- Sidebar nav grouped into labelled sections (Sales, Stock, Contacts, Finance, Admin)
- `BmsFilterRow` and `BmsDateBar` - shared filter bar components used across all screens
- BMS SVG logo in sidebar header and web favicon
- Detailed README with banner, feature list, tech stack table, role permission table, and getting-started guide
- Banner and logo assets in `docs/` for GitHub org branding
- Apache 2.0 license
- GitHub PR template and issue templates (bug report, feature request, task)
- Sales Returns UI: "Process Return" button on invoice detail (admin/manager only) opens a bottom sheet to select items, quantities, return type (refund/credit/exchange), and reason
- Return history section on invoice detail showing all past returns with type, total, and date
- `nextReturnNumber()` in `ReturnsDao` using `MAX()` aggregate for O(log n) return number generation
- `invoiceReturnsProvider` Riverpod provider to watch returns for a specific invoice
- Role-based routing with guards (Admin, Manager, Cashier, Viewer)
- Drift (SQLite) database with UUID primary keys and versioned migrations
- Collapsible sidebar rail navigation
- Inventory management - product list, add/edit/delete, stock level tracking
- Invoice management - create invoice, line items, payment status
- Customer and supplier contact management
- Dashboard with summary cards
- Settings screen with role switcher
- App theme, color palette, and text styles
- Riverpod 3.x state management setup
- Core constants, error types, and utility helpers

### Changed
- `isDense` moved to `InputDecorationTheme` so all inputs are compact by default - removed all local overrides
- Em dashes replaced with hyphens across all UI strings and code comments
- Box-drawing divider comments removed from codebase

### Fixed
- `AppBar` missing from invoices screen
- Duplicate "Add" button appearing in Quick Sales screen
- Date range picker field taller than regular text inputs - switched to `readOnly` TextField for identical height
- Sidebar nav tile text overflowing during collapse animation - replaced fixed layout with `LayoutBuilder`
- Sidebar header and user footer overflowing during animation
- GRN tab label text invisible (white on white background)
