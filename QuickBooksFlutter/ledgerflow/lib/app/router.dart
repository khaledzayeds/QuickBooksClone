// router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../features/dashboard/screens/dashboard_screen.dart';

// Accounts
import '../features/accounts/screens/chart_of_accounts_screen.dart';
import '../features/accounts/screens/account_form_screen.dart';

// Customers
import '../features/customers/screens/customer_list_screen.dart';
import '../features/customers/screens/customer_form_screen.dart';
import '../features/customers/screens/customer_details_screen.dart';

// Vendors
import '../features/vendors/screens/vendor_list_screen.dart';
import '../features/vendors/screens/vendor_form_screen.dart';
import '../features/vendors/screens/vendor_details_screen.dart';

// Items
import '../features/items/screens/item_list_screen.dart';
import '../features/items/screens/item_form_screen.dart';
import '../features/items/screens/item_details_screen.dart';

// Purchase Orders
import '../features/purchase_orders/screens/purchase_order_list_screen.dart';
import '../features/purchase_orders/screens/purchase_order_form_screen.dart';
import '../features/purchase_orders/screens/purchase_order_details_screen.dart';

// Invoices
import '../features/invoices/screens/invoice_form_screen.dart';

// Shell (Sidebar layout)
import '../core/widgets/responsive_scaffold.dart';

// ─── Route Paths ──────────────────────────────────
abstract class AppRoutes {
  // Dashboard
  static const dashboard = '/';

  // Accounts
  static const chartOfAccounts = '/accounts';
  static const accountNew      = '/accounts/new';
  static const accountEdit     = '/accounts/:id/edit';

  // Customers
  static const customers       = '/customers';
  static const customerNew     = '/customers/new';
  static const customerEdit    = '/customers/:id/edit';
  static const customerDetails = '/customers/:id';

  // Vendors
  static const vendors         = '/vendors';
  static const vendorNew       = '/vendors/new';
  static const vendorEdit      = '/vendors/:id/edit';
  static const vendorDetails   = '/vendors/:id';

  // Items
  static const items           = '/items';
  static const itemNew         = '/items/new';
  static const itemEdit        = '/items/:id/edit';
  static const itemDetails     = '/items/:id';

  // Purchase Orders
  static const purchaseOrders         = '/purchase-orders';
  static const purchaseOrderNew       = '/purchase-orders/new';
  static const purchaseOrderDetails   = '/purchase-orders/:id';

  // Receive Inventory
  static const receiveInventory    = '/receive-inventory';
  static const receiveInventoryNew = '/receive-inventory/new';
  static const receiveInventoryDetails = '/receive-inventory/:id';

  // Purchase Bills
  static const purchaseBills        = '/purchase-bills';
  static const purchaseBillNew      = '/purchase-bills/new';
  static const purchaseBillDetails  = '/purchase-bills/:id';

  // Vendor Payments
  static const vendorPayments       = '/vendor-payments';
  static const vendorPaymentNew     = '/vendor-payments/new';

  // Estimates
  static const estimates       = '/estimates';
  static const estimateNew     = '/estimates/new';
  static const estimateDetails = '/estimates/:id';

  // Sales Orders
  static const salesOrders       = '/sales-orders';
  static const salesOrderNew     = '/sales-orders/new';
  static const salesOrderDetails = '/sales-orders/:id';

  // Invoices
  static const invoices       = '/invoices';
  static const invoiceNew     = '/invoices/new';
  static const invoiceDetails = '/invoices/:id';

  // Payments (customer)
  static const payments    = '/payments';
  static const paymentNew  = '/payments/new';

  // Inventory Adjustment
  static const inventoryAdjustmentNew = '/inventory/adjustment/new';

  // Reports
  static const reports = '/reports';

  // Settings
  static const settings = '/settings';
}

