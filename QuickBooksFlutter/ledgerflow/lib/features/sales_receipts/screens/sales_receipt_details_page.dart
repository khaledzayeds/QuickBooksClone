// sales_receipt_details_page.dart
// QuickBooks-style Sales Receipt details — read-only view with print & void actions.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../app/router.dart';
import '../../printing/widgets/document_print_preview_dialog.dart';
import '../../transactions/widgets/void_confirmation_dialog.dart';
import '../data/models/sales_receipt_contracts.dart';
import '../providers/sales_receipts_state.dart';

class SalesReceiptDetailsPage extends ConsumerWidget {
  const SalesReceiptDetailsPage({super.key, required this.id});
  final String id;

  Future<void> _voidReceipt(
    BuildContext context,
    WidgetRef ref,
    SalesReceiptModel receipt,
  ) async {
    final confirmed = await showVoidConfirmationDialog(
      context: context,
      documentLabel:
          'sales receipt ${receipt.receiptNumber}',
      warning:
          'Voiding will also reverse the linked payment when possible.',
    );
    if (!confirmed || !context.mounted) return;

    final result = await ref
        .read(salesReceiptsRepoProvider)
        .voidReceipt(receipt.id);
    if (!context.mounted) return;
    result.when(
      success: (updated) {
        ref
            .read(salesReceiptsStateProvider.notifier)
            .refresh();
        ref.invalidate(salesReceiptDetailsStateProvider(receipt.id));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Receipt ${updated.receiptNumber} voided.'),
          backgroundColor:
              Theme.of(context).colorScheme.error,
        ));
      },
      failure: (e) =>
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor:
            Theme.of(context).colorScheme.error,
      )),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final receiptAsync =
        ref.watch(salesReceiptDetailsStateProvider(id));

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        titleSpacing: 12,
        automaticallyImplyLeading: false,
        title: Row(children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => context.go(AppRoutes.salesReceipts),
            icon: const Icon(Icons.arrow_back, size: 20),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.salesReceiptDetails,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              receiptAsync.maybeWhen(
                data: (r) => Text(
                  r.receiptNumber,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ]),
        actions: [
          // Print
          IconButton(
            tooltip: 'Print / Preview',
            icon: const Icon(Icons.print_outlined),
            onPressed: () => showDocumentPrintPreviewDialog(
              context: context,
              ref: ref,
              documentType: 'sales-receipt',
              documentId: id,
            ),
          ),
          // Void
          receiptAsync.maybeWhen(
            data: (r) => !r.isVoid
                ? IconButton(
                    tooltip: 'Void receipt',
                    icon: Icon(Icons.block_outlined,
                        color: cs.error),
                    onPressed: () =>
                        _voidReceipt(context, ref, r),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          // Back to list
          IconButton(
            tooltip: l10n.salesReceipts,
            icon: const Icon(Icons.list_alt_outlined),
            onPressed: () =>
                context.go(AppRoutes.salesReceipts),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outlineVariant),
        ),
      ),
      body: receiptAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text(e.toString(),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(
                    salesReceiptDetailsStateProvider(id)),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (receipt) =>
            _DetailsBody(receipt: receipt, l10n: l10n),
      ),
    );
  }
}

