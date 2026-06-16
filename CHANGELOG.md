# Changelog

All notable changes to BMS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

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
