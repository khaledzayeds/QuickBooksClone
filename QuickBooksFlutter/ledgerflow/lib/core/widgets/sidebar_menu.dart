// sidebar_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';
import '../../app/router.dart';
import '../providers/sidebar_provider.dart';

class SidebarMenu extends ConsumerStatefulWidget {
  const SidebarMenu({super.key});

  @override
  ConsumerState<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends ConsumerState<SidebarMenu> {
  // To keep track of which expansion tile is open
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isCollapsed = ref.watch(sidebarCollapsedProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      width: isCollapsed ? 80 : 260,
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        children: [
          // ── Logo / App Name ─────────────────────
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: AlignmentDirectional.centerStart,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
                right: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  Icons.account_balance_outlined,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.appName,
                      style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Collapse Toggle ─────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
                right: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: InkWell(
              onTap: () => ref.read(sidebarCollapsedProvider.notifier).state = !isCollapsed,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Icon(
                  isCollapsed ? Icons.menu : Icons.menu_open,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ),

          // ── Menu Items ──────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  // Dashboard
                  _NavItem(
                    icon:     Icons.dashboard_outlined,
                    label:    l10n.dashboard,
                    path:     AppRoutes.dashboard,
                    current:  location,
                    isCollapsed: isCollapsed,
                  ),

                  const SizedBox(height: 8),

                  _AccordionGroup(
                    title: l10n.sales,
                    icon: Icons.sell_outlined,
                    isCollapsed: isCollapsed,
                    isExpanded: _expandedIndex == 0,
                    onExpansionChanged: (exp) => setState(() => _expandedIndex = exp ? 0 : null),
                    children: [
                      _NavItem(icon: Icons.request_quote_outlined, label: l10n.estimates, path: AppRoutes.estimates, current: location, isCollapsed: isCollapsed),
                      _NavItem(icon: Icons.receipt_long_outlined, label: l10n.salesOrders, path: AppRoutes.salesOrders, current: location, isCollapsed: isCollapsed),
                      _NavItem(icon: Icons.description_outlined, label: l10n.invoices, path: AppRoutes.invoices, current: location, isCollapsed: isCollapsed),
                      _NavItem(icon: Icons.payments_outlined, label: l10n.payments, path: AppRoutes.payments, current: location, isCollapsed: isCollapsed),
                    ],
                  ),

                  _AccordionGroup(
                    title: l10n.purchases,
                    icon: Icons.shopping_bag_outlined,
                    isCollapsed: isCollapsed,
                    isExpanded: _expandedIndex == 1,
                    onExpansionChanged: (exp) => setState(() => _expandedIndex = exp ? 1 : null),
                    children: [
                      _NavItem(icon: Icons.shopping_cart_outlined, label: l10n.purchaseOrders, path: AppRoutes.purchaseOrders, current: location, isCollapsed: isCollapsed),
                      _NavItem(icon: Icons.inventory_2_outlined, label: l10n.receiveInventory, path: AppRoutes.receiveInventory, current: location, isCollapsed: isCollapsed),
                      _NavItem(icon: Icons.receipt_outlined, label: l10n.purchaseBills, path: AppRoutes.purchaseBills, current: location, isCollapsed: isCollapsed),
                      _NavItem(icon: Icons.account_balance_wallet_outlined, label: l10n.vendorPayments, path: AppRoutes.vendorPayments, current: location, isCollapsed: isCollapsed),
                    ],
                  ),

                  _AccordionGroup(
                    title: l10n.masterData,
                    icon: Icons.dns_outlined,
                    isCollapsed: isCollapsed,
                    isExpanded: _expandedIndex == 2,
                    onExpansionChanged: (exp) => setState(() => _expandedIndex = exp ? 2 : null),
                    children: [
                      _NavItem(icon: Icons.people_outline, label: l10n.customers, path: AppRoutes.customers, current: location, isCollapsed: isCollapsed),
                      _NavItem(icon: Icons.local_shipping_outlined, label: l10n.vendors, path: AppRoutes.vendors, current: location, isCollapsed: isCollapsed),
                      _NavItem(icon: Icons.category_outlined, label: l10n.items, path: AppRoutes.items, current: location, isCollapsed: isCollapsed),
                      _NavItem(icon: Icons.account_tree_outlined, label: l10n.chartOfAccounts, path: AppRoutes.chartOfAccounts, current: location, isCollapsed: isCollapsed),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Divider(color: theme.dividerColor, height: 1),
                  const SizedBox(height: 8),

                  _NavItem(
                    icon:     Icons.bar_chart_outlined,
                    label:    l10n.reports,
                    path:     AppRoutes.reports,
                    current:  location,
                    isCollapsed: isCollapsed,
                  ),
                  _NavItem(
                    icon:     Icons.settings_outlined,
                    label:    l10n.settings,
                    path:     AppRoutes.settings,
                    current:  location,
                    isCollapsed: isCollapsed,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Accordion Group ────────────────────────────────
class _AccordionGroup extends StatelessWidget {
  const _AccordionGroup({
    required this.title,
    required this.icon,
    required this.children,
    required this.isCollapsed,
    required this.isExpanded,
    required this.onExpansionChanged,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool isCollapsed;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (isCollapsed) {
      return PopupMenuButton(
        offset: const Offset(80, 0),
        tooltip: title,
        itemBuilder: (context) {
          return children.map((child) {
            return PopupMenuItem(
              padding: EdgeInsets.zero,
              height: 40,
              child: child,
            );
          }).toList();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Icon(icon, color: isExpanded ? primary : theme.colorScheme.onSurfaceVariant, size: 22),
        ),
      );
    }

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 24),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: Icon(icon, size: 20, color: isExpanded ? primary : theme.colorScheme.onSurfaceVariant),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isExpanded ? FontWeight.w700 : FontWeight.w600,
            color: isExpanded ? primary : theme.colorScheme.onSurface,
          ),
        ),
        children: children,
      ),
    );
  }
}

// ─── Nav Item ─────────────────────────────────────
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.current,
    required this.isCollapsed,
  });

  final IconData icon;
  final String   label;
  final String   path;
  final String   current;
  final bool     isCollapsed;

  bool get _isActive {
    if (path == AppRoutes.dashboard) return current == '/';
    return current.startsWith(path);
  }

  @override
  Widget build(BuildContext context) {
    final active  = _isActive;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 12, vertical: 2),
      child: Material(
        color: active
            ? primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            // Close popup menu if any (when collapsed and clicking inside popup)
            if (isCollapsed && ModalRoute.of(context)?.isCurrent != true) {
               Navigator.of(context).pop();
            }
            context.go(path);
          },
          borderRadius: BorderRadius.circular(8),
          hoverColor: primary.withValues(alpha: 0.05),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 0 : 12, vertical: isCollapsed ? 12 : 10),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Tooltip(
                  message: isCollapsed ? label : '',
                  child: Icon(
                    icon,
                    size:  20,
                    color: active ? primary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                            color:      active ? primary : theme.colorScheme.onSurface,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                    ),
                  ),
                  if (active)
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}