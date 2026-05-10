// features/dashboard/widgets/dashboard_flowchart.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/router.dart';

class DashboardFlowchart extends StatelessWidget {
  const DashboardFlowchart({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final workflows = [
      _WorkflowGroup(
        title: l10n.customers,
        subtitle: 'Sales workflow',
        icon: PhosphorIconsRegular.handCoins,
        accent: const Color(0xFF0EA5E9),
        actions: [
          _WorkflowAction(l10n.estimates, AppRoutes.estimateNew, PhosphorIconsRegular.clipboardText),
          _WorkflowAction(l10n.salesOrders, AppRoutes.salesOrderNew, PhosphorIconsRegular.shoppingCart),
          _WorkflowAction(l10n.createInvoices, AppRoutes.invoiceNew, PhosphorIconsRegular.fileText),
          _WorkflowAction(l10n.salesReceipts, AppRoutes.salesReceiptNew, PhosphorIconsRegular.receipt),
          _WorkflowAction(l10n.receivePayments, AppRoutes.paymentNew, PhosphorIconsRegular.creditCard),
          _WorkflowAction('Customer Center', AppRoutes.customers, PhosphorIconsRegular.usersThree),
        ],
      ),
      _WorkflowGroup(
        title: l10n.vendors,
        subtitle: 'Purchasing workflow',
        icon: PhosphorIconsRegular.truck,
        accent: const Color(0xFF8B5CF6),
        actions: [
          _WorkflowAction(l10n.purchaseOrders, AppRoutes.purchaseOrderNew, PhosphorIconsRegular.clipboardText),
          _WorkflowAction(l10n.receiveInventory, AppRoutes.receiveInventoryNew, PhosphorIconsRegular.package),
          _WorkflowAction(l10n.enterBills, AppRoutes.purchaseBillNew, PhosphorIconsRegular.receipt),
          _WorkflowAction(l10n.payBills, AppRoutes.vendorPaymentNew, PhosphorIconsRegular.money),
          _WorkflowAction('Vendor Credits', AppRoutes.vendorCreditNew, PhosphorIconsRegular.arrowUDownLeft),
          _WorkflowAction('Vendor Center', AppRoutes.vendors, PhosphorIconsRegular.storefront),
        ],
      ),
      _WorkflowGroup(
        title: l10n.company,
        subtitle: 'Setup and accounting',
        icon: PhosphorIconsRegular.briefcase,
        accent: const Color(0xFF10B981),
        actions: [
          _WorkflowAction(l10n.chartOfAccounts, AppRoutes.chartOfAccounts, PhosphorIconsRegular.treeStructure),
          _WorkflowAction(l10n.itemsAndServices, AppRoutes.items, PhosphorIconsRegular.package),
          _WorkflowAction(l10n.journalEntries, AppRoutes.journalEntryNew, PhosphorIconsRegular.notebook),
          _WorkflowAction(l10n.inventoryAdjustments, AppRoutes.inventoryAdjustmentNew, PhosphorIconsRegular.slidersHorizontal),
          _WorkflowAction(l10n.reports, AppRoutes.reports, PhosphorIconsRegular.presentationChart),
          _WorkflowAction(l10n.settings, AppRoutes.settings, PhosphorIconsRegular.gearSix),
        ],
      ),
      _WorkflowGroup(
        title: 'Banking',
        subtitle: 'Cash and reconciliation',
        icon: PhosphorIconsRegular.bank,
        accent: const Color(0xFFF59E0B),
        actions: [
          _WorkflowAction('Bank Register', AppRoutes.bankingRegister, PhosphorIconsRegular.bookOpen),
          _WorkflowAction('Write Checks', AppRoutes.bankingChecks, PhosphorIconsRegular.penNib),
          _WorkflowAction(l10n.recordDeposits, AppRoutes.bankingDeposits, PhosphorIconsRegular.arrowDown),
          _WorkflowAction('Bank Transfer', AppRoutes.bankingTransfers, PhosphorIconsRegular.arrowsLeftRight),
          _WorkflowAction('Reconcile', AppRoutes.bankingReconcile, PhosphorIconsRegular.checks),
          _WorkflowAction('Transactions', AppRoutes.transactions, PhosphorIconsRegular.listMagnifyingGlass),
        ],
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 660 || constraints.maxWidth < 1120;
        final columns = constraints.maxWidth >= 1180 ? 4 : 2;
        final cardAspect = compact ? 1.34 : 1.18;

        return Container(
          color: const Color(0xFFF5F7FB),
          padding: EdgeInsets.all(compact ? 14 : 18),
          child: Column(
            children: [
              _HeroStrip(compact: compact),
              Gap(compact ? 12 : 16),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: workflows.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: compact ? 12 : 16,
                    mainAxisSpacing: compact ? 12 : 16,
                    childAspectRatio: cardAspect,
                  ),
                  itemBuilder: (context, index) {
                    return _WorkflowCard(group: workflows[index], compact: compact)
                        .animate(delay: (index * 55).ms)
                        .fadeIn(duration: 240.ms)
                        .slideY(begin: 0.035, end: 0);
                  },
                ),
              ),
              Gap(compact ? 10 : 14),
              _QuickLaunchStrip(compact: compact),
            ],
          ),
        );
      },
    );
  }
}

