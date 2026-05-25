// customer_credit_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../../core/constants/api_enums.dart' show CustomerCreditAction;
import '../../transactions/widgets/transaction_workspace_shell.dart';
import '../data/models/customer_credit_model.dart';
import '../providers/customer_credits_provider.dart';

class CustomerCreditDetailsScreen extends ConsumerWidget {
  const CustomerCreditDetailsScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditAsync = ref.watch(customerCreditDetailsProvider(id));

    final credits = ref.watch(customerCreditsProvider).maybeWhen(
          data: (items) => items,
          orElse: () => <CustomerCreditModel>[],
        );

    final currentIdx = credits.indexWhere((c) => c.id == id);

    void navigateTo(int idx) {
      if (idx >= 0 && idx < credits.length) {
        context.go(
          AppRoutes.customerCreditDetails.replaceFirst(':id', credits[idx].id),
        );
      }
    }

    return creditAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
      ),
      data: (credit) {
        return TransactionWorkspaceShell(
          workspaceName: 'Customer credit workspace',
          saving: false,
          posting: false,
          isEdit: true,
          readOnly: true,
          onFind: () => context.go(AppRoutes.customerCredits),
          onPrevious: currentIdx > 0 ? () => navigateTo(currentIdx - 1) : null,
          onNext: currentIdx < credits.length - 1 && currentIdx != -1
              ? () => navigateTo(currentIdx + 1)
              : null,
          onNew: () => context.go(AppRoutes.customerCreditNew),
          onClose: () => context.go(AppRoutes.customerCredits),
          showVoid: false,
          statusBadgeText: 'POSTED',
          statusMessage: 'Posted · Amount: ${credit.amount.toStringAsFixed(2)}',
          statusColor: Colors.green,
          formContent: _DetailsBody(credit: credit),
          contextPanel: _CreditContextPanel(credit: credit),
        );
      },
    );
  }
}

// ── Details Body ────────────────────────────────────────────────────────────

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.credit});

  final CustomerCreditModel credit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy');
    final isRefund = credit.action == CustomerCreditAction.refundReceipt;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDDE4E8)),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      credit.referenceNumber.isEmpty
                          ? 'Customer Credit Activity'
                          : credit.referenceNumber,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1A3240),
                      ),
                    ),
                  ),
                  _StatusChip(label: isRefund ? 'Refund' : 'Apply To Invoice'),
                ],
              ),
              const Divider(height: 24),
              _InfoRow(
                label: 'Customer',
                value: credit.customerName ?? credit.customerId,
              ),
              _InfoRow(
                label: 'Activity Date',
                value: fmt.format(credit.activityDate),
              ),
              if (credit.invoiceId != null && credit.invoiceId!.isNotEmpty)
                _InfoRow(
                  label: 'Invoice',
                  value: credit.invoiceNumber ?? credit.invoiceId!,
                  isLink: true,
                  onTap: () => context.push(
                    AppRoutes.invoiceDetails.replaceFirst(
                      ':id',
                      credit.invoiceId!,
                    ),
                  ),
                ),
              if (credit.refundAccountName != null &&
                  credit.refundAccountName!.isNotEmpty)
                _InfoRow(
                  label: 'Refund Account',
                  value: credit.refundAccountName!,
                ),
              if (credit.paymentMethod != null)
                _InfoRow(
                  label: 'Payment Method',
                  value: credit.paymentMethod!.toApiString(),
                ),
              if (credit.postedTransactionId != null &&
                  credit.postedTransactionId!.isNotEmpty)
                _InfoRow(
                  label: 'Posted Transaction',
                  value: credit.postedTransactionId!,
                ),
              if (credit.postedAt != null)
                _InfoRow(
                  label: 'Posted At',
                  value: fmt.format(credit.postedAt!),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDDE4E8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Credit Amount',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  credit.amount.toStringAsFixed(2),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF264D5B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Context Panel ───────────────────────────────────────────────────────────

class _CreditContextPanel extends StatelessWidget {
  const _CreditContextPanel({required this.credit});

  final CustomerCreditModel credit;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final isRefund = credit.action == CustomerCreditAction.refundReceipt;

    return Container(
      color: const Color(0xFFF4F7F8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
            color: const Color(0xFF264D5B),
            child: Text(
              'Credit Info',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Stat(
                  label: 'AMOUNT',
                  value: credit.amount.toStringAsFixed(2),
                  isTotal: true,
                ),
                _Stat(
                  label: 'ACTIVITY DATE',
                  value: fmt.format(credit.activityDate),
                ),
                if (credit.customerName != null)
                  _Stat(label: 'CUSTOMER', value: credit.customerName!),
                if (credit.action == CustomerCreditAction.applyToInvoice &&
                    credit.invoiceNumber != null)
                  _Stat(
                    label: 'APPLIED TO',
                    value: 'Invoice #${credit.invoiceNumber}',
                  ),
                if (isRefund)
                  const _Stat(label: 'TYPE', value: 'Refund Receipt'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Small Widgets ────────────────────────────────────────────────────

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

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.isTotal = false});
  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF7D8B93),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              color: const Color(0xFF264D5B),
            ),
          ),
        ],
      ),
    );
  }
}
