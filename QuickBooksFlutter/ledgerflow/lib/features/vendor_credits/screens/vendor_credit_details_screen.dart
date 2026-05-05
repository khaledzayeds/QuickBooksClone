// vendor_credit_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../../core/constants/api_enums.dart' show VendorCreditAction;
import '../data/models/vendor_credit_model.dart';
import '../providers/vendor_credits_provider.dart';

class VendorCreditDetailsScreen extends ConsumerWidget {
  const VendorCreditDetailsScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditAsync = ref.watch(vendorCreditDetailsProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Credit Activity'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(vendorCreditDetailsProvider(id)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: creditAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (credit) => _DetailsBody(credit: credit),
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.credit});

  final VendorCreditModel credit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy');
    final isRefund = credit.action == VendorCreditAction.refundReceipt;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        credit.referenceNumber.isEmpty
                            ? 'Vendor Credit Activity'
                            : credit.referenceNumber,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _StatusChip(
                      label: isRefund ? 'Refund Receipt' : 'Apply To Bill',
                    ),
                  ],
                ),
                const Divider(height: 24),
                _InfoRow(
                  label: 'Vendor',
                  value: credit.vendorName ?? credit.vendorId,
                ),
                _InfoRow(label: 'Date', value: fmt.format(credit.activityDate)),
                if (credit.purchaseBillId != null &&
                    credit.purchaseBillId!.isNotEmpty)
                  _InfoRow(
                    label: 'Purchase bill',
                    value: credit.billNumber ?? credit.purchaseBillId!,
                    isLink: true,
                    onTap: () => context.push(
                      AppRoutes.purchaseBillDetails.replaceFirst(
                        ':id',
                        credit.purchaseBillId!,
                      ),
                    ),
                  ),
                if (credit.depositAccountName != null &&
                    credit.depositAccountName!.isNotEmpty)
                  _InfoRow(
                    label: 'Deposit account',
                    value: credit.depositAccountName!,
                  ),
                if (credit.paymentMethod != null)
                  _InfoRow(
                    label: 'Payment method',
                    value: credit.paymentMethod!.toApiString(),
                  ),
                if (credit.postedTransactionId != null &&
                    credit.postedTransactionId!.isNotEmpty)
                  _InfoRow(
                    label: 'Posted transaction',
                    value: credit.postedTransactionId!,
                  ),
                if (credit.postedAt != null)
                  _InfoRow(
                    label: 'Posted at',
                    value: fmt.format(credit.postedAt!),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: 360,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: _AmountRow(
                  label: 'Amount',
                  amount: credit.amount,
                  isTotal: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.14),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w800),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLink = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool isLink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).hintColor)),
        const Spacer(),
        Flexible(
          child: isLink
              ? InkWell(
                  onTap: onTap,
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(
                  value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
      ],
    ),
  );
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  final String label;
  final double amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)
        : Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(amount.toStringAsFixed(2), style: style),
      ],
    );
  }
}
