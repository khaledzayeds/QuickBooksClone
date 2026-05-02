// features/dashboard/widgets/dashboard_flowchart.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';
import '../../../../app/router.dart';

class DashboardFlowchart extends StatelessWidget {
  const DashboardFlowchart({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _FlowSection(
                title: l10n.vendors.toUpperCase(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _FlowIcon(icon: Icons.shopping_cart_outlined, label: l10n.purchaseOrders, path: AppRoutes.purchaseOrderNew),
                    const _Arrow(),
                    _FlowIcon(icon: Icons.local_shipping_outlined, label: l10n.receiveInventory, path: AppRoutes.receiveInventoryNew),
                    const _Arrow(),
                    _FlowIcon(icon: Icons.assignment_outlined, label: l10n.enterBills, path: AppRoutes.purchaseBills),
                    const _Arrow(),
                    _FlowIcon(icon: Icons.account_balance_wallet_outlined, label: l10n.payBills, path: AppRoutes.vendorPayments),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _FlowSection(
                title: l10n.customers.toUpperCase(),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _FlowIcon(icon: Icons.request_quote_outlined, label: l10n.estimates, path: AppRoutes.estimates),
                        const _Arrow(),
                        _FlowIcon(icon: Icons.inventory_outlined, label: l10n.salesOrders, path: AppRoutes.salesOrders),
                        const _Arrow(),
                        _FlowIcon(icon: Icons.receipt_long_outlined, label: l10n.createInvoices, path: AppRoutes.invoiceNew),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _FlowIcon(icon: Icons.payments_outlined, label: l10n.payments, path: AppRoutes.payments),
                        const _Arrow(),
                        _FlowIcon(icon: Icons.savings_outlined, label: l10n.recordDeposits, path: AppRoutes.dashboard),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _FlowSection(
                      title: l10n.employees.toUpperCase(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _FlowIcon(icon: Icons.timer_outlined, label: l10n.enterTime, path: AppRoutes.dashboard),
                          _FlowIcon(icon: Icons.monetization_on_outlined, label: l10n.payEmployees, path: AppRoutes.dashboard),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _FlowSection(
                      title: l10n.company.toUpperCase(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _FlowIcon(icon: Icons.account_tree_outlined, label: l10n.chartOfAccounts, path: AppRoutes.chartOfAccounts),
                          _FlowIcon(icon: Icons.category_outlined, label: l10n.itemsAndServices, path: AppRoutes.items),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowSection extends StatelessWidget {
  const _FlowSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFFE1EBF4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blue.shade900, letterSpacing: 1),
            ),
          ),
          Padding(padding: const EdgeInsets.all(24), child: child),
        ],
      ),
    );
  }
}

class _FlowIcon extends StatelessWidget {
  const _FlowIcon({required this.icon, required this.label, required this.path});
  final IconData icon;
  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(path),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Icon(icon, size: 28, color: Colors.blue.shade800),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow();
  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Icon(
      isRtl ? Icons.arrow_back : Icons.arrow_forward,
      color: Colors.grey,
      size: 16,
    );
  }
}