// ── Details Body ──────────────────────────────────────────
class _DetailsBody extends StatelessWidget {
  const _DetailsBody(
      {required this.receipt, required this.l10n});
  final SalesReceiptModel receipt;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final numFmt = NumberFormat('#,##0.00');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Voided banner ──────────────────────────
              if (receipt.isVoid)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.errorContainer
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: cs.error
                            .withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.block_outlined,
                        size: 18, color: cs.error),
                    const SizedBox(width: 8),
                    Text(
                      'This sales receipt has been voided.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(
                              color: cs.error,
                              fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),

              // ── Document card ──────────────────────────
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: cs.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // Document header
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // Left: title + receipt#
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sales Receipt',
                                  style: theme
                                      .textTheme.headlineSmall
                                      ?.copyWith(
                                          fontWeight:
                                              FontWeight.w900),
                                ),
                                const SizedBox(height: 4),
                                Row(children: [
                                  _StatusChip(
                                      receipt: receipt,
                                      cs: cs,
                                      theme: theme),
                                  const SizedBox(width: 8),
                                  Text(
                                    receipt.receiptNumber,
                                    style: theme
                                        .textTheme.titleMedium
                                        ?.copyWith(
                                            color:
                                                cs.primary,
                                            fontWeight:
                                                FontWeight
                                                    .w700),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                          // Right: totals summary
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${numFmt.format(receipt.totalAmount)} ${l10n.egp}',
                                style: theme
                                    .textTheme.headlineMedium
                                    ?.copyWith(
                                        fontWeight:
                                            FontWeight.w900,
                                        color: receipt.isVoid
                                            ? cs.error
                                            : cs.primary,
                                        fontFeatures: const [
                                      FontFeature
                                          .tabularFigures()
                                    ]),
                              ),
                              Text(
                                l10n.paid,
                                style: theme.textTheme.labelMedium
                                    ?.copyWith(
                                        color: cs.primary,
                                        fontWeight:
                                            FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Divider(color: cs.outlineVariant),
                      const SizedBox(height: 16),

                      // Meta fields grid
                      Wrap(
                        spacing: 32,
                        runSpacing: 12,
                        children: [
                          _MetaField(
                              label: l10n.customer,
                              value: receipt
                                  .customerName.isEmpty
                                  ? '-'
                                  : receipt.customerName),
                          _MetaField(
                              label: l10n.receiptDate,
                              value: DateFormat('dd MMM yyyy')
                                  .format(receipt.receiptDate)),
                          _MetaField(
                              label: l10n.paymentMethod,
                              value:
                                  receipt.paymentMethod ?? '-'),
                          _MetaField(
                              label: l10n.depositAccount,
                              value:
                                  receipt.depositAccountName ??
                                      '-'),
                          if (receipt.postedAt != null)
                            _MetaField(
                                label: 'Posted',
                                value: DateFormat(
                                        'dd MMM yyyy HH:mm')
                                    .format(receipt.postedAt!
                                        .toLocal())),
                          if (receipt.voidedAt != null)
                            _MetaField(
                                label: 'Voided',
                                value: DateFormat(
                                        'dd MMM yyyy HH:mm')
                                    .format(receipt.voidedAt!
                                        .toLocal())),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Divider(color: cs.outlineVariant),

                      // ── Line items table ───────────────
                      if (receipt.lines.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _LinesTable(
                            receipt: receipt,
                            numFmt: numFmt,
                            l10n: l10n),
                      ],

                      const SizedBox(height: 16),
                      Divider(color: cs.outlineVariant),

                      // ── Totals ─────────────────────────
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: SizedBox(
                          width: 280,
                          child: Column(
                            children: [
                              _TotalRow(
                                  label: l10n.subtotal,
                                  value: numFmt.format(
                                      receipt.subtotal),
                                  currency: l10n.egp,
                                  theme: theme),
                              if (receipt.discountAmount >
                                  0)
                                _TotalRow(
                                    label: 'Discount',
                                    value:
                                        '-${numFmt.format(receipt.discountAmount)}',
                                    currency: l10n.egp,
                                    theme: theme),
                              if (receipt.taxAmount > 0)
                                _TotalRow(
                                    label: l10n.tax,
                                    value: numFmt.format(
                                        receipt.taxAmount),
                                    currency: l10n.egp,
                                    theme: theme),
                              const Divider(),
                              _TotalRow(
                                label: l10n.total,
                                value: numFmt.format(
                                    receipt.totalAmount),
                                currency: l10n.egp,
                                theme: theme,
                                bold: true,
                                color: cs.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Lines Table ───────────────────────────────────────────
class _LinesTable extends StatelessWidget {
  const _LinesTable({
    required this.receipt,
    required this.numFmt,
    required this.l10n,
  });
  final SalesReceiptModel receipt;
  final NumberFormat numFmt;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(4),
        2: FixedColumnWidth(70),
        3: FixedColumnWidth(110),
        4: FixedColumnWidth(110),
      },
      defaultVerticalAlignment:
          TableCellVerticalAlignment.middle,
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6)),
          ),
          children: [
            _TH(l10n.itemService),
            _TH(l10n.description),
            _TH(l10n.qty, align: TextAlign.center),
            _TH(l10n.rate, align: TextAlign.right),
            _TH(l10n.amount, align: TextAlign.right),
          ],
        ),
        // Data rows
        ...receipt.lines.asMap().entries.map((e) {
          final i = e.key;
          final line = e.value;
          final bg = i.isEven
              ? cs.surface
              : cs.surfaceContainerHighest
                  .withValues(alpha: 0.4);
          return TableRow(
            decoration: BoxDecoration(color: bg),
            children: [
              _TD(line.description.isNotEmpty
                  ? line.description
                  : '-'),
              _TD(line.description),
              _TD(line.quantity.toStringAsFixed(
                      line.quantity % 1 == 0 ? 0 : 2),
                  align: TextAlign.center),
              _TD(
                  '${numFmt.format(line.unitPrice)} ${l10n.egp}',
                  align: TextAlign.right),
              _TD(
                  '${numFmt.format(line.lineTotal)} ${l10n.egp}',
                  align: TextAlign.right,
                  bold: true),
            ],
          );
        }),
      ],
    );
  }
}

class _TH extends StatelessWidget {
  const _TH(this.text, {this.align = TextAlign.left});
  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8),
        child: Text(
          text.toUpperCase(),
          textAlign: align,
          style:
              Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
        ),
      );
}

class _TD extends StatelessWidget {
  const _TD(this.text,
      {this.align = TextAlign.left, this.bold = false});
  final String text;
  final TextAlign align;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 9),
        child: Text(
          text,
          textAlign: align,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w400,
                fontFeatures: bold
                    ? const [FontFeature.tabularFigures()]
                    : null,
              ),
        ),
      );
}

// ── Small helpers ─────────────────────────────────────────
class _MetaField extends StatelessWidget {
  const _MetaField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    required this.currency,
    required this.theme,
    this.bold = false,
    this.color,
  });
  final String label;
  final String value;
  final String currency;
  final ThemeData theme;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: bold
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: color)),
          const Spacer(),
          Text('$value $currency',
              style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: bold
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: color,
                  fontFeatures: const [
                    FontFeature.tabularFigures()
                  ])),
        ]),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.receipt,
    required this.cs,
    required this.theme,
  });
  final SalesReceiptModel receipt;
  final ColorScheme cs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isVoid = receipt.isVoid;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isVoid
            ? cs.errorContainer.withValues(alpha: 0.5)
            : cs.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isVoid ? l10n.statusVoided : l10n.statusPosted,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: isVoid ? cs.error : cs.primary,
        ),
      ),
    );
  }
}
