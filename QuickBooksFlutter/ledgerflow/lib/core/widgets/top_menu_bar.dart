// top_menu_bar.dart
// Premium desktop-style command menu for LedgerFlow.

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../localization/locale_provider.dart';

class TopMenuBar extends ConsumerWidget {
  const TopMenuBar({
    super.key,
    this.canGoBack = false,
    this.canGoForward = false,
    this.onBack,
    this.onForward,
    this.location = '/',
  });

  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';
    final user = ref.watch(authProvider).value;
    final displayName = user?.displayName ?? 'System Administrator';
    final initials = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U';

    return Container(
      height: 42,
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
          const Gap(8),
          Expanded(
            child: _WorkspaceSegment(
              location: location,
              canGoBack: canGoBack,
              canGoForward: canGoForward,
              onBack: onBack,
              onForward: onForward,
            ),
          ),
          const Gap(8),
          _RoundIconButton(icon: PhosphorIconsRegular.bell, onPressed: () {}),
          const Gap(5),
          _LanguageButton(
            isArabic: isArabic,
            onPressed: () => ref.read(localeProvider.notifier).toggleLocale(),
          ),
          const Gap(6),
          _UserPill(
            initials: initials,
            displayName: displayName,
            userName: user?.userName ?? '',
            onLogout: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
    );
  }
}

class _WorkspaceSegment extends StatelessWidget {
  const _WorkspaceSegment({
    required this.location,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
  });

  final String location;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback? onBack;
  final VoidCallback? onForward;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        height: 30,
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsetsDirectional.only(start: 3, end: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NavTinyButton(icon: PhosphorIconsRegular.arrowLeft, enabled: canGoBack, onPressed: onBack),
            _NavTinyButton(icon: PhosphorIconsRegular.arrowRight, enabled: canGoForward, onPressed: onForward),
            const Gap(6),
            Icon(PhosphorIconsRegular.houseLine, size: 15, color: cs.primary),
            const Gap(5),
            Flexible(
              child: Text(
                _routeTitle(location),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTinyButton extends StatelessWidget {
  const _NavTinyButton({required this.icon, required this.enabled, required this.onPressed});
  final IconData icon;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 23,
        height: 23,
        child: Icon(
          icon,
          size: 14,
          color: enabled ? cs.onSurfaceVariant : cs.onSurfaceVariant.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Icon(icon, size: 16, color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({required this.isArabic, required this.onPressed});
  final bool isArabic;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(PhosphorIconsRegular.globeHemisphereEast, size: 16, color: cs.onSurfaceVariant),
            const Gap(6),
            Text(isArabic ? 'EN' : 'عربي', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _UserPill extends StatelessWidget {
  const _UserPill({
    required this.initials,
    required this.displayName,
    required this.userName,
    required this.onLogout,
  });

  final String initials;
  final String displayName;
  final String userName;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      offset: const Offset(0, 38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        if (value == 'logout') await onLogout();
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
              if (userName.isNotEmpty) Text(userName, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 18),
              Gap(8),
              Text('Logout', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: Container(
        height: 30,
        padding: const EdgeInsetsDirectional.only(start: 4, end: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.primary,
              radius: 12,
              child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
            ),
            const Gap(7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 145),
              child: Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ),
            const Gap(3),
            Icon(PhosphorIconsRegular.caretDown, size: 11, color: cs.onSurfaceVariant),
          ],
        ),
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
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
          child: const Icon(PhosphorIconsFill.bookOpenText, color: Colors.white, size: 16),
        ),
        const Gap(7),
        const Text('LedgerFlow', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: -0.2)),
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
  const _MenuButton({required this.label, required this.icon, required this.items, this.highlight = false});

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
            .map((action) => DropdownItem<_MenuAction>(value: action, height: 38, child: _MenuRow(action: action)))
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
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 22, offset: const Offset(0, 12))],
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(padding: EdgeInsets.symmetric(horizontal: 8)),
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
      decoration: BoxDecoration(color: highlight ? cs.primary.withValues(alpha: 0.08) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 15, color: highlight ? cs.primary : cs.onSurfaceVariant),
          const Gap(5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: highlight ? cs.primary : cs.onSurface)),
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
          decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(7)),
          child: Icon(action.icon, size: 15, color: cs.primary),
        ),
        const Gap(9),
        Expanded(child: Text(action.label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
      ],
    );
  }
}

String _routeTitle(String location) {
  if (location == AppRoutes.dashboard || location == '/') return 'Home';
  if (location.startsWith('/sales/receipts')) return 'Sales / Receipts';
  if (location.startsWith('/sales/invoices')) return 'Sales / Invoices';
  if (location.startsWith('/sales/payments')) return 'Sales / Payments';
  if (location.startsWith('/sales/orders')) return 'Sales / Orders';
  if (location.startsWith('/sales/estimates')) return 'Sales / Estimates';
  if (location.startsWith('/purchases/orders')) return 'Purchases / Orders';
  if (location.startsWith('/purchases/receive')) return 'Purchases / Receive Inventory';
  if (location.startsWith('/purchases/bills')) return 'Purchases / Bills';
  if (location.startsWith('/master/customers')) return 'Customers';
  if (location.startsWith('/master/vendors')) return 'Vendors';
  if (location.startsWith('/master/items')) return 'Items';
  if (location.startsWith('/master/coa')) return 'Chart of Accounts';
  if (location.startsWith('/banking')) return 'Banking';
  if (location.startsWith('/reports')) return 'Reports';
  if (location.startsWith('/settings')) return 'Settings';
  return location;
}
