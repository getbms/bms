# Changelog

All notable changes to BMS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
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
- Sales returns schema tables scaffolded for the next release
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
