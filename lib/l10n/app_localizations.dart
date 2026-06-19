import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_si.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('si'),
    Locale('ta'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BMS'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Business Manager'**
  String get appSubtitle;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Business Management System'**
  String get appDescription;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© {year} BMS. All rights reserved.'**
  String copyright(int year);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data.'**
  String get noData;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @test.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount *'**
  String get amountRequired;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @currencyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Rs. '**
  String get currencyPrefix;

  /// No description provided for @by.
  ///
  /// In en, this message translates to:
  /// **'By:'**
  String get by;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @paymentMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentMethodCash;

  /// No description provided for @paymentMethodCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get paymentMethodCard;

  /// No description provided for @paymentMethodBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get paymentMethodBankTransfer;

  /// No description provided for @paymentMethodCheque.
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get paymentMethodCheque;

  /// No description provided for @paymentMethodCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get paymentMethodCredit;

  /// No description provided for @paymentMethodMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get paymentMethodMixed;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @paymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded.'**
  String get paymentRecorded;

  /// No description provided for @navMain.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get navMain;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get navSales;

  /// No description provided for @navPosSales.
  ///
  /// In en, this message translates to:
  /// **'POS / Sales'**
  String get navPosSales;

  /// No description provided for @navQuickSales.
  ///
  /// In en, this message translates to:
  /// **'Quick Sales'**
  String get navQuickSales;

  /// No description provided for @navInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get navInvoices;

  /// No description provided for @navStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get navStock;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navInventory;

  /// No description provided for @navGrn.
  ///
  /// In en, this message translates to:
  /// **'GRN'**
  String get navGrn;

  /// No description provided for @navContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get navContacts;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navDebtors.
  ///
  /// In en, this message translates to:
  /// **'Debtors'**
  String get navDebtors;

  /// No description provided for @navSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get navSuppliers;

  /// No description provided for @navFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get navFinance;

  /// No description provided for @navCheques.
  ///
  /// In en, this message translates to:
  /// **'Cheques'**
  String get navCheques;

  /// No description provided for @navPettyCash.
  ///
  /// In en, this message translates to:
  /// **'Petty Cash'**
  String get navPettyCash;

  /// No description provided for @navAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get navUsers;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @navPos.
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get navPos;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @alertsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTooltip;

  /// No description provided for @alertsPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsPanelTitle;

  /// No description provided for @alertsAllClear.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get alertsAllClear;

  /// No description provided for @alertsNone.
  ///
  /// In en, this message translates to:
  /// **'No alerts right now.'**
  String get alertsNone;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @statTodaysSales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sales'**
  String get statTodaysSales;

  /// No description provided for @statLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Items'**
  String get statLowStock;

  /// No description provided for @statChequesDue.
  ///
  /// In en, this message translates to:
  /// **'Cheques Due (7d)'**
  String get statChequesDue;

  /// No description provided for @statTotalReceivables.
  ///
  /// In en, this message translates to:
  /// **'Total Receivables'**
  String get statTotalReceivables;

  /// No description provided for @mtdPerformance.
  ///
  /// In en, this message translates to:
  /// **'Month-to-Date Performance'**
  String get mtdPerformance;

  /// No description provided for @mtdGrossProfit.
  ///
  /// In en, this message translates to:
  /// **'Gross Profit'**
  String get mtdGrossProfit;

  /// No description provided for @mtdMargin.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get mtdMargin;

  /// No description provided for @mtdAvgOrder.
  ///
  /// In en, this message translates to:
  /// **'Avg Order'**
  String get mtdAvgOrder;

  /// No description provided for @mtdVsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'vs last month'**
  String get mtdVsLastMonth;

  /// No description provided for @revenueTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'Revenue Trend'**
  String get revenueTrendTitle;

  /// No description provided for @revenueTrendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days - Revenue vs Gross Profit'**
  String get revenueTrendSubtitle;

  /// No description provided for @noSalesData.
  ///
  /// In en, this message translates to:
  /// **'No sales data for the last 30 days.'**
  String get noSalesData;

  /// No description provided for @chartRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get chartRevenue;

  /// No description provided for @chartGrossProfit.
  ///
  /// In en, this message translates to:
  /// **'Gross Profit'**
  String get chartGrossProfit;

  /// No description provided for @weeklyPerfTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Performance'**
  String get weeklyPerfTitle;

  /// No description provided for @weeklyPerfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get weeklyPerfSubtitle;

  /// No description provided for @paymentMixTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Mix'**
  String get paymentMixTitle;

  /// No description provided for @paymentMixSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Current month by method'**
  String get paymentMixSubtitle;

  /// No description provided for @recentInvoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Invoices'**
  String get recentInvoicesTitle;

  /// No description provided for @recentInvoicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get recentInvoicesSubtitle;

  /// No description provided for @inventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryTitle;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @lowStockOnly.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Only'**
  String get lowStockOnly;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found.'**
  String get noProductsFound;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name *'**
  String get productName;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @unitType.
  ///
  /// In en, this message translates to:
  /// **'Unit Type *'**
  String get unitType;

  /// No description provided for @unitPieces.
  ///
  /// In en, this message translates to:
  /// **'Pieces'**
  String get unitPieces;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'Kg'**
  String get unitKg;

  /// No description provided for @unitGrams.
  ///
  /// In en, this message translates to:
  /// **'Grams'**
  String get unitGrams;

  /// No description provided for @unitLitres.
  ///
  /// In en, this message translates to:
  /// **'Litres'**
  String get unitLitres;

  /// No description provided for @unitMl.
  ///
  /// In en, this message translates to:
  /// **'Ml'**
  String get unitMl;

  /// No description provided for @unitBox.
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get unitBox;

  /// No description provided for @reorderLevel.
  ///
  /// In en, this message translates to:
  /// **'Reorder Level'**
  String get reorderLevel;

  /// No description provided for @costPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost Price *'**
  String get costPrice;

  /// No description provided for @sellPrice.
  ///
  /// In en, this message translates to:
  /// **'Sell Price *'**
  String get sellPrice;

  /// No description provided for @stockQty.
  ///
  /// In en, this message translates to:
  /// **'Stock Qty'**
  String get stockQty;

  /// No description provided for @updateProduct.
  ///
  /// In en, this message translates to:
  /// **'Update Product'**
  String get updateProduct;

  /// No description provided for @productAdded.
  ///
  /// In en, this message translates to:
  /// **'Product added.'**
  String get productAdded;

  /// No description provided for @productUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product updated.'**
  String get productUpdated;

  /// No description provided for @posTitle.
  ///
  /// In en, this message translates to:
  /// **'POS / Sales'**
  String get posTitle;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get clearCart;

  /// No description provided for @scanOrSearch.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode or search...'**
  String get scanOrSearch;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock:'**
  String get stock;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @cartItems.
  ///
  /// In en, this message translates to:
  /// **'item(s)'**
  String get cartItems;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get cartEmpty;

  /// No description provided for @addDiscount.
  ///
  /// In en, this message translates to:
  /// **'Add Discount'**
  String get addDiscount;

  /// No description provided for @setCustomer.
  ///
  /// In en, this message translates to:
  /// **'Set Customer (optional)'**
  String get setCustomer;

  /// No description provided for @removeCustomer.
  ///
  /// In en, this message translates to:
  /// **'Remove Customer'**
  String get removeCustomer;

  /// No description provided for @amountReceived.
  ///
  /// In en, this message translates to:
  /// **'Amount Received'**
  String get amountReceived;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @invoiceCompleted.
  ///
  /// In en, this message translates to:
  /// **'Invoice {invoiceNo} completed!'**
  String invoiceCompleted(String invoiceNo);

  /// No description provided for @checkoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Checkout failed: {error}'**
  String checkoutFailed(String error);

  /// No description provided for @lineDiscount.
  ///
  /// In en, this message translates to:
  /// **'Line Discount - {productName}'**
  String lineDiscount(String productName);

  /// No description provided for @discountPercent.
  ///
  /// In en, this message translates to:
  /// **'Discount %'**
  String get discountPercent;

  /// No description provided for @billDiscount.
  ///
  /// In en, this message translates to:
  /// **'Bill Discount'**
  String get billDiscount;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @set.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// No description provided for @searchCustomers.
  ///
  /// In en, this message translates to:
  /// **'Search customers...'**
  String get searchCustomers;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @invoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoicesTitle;

  /// No description provided for @searchInvoice.
  ///
  /// In en, this message translates to:
  /// **'Search invoice / customer'**
  String get searchInvoice;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get filterPaid;

  /// No description provided for @filterPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get filterPartial;

  /// No description provided for @filterOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get filterOpen;

  /// No description provided for @filterVoid.
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get filterVoid;

  /// No description provided for @summaryInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get summaryInvoices;

  /// No description provided for @summaryTotalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get summaryTotalSales;

  /// No description provided for @summaryCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get summaryCollected;

  /// No description provided for @summaryOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get summaryOutstanding;

  /// No description provided for @walkIn.
  ///
  /// In en, this message translates to:
  /// **'Walk-in'**
  String get walkIn;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @noInvoicesFound.
  ///
  /// In en, this message translates to:
  /// **'No invoices in this period.'**
  String get noInvoicesFound;

  /// No description provided for @invoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoiceTitle;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @voidInvoice.
  ///
  /// In en, this message translates to:
  /// **'Void Invoice'**
  String get voidInvoice;

  /// No description provided for @voidInvoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'This will void {invoiceNo}. Stock will NOT be auto-restored.'**
  String voidInvoiceMessage(String invoiceNo);

  /// No description provided for @voidReason.
  ///
  /// In en, this message translates to:
  /// **'Reason *'**
  String get voidReason;

  /// No description provided for @voidAction.
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get voidAction;

  /// No description provided for @invoiceVoided.
  ///
  /// In en, this message translates to:
  /// **'Invoice voided'**
  String get invoiceVoided;

  /// No description provided for @processReturn.
  ///
  /// In en, this message translates to:
  /// **'Process Return - {invoiceNo}'**
  String processReturn(String invoiceNo);

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @amountReceived2.
  ///
  /// In en, this message translates to:
  /// **'Amount Received'**
  String get amountReceived2;

  /// No description provided for @balanceDue.
  ///
  /// In en, this message translates to:
  /// **'Balance Due'**
  String get balanceDue;

  /// No description provided for @processReturnButton.
  ///
  /// In en, this message translates to:
  /// **'Process Return'**
  String get processReturnButton;

  /// No description provided for @returns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get returns;

  /// No description provided for @returnTypeRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get returnTypeRefund;

  /// No description provided for @returnTypeCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit Note'**
  String get returnTypeCredit;

  /// No description provided for @returnTypeExchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get returnTypeExchange;

  /// No description provided for @selectItemsToReturn.
  ///
  /// In en, this message translates to:
  /// **'Select Items to Return'**
  String get selectItemsToReturn;

  /// No description provided for @returnType.
  ///
  /// In en, this message translates to:
  /// **'Return Type'**
  String get returnType;

  /// No description provided for @returnTotal.
  ///
  /// In en, this message translates to:
  /// **'Return Total'**
  String get returnTotal;

  /// No description provided for @confirmReturn.
  ///
  /// In en, this message translates to:
  /// **'Confirm Return'**
  String get confirmReturn;

  /// No description provided for @sold.
  ///
  /// In en, this message translates to:
  /// **'Sold:'**
  String get sold;

  /// No description provided for @at.
  ///
  /// In en, this message translates to:
  /// **'@'**
  String get at;

  /// No description provided for @invoiceNo.
  ///
  /// In en, this message translates to:
  /// **'Invoice No'**
  String get invoiceNo;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @voided.
  ///
  /// In en, this message translates to:
  /// **'VOIDED'**
  String get voided;

  /// No description provided for @returnProcessed.
  ///
  /// In en, this message translates to:
  /// **'Return processed and stock restored'**
  String get returnProcessed;

  /// No description provided for @returnEnterQty.
  ///
  /// In en, this message translates to:
  /// **'Enter a return quantity for at least one item'**
  String get returnEnterQty;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @noCustomersYet.
  ///
  /// In en, this message translates to:
  /// **'No customers yet. Add one with the button above.'**
  String get noCustomersYet;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomer;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get customerName;

  /// No description provided for @customerAdded.
  ///
  /// In en, this message translates to:
  /// **'Customer added.'**
  String get customerAdded;

  /// No description provided for @outstandingBalance.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Balance'**
  String get outstandingBalance;

  /// No description provided for @recordPaymentFor.
  ///
  /// In en, this message translates to:
  /// **'Record Payment - {partyName}'**
  String recordPaymentFor(String partyName);

  /// No description provided for @paymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount *'**
  String get paymentAmount;

  /// No description provided for @suppliersTitle.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliersTitle;

  /// No description provided for @noSuppliersYet.
  ///
  /// In en, this message translates to:
  /// **'No suppliers yet. Add one with the button above.'**
  String get noSuppliersYet;

  /// No description provided for @addSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add Supplier'**
  String get addSupplier;

  /// No description provided for @supplierName.
  ///
  /// In en, this message translates to:
  /// **'Supplier Name *'**
  String get supplierName;

  /// No description provided for @paymentTerms.
  ///
  /// In en, this message translates to:
  /// **'Payment Terms (e.g. Net 30)'**
  String get paymentTerms;

  /// No description provided for @supplierAdded.
  ///
  /// In en, this message translates to:
  /// **'Supplier added.'**
  String get supplierAdded;

  /// No description provided for @amountPayable.
  ///
  /// In en, this message translates to:
  /// **'Amount Payable'**
  String get amountPayable;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @noPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded yet.'**
  String get noPayments;

  /// No description provided for @grnTitle.
  ///
  /// In en, this message translates to:
  /// **'GRN - Goods Receipt'**
  String get grnTitle;

  /// No description provided for @newGrn.
  ///
  /// In en, this message translates to:
  /// **'New GRN'**
  String get newGrn;

  /// No description provided for @grnHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get grnHistory;

  /// No description provided for @purchaseOrders.
  ///
  /// In en, this message translates to:
  /// **'Purchase Orders'**
  String get purchaseOrders;

  /// No description provided for @selectSupplierToStart.
  ///
  /// In en, this message translates to:
  /// **'Select a supplier to start'**
  String get selectSupplierToStart;

  /// No description provided for @selectSupplier.
  ///
  /// In en, this message translates to:
  /// **'Select Supplier'**
  String get selectSupplier;

  /// No description provided for @linkToPo.
  ///
  /// In en, this message translates to:
  /// **'Link to Purchase Order'**
  String get linkToPo;

  /// No description provided for @linkedPo.
  ///
  /// In en, this message translates to:
  /// **'Linked: {poNumber}'**
  String linkedPo(String poNumber);

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @addItemsHint.
  ///
  /// In en, this message translates to:
  /// **'Add items from your product catalog'**
  String get addItemsHint;

  /// No description provided for @addProduct2.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct2;

  /// No description provided for @searchProduct.
  ///
  /// In en, this message translates to:
  /// **'Search product...'**
  String get searchProduct;

  /// No description provided for @supplierInvoiceNo.
  ///
  /// In en, this message translates to:
  /// **'Supplier Invoice No (optional)'**
  String get supplierInvoiceNo;

  /// No description provided for @supplierInvoiceAmt.
  ///
  /// In en, this message translates to:
  /// **'Inv. Amount'**
  String get supplierInvoiceAmt;

  /// No description provided for @discrepancy.
  ///
  /// In en, this message translates to:
  /// **'Discrepancy: {amount}'**
  String discrepancy(String amount);

  /// No description provided for @confirmGrn.
  ///
  /// In en, this message translates to:
  /// **'Confirm GRN & Stock In'**
  String get confirmGrn;

  /// No description provided for @grnConfirmed.
  ///
  /// In en, this message translates to:
  /// **'GRN {grnNo} confirmed - stock updated'**
  String grnConfirmed(String grnNo);

  /// No description provided for @noGrnsYet.
  ///
  /// In en, this message translates to:
  /// **'No GRNs yet.'**
  String get noGrnsYet;

  /// No description provided for @noPurchaseOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No purchase orders yet.'**
  String get noPurchaseOrdersYet;

  /// No description provided for @newPo.
  ///
  /// In en, this message translates to:
  /// **'New PO'**
  String get newPo;

  /// No description provided for @newPurchaseOrder.
  ///
  /// In en, this message translates to:
  /// **'New Purchase Order'**
  String get newPurchaseOrder;

  /// No description provided for @createPurchaseOrder.
  ///
  /// In en, this message translates to:
  /// **'Create Purchase Order'**
  String get createPurchaseOrder;

  /// No description provided for @notesOptional2.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional2;

  /// No description provided for @poCreated.
  ///
  /// In en, this message translates to:
  /// **'PO {poNumber} created'**
  String poCreated(String poNumber);

  /// No description provided for @selectPurchaseOrder.
  ///
  /// In en, this message translates to:
  /// **'Select Purchase Order'**
  String get selectPurchaseOrder;

  /// No description provided for @chequesTitle.
  ///
  /// In en, this message translates to:
  /// **'Cheques'**
  String get chequesTitle;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @byMonth.
  ///
  /// In en, this message translates to:
  /// **'By Month'**
  String get byMonth;

  /// No description provided for @noChequesUpcoming.
  ///
  /// In en, this message translates to:
  /// **'No cheques due in the next 7 days.'**
  String get noChequesUpcoming;

  /// No description provided for @recordCheque.
  ///
  /// In en, this message translates to:
  /// **'Record Cheque'**
  String get recordCheque;

  /// No description provided for @chequeType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get chequeType;

  /// No description provided for @chequeTypeReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get chequeTypeReceived;

  /// No description provided for @chequeTypeIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get chequeTypeIssued;

  /// No description provided for @partyType.
  ///
  /// In en, this message translates to:
  /// **'Party Type'**
  String get partyType;

  /// No description provided for @partyTypeCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get partyTypeCustomer;

  /// No description provided for @partyTypeSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get partyTypeSupplier;

  /// No description provided for @partyTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get partyTypeOther;

  /// No description provided for @partyName.
  ///
  /// In en, this message translates to:
  /// **'Party Name *'**
  String get partyName;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date *'**
  String get dueDate;

  /// No description provided for @chequeNo.
  ///
  /// In en, this message translates to:
  /// **'Cheque No.'**
  String get chequeNo;

  /// No description provided for @bank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bank;

  /// No description provided for @chequeRecorded.
  ///
  /// In en, this message translates to:
  /// **'Cheque recorded.'**
  String get chequeRecorded;

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @markCleared.
  ///
  /// In en, this message translates to:
  /// **'Mark as Cleared'**
  String get markCleared;

  /// No description provided for @markBounced.
  ///
  /// In en, this message translates to:
  /// **'Mark as Bounced'**
  String get markBounced;

  /// No description provided for @rePresent.
  ///
  /// In en, this message translates to:
  /// **'Re-present'**
  String get rePresent;

  /// No description provided for @confirmDeposit.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deposit'**
  String get confirmDeposit;

  /// No description provided for @depositDate.
  ///
  /// In en, this message translates to:
  /// **'Deposit Date'**
  String get depositDate;

  /// No description provided for @confirmDepositButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deposit'**
  String get confirmDepositButton;

  /// No description provided for @recordBounce.
  ///
  /// In en, this message translates to:
  /// **'Record Bounce'**
  String get recordBounce;

  /// No description provided for @bounceDate.
  ///
  /// In en, this message translates to:
  /// **'Bounce Date'**
  String get bounceDate;

  /// No description provided for @bounceReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get bounceReason;

  /// No description provided for @confirmBounce.
  ///
  /// In en, this message translates to:
  /// **'Confirm Bounce'**
  String get confirmBounce;

  /// No description provided for @chequeCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get chequeCreated;

  /// No description provided for @chequeDeposited.
  ///
  /// In en, this message translates to:
  /// **'Deposited'**
  String get chequeDeposited;

  /// No description provided for @chequeBounced.
  ///
  /// In en, this message translates to:
  /// **'Bounced'**
  String get chequeBounced;

  /// No description provided for @chequeRePresentedLabel.
  ///
  /// In en, this message translates to:
  /// **'Re-presented'**
  String get chequeRePresentedLabel;

  /// No description provided for @chequeCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get chequeCleared;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @pettyCashTitle.
  ///
  /// In en, this message translates to:
  /// **'Petty Cash'**
  String get pettyCashTitle;

  /// No description provided for @noEntriesFound.
  ///
  /// In en, this message translates to:
  /// **'No entries for this period.'**
  String get noEntriesFound;

  /// No description provided for @inLabel.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get inLabel;

  /// No description provided for @outLabel.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get outLabel;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addEntry;

  /// No description provided for @addPettyCashEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Petty Cash Entry'**
  String get addPettyCashEntry;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description *'**
  String get description;

  /// No description provided for @entryType.
  ///
  /// In en, this message translates to:
  /// **'Type *'**
  String get entryType;

  /// No description provided for @typeOut.
  ///
  /// In en, this message translates to:
  /// **'Out (Expense)'**
  String get typeOut;

  /// No description provided for @typeIn.
  ///
  /// In en, this message translates to:
  /// **'In (Income)'**
  String get typeIn;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category *'**
  String get category;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt:'**
  String get receipt;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @removeReceipt.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeReceipt;

  /// No description provided for @entryAdded.
  ///
  /// In en, this message translates to:
  /// **'Entry added.'**
  String get entryAdded;

  /// No description provided for @approveOrReject.
  ///
  /// In en, this message translates to:
  /// **'Approve or Reject?'**
  String get approveOrReject;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @rejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason'**
  String get rejectionReason;

  /// No description provided for @rejectionReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Optional - explain why this entry is rejected'**
  String get rejectionReasonHint;

  /// No description provided for @confirmReject.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reject'**
  String get confirmReject;

  /// No description provided for @receiptNotFound.
  ///
  /// In en, this message translates to:
  /// **'Receipt image not found'**
  String get receiptNotFound;

  /// No description provided for @debtorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Debtors'**
  String get debtorsTitle;

  /// No description provided for @noDebts.
  ///
  /// In en, this message translates to:
  /// **'No outstanding debts.'**
  String get noDebts;

  /// No description provided for @totalOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Total Outstanding'**
  String get totalOutstanding;

  /// No description provided for @aging30.
  ///
  /// In en, this message translates to:
  /// **'30+ days'**
  String get aging30;

  /// No description provided for @aging60.
  ///
  /// In en, this message translates to:
  /// **'60+ days'**
  String get aging60;

  /// No description provided for @agingCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get agingCurrent;

  /// No description provided for @creditLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit Limit'**
  String get creditLimit;

  /// No description provided for @savePayment.
  ///
  /// In en, this message translates to:
  /// **'Save Payment'**
  String get savePayment;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @tabPL.
  ///
  /// In en, this message translates to:
  /// **'P&L'**
  String get tabPL;

  /// No description provided for @tabStockValue.
  ///
  /// In en, this message translates to:
  /// **'Stock Value'**
  String get tabStockValue;

  /// No description provided for @tabAging.
  ///
  /// In en, this message translates to:
  /// **'Aging'**
  String get tabAging;

  /// No description provided for @noSalesDataTitle.
  ///
  /// In en, this message translates to:
  /// **'No Sales Data'**
  String get noSalesDataTitle;

  /// No description provided for @noSalesDataMessage.
  ///
  /// In en, this message translates to:
  /// **'No transactions were recorded for this period.\nTry adjusting the date range.'**
  String get noSalesDataMessage;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @cogs.
  ///
  /// In en, this message translates to:
  /// **'COGS'**
  String get cogs;

  /// No description provided for @grossProfit.
  ///
  /// In en, this message translates to:
  /// **'Gross Profit'**
  String get grossProfit;

  /// No description provided for @margin.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get margin;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @dailyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Daily Revenue'**
  String get dailyRevenue;

  /// No description provided for @noStockTitle.
  ///
  /// In en, this message translates to:
  /// **'No Stock on Hand'**
  String get noStockTitle;

  /// No description provided for @noStockMessage.
  ///
  /// In en, this message translates to:
  /// **'Products with stock will appear here once\nyou record a goods received note.'**
  String get noStockMessage;

  /// No description provided for @totalStockValue.
  ///
  /// In en, this message translates to:
  /// **'Total Stock Value'**
  String get totalStockValue;

  /// No description provided for @productsWithStock.
  ///
  /// In en, this message translates to:
  /// **'products with stock'**
  String get productsWithStock;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @allClearTitle.
  ///
  /// In en, this message translates to:
  /// **'All Clear'**
  String get allClearTitle;

  /// No description provided for @allClearMessage.
  ///
  /// In en, this message translates to:
  /// **'No customers have outstanding balances.\nAll receivables are settled.'**
  String get allClearMessage;

  /// No description provided for @balanceByAge.
  ///
  /// In en, this message translates to:
  /// **'Balance by Age'**
  String get balanceByAge;

  /// No description provided for @aging0_30.
  ///
  /// In en, this message translates to:
  /// **'0-30 days'**
  String get aging0_30;

  /// No description provided for @aging31_60.
  ///
  /// In en, this message translates to:
  /// **'31-60 days'**
  String get aging31_60;

  /// No description provided for @aging61_90.
  ///
  /// In en, this message translates to:
  /// **'61-90 days'**
  String get aging61_90;

  /// No description provided for @aging90plus.
  ///
  /// In en, this message translates to:
  /// **'90+ days'**
  String get aging90plus;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @csvExport.
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get csvExport;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @storeInfo.
  ///
  /// In en, this message translates to:
  /// **'Store Info'**
  String get storeInfo;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// No description provided for @productsSection.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsSection;

  /// No description provided for @importProductsCsv.
  ///
  /// In en, this message translates to:
  /// **'Import Products from CSV'**
  String get importProductsCsv;

  /// No description provided for @importProductsCsvHint.
  ///
  /// In en, this message translates to:
  /// **'Bulk add products via CSV file\nFormat: name, unit_type, cost_price, sell_price, barcode, brand, reorder_level'**
  String get importProductsCsvHint;

  /// No description provided for @downloadTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download CSV Template'**
  String get downloadTemplate;

  /// No description provided for @downloadTemplateHint.
  ///
  /// In en, this message translates to:
  /// **'Get a blank template to fill in'**
  String get downloadTemplateHint;

  /// No description provided for @databaseSection.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get databaseSection;

  /// No description provided for @exportDatabase.
  ///
  /// In en, this message translates to:
  /// **'Export Database'**
  String get exportDatabase;

  /// No description provided for @exportDatabaseHint.
  ///
  /// In en, this message translates to:
  /// **'Download all data as a JSON backup'**
  String get exportDatabaseHint;

  /// No description provided for @importDatabase.
  ///
  /// In en, this message translates to:
  /// **'Import Database'**
  String get importDatabase;

  /// No description provided for @importDatabaseHint.
  ///
  /// In en, this message translates to:
  /// **'Restore from a JSON backup file'**
  String get importDatabaseHint;

  /// No description provided for @dbConnectionSection.
  ///
  /// In en, this message translates to:
  /// **'Database Connection'**
  String get dbConnectionSection;

  /// No description provided for @auditLogSection.
  ///
  /// In en, this message translates to:
  /// **'Audit Log'**
  String get auditLogSection;

  /// No description provided for @viewAuditLog.
  ///
  /// In en, this message translates to:
  /// **'View Audit Log'**
  String get viewAuditLog;

  /// No description provided for @viewAuditLogHint.
  ///
  /// In en, this message translates to:
  /// **'See all tracked changes across the system'**
  String get viewAuditLogHint;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @appNameVersion.
  ///
  /// In en, this message translates to:
  /// **'BMS - Business Manager'**
  String get appNameVersion;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get appVersion;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role:'**
  String get roleLabel;

  /// No description provided for @storeName.
  ///
  /// In en, this message translates to:
  /// **'Store Name'**
  String get storeName;

  /// No description provided for @storeNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My Shop'**
  String get storeNameHint;

  /// No description provided for @storeAddressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 123 Main St, Colombo'**
  String get storeAddressHint;

  /// No description provided for @storePhoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 077 123 4567'**
  String get storePhoneHint;

  /// No description provided for @saveStoreInfo.
  ///
  /// In en, this message translates to:
  /// **'Save Store Info'**
  String get saveStoreInfo;

  /// No description provided for @storeInfoSaved.
  ///
  /// In en, this message translates to:
  /// **'Store info saved'**
  String get storeInfoSaved;

  /// No description provided for @csvImportComplete.
  ///
  /// In en, this message translates to:
  /// **'CSV Import Complete'**
  String get csvImportComplete;

  /// No description provided for @inserted.
  ///
  /// In en, this message translates to:
  /// **'Inserted:'**
  String get inserted;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped:'**
  String get skipped;

  /// No description provided for @errors.
  ///
  /// In en, this message translates to:
  /// **'Errors:'**
  String get errors;

  /// No description provided for @importDatabaseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importDatabaseConfirm;

  /// No description provided for @importDatabaseMessage.
  ///
  /// In en, this message translates to:
  /// **'This will add records from the backup file. Existing records will not be overwritten. Continue?'**
  String get importDatabaseMessage;

  /// No description provided for @dbBackend.
  ///
  /// In en, this message translates to:
  /// **'Backend'**
  String get dbBackend;

  /// No description provided for @dbSqliteLocal.
  ///
  /// In en, this message translates to:
  /// **'SQLite (local)'**
  String get dbSqliteLocal;

  /// No description provided for @dbMysqlLocal.
  ///
  /// In en, this message translates to:
  /// **'MySQL (local)'**
  String get dbMysqlLocal;

  /// No description provided for @dbMysqlRemote.
  ///
  /// In en, this message translates to:
  /// **'MySQL (remote)'**
  String get dbMysqlRemote;

  /// No description provided for @dbHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get dbHost;

  /// No description provided for @dbHostHint.
  ///
  /// In en, this message translates to:
  /// **'127.0.0.1'**
  String get dbHostHint;

  /// No description provided for @dbPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get dbPort;

  /// No description provided for @dbName.
  ///
  /// In en, this message translates to:
  /// **'Database name'**
  String get dbName;

  /// No description provided for @dbNameHint.
  ///
  /// In en, this message translates to:
  /// **'bms'**
  String get dbNameHint;

  /// No description provided for @dbUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get dbUsername;

  /// No description provided for @dbPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get dbPassword;

  /// No description provided for @sqliteConnOk.
  ///
  /// In en, this message translates to:
  /// **'SQLite is the active database - connection OK'**
  String get sqliteConnOk;

  /// No description provided for @mysqlSyncPlanned.
  ///
  /// In en, this message translates to:
  /// **'MySQL sync is planned for a future release. Settings saved for {host}:{port}.'**
  String mysqlSyncPlanned(String host, String port);

  /// No description provided for @downloadNotSupportedWeb.
  ///
  /// In en, this message translates to:
  /// **'Download not supported in web preview'**
  String get downloadNotSupportedWeb;

  /// No description provided for @fileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: {path}'**
  String fileSaved(String path);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed. Please try again.'**
  String get exportFailed;

  /// No description provided for @auditLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit Log'**
  String get auditLogTitle;

  /// No description provided for @filterByType.
  ///
  /// In en, this message translates to:
  /// **'Filter by type'**
  String get filterByType;

  /// No description provided for @filterAll2.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll2;

  /// No description provided for @noAuditEntries.
  ///
  /// In en, this message translates to:
  /// **'No audit entries.'**
  String get noAuditEntries;

  /// No description provided for @auditBefore.
  ///
  /// In en, this message translates to:
  /// **'Before:'**
  String get auditBefore;

  /// No description provided for @auditAfter.
  ///
  /// In en, this message translates to:
  /// **'After:'**
  String get auditAfter;

  /// No description provided for @auditAt.
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get auditAt;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get noUsersFound;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @inactiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveStatus;

  /// No description provided for @createUser.
  ///
  /// In en, this message translates to:
  /// **'Create User'**
  String get createUser;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name *'**
  String get fullName;

  /// No description provided for @usernameField.
  ///
  /// In en, this message translates to:
  /// **'Username *'**
  String get usernameField;

  /// No description provided for @passwordField.
  ///
  /// In en, this message translates to:
  /// **'Password *'**
  String get passwordField;

  /// No description provided for @roleField.
  ///
  /// In en, this message translates to:
  /// **'Role *'**
  String get roleField;

  /// No description provided for @roleCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get roleCashier;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get roleDeveloper;

  /// No description provided for @userCreated.
  ///
  /// In en, this message translates to:
  /// **'User created.'**
  String get userCreated;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUser;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @userUpdated.
  ///
  /// In en, this message translates to:
  /// **'User updated.'**
  String get userUpdated;

  /// No description provided for @changeMyPassword.
  ///
  /// In en, this message translates to:
  /// **'Change My Password'**
  String get changeMyPassword;

  /// No description provided for @deactivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Account'**
  String get deactivateAccount;

  /// No description provided for @activateAccount.
  ///
  /// In en, this message translates to:
  /// **'Activate Account'**
  String get activateAccount;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @accountDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Account deactivated.'**
  String get accountDeactivated;

  /// No description provided for @accountActivated.
  ///
  /// In en, this message translates to:
  /// **'Account activated.'**
  String get accountActivated;

  /// No description provided for @devSeedWarning.
  ///
  /// In en, this message translates to:
  /// **'Developer seed account - cannot be deactivated or deleted.'**
  String get devSeedWarning;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password - {userName}'**
  String changePasswordTitle(String userName);

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password *'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password *'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password *'**
  String get confirmNewPassword;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed.'**
  String get passwordChanged;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password - {userName}'**
  String resetPasswordTitle(String userName);

  /// No description provided for @passwordReset.
  ///
  /// In en, this message translates to:
  /// **'Password reset.'**
  String get passwordReset;

  /// No description provided for @minCharsUsername.
  ///
  /// In en, this message translates to:
  /// **'Min 3 characters'**
  String get minCharsUsername;

  /// No description provided for @minCharsPassword.
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get minCharsPassword;

  /// No description provided for @passwordsMustMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsMustMatch;

  /// No description provided for @lastLogin.
  ///
  /// In en, this message translates to:
  /// **'Last login:'**
  String get lastLogin;

  /// No description provided for @passwordChangedAt.
  ///
  /// In en, this message translates to:
  /// **'Password changed:'**
  String get passwordChangedAt;

  /// No description provided for @quickSalesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Sales'**
  String get quickSalesTitle;

  /// No description provided for @noQuickSales.
  ///
  /// In en, this message translates to:
  /// **'No quick sales for this period.'**
  String get noQuickSales;

  /// No description provided for @quickSaleRecorded.
  ///
  /// In en, this message translates to:
  /// **'Quick sale recorded: {productName} × {qty}'**
  String quickSaleRecorded(String productName, String qty);

  /// No description provided for @qtyAndPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Quantity and price must be greater than zero'**
  String get qtyAndPriceRequired;

  /// No description provided for @quickSaleFailed.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String quickSaleFailed(String error);

  /// No description provided for @newQuickSale.
  ///
  /// In en, this message translates to:
  /// **'New Quick Sale'**
  String get newQuickSale;

  /// No description provided for @recordSale.
  ///
  /// In en, this message translates to:
  /// **'Record Sale'**
  String get recordSale;

  /// No description provided for @salesCount.
  ///
  /// In en, this message translates to:
  /// **'sales'**
  String get salesCount;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'total revenue'**
  String get totalRevenue;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'si', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'si':
      return AppLocalizationsSi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
