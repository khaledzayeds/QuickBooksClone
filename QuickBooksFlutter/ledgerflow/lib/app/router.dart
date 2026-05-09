// app/router.dart
// Main application router wiring dashboard, master data, sales, purchases, reports,
// and transaction screens.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/responsive_scaffold.dart';
import '../features/accounts/screens/account_form_screen.dart';
import '../features/accounts/screens/chart_of_accounts_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/banking/screens/bank_reconcile_screen.dart';
import '../features/banking/screens/bank_register_screen.dart';
import '../features/banking/screens/bank_transfer_screen.dart';
import '../features/banking/screens/make_deposit_screen.dart';
import '../features/banking/screens/write_check_screen.dart';
import '../features/calendar/screens/calendar_screen.dart';
import '../features/cash_flow/screens/cash_flow_hub_screen.dart';
import '../features/customer_credits/screens/customer_credit_details_screen.dart';
import '../features/customer_credits/screens/customer_credit_form_screen.dart';
import '../features/customer_credits/screens/customer_credit_list_screen.dart';
import '../features/customers/screens/customer_details_screen.dart';
import '../features/customers/screens/customer_form_screen.dart';
import '../features/customers/screens/customer_list_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/estimates/screens/estimate_details_screen.dart';
import '../features/estimates/screens/estimate_form_screen.dart';
import '../features/estimates/screens/estimate_list_screen.dart';
import '../features/inventory_adjustments/screens/inventory_adjustment_details_screen.dart';
import '../features/inventory_adjustments/screens/inventory_adjustment_form_screen.dart';
import '../features/inventory_adjustments/screens/inventory_adjustment_list_screen.dart';
import '../features/invoices/screens/invoice_details_page.dart';
import '../features/invoices/screens/invoice_form_page.dart';
import '../features/invoices/screens/invoices_list_page.dart';
import '../features/items/screens/item_details_screen.dart';
import '../features/items/screens/item_form_screen.dart';
import '../features/items/screens/item_list_screen.dart';
import '../features/journal_entries/screens/journal_entry_details_screen.dart';
import '../features/journal_entries/screens/journal_entry_form_screen.dart';
import '../features/journal_entries/screens/journal_entry_list_screen.dart';
import '../features/payments/screens/payment_form_screen.dart';
import '../features/payments/screens/payment_details_screen.dart';
import '../features/payments/screens/payment_list_screen.dart';
import '../features/payroll/screens/payroll_setup_screen.dart';
import '../features/purchase_bills/screens/purchase_bill_details_screen.dart';
import '../features/purchase_bills/screens/purchase_bill_form_screen.dart';
import '../features/purchase_bills/screens/purchase_bill_list_screen.dart';
import '../features/purchase_orders/screens/purchase_order_details_screen.dart';
import '../features/purchase_orders/screens/purchase_order_form_screen.dart';
import '../features/purchase_orders/screens/purchase_order_list_screen.dart';
import '../features/purchase_returns/screens/purchase_return_details_screen.dart';
import '../features/purchase_returns/screens/purchase_return_form_screen.dart';
import '../features/purchase_returns/screens/purchase_return_list_screen.dart';
import '../features/receive_inventory/screens/receive_inventory_details_screen.dart';
import '../features/receive_inventory/screens/receive_inventory_form_screen.dart';
import '../features/receive_inventory/screens/receive_inventory_list_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/sales_orders/screens/sales_order_form_screen.dart';
import '../features/sales_orders/screens/sales_order_details_screen.dart';
import '../features/sales_orders/screens/sales_order_list_screen.dart';
import '../features/sales_receipts/screens/sales_receipt_details_page.dart';
import '../features/sales_receipts/screens/sales_receipt_form_page_redesign.dart';
import '../features/sales_receipts/screens/sales_receipts_list_page.dart';
import '../features/sales_returns/screens/sales_return_form_screen.dart';
import '../features/sales_returns/screens/sales_return_details_screen.dart';
import '../features/sales_returns/screens/sales_return_list_screen.dart';
import '../features/settings/data/models/license_settings_model.dart';
import '../features/settings/screens/backup_settings_screen.dart';
import '../features/settings/screens/company_settings_screen.dart';
import '../features/settings/screens/connection_settings_screen.dart';
import '../features/settings/screens/license_settings_screen.dart';
import '../features/settings/screens/printing_settings_screen.dart';
import '../features/settings/screens/settings_home_screen.dart';
import '../features/settings/screens/setup_wizard_screen.dart';
import '../features/settings/screens/tax_settings_screen.dart';
import '../features/settings/screens/users_permissions_screen.dart';
import '../features/settings/widgets/license_gate.dart';
import '../features/setup/providers/setup_provider.dart';
import '../features/setup/screens/setup_screen.dart';
import '../features/snapshots/screens/snapshots_screen.dart';
import '../features/time_tracking/screens/enter_time_screen.dart';
import '../features/transactions/screens/transaction_details_screen.dart';
import '../features/transactions/screens/transaction_list_screen.dart';
import '../features/vendor_credits/screens/vendor_credit_details_screen.dart';
import '../features/vendor_credits/screens/vendor_credit_form_screen.dart';
import '../features/vendor_credits/screens/vendor_credit_list_screen.dart';
import '../features/vendor_payments/screens/vendor_payment_details_screen.dart';
import '../features/vendor_payments/screens/vendor_payment_form_screen.dart';
import '../features/vendor_payments/screens/vendor_payment_list_screen.dart';
import '../features/vendors/screens/vendor_details_screen.dart';
import '../features/vendors/screens/vendor_form_screen.dart';
import '../features/vendors/screens/vendor_list_screen.dart';
import '../design_playground/form_playground_screen.dart';
import '../design_playground/table_playground_screen.dart';
import '../features/workspace/screens/open_windows_screen.dart';

