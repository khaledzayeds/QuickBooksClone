// app/router_full_fixed.dart
// Full replacement router preserving master-data routes and wiring Sales Receipts + Invoices.
// After verification, replace router.dart with this file content.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/responsive_scaffold.dart';
import '../features/accounts/screens/account_form_screen.dart';
import '../features/accounts/screens/chart_of_accounts_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/customers/screens/customer_details_screen.dart';
import '../features/customers/screens/customer_form_screen.dart';
import '../features/customers/screens/customer_list_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/estimates/screens/estimate_form_screen.dart';
import '../features/estimates/screens/estimate_list_screen.dart';
import '../features/inventory_adjustments/screens/inventory_adjustment_form_screen.dart';
import '../features/inventory_adjustments/screens/inventory_adjustment_list_screen.dart';
import '../features/invoices/screens/invoice_details_page.dart';
import '../features/invoices/screens/invoice_form_page.dart';
import '../features/invoices/screens/invoices_list_page.dart';
import '../features/items/screens/item_details_screen.dart';
import '../features/items/screens/item_form_screen.dart';
import '../features/items/screens/item_list_screen.dart';
import '../features/journal_entries/screens/journal_entry_form_screen.dart';
import '../features/journal_entries/screens/journal_entry_list_screen.dart';
import '../features/payments/screens/payment_form_screen.dart';
import '../features/payments/screens/payment_list_screen.dart';
import '../features/purchase_bills/screens/purchase_bill_form_screen.dart';
import '../features/purchase_bills/screens/purchase_bill_list_screen.dart';
import '../features/purchase_orders/screens/purchase_order_details_screen.dart';
import '../features/purchase_orders/screens/purchase_order_form_screen.dart';
import '../features/purchase_orders/screens/purchase_order_list_screen.dart';
import '../features/receive_inventory/screens/receive_inventory_details_screen.dart';
import '../features/receive_inventory/screens/receive_inventory_form_screen.dart';
import '../features/receive_inventory/screens/receive_inventory_list_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/sales_orders/screens/sales_order_form_screen.dart';
import '../features/sales_orders/screens/sales_order_list_screen.dart';
import '../features/sales_receipts/screens/sales_receipt_details_page.dart';
import '../features/sales_receipts/screens/sales_receipt_form_page.dart';
import '../features/sales_receipts/screens/sales_receipts_list_page.dart';
import '../features/vendor_payments/screens/vendor_payment_form_screen.dart';
import '../features/vendors/screens/vendor_details_screen.dart';
import '../features/vendors/screens/vendor_form_screen.dart';
import '../features/vendors/screens/vendor_list_screen.dart';

class AppRoutes {
  static const dashboard = '/';
  static const login = '/login';

  // Purchases
  static const purchaseOrders = '/purchases/orders';
  static const purchaseOrderNew = '/purchases/orders/new';
  static const purchaseOrderDetails = '/purchases/orders/:id';
  static const purchaseBillNew = '/purchases/bills/new';
  static const purchaseBills = '/purchases/bills';
  static const receiveInventory = '/purchases/receive';
  static const receiveInventoryNew = '/purchases/receive/new';
  static const receiveInventoryDetails = '/purchases/receive/:id';
  static const vendorPayments = '/purchases/vendor-payments';
  static const vendorPaymentNew = '/purchases/vendor-payments/new';

  // Sales
  static const estimates = '/sales/estimates';
  static const estimateNew = '/sales/estimates/new';
  static const salesOrders = '/sales/orders';
  static const salesOrderNew = '/sales/orders/new';
  static const salesReceipts = '/sales/receipts';
  static const salesReceiptNew = '/sales/receipts/new';
  static const salesReceiptDetails = '/sales/receipts/:id';
  static const invoices = '/sales/invoices';
  static const invoiceNew = '/sales/invoices/new';
  static const invoiceDetails = '/sales/invoices/:id';
  static const payments = '/sales/payments';
  static const paymentNew = '/sales/payments/new';

  // Master Data
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

  // Others
  static const inventoryAdjustments = '/inventory/adjustments';
  static const inventoryAdjustmentNew = '/inventory/adjustments/new';
  static const journalEntries = '/company/journal-entries';
  static const journalEntryNew = '/company/journal-entries/new';
  static const reports = '/reports';
  static const settings = '/settings';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      if (authState is AsyncLoading) return null;

      final user = authState.value;
      final isLoggedIn = user != null;
      final isLoggingIn = state.uri.path == AppRoutes.login;

      if (!isLoggedIn && !isLoggingIn) return AppRoutes.login;
      if (isLoggedIn && isLoggingIn) return AppRoutes.dashboard;

