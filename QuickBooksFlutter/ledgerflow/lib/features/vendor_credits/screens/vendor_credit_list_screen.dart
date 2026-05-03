// vendor_credit_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../core/constants/api_enums.dart' show VendorCreditAction;
import '../data/models/vendor_credit_model.dart';
import '../providers/vendor_credits_provider.dart';

class VendorCreditListScreen extends ConsumerWidget {
  const VendorCreditListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final creditsAsync = ref.watch(vendorCreditsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.creditBalance),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            onPressed: () => ref.read(vendorCreditsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton.icon(
              onPressed: () => context.go('/purchases/vendor-credits/new'),
              icon: const Icon(Icons.add),
              label: Text('${l10n.newText} ${l10n.creditBalance}'),
            ),
          ),
        ],
      ),
      body: creditsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(vendorCreditsProvider.notifier).refresh(),
        ),
        data: (credits) {
          if (credits.isEmpty) return const _EmptyState();

          return RefreshIndicator(
            onRefresh: () => ref.read(vendorCreditsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: credits.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _VendorCreditCard(credit: credits[index]),
            ),
          );
        },
      ),
    );
  }
}

class _VendorCreditCard extends StatelessWidget {
  const _VendorCreditCard({required this.credit});

  final VendorCreditModel credit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDeposit = credit.action == VendorCreditAction.depositRefund;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isDeposit ? cs.secondaryContainer : cs.primaryContainer,
                child: Icon(
                  isDeposit ? Icons.account_balance_outlined : Icons.receipt_long_outlined,
                  color: isDeposit ? cs.onSecondaryContainer : cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      credit.referenceNumber.isEmpty ? '-' : credit.referenceNumber,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(credit.vendorName ?? '-'),
                    const SizedBox(height: 4),
                    Text(
                      '${_date(credit.activityDate)} • ${isDeposit ? l10n.recordDeposits : l10n.purchaseBill}',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    if (credit.billNumber != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.purchaseBill}: ${credit.billNumber}',
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                    if (credit.depositAccountName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.depositAccount}: ${credit.depositAccountName}',
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${credit.amount.toStringAsFixed(2)} ${l10n.egp}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.posted,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
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

  static String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 56),
            const SizedBox(height: 16),
            Text(l10n.creditBalance, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.underDevelopment, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/purchases/vendor-credits/new'),
              icon: const Icon(Icons.add),
              label: Text('${l10n.newText} ${l10n.creditBalance}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
