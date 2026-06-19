// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BMS';

  @override
  String get appSubtitle => 'Business Manager';

  @override
  String get appDescription => 'Business Management System';

  @override
  String copyright(int year) {
    return '© $year BMS. All rights reserved.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get saving => 'Saving...';

  @override
  String get close => 'Close';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get ok => 'OK';

  @override
  String get required => 'Required';

  @override
  String get viewAll => 'View All';

  @override
  String get noData => 'No data.';

  @override
  String get clear => 'Clear';

  @override
  String get change => 'Change';

  @override
  String get test => 'Test';

  @override
  String get refresh => 'Refresh';

  @override
  String get total => 'Total';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get discount => 'Discount';

  @override
  String get amount => 'Amount';

  @override
  String get amountRequired => 'Amount *';

  @override
  String get qty => 'Qty';

  @override
  String get cost => 'Cost';

  @override
  String get price => 'Price';

  @override
  String get balance => 'Balance';

  @override
  String get notes => 'Notes';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get date => 'Date';

  @override
  String get status => 'Status';

  @override
  String get name => 'Name';

  @override
  String get reason => 'Reason';

  @override
  String get type => 'Type';

  @override
  String get search => 'Search...';

  @override
  String get currencyPrefix => 'Rs. ';

  @override
  String get by => 'By:';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentMethodCard => 'Card';

  @override
  String get paymentMethodBankTransfer => 'Bank Transfer';

  @override
  String get paymentMethodCheque => 'Cheque';

  @override
  String get paymentMethodCredit => 'Credit';

  @override
  String get paymentMethodMixed => 'Mixed';

  @override
  String get recordPayment => 'Record Payment';

  @override
  String get paymentRecorded => 'Payment recorded.';

  @override
  String get navMain => 'Main';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navSales => 'Sales';

  @override
  String get navPosSales => 'POS / Sales';

  @override
  String get navQuickSales => 'Quick Sales';

  @override
  String get navInvoices => 'Invoices';

  @override
  String get navStock => 'Stock';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navGrn => 'GRN';

  @override
  String get navContacts => 'Contacts';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navDebtors => 'Debtors';

  @override
  String get navSuppliers => 'Suppliers';

  @override
  String get navFinance => 'Finance';

  @override
  String get navCheques => 'Cheques';

  @override
  String get navPettyCash => 'Petty Cash';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navReports => 'Reports';

  @override
  String get navUsers => 'Users';

  @override
  String get navSettings => 'Settings';

  @override
  String get navMore => 'More';

  @override
  String get navPos => 'POS';

  @override
  String get signOut => 'Sign out';

  @override
  String get alertsTooltip => 'Alerts';

  @override
  String get alertsPanelTitle => 'Alerts';

  @override
  String get alertsAllClear => 'All clear';

  @override
  String get alertsNone => 'No alerts right now.';

  @override
  String get usernameLabel => 'Username';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signIn => 'Sign In';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get statTodaysSales => 'Today\'s Sales';

  @override
  String get statLowStock => 'Low Stock Items';

  @override
  String get statChequesDue => 'Cheques Due (7d)';

  @override
  String get statTotalReceivables => 'Total Receivables';

  @override
  String get mtdPerformance => 'Month-to-Date Performance';

  @override
  String get mtdGrossProfit => 'Gross Profit';

  @override
  String get mtdMargin => 'Margin';

  @override
  String get mtdAvgOrder => 'Avg Order';

  @override
  String get mtdVsLastMonth => 'vs last month';

  @override
  String get revenueTrendTitle => 'Revenue Trend';

  @override
  String get revenueTrendSubtitle => 'Last 30 days - Revenue vs Gross Profit';

  @override
  String get noSalesData => 'No sales data for the last 30 days.';

  @override
  String get chartRevenue => 'Revenue';

  @override
  String get chartGrossProfit => 'Gross Profit';

  @override
  String get weeklyPerfTitle => 'Weekly Performance';

  @override
  String get weeklyPerfSubtitle => 'Last 7 days';

  @override
  String get paymentMixTitle => 'Payment Mix';

  @override
  String get paymentMixSubtitle => 'Current month by method';

  @override
  String get recentInvoicesTitle => 'Recent Invoices';

  @override
  String get recentInvoicesSubtitle => 'Last 30 days';

  @override
  String get inventoryTitle => 'Inventory';

  @override
  String get searchProducts => 'Search products...';

  @override
  String get lowStockOnly => 'Low Stock Only';

  @override
  String get noProductsFound => 'No products found.';

  @override
  String get addProduct => 'Add Product';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get productName => 'Product Name *';

  @override
  String get brand => 'Brand';

  @override
  String get barcode => 'Barcode';

  @override
  String get unitType => 'Unit Type *';

  @override
  String get unitPieces => 'Pieces';

  @override
  String get unitKg => 'Kg';

  @override
  String get unitGrams => 'Grams';

  @override
  String get unitLitres => 'Litres';

  @override
  String get unitMl => 'Ml';

  @override
  String get unitBox => 'Box';

  @override
  String get reorderLevel => 'Reorder Level';

  @override
  String get costPrice => 'Cost Price *';

  @override
  String get sellPrice => 'Sell Price *';

  @override
  String get stockQty => 'Stock Qty';

  @override
  String get updateProduct => 'Update Product';

  @override
  String get productAdded => 'Product added.';

  @override
  String get productUpdated => 'Product updated.';

  @override
  String get posTitle => 'POS / Sales';

  @override
  String get clearCart => 'Clear Cart';

  @override
  String get scanOrSearch => 'Scan barcode or search...';

  @override
  String get scan => 'Scan';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get stock => 'Stock:';

  @override
  String get quantity => 'Quantity';

  @override
  String get cart => 'Cart';

  @override
  String get cartItems => 'item(s)';

  @override
  String get cartEmpty => 'Cart is empty';

  @override
  String get addDiscount => 'Add Discount';

  @override
  String get setCustomer => 'Set Customer (optional)';

  @override
  String get removeCustomer => 'Remove Customer';

  @override
  String get amountReceived => 'Amount Received';

  @override
  String get checkout => 'Checkout';

  @override
  String invoiceCompleted(String invoiceNo) {
    return 'Invoice $invoiceNo completed!';
  }

  @override
  String checkoutFailed(String error) {
    return 'Checkout failed: $error';
  }

  @override
  String lineDiscount(String productName) {
    return 'Line Discount - $productName';
  }

  @override
  String get discountPercent => 'Discount %';

  @override
  String get billDiscount => 'Bill Discount';

  @override
  String get remove => 'Remove';

  @override
  String get apply => 'Apply';

  @override
  String get set => 'Set';

  @override
  String get searchCustomers => 'Search customers...';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get invoicesTitle => 'Invoices';

  @override
  String get searchInvoice => 'Search invoice / customer';

  @override
  String get filterAll => 'All';

  @override
  String get filterPaid => 'Paid';

  @override
  String get filterPartial => 'Partial';

  @override
  String get filterOpen => 'Open';

  @override
  String get filterVoid => 'Void';

  @override
  String get summaryInvoices => 'Invoices';

  @override
  String get summaryTotalSales => 'Total Sales';

  @override
  String get summaryCollected => 'Collected';

  @override
  String get summaryOutstanding => 'Outstanding';

  @override
  String get walkIn => 'Walk-in';

  @override
  String get due => 'Due';

  @override
  String get noInvoicesFound => 'No invoices in this period.';

  @override
  String get invoiceTitle => 'Invoice';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get voidInvoice => 'Void Invoice';

  @override
  String voidInvoiceMessage(String invoiceNo) {
    return 'This will void $invoiceNo. Stock will NOT be auto-restored.';
  }

  @override
  String get voidReason => 'Reason *';

  @override
  String get voidAction => 'Void';

  @override
  String get invoiceVoided => 'Invoice voided';

  @override
  String processReturn(String invoiceNo) {
    return 'Process Return - $invoiceNo';
  }

  @override
  String get items => 'Items';

  @override
  String get item => 'Item';

  @override
  String get amountReceived2 => 'Amount Received';

  @override
  String get balanceDue => 'Balance Due';

  @override
  String get processReturnButton => 'Process Return';

  @override
  String get returns => 'Returns';

  @override
  String get returnTypeRefund => 'Refund';

  @override
  String get returnTypeCredit => 'Credit Note';

  @override
  String get returnTypeExchange => 'Exchange';

  @override
  String get selectItemsToReturn => 'Select Items to Return';

  @override
  String get returnType => 'Return Type';

  @override
  String get returnTotal => 'Return Total';

  @override
  String get confirmReturn => 'Confirm Return';

  @override
  String get sold => 'Sold:';

  @override
  String get at => '@';

  @override
  String get invoiceNo => 'Invoice No';

  @override
  String get customer => 'Customer';

  @override
  String get payment => 'Payment';

  @override
  String get voided => 'VOIDED';

  @override
  String get returnProcessed => 'Return processed and stock restored';

  @override
  String get returnEnterQty => 'Enter a return quantity for at least one item';

  @override
  String get customersTitle => 'Customers';

  @override
  String get noCustomersYet =>
      'No customers yet. Add one with the button above.';

  @override
  String get addCustomer => 'Add Customer';

  @override
  String get customerName => 'Name *';

  @override
  String get customerAdded => 'Customer added.';

  @override
  String get outstandingBalance => 'Outstanding Balance';

  @override
  String recordPaymentFor(String partyName) {
    return 'Record Payment - $partyName';
  }

  @override
  String get paymentAmount => 'Amount *';

  @override
  String get suppliersTitle => 'Suppliers';

  @override
  String get noSuppliersYet =>
      'No suppliers yet. Add one with the button above.';

  @override
  String get addSupplier => 'Add Supplier';

  @override
  String get supplierName => 'Supplier Name *';

  @override
  String get paymentTerms => 'Payment Terms (e.g. Net 30)';

  @override
  String get supplierAdded => 'Supplier added.';

  @override
  String get amountPayable => 'Amount Payable';

  @override
  String get paymentHistory => 'Payment History';

  @override
  String get noPayments => 'No payments recorded yet.';

  @override
  String get grnTitle => 'GRN - Goods Receipt';

  @override
  String get newGrn => 'New GRN';

  @override
  String get grnHistory => 'History';

  @override
  String get purchaseOrders => 'Purchase Orders';

  @override
  String get selectSupplierToStart => 'Select a supplier to start';

  @override
  String get selectSupplier => 'Select Supplier';

  @override
  String get linkToPo => 'Link to Purchase Order';

  @override
  String linkedPo(String poNumber) {
    return 'Linked: $poNumber';
  }

  @override
  String get addItem => 'Add Item';

  @override
  String get addItemsHint => 'Add items from your product catalog';

  @override
  String get addProduct2 => 'Add Product';

  @override
  String get searchProduct => 'Search product...';

  @override
  String get supplierInvoiceNo => 'Supplier Invoice No (optional)';

  @override
  String get supplierInvoiceAmt => 'Inv. Amount';

  @override
  String discrepancy(String amount) {
    return 'Discrepancy: $amount';
  }

  @override
  String get confirmGrn => 'Confirm GRN & Stock In';

  @override
  String grnConfirmed(String grnNo) {
    return 'GRN $grnNo confirmed - stock updated';
  }

  @override
  String get noGrnsYet => 'No GRNs yet.';

  @override
  String get noPurchaseOrdersYet => 'No purchase orders yet.';

  @override
  String get newPo => 'New PO';

  @override
  String get newPurchaseOrder => 'New Purchase Order';

  @override
  String get createPurchaseOrder => 'Create Purchase Order';

  @override
  String get notesOptional2 => 'Notes (optional)';

  @override
  String poCreated(String poNumber) {
    return 'PO $poNumber created';
  }

  @override
  String get selectPurchaseOrder => 'Select Purchase Order';

  @override
  String get chequesTitle => 'Cheques';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get byMonth => 'By Month';

  @override
  String get noChequesUpcoming => 'No cheques due in the next 7 days.';

  @override
  String get recordCheque => 'Record Cheque';

  @override
  String get chequeType => 'Type';

  @override
  String get chequeTypeReceived => 'Received';

  @override
  String get chequeTypeIssued => 'Issued';

  @override
  String get partyType => 'Party Type';

  @override
  String get partyTypeCustomer => 'Customer';

  @override
  String get partyTypeSupplier => 'Supplier';

  @override
  String get partyTypeOther => 'Other';

  @override
  String get partyName => 'Party Name *';

  @override
  String get dueDate => 'Due Date *';

  @override
  String get chequeNo => 'Cheque No.';

  @override
  String get bank => 'Bank';

  @override
  String get chequeRecorded => 'Cheque recorded.';

  @override
  String get deposit => 'Deposit';

  @override
  String get markCleared => 'Mark as Cleared';

  @override
  String get markBounced => 'Mark as Bounced';

  @override
  String get rePresent => 'Re-present';

  @override
  String get confirmDeposit => 'Confirm Deposit';

  @override
  String get depositDate => 'Deposit Date';

  @override
  String get confirmDepositButton => 'Confirm Deposit';

  @override
  String get recordBounce => 'Record Bounce';

  @override
  String get bounceDate => 'Bounce Date';

  @override
  String get bounceReason => 'Reason (optional)';

  @override
  String get confirmBounce => 'Confirm Bounce';

  @override
  String get chequeCreated => 'Created';

  @override
  String get chequeDeposited => 'Deposited';

  @override
  String get chequeBounced => 'Bounced';

  @override
  String get chequeRePresentedLabel => 'Re-presented';

  @override
  String get chequeCleared => 'Cleared';

  @override
  String get timeline => 'Timeline';

  @override
  String get pettyCashTitle => 'Petty Cash';

  @override
  String get noEntriesFound => 'No entries for this period.';

  @override
  String get inLabel => 'In';

  @override
  String get outLabel => 'Out';

  @override
  String get addEntry => 'Add Entry';

  @override
  String get addPettyCashEntry => 'Add Petty Cash Entry';

  @override
  String get description => 'Description *';

  @override
  String get entryType => 'Type *';

  @override
  String get typeOut => 'Out (Expense)';

  @override
  String get typeIn => 'In (Income)';

  @override
  String get category => 'Category *';

  @override
  String get receipt => 'Receipt:';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get removeReceipt => 'Remove';

  @override
  String get entryAdded => 'Entry added.';

  @override
  String get approveOrReject => 'Approve or Reject?';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get rejectionReason => 'Rejection Reason';

  @override
  String get rejectionReasonHint =>
      'Optional - explain why this entry is rejected';

  @override
  String get confirmReject => 'Confirm Reject';

  @override
  String get receiptNotFound => 'Receipt image not found';

  @override
  String get debtorsTitle => 'Debtors';

  @override
  String get noDebts => 'No outstanding debts.';

  @override
  String get totalOutstanding => 'Total Outstanding';

  @override
  String get aging30 => '30+ days';

  @override
  String get aging60 => '60+ days';

  @override
  String get agingCurrent => 'Current';

  @override
  String get creditLimit => 'Credit Limit';

  @override
  String get savePayment => 'Save Payment';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get tabPL => 'P&L';

  @override
  String get tabStockValue => 'Stock Value';

  @override
  String get tabAging => 'Aging';

  @override
  String get noSalesDataTitle => 'No Sales Data';

  @override
  String get noSalesDataMessage =>
      'No transactions were recorded for this period.\nTry adjusting the date range.';

  @override
  String get revenue => 'Revenue';

  @override
  String get cogs => 'COGS';

  @override
  String get grossProfit => 'Gross Profit';

  @override
  String get margin => 'Margin';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get dailyRevenue => 'Daily Revenue';

  @override
  String get noStockTitle => 'No Stock on Hand';

  @override
  String get noStockMessage =>
      'Products with stock will appear here once\nyou record a goods received note.';

  @override
  String get totalStockValue => 'Total Stock Value';

  @override
  String get productsWithStock => 'products with stock';

  @override
  String get product => 'Product';

  @override
  String get value => 'Value';

  @override
  String get allClearTitle => 'All Clear';

  @override
  String get allClearMessage =>
      'No customers have outstanding balances.\nAll receivables are settled.';

  @override
  String get balanceByAge => 'Balance by Age';

  @override
  String get aging0_30 => '0-30 days';

  @override
  String get aging31_60 => '31-60 days';

  @override
  String get aging61_90 => '61-90 days';

  @override
  String get aging90plus => '90+ days';

  @override
  String get customers => 'Customers';

  @override
  String get csvExport => 'CSV';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get storeInfo => 'Store Info';

  @override
  String get languageSection => 'Language';

  @override
  String get productsSection => 'Products';

  @override
  String get importProductsCsv => 'Import Products from CSV';

  @override
  String get importProductsCsvHint =>
      'Bulk add products via CSV file\nFormat: name, unit_type, cost_price, sell_price, barcode, brand, reorder_level';

  @override
  String get downloadTemplate => 'Download CSV Template';

  @override
  String get downloadTemplateHint => 'Get a blank template to fill in';

  @override
  String get databaseSection => 'Database';

  @override
  String get exportDatabase => 'Export Database';

  @override
  String get exportDatabaseHint => 'Download all data as a JSON backup';

  @override
  String get importDatabase => 'Import Database';

  @override
  String get importDatabaseHint => 'Restore from a JSON backup file';

  @override
  String get dbConnectionSection => 'Database Connection';

  @override
  String get auditLogSection => 'Audit Log';

  @override
  String get viewAuditLog => 'View Audit Log';

  @override
  String get viewAuditLogHint => 'See all tracked changes across the system';

  @override
  String get aboutSection => 'About';

  @override
  String get appNameVersion => 'BMS - Business Manager';

  @override
  String get appVersion => 'Version 1.0.0';

  @override
  String get roleLabel => 'Role:';

  @override
  String get storeName => 'Store Name';

  @override
  String get storeNameHint => 'e.g. My Shop';

  @override
  String get storeAddressHint => 'e.g. 123 Main St, Colombo';

  @override
  String get storePhoneHint => 'e.g. 077 123 4567';

  @override
  String get saveStoreInfo => 'Save Store Info';

  @override
  String get storeInfoSaved => 'Store info saved';

  @override
  String get csvImportComplete => 'CSV Import Complete';

  @override
  String get inserted => 'Inserted:';

  @override
  String get skipped => 'Skipped:';

  @override
  String get errors => 'Errors:';

  @override
  String get importDatabaseConfirm => 'Import';

  @override
  String get importDatabaseMessage =>
      'This will add records from the backup file. Existing records will not be overwritten. Continue?';

  @override
  String get dbBackend => 'Backend';

  @override
  String get dbSqliteLocal => 'SQLite (local)';

  @override
  String get dbMysqlLocal => 'MySQL (local)';

  @override
  String get dbMysqlRemote => 'MySQL (remote)';

  @override
  String get dbHost => 'Host';

  @override
  String get dbHostHint => '127.0.0.1';

  @override
  String get dbPort => 'Port';

  @override
  String get dbName => 'Database name';

  @override
  String get dbNameHint => 'bms';

  @override
  String get dbUsername => 'Username';

  @override
  String get dbPassword => 'Password';

  @override
  String get sqliteConnOk => 'SQLite is the active database - connection OK';

  @override
  String mysqlSyncPlanned(String host, String port) {
    return 'MySQL sync is planned for a future release. Settings saved for $host:$port.';
  }

  @override
  String get downloadNotSupportedWeb => 'Download not supported in web preview';

  @override
  String fileSaved(String path) {
    return 'Saved: $path';
  }

  @override
  String get exportFailed => 'Export failed. Please try again.';

  @override
  String get auditLogTitle => 'Audit Log';

  @override
  String get filterByType => 'Filter by type';

  @override
  String get filterAll2 => 'All';

  @override
  String get noAuditEntries => 'No audit entries.';

  @override
  String get auditBefore => 'Before:';

  @override
  String get auditAfter => 'After:';

  @override
  String get auditAt => 'at';

  @override
  String get userManagement => 'User Management';

  @override
  String get noUsersFound => 'No users found.';

  @override
  String get addUser => 'Add User';

  @override
  String get youLabel => 'You';

  @override
  String get activeStatus => 'Active';

  @override
  String get inactiveStatus => 'Inactive';

  @override
  String get createUser => 'Create User';

  @override
  String get fullName => 'Full Name *';

  @override
  String get usernameField => 'Username *';

  @override
  String get passwordField => 'Password *';

  @override
  String get roleField => 'Role *';

  @override
  String get roleCashier => 'Cashier';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleDeveloper => 'Developer';

  @override
  String get userCreated => 'User created.';

  @override
  String get editUser => 'Edit User';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get userUpdated => 'User updated.';

  @override
  String get changeMyPassword => 'Change My Password';

  @override
  String get deactivateAccount => 'Deactivate Account';

  @override
  String get activateAccount => 'Activate Account';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get accountDeactivated => 'Account deactivated.';

  @override
  String get accountActivated => 'Account activated.';

  @override
  String get devSeedWarning =>
      'Developer seed account - cannot be deactivated or deleted.';

  @override
  String changePasswordTitle(String userName) {
    return 'Change Password - $userName';
  }

  @override
  String get currentPassword => 'Current Password *';

  @override
  String get newPassword => 'New Password *';

  @override
  String get confirmNewPassword => 'Confirm New Password *';

  @override
  String get changePassword => 'Change Password';

  @override
  String get passwordChanged => 'Password changed.';

  @override
  String resetPasswordTitle(String userName) {
    return 'Reset Password - $userName';
  }

  @override
  String get passwordReset => 'Password reset.';

  @override
  String get minCharsUsername => 'Min 3 characters';

  @override
  String get minCharsPassword => 'Min 6 characters';

  @override
  String get passwordsMustMatch => 'Passwords do not match';

  @override
  String get lastLogin => 'Last login:';

  @override
  String get passwordChangedAt => 'Password changed:';

  @override
  String get quickSalesTitle => 'Quick Sales';

  @override
  String get noQuickSales => 'No quick sales for this period.';

  @override
  String quickSaleRecorded(String productName, String qty) {
    return 'Quick sale recorded: $productName × $qty';
  }

  @override
  String get qtyAndPriceRequired =>
      'Quantity and price must be greater than zero';

  @override
  String quickSaleFailed(String error) {
    return 'Error: $error';
  }

  @override
  String get newQuickSale => 'New Quick Sale';

  @override
  String get recordSale => 'Record Sale';

  @override
  String get salesCount => 'sales';

  @override
  String get totalRevenue => 'total revenue';
}