// ─── Router ───────────────────────────────────────
class AppRouter {
  static final _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: true,           // ← شيله في production
    routes: [
      // ── Shell Route (Sidebar layout) ────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) =>
            ResponsiveScaffold(child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),

          // ── Accounts ──────────────────────────
          GoRoute(
            path: AppRoutes.chartOfAccounts,
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: ChartOfAccountsScreen()),
          ),
          GoRoute(
            path: AppRoutes.accountNew,
            builder: (c, s) => const AccountFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.accountEdit,
            builder: (c, s) =>
                AccountFormScreen(id: s.pathParameters['id']),
          ),

          // ── Customers ─────────────────────────
          GoRoute(
            path: AppRoutes.customers,
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: CustomerListScreen()),
          ),
          GoRoute(
            path: AppRoutes.customerNew,
            builder: (c, s) => const CustomerFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.customerDetails,
            builder: (c, s) =>
                CustomerDetailsScreen(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.customerEdit,
            builder: (c, s) =>
                CustomerFormScreen(id: s.pathParameters['id']),
          ),

          // ── Vendors ───────────────────────────
          GoRoute(
            path: AppRoutes.vendors,
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: VendorListScreen()),
          ),
          GoRoute(
            path: AppRoutes.vendorNew,
            builder: (c, s) => const VendorFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.vendorDetails,
            builder: (c, s) =>
                VendorDetailsScreen(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.vendorEdit,
            builder: (c, s) =>
                VendorFormScreen(id: s.pathParameters['id']),
          ),

          // ── Items ─────────────────────────────
          GoRoute(
            path: AppRoutes.items,
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: ItemListScreen()),
          ),
          GoRoute(
            path: AppRoutes.itemNew,
            builder: (c, s) => const ItemFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.itemDetails,
            builder: (c, s) =>
                ItemDetailsScreen(id: s.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.itemEdit,
            builder: (c, s) =>
                ItemFormScreen(id: s.pathParameters['id']),
          ),

          // ── Purchase Orders ───────────────────
          GoRoute(
            path: AppRoutes.purchaseOrders,
            pageBuilder: (c, s) =>
                NoTransitionPage(child: PurchaseOrderListScreen()),
          ),
          GoRoute(
            path: AppRoutes.purchaseOrderNew,
            builder: (c, s) => const PurchaseOrderFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.purchaseOrderDetails,
            builder: (c, s) => PurchaseOrderDetailsScreen(
                id: s.pathParameters['id']!),
          ),

          // ── Receive Inventory (placeholder) ───
          GoRoute(
            path: AppRoutes.receiveInventory,
            builder: (c, s) => _PlaceholderScreen(
                title: AppLocalizations.of(c)!.receiveInventory),
          ),
          GoRoute(
            path: AppRoutes.receiveInventoryNew,
            builder: (c, s) => _PlaceholderScreen(
                title: '${AppLocalizations.of(c)!.receiveInventory} (${AppLocalizations.of(c)!.newText})'),
          ),
          GoRoute(
            path: AppRoutes.receiveInventoryDetails,
            builder: (c, s) => _PlaceholderScreen(
                title: '${AppLocalizations.of(c)!.receiveInventory} ${s.pathParameters['id']}'),
          ),

          // ── Purchase Bills (placeholder) ──────
          GoRoute(
            path: AppRoutes.purchaseBills,
            builder: (c, s) =>
                _PlaceholderScreen(title: AppLocalizations.of(c)!.purchaseBills),
          ),
          GoRoute(
            path: AppRoutes.purchaseBillNew,
            builder: (c, s) =>
                _PlaceholderScreen(title: '${AppLocalizations.of(c)!.purchaseBills} (${AppLocalizations.of(c)!.newText})'),
          ),
          GoRoute(
            path: AppRoutes.purchaseBillDetails,
            builder: (c, s) => _PlaceholderScreen(
                title: '${AppLocalizations.of(c)!.purchaseBills} ${s.pathParameters['id']}'),
          ),

          // ── Vendor Payments (placeholder) ─────
          GoRoute(
            path: AppRoutes.vendorPayments,
            builder: (c, s) =>
                _PlaceholderScreen(title: AppLocalizations.of(c)!.vendorPayments),
          ),
          GoRoute(
            path: AppRoutes.vendorPaymentNew,
            builder: (c, s) =>
                _PlaceholderScreen(title: '${AppLocalizations.of(c)!.vendorPayments} (${AppLocalizations.of(c)!.newText})'),
          ),

          // ── Estimates (placeholder) ───────────
          GoRoute(
            path: AppRoutes.estimates,
            builder: (c, s) =>
                _PlaceholderScreen(title: AppLocalizations.of(c)!.estimates),
          ),
          GoRoute(
            path: AppRoutes.estimateNew,
            builder: (c, s) =>
                _PlaceholderScreen(title: '${AppLocalizations.of(c)!.estimates} (${AppLocalizations.of(c)!.newText})'),
          ),
          GoRoute(
            path: AppRoutes.estimateDetails,
            builder: (c, s) => _PlaceholderScreen(
                title: '${AppLocalizations.of(c)!.estimates} ${s.pathParameters['id']}'),
          ),

          // ── Sales Orders (placeholder) ────────
          GoRoute(
            path: AppRoutes.salesOrders,
            builder: (c, s) =>
                _PlaceholderScreen(title: AppLocalizations.of(c)!.salesOrders),
          ),
          GoRoute(
            path: AppRoutes.salesOrderNew,
            builder: (c, s) =>
                _PlaceholderScreen(title: '${AppLocalizations.of(c)!.salesOrders} (${AppLocalizations.of(c)!.newText})'),
          ),
          GoRoute(
            path: AppRoutes.salesOrderDetails,
            builder: (c, s) => _PlaceholderScreen(
                title: '${AppLocalizations.of(c)!.salesOrders} ${s.pathParameters['id']}'),
          ),

          // ── Invoices ────────────
          GoRoute(
            path: AppRoutes.invoices,
            builder: (c, s) =>
                _PlaceholderScreen(title: AppLocalizations.of(c)!.invoices),
          ),
          GoRoute(
            path: AppRoutes.invoiceNew,
            builder: (c, s) => const InvoiceFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.invoiceDetails,
            builder: (c, s) => _PlaceholderScreen(
                title: '${AppLocalizations.of(c)!.invoices} ${s.pathParameters['id']}'),
          ),

          // ── Customer Payments (placeholder) ───
          GoRoute(
            path: AppRoutes.payments,
            builder: (c, s) =>
                _PlaceholderScreen(title: AppLocalizations.of(c)!.payments),
          ),
          GoRoute(
            path: AppRoutes.paymentNew,
            builder: (c, s) =>
                _PlaceholderScreen(title: '${AppLocalizations.of(c)!.payments} (${AppLocalizations.of(c)!.newText})'),
          ),

          // ── Inventory Adjustment (placeholder)
          GoRoute(
            path: AppRoutes.inventoryAdjustmentNew,
            builder: (c, s) =>
                _PlaceholderScreen(title: 'Inventory Adjustment'), // Hardcoded till we add to arb
          ),

          // ── Reports (placeholder) ─────────────
          GoRoute(
            path: AppRoutes.reports,
            builder: (c, s) =>
                _PlaceholderScreen(title: AppLocalizations.of(c)!.reports),
          ),

          // ── Settings (placeholder) ────────────
          GoRoute(
            path: AppRoutes.settings,
            builder: (c, s) =>
                _PlaceholderScreen(title: AppLocalizations.of(c)!.settings),
          ),
        ],
      ),
    ],

    // ── 404 ─────────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.pageNotFound,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(state.uri.toString(),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: Text(AppLocalizations.of(context)!.backToHome),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── Placeholder Screen ───────────────────────────
// بيتحذف لما يتم بناء الـ screen الحقيقي
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction_outlined,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(title,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.underDevelopment,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    )),
          ],
        ),
      ),
    );
  }
}