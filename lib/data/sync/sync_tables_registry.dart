import 'package:bms/data/sync/sync_table.dart';

/// All tables enrolled in bidirectional sync, in dependency order
/// (parents before children so FK constraints on MySQL are satisfied).
const List<SyncTable> kSyncTables = [
  _categories,
  _products,
  _stock,
  _customers,
  _customerPayments,
  _suppliers,
  _supplierPayments,
  _purchaseOrders,
  _purchases,
  _purchaseItems,
  _purchaseOrderItems,
  _cheques,
  _pettyCash,
  _invoices,
  _invoiceItems,
  _noInvoiceSales,
  _salesReturns,
  _returnItems,
  _auditLog,
  _stockMovements,
];

// ---------------------------------------------------------------------------
// Table descriptors
// ---------------------------------------------------------------------------

const _pk   = SyncColumn('id', SyncColumnType.uuid, primaryKey: true);
const _ts   = SyncColumnType.integer;
const _uuid = SyncColumnType.uuid;
const _txt  = SyncColumnType.text;
const _real = SyncColumnType.real;

const _categories = SyncTable(
  sqliteName: 'categories',
  columns: [
    _pk,
    SyncColumn('name', SyncColumnType.text),
    SyncColumn('created_at', SyncColumnType.integer),
  ],
);

const _products = SyncTable(
  sqliteName: 'products',
  columns: [
    _pk,
    SyncColumn('name', _txt),
    SyncColumn('barcode', _txt, nullable: true),
    SyncColumn('category_id', _uuid, nullable: true),
    SyncColumn('brand', _txt, nullable: true),
    SyncColumn('unit_type', _txt),
    SyncColumn('cost_price', _real),
    SyncColumn('sell_price', _real),
    SyncColumn('reorder_level', _ts),
    SyncColumn('is_active', _ts),
    SyncColumn('track_batch', _ts),
    SyncColumn('created_at', _ts),
    SyncColumn('updated_at', _ts),
  ],
);

const _stock = SyncTable(
  sqliteName: 'stock',
  columns: [
    SyncColumn('product_id', _uuid, primaryKey: true),
    SyncColumn('qty', _real),
    SyncColumn('updated_at', _ts),
  ],
);

const _customers = SyncTable(
  sqliteName: 'customers',
  columns: [
    _pk,
    SyncColumn('name', _txt),
    SyncColumn('phone', _txt, nullable: true),
    SyncColumn('address', _txt, nullable: true),
    SyncColumn('balance', _real),
    SyncColumn('credit_limit', _real, nullable: true),
    SyncColumn('created_at', _ts),
    SyncColumn('updated_at', _ts),
  ],
);

const _customerPayments = SyncTable(
  sqliteName: 'customer_payments',
  columns: [
    _pk,
    SyncColumn('customer_id', _uuid),
    SyncColumn('amount', _real),
    SyncColumn('method', _txt),
    SyncColumn('reference_no', _txt, nullable: true),
    SyncColumn('notes', _txt, nullable: true),
    SyncColumn('user_id', _uuid),
    SyncColumn('created_at', _ts),
    SyncColumn('updated_at', _ts),
  ],
);

const _suppliers = SyncTable(
  sqliteName: 'suppliers',
  columns: [
    _pk,
    SyncColumn('name', _txt),
    SyncColumn('phone', _txt, nullable: true),
    SyncColumn('address', _txt, nullable: true),
    SyncColumn('balance', _real),
    SyncColumn('credit_limit', _real, nullable: true),
    SyncColumn('created_at', _ts),
    SyncColumn('updated_at', _ts),
  ],
);

const _supplierPayments = SyncTable(
  sqliteName: 'supplier_payments',
  columns: [
    _pk,
    SyncColumn('supplier_id', _uuid),
    SyncColumn('amount', _real),
    SyncColumn('method', _txt),
    SyncColumn('cheque_id', _uuid, nullable: true),
    SyncColumn('reference_no', _txt, nullable: true),
    SyncColumn('notes', _txt, nullable: true),
    SyncColumn('user_id', _uuid),
    SyncColumn('created_at', _ts),
    SyncColumn('updated_at', _ts),
  ],
);

const _purchaseOrders = SyncTable(
  sqliteName: 'purchase_orders',
  columns: [
    _pk,
    SyncColumn('po_number', _txt),
    SyncColumn('supplier_id', _uuid),
    SyncColumn('status', _txt),
    SyncColumn('notes', _txt, nullable: true),
    SyncColumn('total', _real),
    SyncColumn('created_at', _ts),
    SyncColumn('updated_at', _ts),
  ],
);

const _purchases = SyncTable(
  sqliteName: 'purchases',
  columns: [
    _pk,
    SyncColumn('grn_number', _txt),
    SyncColumn('supplier_id', _uuid),
    SyncColumn('po_id', _uuid, nullable: true),
    SyncColumn('total', _real),
    SyncColumn('supplier_invoice_no', _txt, nullable: true),
    SyncColumn('supplier_invoice_amount', _real, nullable: true),
    SyncColumn('notes', _txt, nullable: true),
    SyncColumn('user_id', _uuid),
    SyncColumn('created_at', _ts),
    SyncColumn('updated_at', _ts),
  ],
);

const _purchaseItems = SyncTable(
  sqliteName: 'purchase_items',
  columns: [
    _pk,
    SyncColumn('purchase_id', _uuid),
    SyncColumn('product_id', _uuid),
    SyncColumn('qty', _real),
    SyncColumn('cost_price', _real),
    SyncColumn('subtotal', _real),
  ],
);

