// top_menu_bar.dart
// Desktop-style menu bar for LedgerFlow (QuickBooks Desktop Aesthetic)
// Now with functional navigation and explicit coming-soon placeholders.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';

class TopMenuBar extends StatelessWidget {
  const TopMenuBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          _MenuButton(
            label: 'File',
            items: const {
              'New Company': AppRoutes.companySettings,
              'Open Company': AppRoutes.companySettings,
              'Exit': AppRoutes.login,
            },
          ),
          _MenuButton(
            label: 'Lists',
            items: const {
              'Chart of Accounts': AppRoutes.chartOfAccounts,
              'Item List': AppRoutes.items,
              'Vendor List': AppRoutes.vendors,
              'Customer List': AppRoutes.customers,
            },
          ),
          _MenuButton(
            label: 'Company',
            items: const {
              'My Company': AppRoutes.companySettings,
              'Inventory Adjustments': AppRoutes.inventoryAdjustments,
              'Journal Entries': AppRoutes.journalEntries,
              'Enter Time': AppRoutes.timeTracking,
              'Payroll': AppRoutes.payroll,
              'Settings': AppRoutes.settings,
            },
          ),
          _MenuButton(
            label: 'Customers',
            items: const {
              'Customer Center': AppRoutes.customers,
              'Estimates': AppRoutes.estimates,
              'Sales Orders': AppRoutes.salesOrders,
              'Sales Receipts': AppRoutes.salesReceipts,
              'Create Invoices': AppRoutes.invoiceNew,
              'Receive Payments': AppRoutes.paymentNew,
              'Customer Credits': AppRoutes.customerCredits,
              'Sales Returns': AppRoutes.salesReturns,
            },
          ),
          _MenuButton(
            label: 'Vendors',
            items: const {
              'Vendor Center': AppRoutes.vendors,
              'Purchase Orders': AppRoutes.purchaseOrders,
              'Receive Inventory': AppRoutes.receiveInventory,
              'Enter Bills': AppRoutes.purchaseBills,
              'Pay Bills': AppRoutes.vendorPayments,
              'Vendor Credits': AppRoutes.vendorCredits,
              'Purchase Returns': AppRoutes.purchaseReturns,
            },
          ),
          _MenuButton(
            label: 'Banking',
            items: const {
              'Write Checks': AppRoutes.bankingChecks,
              'Make Deposits': AppRoutes.bankingDeposits,
              'Reconcile': AppRoutes.bankingReconcile,
            },
          ),
          _MenuButton(
            label: 'Reports',
            items: const {
              'Reports Center': AppRoutes.reports,
              'Transactions': AppRoutes.transactions,
              'Profit & Loss': AppRoutes.reports,
              'Balance Sheet': AppRoutes.reports,
            },
          ),
          _MenuButton(
            label: 'Help',
            items: const {'About LedgerFlow': AppRoutes.companySettings},
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'LedgerFlow Enterprise Solutions 24.0',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withValues(alpha: 0.5),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.label, required this.items});
  final String label;
  final Map<String, String> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      offset: const Offset(0, 32),
      tooltip: '',
      surfaceTintColor: Colors.white,
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      onSelected: (path) => context.go(path),
      itemBuilder: (context) => items.entries
          .map(
            (e) => PopupMenuItem<String>(
              height: 32,
              value: e.value,
              child: Text(e.key, style: const TextStyle(fontSize: 12)),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
        ),
      ),
    );
  }
}