      return null;
    },
    routes: [
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

          // Master data
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
            builder: (context, state) =>
                ItemDetailsScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.itemEdit,
            builder: (context, state) =>
                ItemFormScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.vendors,
            builder: (context, state) => const VendorListScreen(),
          ),
          GoRoute(
            path: AppRoutes.vendorNew,
            builder: (context, state) => const VendorFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.vendorDetails,
            builder: (context, state) =>
                VendorDetailsScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.vendorEdit,
            builder: (context, state) =>
                VendorFormScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.customers,
            builder: (context, state) => const CustomerListScreen(),
          ),
          GoRoute(
            path: AppRoutes.customerNew,
            builder: (context, state) => const CustomerFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.customerDetails,
            builder: (context, state) =>
                CustomerDetailsScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.customerEdit,
            builder: (context, state) =>
                CustomerFormScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.chartOfAccounts,
            builder: (context, state) => const ChartOfAccountsScreen(),
          ),
          GoRoute(
            path: AppRoutes.accountNew,
            builder: (context, state) => const AccountFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.accountEdit,
            builder: (context, state) =>
                AccountFormScreen(id: state.pathParameters['id']!),
          ),

          // Purchases
          GoRoute(
            path: AppRoutes.purchaseOrders,
            builder: (context, state) => const PurchaseOrderListScreen(),
          ),
          GoRoute(
            path: AppRoutes.purchaseOrderNew,
            builder: (context, state) => const PurchaseOrderFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.purchaseOrderDetails,
            builder: (context, state) =>
                PurchaseOrderDetailsScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.receiveInventory,
            builder: (context, state) => const ReceiveInventoryListScreen(),
          ),
          GoRoute(
            path: AppRoutes.receiveInventoryNew,
            builder: (context, state) {
              final poId = state.uri.queryParameters['poId'];
              return ReceiveInventoryFormScreen(purchaseOrderId: poId);
            },
          ),
          GoRoute(
            path: AppRoutes.receiveInventoryDetails,
            builder: (context, state) =>
                ReceiveInventoryDetailsScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.purchaseBills,
            builder: (context, state) => const PurchaseBillListScreen(),
          ),
          GoRoute(
            path: AppRoutes.purchaseBillNew,
            builder: (context, state) => const PurchaseBillFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.vendorPayments,
            builder: (context, state) => const VendorPaymentFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.vendorPaymentNew,
            builder: (context, state) => const VendorPaymentFormScreen(),
          ),

          // Sales
          GoRoute(
            path: AppRoutes.estimates,
            builder: (context, state) => const EstimateListScreen(),
          ),
          GoRoute(
            path: AppRoutes.estimateNew,
            builder: (context, state) => const EstimateFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.salesOrders,
            builder: (context, state) => const SalesOrderListScreen(),
          ),
          GoRoute(
            path: AppRoutes.salesOrderNew,
            builder: (context, state) => const SalesOrderFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.salesReceipts,
            builder: (context, state) => const SalesReceiptsListPage(),
          ),
          GoRoute(
            path: AppRoutes.salesReceiptNew,
            builder: (context, state) => const SalesReceiptFormPage(),
          ),
          GoRoute(
            path: AppRoutes.salesReceiptDetails,
            builder: (context, state) =>
                SalesReceiptDetailsPage(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.invoices,
            builder: (context, state) => const InvoicesListPage(),
          ),
          GoRoute(
            path: AppRoutes.invoiceNew,
            builder: (context, state) => const InvoiceFormPage(),
          ),
          GoRoute(
            path: AppRoutes.invoiceDetails,
            builder: (context, state) =>
                InvoiceDetailsPage(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.payments,
            builder: (context, state) => const PaymentListScreen(),
          ),
          GoRoute(
            path: AppRoutes.paymentNew,
            builder: (context, state) => const PaymentFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.inventoryAdjustments,
            builder: (context, state) => const InventoryAdjustmentListScreen(),
          ),
          GoRoute(
            path: AppRoutes.inventoryAdjustmentNew,
            builder: (context, state) => const InventoryAdjustmentFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.journalEntries,
            builder: (context, state) => const JournalEntryListScreen(),
          ),
          GoRoute(
            path: AppRoutes.journalEntryNew,
            builder: (context, state) => const JournalEntryFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (context, state) => const ReportsScreen(),
          ),
          _placeholder(AppRoutes.settings),
        ],
      ),
    ],
  );
});

GoRoute _placeholder(String path) => GoRoute(
  path: path,
  builder: (context, state) => Scaffold(
    body: Center(child: Text('Screen for $path is under development')),
  ),
);
