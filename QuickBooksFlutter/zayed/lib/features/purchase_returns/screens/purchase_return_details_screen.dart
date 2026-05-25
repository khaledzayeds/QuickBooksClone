// purchase_return_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../purchase_bills/providers/purchase_bills_provider.dart';
import '../../transactions/widgets/transaction_workspace_shell.dart';
import '../data/models/purchase_return_model.dart';
import '../providers/purchase_returns_provider.dart';

class PurchaseReturnDetailsScreen extends ConsumerWidget {
  const PurchaseReturnDetailsScreen({super.key, required this.id});

  final String id;

  Future<void> _voidReturn(
    BuildContext context,
    WidgetRef ref,
    PurchaseReturnModel purchaseReturn,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.block_outlined, color: Theme.of(context).colorScheme.error),
        title: Text('Void ${purchaseReturn.returnNumber}?'),
        content: const Text(
          'This reverses the purchase return accounting and inventory effect.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Return'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.block_outlined),
            label: const Text('Void'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(purchaseReturnsProvider.notifier)
        .voidReturn(purchaseReturn.id);
    if (!context.mounted) return;

    result.when(
      success: (_) {
        ref.invalidate(purchaseReturnDetailsProvider(purchaseReturn.id));
        ref.invalidate(purchaseBillDetailsProvider(purchaseReturn.purchaseBillId));
        ref.read(purchaseBillsProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase return ${purchaseReturn.returnNumber} voided.'),
          ),
        );
      },
      failure: (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseReturnAsync = ref.watch(purchaseReturnDetailsProvider(id));

    final returns = ref.watch(purchaseReturnsProvider).maybeWhen(
          data: (items) => items,
          orElse: () => <PurchaseReturnModel>[],
        );

    final currentIdx = returns.indexWhere((r) => r.id == id);

    void navigateTo(int idx) {
      if (idx >= 0 && idx < returns.length) {
        context.go(
          AppRoutes.purchaseReturnDetails.replaceFirst(':id', returns[idx].id),
        );
      }
    }

    return purchaseReturnAsync.when(
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
      data: (purchaseReturn) {
        return TransactionWorkspaceShell(
          workspaceName: 'Purchase return workspace',
          saving: false,
          posting: false,
          isEdit: true,
          readOnly: true,
          onFind: () => context.go(AppRoutes.purchaseReturns),
          onPrevious: currentIdx > 0 ? () => navigateTo(currentIdx - 1) : null,
          onNext: currentIdx < returns.length - 1 && currentIdx != -1
              ? () => navigateTo(currentIdx + 1)
              : null,
          onNew: () => context.go(AppRoutes.purchaseReturnNew),
          onVoid: purchaseReturn.isVoid
              ? null
              : () => _voidReturn(context, ref, purchaseReturn),
          onClose: () => context.go(AppRoutes.purchaseReturns),
          statusBadgeText: purchaseReturn.isVoid ? 'VOID' : 'POSTED',
          statusMessage: purchaseReturn.isVoid
              ? 'This return has been voided and reversed.'
              : 'Posted · Total: ${purchaseReturn.totalAmount.toStringAsFixed(2)}',
          statusColor: purchaseReturn.isVoid ? Colors.red : Colors.green,
          formContent: _DetailsBody(purchaseReturn: purchaseReturn),
          contextPanel: _ReturnContextPanel(purchaseReturn: purchaseReturn),
        );
      },
    );
  }
}

// ── Details Body ────────────────────────────────────────────────────────────

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.purchaseReturn});

  final PurchaseReturnModel purchaseReturn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Main info card
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
                      purchaseReturn.returnNumber.isEmpty
                          ? 'Purchase Return'
                          : purchaseReturn.returnNumber,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1A3240),
                      ),
                    ),
                  ),
                  _StatusChip(purchaseReturn: purchaseReturn),
                ],
              ),
              const Divider(height: 24),
              _InfoRow(
                label: 'Vendor',
                value: purchaseReturn.vendorName ?? purchaseReturn.vendorId,
              ),
              _InfoRow(
                label: 'Return Date',
                value: fmt.format(purchaseReturn.returnDate),
              ),
              _InfoRow(
                label: 'Purchase Bill',
                value: purchaseReturn.billNumber ?? purchaseReturn.purchaseBillId,
                isLink: true,
                onTap: () => context.push(
                  AppRoutes.purchaseBillDetails.replaceFirst(
                    ':id',
                    purchaseReturn.purchaseBillId,
                  ),
                ),
              ),
              if (purchaseReturn.postedTransactionId != null &&
                  purchaseReturn.postedTransactionId!.isNotEmpty)
                _InfoRow(
                  label: 'Posted Transaction',
                  value: purchaseReturn.postedTransactionId!,
                ),
              if (purchaseReturn.reversalTransactionId != null &&
                  purchaseReturn.reversalTransactionId!.isNotEmpty)
                _InfoRow(
                  label: 'Reversal Transaction',
                  value: purchaseReturn.reversalTransactionId!,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Lines card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDDE4E8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFE7EEF1),
                  border: Border(bottom: BorderSide(color: Color(0xFFB9C3CA))),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Returned Lines',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2D4854),
                    ),
                  ),
                ),
              ),
              if (purchaseReturn.lines.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No lines on this purchase return.'),
                )
              else
                ...purchaseReturn.lines.map((line) => _LineTile(line: line)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Total row
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
                  'Total Returned',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  purchaseReturn.totalAmount.toStringAsFixed(2),
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

class _ReturnContextPanel extends StatelessWidget {
  const _ReturnContextPanel({required this.purchaseReturn});

  final PurchaseReturnModel purchaseReturn;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Container(
      color: const Color(0xFFF4F7F8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
            color: const Color(0xFF264D5B),
            child: Text(
              'Return Summary',
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
                  label: 'TOTAL',
                  value: purchaseReturn.totalAmount.toStringAsFixed(2),
                  isTotal: true,
                ),
                _Stat(
                  label: 'RETURN DATE',
                  value: fmt.format(purchaseReturn.returnDate),
                ),
                if (purchaseReturn.vendorName != null)
                  _Stat(label: 'VENDOR', value: purchaseReturn.vendorName!),
                if (purchaseReturn.billNumber != null)
                  _Stat(label: 'BILL #', value: purchaseReturn.billNumber!),
                _Stat(
                  label: 'STATUS',
                  value: purchaseReturn.isVoid ? 'Voided' : 'Posted',
                ),
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
  const _StatusChip({required this.purchaseReturn});
  final PurchaseReturnModel purchaseReturn;

  @override
  Widget build(BuildContext context) {
    final isVoid = purchaseReturn.isVoid;
    final color = isVoid
        ? Theme.of(context).colorScheme.error
        : Colors.green.shade800;
    return Chip(
      label: Text(isVoid ? 'Void' : 'Posted'),
      backgroundColor: color.withValues(alpha: 0.14),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w800),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.line});
  final PurchaseReturnLineModel line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE8EEF1))),
      ),
      child: Row(
        children: [
          const Icon(Icons.keyboard_return_outlined,
              size: 18, color: Color(0xFF5B7A89)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              line.description,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E3540),
              ),
            ),
          ),
          Text(
            'Qty ${line.quantity.toStringAsFixed(2)} × ${line.unitCost.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF667A84)),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: Text(
              line.lineTotal.toStringAsFixed(2),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF264D5B),
              ),
            ),
          ),
        ],
      ),
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