const _purchaseOrderItems = SyncTable(
  sqliteName: 'purchase_order_items',
  columns: [
    _pk,
    SyncColumn('po_id', _uuid),
    SyncColumn('product_id', _uuid),
    SyncColumn('qty', _real),
    SyncColumn('cost_price', _real),
    SyncColumn('subtotal', _real),
  ],
);

const _cheques = SyncTable(
  sqliteName: 'cheques',
  columns: [
    _pk,
    SyncColumn('type', _txt),
    SyncColumn('party_name', _txt),
    SyncColumn('amount', _real),
    SyncColumn('cheque_no', _txt, nullable: true),
    SyncColumn('bank', _txt, nullable: true),
    SyncColumn('due_date', _ts),
    SyncColumn('status', _txt),
    SyncColumn('deposit_date', _ts, nullable: true),
    SyncColumn('bounce_date', _ts, nullable: true),
    SyncColumn('bounce_reason', _txt, nullable: true),
    SyncColumn('representation_count', _ts),
    SyncColumn('user_id', _uuid),
    SyncColumn('created_at', _ts),
    SyncColumn('updated_at', _ts),
  ],
);

const _pettyCash = SyncTable(
  sqliteName: 'petty_cash',
  columns: [
    _pk,
    SyncColumn('description', _txt),
    SyncColumn('amount', _real),
    SyncColumn('type', _txt),
    SyncColumn('category', _txt),
    SyncColumn('status', _txt),
    SyncColumn('receipt_path', _txt, nullable: true),
    SyncColumn('approval_notes', _txt, nullable: true),
    SyncColumn('user_id', _uuid),
    SyncColumn('approved_by', _uuid, nullable: true),
    SyncColumn('approved_at', _ts, nullable: true),
    SyncColumn('created_at', _ts),
    SyncColumn('updated_at', _ts),
  ],
);

const _invoices = SyncTable(
  sqliteName: 'invoices',
  columns: [
    _pk,
    SyncColumn('invoice_no', _txt),
    SyncColumn('customer_id', _uuid, nullable: true),
    SyncColumn('subtotal', _real),
    SyncColumn('discount_amount', _real),
    SyncColumn('total', _real),
    SyncColumn('paid_amount', _real),
    SyncColumn('payment_type', _txt),
    SyncColumn('status', _txt),
    SyncColumn('void_reason', _txt, nullable: true),
    SyncColumn('void_approved_by', _uuid, nullable: true),
    SyncColumn('user_id', _uuid),
    SyncColumn('created_at', _ts),
    SyncColumn('updated_at', _ts),
    SyncColumn('deleted_at', _ts, nullable: true),
  ],
);

const _invoiceItems = SyncTable(
  sqliteName: 'invoice_items',
  columns: [
    _pk,
    SyncColumn('invoice_id', _uuid),
    SyncColumn('product_id', _uuid),
    SyncColumn('product_name', _txt),
    SyncColumn('qty', _real),
    SyncColumn('unit_price', _real),
    SyncColumn('discount_percent', _real),
    SyncColumn('discount_amount', _real),
    SyncColumn('subtotal', _real),
    SyncColumn('updated_at', _ts),
  ],
);

const _noInvoiceSales = SyncTable(
  sqliteName: 'no_invoice_sales',
  columns: [
    _pk,
    SyncColumn('product_id', _uuid),
    SyncColumn('product_name', _txt),
    SyncColumn('qty', _real),
    SyncColumn('price', _real),
    SyncColumn('user_id', _uuid),
    SyncColumn('notes', _txt, nullable: true),
    SyncColumn('created_at', _ts),
    SyncColumn('updated_at', _ts),
  ],
);

const _salesReturns = SyncTable(
  sqliteName: 'sales_returns',
  columns: [
    _pk,
    SyncColumn('invoice_id', _uuid),
    SyncColumn('return_no', _txt),
    SyncColumn('type', _txt),
    SyncColumn('total_amount', _real),
    SyncColumn('reason', _txt, nullable: true),
    SyncColumn('user_id', _uuid),
    SyncColumn('created_at', _ts),
    SyncColumn('updated_at', _ts),
  ],
);

const _returnItems = SyncTable(
  sqliteName: 'return_items',
  columns: [
    _pk,
    SyncColumn('return_id', _uuid),
    SyncColumn('product_id', _uuid),
    SyncColumn('product_name', _txt),
    SyncColumn('qty', _real),
    SyncColumn('unit_price', _real),
    SyncColumn('subtotal', _real),
  ],
);

const _auditLog = SyncTable(
  sqliteName: 'audit_log',
  pushOnly: true,
  columns: [
    _pk,
    SyncColumn('entity_type', _txt),
    SyncColumn('entity_id', _uuid),
    SyncColumn('action', _txt),
    SyncColumn('old_value', _txt, nullable: true),
    SyncColumn('new_value', _txt, nullable: true),
    SyncColumn('user_id', _uuid),
    SyncColumn('user_name', _txt),
    SyncColumn('created_at', _ts),
  ],
);

const _stockMovements = SyncTable(
  sqliteName: 'stock_movements',
  pushOnly: true,
  columns: [
    _pk,
    SyncColumn('type', _txt),
    SyncColumn('product_id', _uuid),
    SyncColumn('qty', _real),
    SyncColumn('reason', _txt, nullable: true),
    SyncColumn('user_id', _uuid),
    SyncColumn('ref_id', _uuid, nullable: true),
    SyncColumn('ref_type', _txt, nullable: true),
    SyncColumn('created_at', _ts),
  ],
);
