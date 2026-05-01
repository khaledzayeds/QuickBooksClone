// app/router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/purchase_orders/screens/purchase_order_form_screen.dart';
import '../features/purchase_orders/screens/purchase_order_list_screen.dart';
import '../features/purchase_orders/screens/purchase_order_details_screen.dart';
import '../features/items/screens/item_list_screen.dart';
import '../features/vendors/screens/vendor_list_screen.dart';
import '../features/customers/screens/customer_list_screen.dart';
import '../features/accounts/screens/chart_of_accounts_screen.dart';
import '../core/widgets/responsive_scaffold.dart';

class AppRoutes {
  static const dashboard = '/';
  static const login     = '/login';
  
  // Purchases
  static const purchaseOrders    = '/purchases/orders';
  static const purchaseOrderNew  = '/purchases/orders/new';
  static const purchaseOrderDetails = '/purchases/orders/:id';
  static const purchaseBillNew   = '/purchases/bills/new';
  
  // Sales
  static const estimates   = '/sales/estimates';
  static const salesOrders = '/sales/orders';
  static const invoices    = '/sales/invoices';
  static const payments    = '/sales/payments';
  static const invoiceNew  = '/sales/invoices/new';
  static const paymentNew  = '/sales/payments/new';
  
  // Master Data
  static const items    = '/master/items';
  static const vendors  = '/master/vendors';
  static const customers = '/master/customers';
  static const chartOfAccounts = '/master/coa';
  static const vendorNew = '/master/vendors/new';
  static const vendorDetails = '/master/vendors/:id';
  static const vendorEdit = '/master/vendors/edit/:id';
  static const customerNew = '/master/customers/new';
  static const customerDetails = '/master/customers/:id';
  static const customerEdit = '/master/customers/edit/:id';

  // Others
  static const accountNew = '/master/coa/new';
  static const accountEdit = '/master/coa/edit/:id';
  static const itemNew = '/master/items/new';
  static const itemEdit = '/master/items/edit/:id';
  static const itemDetails = '/master/items/:id';
  static const inventoryAdjustmentNew = '/inventory/adjustments/new';

  static const receiveInventory = '/purchases/receive';
  static const receiveInventoryNew = '/purchases/receive/new';
  static const receiveInventoryDetails = '/purchases/receive/:id';
  static const purchaseBills = '/purchases/bills';
  static const vendorPayments = '/purchases/vendor-payments';
  static const vendorPaymentNew = '/purchases/vendor-payments/new';
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
            builder: (context, state) => PurchaseOrderDetailsScreen(id: state.pathParameters['id']!),
          ),

          GoRoute(
            path: AppRoutes.items, 
            builder: (context, state) => const ItemListScreen()
          ),
          GoRoute(
            path: AppRoutes.vendors, 
            builder: (context, state) => const VendorListScreen()
          ),
          GoRoute(
            path: AppRoutes.customers, 
            builder: (context, state) => const CustomerListScreen()
          ),
          GoRoute(
            path: AppRoutes.chartOfAccounts, 
            builder: (context, state) => const ChartOfAccountsScreen()
          ),

          _placeholder(AppRoutes.estimates),
          _placeholder(AppRoutes.salesOrders),
          _placeholder(AppRoutes.invoices),
          _placeholder(AppRoutes.payments),
          _placeholder(AppRoutes.invoiceNew),
          _placeholder(AppRoutes.paymentNew),
          _placeholder(AppRoutes.purchaseBillNew),
          _placeholder(AppRoutes.vendorPaymentNew),
          _placeholder(AppRoutes.receiveInventory),
          _placeholder(AppRoutes.receiveInventoryNew),
          _placeholder(AppRoutes.receiveInventoryDetails),
          _placeholder(AppRoutes.purchaseBills),
          _placeholder(AppRoutes.vendorPayments),
          _placeholder(AppRoutes.reports),
          _placeholder(AppRoutes.settings),
          _placeholder(AppRoutes.vendorNew),
          _placeholder(AppRoutes.vendorDetails),
          _placeholder(AppRoutes.vendorEdit),
          _placeholder(AppRoutes.customerNew),
          _placeholder(AppRoutes.customerDetails),
          _placeholder(AppRoutes.customerEdit),
          _placeholder(AppRoutes.accountNew),
          _placeholder(AppRoutes.accountEdit),
          _placeholder(AppRoutes.itemNew),
          _placeholder(AppRoutes.itemEdit),
          _placeholder(AppRoutes.itemDetails),
          _placeholder(AppRoutes.inventoryAdjustmentNew),
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
