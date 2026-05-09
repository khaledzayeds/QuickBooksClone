// sales_receipts_list_page.dart
// QuickBooks-style Sales Receipts list with search, filter, and status badges.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../app/router.dart';
import '../data/models/sales_receipt_contracts.dart';
import '../providers/sales_receipts_state.dart';

class SalesReceiptsListPage extends ConsumerStatefulWidget {
  const SalesReceiptsListPage({super.key});

  @override
  ConsumerState<SalesReceiptsListPage> createState() =>
      _SalesReceiptsListPageState();
}

class _SalesReceiptsListPageState
    extends ConsumerState<SalesReceiptsListPage> {
  final _searchCtrl = TextEditingController();
  bool _includeVoided = false;
  String _searchText = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final receiptsAsync = ref.watch(salesReceiptsStateProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: Column(
        children: [
          // ── Top toolbar ─────────────────────────────────
          Container(
            color: cs.surface,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Search
                SizedBox(
                  width: 260,
                  height: 36,
                  child: TextField(
                    controller: _searchCtrl,
                    style: theme.textTheme.bodySmall,
                    decoration: InputDecoration(
                      hintText: l10n.search,
                      isDense: true,
                      prefixIcon:
                          const Icon(Icons.search, size: 18),
                      suffixIcon: _searchText.isNotEmpty
                          ? IconButton(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => setState(() {
                                _searchCtrl.clear();
                                _searchText = '';
                              }),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:
                            BorderSide(color: cs.outlineVariant),
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => _searchText = v.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                // Include voided toggle
                FilterChip(
                  label: Text(l10n.statusVoided,
                      style: theme.textTheme.labelSmall),
                  selected: _includeVoided,
                  onSelected: (v) =>
                      setState(() => _includeVoided = v),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: cs.outlineVariant),
                ),
                const Spacer(),
                // Refresh
                IconButton(
                  tooltip: l10n.retry,
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () => ref
                      .read(salesReceiptsStateProvider.notifier)
                      .refresh(),
                ),
                const SizedBox(width: 8),
                // New receipt
                FilledButton.icon(
                  onPressed: () =>
                      context.go(AppRoutes.salesReceiptNew),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.newText),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Content ──────────────────────────────────────
          Expanded(
            child: receiptsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(
                message: error.toString(),
                onRetry: () => ref
                    .read(salesReceiptsStateProvider.notifier)
                    .refresh(),
              ),
              data: (receipts) {
                final filtered = receipts.where((r) {
                  if (!_includeVoided && r.isVoid) return false;
                  if (_searchText.isEmpty) return true;
                  return r.receiptNumber
                          .toLowerCase()
                          .contains(_searchText) ||
                      r.customerName
                          .toLowerCase()
                          .contains(_searchText) ||
                      (r.paymentMethod
                              ?.toLowerCase()
                              .contains(_searchText) ??
                          false);
                }).toList();

                if (filtered.isEmpty) {
                  return _EmptyState(
                    l10n: l10n,
                    isFiltered: _searchText.isNotEmpty,
                  );
                }

                return _ReceiptsTable(receipts: filtered);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Table View ────────────────────────────────────────────
class _ReceiptsTable extends StatelessWidget {
  const _ReceiptsTable({required this.receipts});
  final List<SalesReceiptModel> receipts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final fmt = NumberFormat('#,##0.00');

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header row
          Container(
            color: cs.surfaceContainerHigh,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _HeaderCell(l10n.salesReceipt, flex: 2),
                _HeaderCell(l10n.customer, flex: 3),
                _HeaderCell(l10n.receiptDate, flex: 2),
                _HeaderCell(l10n.paymentMethod, flex: 2),
                _HeaderCell(l10n.depositAccount, flex: 2),
                _HeaderCell(l10n.totalAmount,
                    flex: 2, align: TextAlign.right),
                _HeaderCell('', flex: 1),
              ],
            ),
          ),
          const Divider(height: 1),
          // Data rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: receipts.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: cs.outlineVariant),
            itemBuilder: (context, i) {
              final r = receipts[i];
              return InkWell(
                onTap: () => context.go(
                    AppRoutes.salesReceiptDetails
                        .replaceFirst(':id', r.id)),
                hoverColor:
                    cs.primary.withValues(alpha: 0.04),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // Receipt #
                      Expanded(
                        flex: 2,
                        child: Row(children: [
                          _StatusDot(isVoid: r.isVoid),
                          const SizedBox(width: 8),
                          Text(
                            r.receiptNumber.isEmpty
                                ? '-'
                                : r.receiptNumber,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(
                                    fontWeight:
                                        FontWeight.w700,
                                    color: r.isVoid
                                        ? cs.error
                                        : cs.primary),
                          ),
                        ]),
                      ),
                      // Customer
                      Expanded(
                        flex: 3,
                        child: Text(
                          r.customerName.isEmpty
                              ? '-'
                              : r.customerName,
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Date
                      Expanded(
                        flex: 2,
                        child: Text(
                          DateFormat('dd/MM/yyyy')
                              .format(r.receiptDate),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      // Payment method
                      Expanded(
                        flex: 2,
                        child: _PaymentMethodBadge(
                            method: r.paymentMethod),
                      ),
                      // Deposit account
                      Expanded(
                        flex: 2,
                        child: Text(
                          r.depositAccountName ?? '-',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(
                                  color: cs.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Total
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${fmt.format(r.totalAmount)} ${l10n.egp}',
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                FontFeature.tabularFigures()
                              ]),
                        ),
                      ),
                      // Actions
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.end,
                          children: [
                            if (r.isVoid)
                              Chip(
                                label: Text(l10n.statusVoided,
                                    style: theme
                                        .textTheme.labelSmall
                                        ?.copyWith(
                                            color: cs.error)),
                                backgroundColor: cs
                                    .errorContainer
                                    .withValues(alpha: 0.4),
                                padding: EdgeInsets.zero,
                                visualDensity:
                                    VisualDensity.compact,
                                side: BorderSide.none,
                              )
                            else
                              Chip(
                                label: Text(l10n.statusPosted,
                                    style: theme
                                        .textTheme.labelSmall
                                        ?.copyWith(
                                            color: cs.primary)),
                                backgroundColor: cs
                                    .primaryContainer
                                    .withValues(alpha: 0.5),
                                padding: EdgeInsets.zero,
                                visualDensity:
                                    VisualDensity.compact,
                                side: BorderSide.none,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label,
      {this.flex = 1, this.align = TextAlign.left});
  final String label;
  final int flex;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(
          label.toUpperCase(),
          textAlign: align,
          style:
              Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
        ),
      );
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.isVoid});
  final bool isVoid;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isVoid ? cs.error : cs.primary,
      ),
    );
  }
}

class _PaymentMethodBadge extends StatelessWidget {
  const _PaymentMethodBadge({this.method});
  final String? method;

  IconData get _icon {
    switch (method?.toLowerCase()) {
      case 'cash':
        return Icons.payments_outlined;
      case 'card':
      case 'credit card':
        return Icons.credit_card_outlined;
      case 'bank transfer':
        return Icons.account_balance_outlined;
      case 'check':
        return Icons.receipt_outlined;
      default:
        return Icons.payment_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (method == null || method!.isEmpty) {
      return Text('-',
          style: Theme.of(context).textTheme.bodySmall);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon,
            size: 14,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant),
        const SizedBox(width: 4),
        Text(method!,
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n, this.isFiltered = false});
  final AppLocalizations l10n;
  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.point_of_sale_outlined,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'No receipts match your search'
                  : l10n.noSalesReceipts,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try a different search term or clear the filter.'
                  : l10n.startSalesReceipt,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant),
            ),
            if (!isFiltered) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    context.go(AppRoutes.salesReceiptNew),
                icon: const Icon(Icons.add),
                label: Text(l10n.createSalesReceipt),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState(
      {required this.message, required this.onRetry});
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
            Icon(Icons.error_outline,
                size: 48,
                color:
                    Theme.of(context).colorScheme.error),
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
