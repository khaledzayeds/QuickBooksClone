// sidebar_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';
import '../../app/router.dart';
import '../providers/sidebar_provider.dart';
import '../theme/app_colors.dart';

class SidebarMenu extends ConsumerWidget {
  const SidebarMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final l10n = AppLocalizations.of(context)!;
    final isCollapsed = ref.watch(sidebarCollapsedProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      width: isCollapsed ? 70 : 220,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                const Icon(Icons.account_balance, color: Colors.white70, size: 28),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  const Text(
                    'QB',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                  ),
                ],
              ],
            ),
          ),

          if (!isCollapsed)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: l10n.searchHelp,
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 11),
                  prefixIcon: const Icon(Icons.search, size: 14, color: Colors.white54),
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                ),
              ),
            ),

          const Divider(color: Colors.white12, height: 1),

          if (!isCollapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(l10n.myShortcuts.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const Spacer(),
                  const Icon(Icons.settings, size: 12, color: Colors.white38),
                ],
              ),
            ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _ShortcutItem(icon: Icons.home_outlined, label: l10n.home, path: AppRoutes.dashboard, current: location, isCollapsed: isCollapsed),
                _ShortcutItem(icon: Icons.business_outlined, label: l10n.myCompany, path: AppRoutes.myCompany, current: location, isCollapsed: isCollapsed),
                _ShortcutItem(icon: Icons.account_balance_wallet_outlined, label: l10n.cashFlowHub, path: AppRoutes.cashFlowHub, current: location, isCollapsed: isCollapsed),
                _ShortcutItem(icon: Icons.trending_up_outlined, label: l10n.incomeTracker, path: AppRoutes.invoices, current: location, isCollapsed: isCollapsed),
                _ShortcutItem(icon: Icons.receipt_outlined, label: l10n.billTracker, path: AppRoutes.purchaseBills, current: location, isCollapsed: isCollapsed),
                _ShortcutItem(icon: Icons.calendar_today_outlined, label: l10n.calendar, path: AppRoutes.calendar, current: location, isCollapsed: isCollapsed),
                _ShortcutItem(icon: Icons.camera_alt_outlined, label: l10n.snapshots, path: AppRoutes.snapshots, current: location, isCollapsed: isCollapsed),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Colors.white12, height: 1),
                ),

                _ShortcutItem(icon: Icons.point_of_sale_outlined, label: l10n.salesReceipts, path: AppRoutes.salesReceipts, current: location, isCollapsed: isCollapsed),
                _ShortcutItem(icon: Icons.assignment_return_outlined, label: 'Sales Returns', path: AppRoutes.salesReturns, current: location, isCollapsed: isCollapsed),
                _ShortcutItem(icon: Icons.account_balance_wallet_outlined, label: 'Customer Credits', path: AppRoutes.customerCredits, current: location, isCollapsed: isCollapsed),
                _ShortcutItem(icon: Icons.keyboard_return_outlined, label: 'Purchase Returns', path: AppRoutes.purchaseReturns, current: location, isCollapsed: isCollapsed),
                _ShortcutItem(icon: Icons.account_balance_outlined, label: 'Vendor Credits', path: AppRoutes.vendorCredits, current: location, isCollapsed: isCollapsed),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Colors.white12, height: 1),
                ),

                _ShortcutItem(icon: Icons.list_alt_outlined, label: l10n.viewBalances, path: AppRoutes.chartOfAccounts, current: location, isCollapsed: isCollapsed),
                _ShortcutItem(icon: Icons.description_outlined, label: l10n.runFavoriteReports, path: AppRoutes.reports, current: location, isCollapsed: isCollapsed),
                _ShortcutItem(icon: Icons.window_outlined, label: l10n.openWindows, path: AppRoutes.openWindows, current: location, isCollapsed: isCollapsed),
              ],
            ),
          ),

          InkWell(
            onTap: () => ref.read(sidebarCollapsedProvider.notifier).state = !isCollapsed,
            child: Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Icon(isCollapsed ? Icons.chevron_right : Icons.chevron_left, color: Colors.white38),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutItem extends StatelessWidget {
  const _ShortcutItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.current,
    required this.isCollapsed,
  });

  final IconData icon;
  final String label;
  final String path;
  final String current;
  final bool isCollapsed;

  bool get _isActive {
    if (path == AppRoutes.dashboard) return current == '/';
    return current.startsWith(path);
  }

  @override
  Widget build(BuildContext context) {
    final active = _isActive;

    return Material(
      color: active ? AppColors.sidebarActive : Colors.transparent,
      child: InkWell(
        onTap: () => context.go(path),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: isCollapsed ? 12 : 10),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: active ? Colors.white : Colors.white60),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