class AppRoutes {
  static const dashboard = '/';
  static const login = '/login';
  static const setup = '/setup';
  static const purchaseOrders = '/purchases/orders';
  static const purchaseOrderNew = '/purchases/orders/new';
  static const purchaseOrderEdit = '/purchases/orders/edit/:id';
  static const purchaseOrderDetails = '/purchases/orders/:id';
  static const purchaseBillNew = '/purchases/bills/new';
  static const purchaseBills = '/purchases/bills';
  static const purchaseBillDetails = '/purchases/bills/:id';
  static const receiveInventory = '/purchases/receive';
  static const receiveInventoryNew = '/purchases/receive/new';
  static const receiveInventoryDetails = '/purchases/receive/:id';
  static const vendorPayments = '/purchases/vendor-payments';
  static const vendorPaymentNew = '/purchases/vendor-payments/new';
  static const vendorPaymentDetails = '/purchases/vendor-payments/:id';
  static const vendorCredits = '/purchases/vendor-credits';
  static const vendorCreditNew = '/purchases/vendor-credits/new';
  static const vendorCreditDetails = '/purchases/vendor-credits/:id';
  static const purchaseReturns = '/purchases/returns';
  static const purchaseReturnNew = '/purchases/returns/new';
  static const purchaseReturnDetails = '/purchases/returns/:id';
  static const estimates = '/sales/estimates';
  static const estimateNew = '/sales/estimates/new';
  static const estimateDetails = '/sales/estimates/:id';
  static const salesOrders = '/sales/orders';
  static const salesOrderNew = '/sales/orders/new';
  static const salesOrderDetails = '/sales/orders/:id';
  static const salesReceipts = '/sales/receipts';
  static const salesReceiptNew = '/sales/receipts/new';
  static const salesReceiptDetails = '/sales/receipts/:id';
  static const invoices = '/sales/invoices';
  static const invoiceNew = '/sales/invoices/new';
  static const invoiceDetails = '/sales/invoices/:id';
  static const invoiceEdit = '/sales/invoices/edit/:id';
  static const payments = '/sales/payments';
  static const paymentNew = '/sales/payments/new';
  static const paymentDetails = '/sales/payments/:id';
  static const customerCredits = '/sales/customer-credits';
  static const customerCreditNew = '/sales/customer-credits/new';
  static const customerCreditDetails = '/sales/customer-credits/:id';
  static const salesReturns = '/sales/returns';
  static const salesReturnNew = '/sales/returns/new';
  static const salesReturnDetails = '/sales/returns/:id';
  static const items = '/master/items';
  static const itemNew = '/master/items/new';
  static const itemDetails = '/master/items/:id';
  static const itemEdit = '/master/items/edit/:id';
  static const vendors = '/master/vendors';
  static const vendorNew = '/master/vendors/new';
  static const vendorDetails = '/master/vendors/:id';
  static const vendorEdit = '/master/vendors/edit/:id';
  static const customers = '/master/customers';
  static const customerNew = '/master/customers/new';
  static const customerDetails = '/master/customers/:id';
  static const customerEdit = '/master/customers/edit/:id';
  static const chartOfAccounts = '/master/coa';
  static const accountNew = '/master/coa/new';
  static const accountEdit = '/master/coa/edit/:id';
  static const inventoryAdjustments = '/inventory/adjustments';
  static const inventoryAdjustmentNew = '/inventory/adjustments/new';
  static const inventoryAdjustmentDetails = '/inventory/adjustments/:id';
  static const journalEntries = '/company/journal-entries';
  static const journalEntryNew = '/company/journal-entries/new';
  static const journalEntryDetails = '/company/journal-entries/:id';
  static const reports = '/reports';
  static const transactions = '/transactions';
  static const transactionDetails = '/transactions/:id';
  static const settings = '/settings';
  static const companySettings = '/settings/company';
  static const connectionSettings = '/settings/connection';
  static const setupWizard = '/settings/setup-wizard';
  static const taxSettings = '/settings/tax';
  static const backupSettings = '/settings/backup';
  static const printingSettings = '/settings/printing';
  static const usersPermissions = '/settings/users-permissions';
  static const licenseSettings = '/settings/license';
  static const bankingRegister = '/banking/register';
  static const bankingTransfers = '/banking/transfers';
  static const bankingDeposits = '/banking/deposits';
  static const bankingChecks = '/banking/checks';
  static const bankingReconcile = '/banking/reconcile';
  static const payroll = '/company/payroll';
  static const timeTracking = '/company/time-tracking';
  static const calendar = '/company/calendar';
  static const snapshots = '/company/snapshots';
  static const cashFlowHub = '/company/cash-flow-hub';
  static const myCompany = '/company/profile';
  static const openWindows = '/company/open-windows';

