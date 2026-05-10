// top_menu_bar.dart
// Premium desktop-style command menu for LedgerFlow.

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/router.dart';

class TopMenuBar extends StatelessWidget {
  const TopMenuBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _BrandMark(color: cs.primary),
          const Gap(12),
          _MenuButton(
            label: 'File',
            icon: PhosphorIconsRegular.file,
            items: const [
              _MenuAction('New Company', AppRoutes.companySettings, PhosphorIconsRegular.buildings),
              _MenuAction('Open Company', AppRoutes.companySettings, PhosphorIconsRegular.folderOpen),
              _MenuAction('Settings', AppRoutes.settings, PhosphorIconsRegular.gearSix),
              _MenuAction('Exit', AppRoutes.login, PhosphorIconsRegular.signOut),
            ],
          ),
          _MenuButton(
            label: 'Lists',
            icon: PhosphorIconsRegular.listBullets,
            items: const [
              _MenuAction('Chart of Accounts', AppRoutes.chartOfAccounts, PhosphorIconsRegular.treeStructure),
              _MenuAction('Item List', AppRoutes.items, PhosphorIconsRegular.package),
              _MenuAction('Vendor List', AppRoutes.vendors, PhosphorIconsRegular.storefront),
              _MenuAction('Customer List', AppRoutes.customers, PhosphorIconsRegular.usersThree),
            ],
          ),
          _MenuButton(
            label: 'Company',
            icon: PhosphorIconsRegular.briefcase,
            items: const [
              _MenuAction('My Company', AppRoutes.companySettings, PhosphorIconsRegular.buildingOffice),
              _MenuAction('Inventory Adjustments', AppRoutes.inventoryAdjustments, PhosphorIconsRegular.slidersHorizontal),
              _MenuAction('Journal Entries', AppRoutes.journalEntries, PhosphorIconsRegular.notebook),
              _MenuAction('Enter Time', AppRoutes.timeTracking, PhosphorIconsRegular.timer),
              _MenuAction('Payroll', AppRoutes.payroll, PhosphorIconsRegular.identificationBadge),
            ],
          ),
          _MenuButton(
            label: 'Customers',
            icon: PhosphorIconsRegular.handCoins,
            highlight: true,
            items: const [
              _MenuAction('Customer Center', AppRoutes.customers, PhosphorIconsRegular.users),
              _MenuAction('Estimates', AppRoutes.estimates, PhosphorIconsRegular.clipboardText),
              _MenuAction('Sales Orders', AppRoutes.salesOrders, PhosphorIconsRegular.shoppingCart),
              _MenuAction('Sales Receipts', AppRoutes.salesReceiptNew, PhosphorIconsRegular.receipt),
              _MenuAction('Create Invoices', AppRoutes.invoiceNew, PhosphorIconsRegular.fileText),
              _MenuAction('Receive Payments', AppRoutes.paymentNew, PhosphorIconsRegular.creditCard),
              _MenuAction('Customer Credits', AppRoutes.customerCredits, PhosphorIconsRegular.arrowCounterClockwise),
            ],
          ),
          _MenuButton(
            label: 'Vendors',
            icon: PhosphorIconsRegular.truck,
            items: const [
              _MenuAction('Vendor Center', AppRoutes.vendors, PhosphorIconsRegular.storefront),
              _MenuAction('Purchase Orders', AppRoutes.purchaseOrders, PhosphorIconsRegular.clipboardText),
              _MenuAction('Receive Inventory', AppRoutes.receiveInventory, PhosphorIconsRegular.package),
              _MenuAction('Enter Bills', AppRoutes.purchaseBills, PhosphorIconsRegular.receipt),
              _MenuAction('Pay Bills', AppRoutes.vendorPayments, PhosphorIconsRegular.money),
              _MenuAction('Vendor Credits', AppRoutes.vendorCredits, PhosphorIconsRegular.arrowUDownLeft),
            ],
          ),
          _MenuButton(
            label: 'Banking',
            icon: PhosphorIconsRegular.bank,
            items: const [
              _MenuAction('Bank Register', AppRoutes.bankingRegister, PhosphorIconsRegular.bookOpen),
              _MenuAction('Write Checks', AppRoutes.bankingChecks, PhosphorIconsRegular.penNib),
              _MenuAction('Make Deposits', AppRoutes.bankingDeposits, PhosphorIconsRegular.arrowDown),
              _MenuAction('Reconcile', AppRoutes.bankingReconcile, PhosphorIconsRegular.checks),
            ],
          ),
          _MenuButton(
            label: 'Reports',
            icon: PhosphorIconsRegular.chartBar,
            items: const [
              _MenuAction('Reports Center', AppRoutes.reports, PhosphorIconsRegular.presentationChart),
              _MenuAction('Transactions', AppRoutes.transactions, PhosphorIconsRegular.listMagnifyingGlass),
              _MenuAction('Profit & Loss', AppRoutes.reports, PhosphorIconsRegular.trendUp),
              _MenuAction('Balance Sheet', AppRoutes.reports, PhosphorIconsRegular.scales),
            ],
          ),
          _MenuButton(
            label: 'Help',
            icon: PhosphorIconsRegular.question,
            items: const [
              _MenuAction('About LedgerFlow', AppRoutes.companySettings, PhosphorIconsRegular.info),
            ],
          ),
          const Spacer(),
          Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.sparkle, size: 14, color: cs.primary),
                const Gap(6),
                Text(
                  'LedgerFlow Enterprise 24.0',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(PhosphorIconsFill.bookOpenText, color: Colors.white, size: 16),
        ),
        const Gap(7),
        const Text(
          'LedgerFlow',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: -0.2),
        ),
      ],
    );
  }
}

class _MenuAction {
  const _MenuAction(this.label, this.path, this.icon);
  final String label;
  final String path;
  final IconData icon;
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.items,
    this.highlight = false,
  });

  final String label;
  final IconData icon;
  final List<_MenuAction> items;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DropdownButtonHideUnderline(
      child: DropdownButton2<_MenuAction>(
        customButton: _MenuPill(label: label, icon: icon, highlight: highlight),
        items: items
            .map(
              (action) => DropdownMenuItem<_MenuAction>(
                value: action,
                child: _MenuRow(action: action),
              ),
            )
            .toList(),
        onChanged: (action) {
          if (action != null) context.go(action.path);
        },
        dropdownStyleData: DropdownStyleData(
          width: 230,
          maxHeight: 360,
          offset: const Offset(0, -2),
          elevation: 8,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 38,
          padding: EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}

class _MenuPill extends StatelessWidget {
  const _MenuPill({required this.label, required this.icon, required this.highlight});
  final String label;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: highlight ? cs.primary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: highlight ? cs.primary : cs.onSurfaceVariant),
          const Gap(5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: highlight ? cs.primary : cs.onSurface,
            ),
          ),
          const Gap(3),
          Icon(PhosphorIconsRegular.caretDown, size: 11, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.action});
  final _MenuAction action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(action.icon, size: 15, color: cs.primary),
        ),
        const Gap(9),
        Expanded(
          child: Text(
            action.label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