class _HeroStrip extends StatelessWidget {
  const _HeroStrip({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      height: compact ? 58 : 72,
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.10),
            cs.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 36 : 44,
            height: compact ? 36 : 44,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(PhosphorIconsFill.flowArrow, color: cs.onPrimary, size: compact ? 19 : 22),
          ),
          Gap(compact ? 11 : 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workflow Home',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                if (!compact)
                  Text(
                    'Navigate daily work without balances or financial noise.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          _HeroChip(label: 'No balances', icon: PhosphorIconsRegular.eyeSlash),
          const Gap(8),
          if (!compact) _HeroChip(label: 'QuickBooks-style flow', icon: PhosphorIconsRegular.graph),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const Gap(6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({required this.group, required this.compact});
  final _WorkflowGroup group;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 34 : 38,
                height: compact ? 34 : 38,
                decoration: BoxDecoration(
                  color: group.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(group.icon, size: compact ? 18 : 20, color: group.accent),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      group.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Gap(compact ? 10 : 12),
          Expanded(
            child: Column(
              children: group.actions
                  .map((action) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: action == group.actions.last ? 0 : 6),
                          child: _WorkflowActionTile(action: action, accent: group.accent),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowActionTile extends StatelessWidget {
  const _WorkflowActionTile({required this.action, required this.accent});
  final _WorkflowAction action;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(action.path),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.70)),
          ),
          child: Row(
            children: [
              Icon(action.icon, size: 16, color: accent),
              const Gap(8),
              Expanded(
                child: Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              Icon(PhosphorIconsRegular.caretRight, size: 13, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickLaunchStrip extends StatelessWidget {
  const _QuickLaunchStrip({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final quick = [
      _WorkflowAction('New Invoice', AppRoutes.invoiceNew, PhosphorIconsRegular.fileText),
      _WorkflowAction('Sales Receipt', AppRoutes.salesReceiptNew, PhosphorIconsRegular.receipt),
      _WorkflowAction('Receive Payment', AppRoutes.paymentNew, PhosphorIconsRegular.creditCard),
      _WorkflowAction('Receive Inventory', AppRoutes.receiveInventoryNew, PhosphorIconsRegular.package),
      _WorkflowAction('Journal Entry', AppRoutes.journalEntryNew, PhosphorIconsRegular.notebook),
    ];
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: compact ? 42 : 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.lightning, size: 17, color: cs.primary),
          const Gap(8),
          const Text('Quick launch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          const Gap(12),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quick.length,
              separatorBuilder: (_, __) => const Gap(8),
              itemBuilder: (context, index) => _QuickButton(action: quick[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({required this.action});
  final _WorkflowAction action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: () => context.go(action.path),
      icon: Icon(action.icon, size: 15),
      label: Text(action.label),
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.onSurface,
        side: BorderSide(color: cs.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _WorkflowGroup {
  const _WorkflowGroup({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<_WorkflowAction> actions;
}

class _WorkflowAction {
  const _WorkflowAction(this.label, this.path, this.icon);
  final String label;
  final String path;
  final IconData icon;
}