  // Design Playground
  static const playgroundTable = '/playground/table';
  static const playgroundForm = '/playground/form';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final setupState = ref.watch(setupProvider);
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.setup,
    redirect: (context, state) {
      if (authState is AsyncLoading || setupState is AsyncLoading) return null;
      if (setupState.hasError) {
        return state.uri.path == AppRoutes.setup ? null : AppRoutes.setup;
      }

      final setup = setupState.value;
      final isSetupRoute = state.uri.path == AppRoutes.setup;
      if (setup != null && !setup.isInitialized && !isSetupRoute) {
        return AppRoutes.setup;
      }
      if (setup != null && setup.isInitialized && isSetupRoute) {
        return AppRoutes.login;
      }

      final user = authState.value;
      final isLoggedIn = user != null;
      final isLoggingIn = state.uri.path == AppRoutes.login;
      if (!isLoggedIn && !isLoggingIn) return AppRoutes.login;
      if (isLoggedIn && isLoggingIn) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.setup,
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ResponsiveScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.items,
            builder: (context, state) => const ItemListScreen(),
          ),
          GoRoute(
            path: AppRoutes.itemNew,
            builder: (context, state) => const ItemFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.itemDetails,
            builder: (context, state) => ItemDetailsScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.itemEdit,
            builder: (context, state) => ItemFormScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(path: AppRoutes.vendors, builder: (context, state) => const VendorListScreen()),
          GoRoute(path: AppRoutes.vendorNew, builder: (context, state) => const VendorFormScreen()),
          GoRoute(path: AppRoutes.vendorDetails, builder: (context, state) => VendorDetailsScreen(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.vendorEdit, builder: (context, state) => VendorFormScreen(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.customers, builder: (context, state) => const CustomerListScreen()),
          GoRoute(path: AppRoutes.customerNew, builder: (context, state) => const CustomerFormScreen()),
          GoRoute(path: AppRoutes.customerDetails, builder: (context, state) => CustomerDetailsScreen(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.customerEdit, builder: (context, state) => CustomerFormScreen(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.chartOfAccounts, builder: (context, state) => const ChartOfAccountsScreen()),
          GoRoute(path: AppRoutes.accountNew, builder: (context, state) => const AccountFormScreen()),
          GoRoute(path: AppRoutes.accountEdit, builder: (context, state) => AccountFormScreen(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.purchaseOrders, builder: (context, state) => const PurchaseOrderListScreen()),
          GoRoute(path: AppRoutes.purchaseOrderNew, builder: (context, state) => const PurchaseOrderFormScreen()),
          GoRoute(path: AppRoutes.purchaseOrderEdit, builder: (context, state) => PurchaseOrderFormScreen(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.purchaseOrderDetails, builder: (context, state) => PurchaseOrderDetailsScreen(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.receiveInventory, builder: (context, state) => const ReceiveInventoryListScreen()),
          GoRoute(path: AppRoutes.receiveInventoryNew, builder: (context, state) => ReceiveInventoryFormScreen(purchaseOrderId: state.uri.queryParameters['poId'])),
          GoRoute(path: AppRoutes.receiveInventoryDetails, builder: (context, state) => ReceiveInventoryDetailsScreen(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.purchaseBills, builder: (context, state) => const PurchaseBillListScreen()),
          GoRoute(path: AppRoutes.purchaseBillNew, builder: (context, state) => PurchaseBillFormScreen(inventoryReceiptId: state.uri.queryParameters['receiptId'])),
          GoRoute(path: AppRoutes.purchaseBillDetails, builder: (context, state) => PurchaseBillDetailsScreen(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.vendorPayments, builder: (context, state) => const VendorPaymentListScreen()),
          GoRoute(path: AppRoutes.vendorPaymentNew, builder: (context, state) => VendorPaymentFormScreen(billId: state.uri.queryParameters['billId'])),
          GoRoute(path: AppRoutes.vendorPaymentDetails, builder: (context, state) => VendorPaymentDetailsScreen(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.vendorCredits, builder: (context, state) => const VendorCreditListScreen()),
          GoRoute(path: AppRoutes.vendorCreditNew, builder: (context, state) => VendorCreditFormScreen(billId: state.uri.queryParameters['billId'])),
          GoRoute(path: AppRoutes.vendorCreditDetails, builder: (context, state) => VendorCreditDetailsScreen(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.purchaseReturns, builder: (context, state) => const PurchaseReturnListScreen()),
          GoRoute(path: AppRoutes.purchaseReturnNew, builder: (context, state) => PurchaseReturnFormScreen(billId: state.uri.queryParameters['billId'])),
          GoRoute(path: AppRoutes.purchaseReturnDetails, builder: (context, state) => PurchaseReturnDetailsScreen(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.estimates, builder: (context, state) => const EstimateListScreen()),
          GoRoute(path: AppRoutes.estimateNew, builder: (context, state) => const EstimateFormScreen()),
          GoRoute(path: AppRoutes.estimateDetails, builder: (context, state) => EstimateDetailsScreen(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.salesOrders, builder: (context, state) => const SalesOrderListScreen()),
          GoRoute(path: AppRoutes.salesOrderNew, builder: (context, state) => const SalesOrderFormScreen()),
          GoRoute(path: AppRoutes.salesOrderDetails, builder: (context, state) => SalesOrderDetailsScreen(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.salesReceipts, builder: (context, state) => const SalesReceiptsListPage()),
          GoRoute(path: AppRoutes.salesReceiptNew, builder: (context, state) => const SalesReceiptFormPageRedesign()),
          GoRoute(path: AppRoutes.salesReceiptDetails, builder: (context, state) => SalesReceiptDetailsPage(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.invoices, builder: (context, state) => const InvoicesListPage()),
          GoRoute(path: AppRoutes.invoiceNew, builder: (context, state) => const InvoiceFormPage()),
          GoRoute(path: AppRoutes.invoiceEdit, builder: (context, state) => InvoiceFormPage(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.invoiceDetails, builder: (context, state) => InvoiceDetailsPage(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.payments, builder: (context, state) => const PaymentListScreen()),
          GoRoute(path: AppRoutes.paymentNew, builder: (context, state) => const PaymentFormScreen()),
          GoRoute(path: AppRoutes.paymentDetails, builder: (context, state) => PaymentDetailsScreen(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.customerCredits, builder: (context, state) => const CustomerCreditListScreen()),
          GoRoute(path: AppRoutes.customerCreditNew, builder: (context, state) => const CustomerCreditFormScreen()),
          GoRoute(path: AppRoutes.customerCreditDetails, builder: (context, state) => CustomerCreditDetailsScreen(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.salesReturns, builder: (context, state) => const SalesReturnListScreen()),
          GoRoute(path: AppRoutes.salesReturnNew, builder: (context, state) => const SalesReturnFormScreen()),
          GoRoute(path: AppRoutes.salesReturnDetails, builder: (context, state) => SalesReturnDetailsScreen(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.inventoryAdjustments, builder: (context, state) => const InventoryAdjustmentListScreen()),
          GoRoute(path: AppRoutes.inventoryAdjustmentNew, builder: (context, state) => const InventoryAdjustmentFormScreen()),
          GoRoute(path: AppRoutes.inventoryAdjustmentDetails, builder: (context, state) => InventoryAdjustmentDetailsScreen(id: state.pathParameters['id']!)),
          GoRoute(path: '/accounting/journal-entries', redirect: (context, state) => AppRoutes.journalEntries),
          GoRoute(path: '/accounting/journal-entries/new', redirect: (context, state) => AppRoutes.journalEntryNew),
          GoRoute(path: '/accounting/journal-entries/:id', redirect: (context, state) => AppRoutes.journalEntryDetails.replaceFirst(':id', state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.journalEntries, builder: (context, state) => const JournalEntryListScreen()),
          GoRoute(path: AppRoutes.journalEntryNew, builder: (context, state) => const JournalEntryFormScreen()),
          GoRoute(path: AppRoutes.journalEntryDetails, builder: (context, state) => JournalEntryDetailsScreen(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.reports, builder: (context, state) => const ReportsScreen()),
          GoRoute(path: AppRoutes.transactions, builder: (context, state) => const TransactionListScreen()),
          GoRoute(path: AppRoutes.transactionDetails, builder: (context, state) => TransactionDetailsScreen(id: state.pathParameters['id']!)),
          GoRoute(path: AppRoutes.bankingRegister, builder: (context, state) => const BankRegisterScreen()),
          GoRoute(path: AppRoutes.bankingTransfers, builder: (context, state) => const BankTransferScreen()),
          GoRoute(path: AppRoutes.bankingDeposits, builder: (context, state) => const MakeDepositScreen()),
          GoRoute(path: AppRoutes.bankingChecks, builder: (context, state) => const WriteCheckScreen()),
          GoRoute(path: AppRoutes.bankingReconcile, builder: (context, state) => const BankReconcileScreen()),
          GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsHomeScreen()),
          GoRoute(path: AppRoutes.companySettings, builder: (context, state) => const CompanySettingsScreen()),
          GoRoute(path: AppRoutes.connectionSettings, builder: (context, state) => const ConnectionSettingsScreen()),
          GoRoute(path: AppRoutes.setupWizard, builder: (context, state) => const SetupWizardScreen()),
          GoRoute(path: AppRoutes.taxSettings, builder: (context, state) => const TaxSettingsScreen()),
          GoRoute(path: AppRoutes.backupSettings, builder: (context, state) => const LicenseGate(feature: LicenseFeature.backupRestore, child: BackupSettingsScreen())),
          GoRoute(path: AppRoutes.printingSettings, builder: (context, state) => const PrintingSettingsScreen()),
          GoRoute(path: AppRoutes.usersPermissions, builder: (context, state) => const UsersPermissionsScreen()),
          GoRoute(path: AppRoutes.licenseSettings, builder: (context, state) => const LicenseSettingsScreen()),
          GoRoute(path: AppRoutes.payroll, builder: (context, state) => const LicenseGate(feature: LicenseFeature.payroll, child: PayrollSetupScreen())),
          GoRoute(path: AppRoutes.timeTracking, builder: (context, state) => const EnterTimeScreen()),
          GoRoute(path: AppRoutes.calendar, builder: (context, state) => const CalendarScreen()),
          GoRoute(path: AppRoutes.snapshots, builder: (context, state) => const SnapshotsScreen()),
          GoRoute(path: AppRoutes.cashFlowHub, builder: (context, state) => const CashFlowHubScreen()),
          GoRoute(path: AppRoutes.myCompany, builder: (context, state) => const CompanySettingsScreen()),
          GoRoute(path: AppRoutes.openWindows, builder: (context, state) => const OpenWindowsScreen()),
          GoRoute(path: AppRoutes.playgroundTable, builder: (context, state) => const TablePlaygroundScreen()),
          GoRoute(path: AppRoutes.playgroundForm, builder: (context, state) => const FormPlaygroundScreen()),
        ],
      ),
    ],
  );
});
