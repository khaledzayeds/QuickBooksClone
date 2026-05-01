// features/dashboard/widgets/dashboard_flowchart.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';

class DashboardFlowchart extends StatelessWidget {
  const DashboardFlowchart({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              _FlowSection(
                title: 'VENDORS',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _FlowIcon(icon: Icons.shopping_bag_outlined, label: 'Purchase Orders', path: AppRoutes.purchaseOrderNew),
                    _Arrow(),
                    _FlowIcon(icon: Icons.inventory_2_outlined, label: 'Receive Inventory', path: AppRoutes.receiveInventoryNew),
                    _Arrow(),
                    _FlowIcon(icon: Icons.receipt_outlined, label: 'Enter Bills', path: AppRoutes.purchaseBills),
                    _Arrow(),
                    _FlowIcon(icon: Icons.payments_outlined, label: 'Pay Bills', path: AppRoutes.vendorPayments),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _FlowSection(
                title: 'CUSTOMERS',
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _FlowIcon(icon: Icons.request_quote_outlined, label: 'Estimates', path: AppRoutes.estimates),
                        _Arrow(),
                        _FlowIcon(icon: Icons.receipt_long_outlined, label: 'Sales Orders', path: AppRoutes.salesOrders),
                        _Arrow(),
                        _FlowIcon(icon: Icons.description_outlined, label: 'Create Invoices', path: AppRoutes.invoiceNew),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _FlowIcon(icon: Icons.payments_outlined, label: 'Receive Payments', path: AppRoutes.payments),
                        _Arrow(),
                        _FlowIcon(icon: Icons.account_balance_outlined, label: 'Record Deposits', path: AppRoutes.dashboard),
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
                      title: 'EMPLOYEES',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _FlowIcon(icon: Icons.timer_outlined, label: 'Enter Time', path: AppRoutes.dashboard),
                          _FlowIcon(icon: Icons.monetization_on_outlined, label: 'Pay Employees', path: AppRoutes.dashboard),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _FlowSection(
                      title: 'COMPANY',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _FlowIcon(icon: Icons.account_tree_outlined, label: 'Chart of Accounts', path: AppRoutes.chartOfAccounts),
                          _FlowIcon(icon: Icons.category_outlined, label: 'Items & Services', path: AppRoutes.items),
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
            decoration: BoxDecoration(
              color: const Color(0xFFE1EBF4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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
  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.arrow_forward, color: Colors.grey, size: 16);
  }
}
