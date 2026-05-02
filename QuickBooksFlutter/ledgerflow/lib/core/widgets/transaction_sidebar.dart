// transaction_sidebar.dart
// A professional sidebar widget that displays real-time vendor insights.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';
import '../../features/vendors/providers/vendors_provider.dart';

class TransactionSidebar extends ConsumerWidget {
  const TransactionSidebar({super.key, this.vendorId});
  final String? vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (vendorId == null || vendorId!.isEmpty) {
      return _EmptySidebar(l10n: l10n);
    }

    final vendorAsync = ref.watch(vendorDetailProvider(vendorId!));

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: vendorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (vendor) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Vendor Header ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              color: cs.primaryContainer.withValues(alpha: 0.3),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: cs.primary,
                    child: Text(
                      vendor.initials,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    vendor.displayName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (vendor.companyName != null)
                    Text(
                      vendor.companyName!,
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
                    ),
                ],
              ),
            ),

            // ── Balances ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _BalanceRow(
                    label: l10n.vendorBalance,
                    amount: vendor.balance,
                    isPositive: vendor.balance > 0,
                    l10n: l10n,
                  ),
                  const Divider(height: 24),
                  _BalanceRow(
                    label: l10n.creditBalance,
                    amount: vendor.creditBalance,
                    isPositive: false, // Credit is usually green
                    l10n: l10n,
                  ),
                ],
              ),
            ),

            const Divider(thickness: 8, height: 8, color: Color(0xFFF5F5F5)),

            // ── Recent Activity ────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      l10n.recentTransactions,
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
                    ),
                  ),
                  const Expanded(
                    child: _RecentActivityList(), // Placeholder for now
                  ),
                ],
              ),
            ),
            
            // ── Footer Actions ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navigate to vendor profile
                },
                icon: const Icon(Icons.person_outline, size: 18),
                label: Text(l10n.viewVendorProfile),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySidebar extends StatelessWidget {
  const _EmptySidebar({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              l10n.selectVendorHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.label,
    required this.amount,
    required this.isPositive,
    required this.l10n,
  });

  final String label;
  final double amount;
  final bool isPositive;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        Text(
          '${amount.toStringAsFixed(2)} ${l10n.egp}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: amount == 0 ? Colors.grey : (isPositive ? Colors.orange.shade800 : Colors.green.shade700),
          ),
        ),
      ],
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // This will be implemented when we have a provider for vendor transactions
    return Center(
      child: Text(
        l10n.noRecentTransactions,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
      ),
    );
  }
}
