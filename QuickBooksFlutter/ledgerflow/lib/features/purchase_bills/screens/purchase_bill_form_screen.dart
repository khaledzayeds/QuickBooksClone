// purchase_bill_form_screen.dart
// QuickBooks-style Bill form with sidebar and Inventory Receipt linking.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../../core/widgets/transaction_line_table.dart';
import '../../../../core/widgets/transaction_sidebar.dart';
import '../../../../core/widgets/transaction_vendor_picker.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../../receive_inventory/data/models/receive_inventory_model.dart';
import '../../receive_inventory/providers/receive_inventory_provider.dart';
import '../../vendors/data/models/vendor_model.dart';
import '../data/models/billing_plan_model.dart';
import '../data/models/create_purchase_bill_dto.dart';
import '../providers/purchase_bills_provider.dart';

class PurchaseBillFormScreen extends ConsumerStatefulWidget {
  const PurchaseBillFormScreen({super.key, this.inventoryReceiptId});
  final String? inventoryReceiptId;

  @override
  ConsumerState<PurchaseBillFormScreen> createState() =>
      _PurchaseBillFormScreenState();
}

class _PurchaseBillFormScreenState
    extends ConsumerState<PurchaseBillFormScreen> {
  VendorModel? _selectedVendor;
  BillingPlanModel? _activePlan;
  ReceiveInventoryModel? _selectedReceipt;

  DateTime _billDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  final _memoCtrl = TextEditingController();
  final List<TransactionLineEntry> _lines = [];

  bool _loadingPlan = false;
  bool _saving = false;

  @override
  void dispose() {
    _memoCtrl.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  void _clearLines() {
    for (final l in _lines) {
      l.dispose();
    }
    _lines.clear();
  }

  void _onVendorChanged(VendorModel vendor) {
    setState(() {
      _selectedVendor = vendor;
      _selectedReceipt = null;
      _activePlan = null;
      _clearLines();
      _lines.add(TransactionLineEntry());
    });
  }

  Future<void> _onReceiptChanged(ReceiveInventoryModel? receipt) async {
    setState(() {
      _selectedReceipt = receipt;
      _activePlan = null;
      _clearLines();
      _lines.add(TransactionLineEntry());
    });

    if (receipt == null) return;

    setState(() => _loadingPlan = true);
    try {
      final result = await ref
          .read(purchaseBillsRepositoryProvider)
          .getBillingPlan(receipt.id);
      result.when(
        success: (plan) {
          final billableLines = plan.lines
              .where((line) => line.remainingQuantity > 0)
              .toList();

          if (plan.totalRemainingQuantity <= 0 || billableLines.isEmpty) {
            setState(() {
              _selectedReceipt = null;
              _activePlan = null;
              _clearLines();
              _lines.add(TransactionLineEntry());
            });
            _showError('This inventory receipt is already fully billed.');
            return;
          }

          setState(() {
            _activePlan = plan;
            _clearLines();
            for (final lp in billableLines) {
              final entry = TransactionLineEntry(
                itemId: lp.itemId,
                itemName: lp.description,
                qty: lp.suggestedBillQuantity,
                rate: lp.unitCost,
                inventoryReceiptLineId: lp.inventoryReceiptLineId,
              );
              entry.descCtrl.text = lp.description;
              _lines.add(entry);
            }
          });
        },
        failure: (e) => _showError(e.message),
      );
    } finally {
      if (mounted) setState(() => _loadingPlan = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedVendor == null) {
      _showError(l10n.selectVendor);
      return;
    }

    final validLines = _lines
        .where((l) => l.itemId != null && l.qty > 0)
        .toList();
    if (validLines.isEmpty) {
      _showError(l10n.minOneQty);
      return;
    }

    if (_activePlan != null) {
      for (final line in validLines) {
        final planLine = _activePlan!.lines
            .where(
              (p) => p.inventoryReceiptLineId == line.inventoryReceiptLineId,
            )
            .firstOrNull;
        if (planLine != null && line.qty > planLine.remainingQuantity) {
          _showError('${line.descCtrl.text} exceeds remaining quantity.');
          return;
        }
      }
    }

    setState(() => _saving = true);
    try {
      final dto = CreatePurchaseBillDto(
        vendorId: _selectedVendor!.id,
        inventoryReceiptId: _selectedReceipt?.id,
        billDate: _billDate,
        dueDate: _dueDate,
        memo: _memoCtrl.text,
        lines: validLines
            .map(
              (l) => CreatePurchaseBillLineDto(
                itemId: l.itemId!,
                description: l.descCtrl.text,
                quantity: l.qty,
                unitCost: l.rate,
                inventoryReceiptLineId: l.inventoryReceiptLineId,
              ),
            )
            .toList(),
      );

      final result = await ref
          .read(purchaseBillsRepositoryProvider)
          .createBill(dto);
      result.when(
        success: (_) {
          ref.read(purchaseBillsProvider.notifier).refresh();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.billCreatedSuccess)));
          context.pop();
        },
        failure: (e) => _showError(e.message),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.enterBills} | ${l10n.purchases}'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check),
            tooltip: l10n.save,
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: VendorPickerField(
                          value: _selectedVendor,
                          onChanged: _onVendorChanged,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _ReceiptPicker(
                          vendorId: _selectedVendor?.id,
                          value: _selectedReceipt,
                          onChanged: _onReceiptChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickerField(
                          label: l10n.billDate,
                          value: _billDate,
                          onChanged: (d) => setState(() => _billDate = d),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _DatePickerField(
                          label: l10n.dueDate,
                          value: _dueDate,
                          onChanged: (d) => setState(() => _dueDate = d),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (_loadingPlan)
                    const Center(child: CircularProgressIndicator())
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: TransactionLineTable(
                          lines: _lines,
                          onChanged: () => setState(() {}),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _memoCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: l10n.memoInternal,
                            border: const OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                      Expanded(
                        flex: 2,
                        child: _TotalsCard(lines: _lines, l10n: l10n),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          TransactionSidebar(vendorId: _selectedVendor?.id),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () => context.pop(),
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(l10n.save),
              style: ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (d != null) onChanged(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text('${value.day}/${value.month}/${value.year}'),
      ),
    );
  }
}

class _ReceiptPicker extends ConsumerWidget {
  const _ReceiptPicker({this.vendorId, this.value, required this.onChanged});
  final String? vendorId;
  final ReceiveInventoryModel? value;
  final ValueChanged<ReceiveInventoryModel?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (vendorId == null) {
      return IgnorePointer(
        child: Opacity(
          opacity: 0.5,
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: l10n.linkToRI,
              border: const OutlineInputBorder(),
            ),
            items: const [],
            onChanged: (_) {},
          ),
        ),
      );
    }

    final receiptsAsync = ref.watch(
      receiveInventoryByVendorProvider(vendorId!),
    );

    return receiptsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(e.toString()),
      data: (receipts) {
        final activeReceipts = receipts
            .where((r) => r.status.toLowerCase() != 'void')
            .toList();

        if (activeReceipts.isEmpty) {
          return InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.linkToRI,
              border: const OutlineInputBorder(),
            ),
            child: Text(
              l10n.noPendingRI,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          );
        }

        return DropdownButtonFormField<ReceiveInventoryModel?>(
          initialValue: value,
          decoration: InputDecoration(
            labelText: l10n.linkToRI,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.link),
          ),
          hint: Text(l10n.selectRI),
          items: [
            DropdownMenuItem<ReceiveInventoryModel?>(
              value: null,
              child: Text(l10n.clear),
            ),
            ...activeReceipts.map(
              (r) => DropdownMenuItem<ReceiveInventoryModel?>(
                value: r,
                child: Text(
                  '${r.receiptNumber} (${r.totalAmount.toStringAsFixed(2)})',
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.lines, required this.l10n});
  final List<TransactionLineEntry> lines;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final subtotal = lines.fold<double>(0, (sum, l) => sum + l.amount);
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _AmountRow(label: l10n.subtotal, amount: subtotal),
            const SizedBox(height: 8),
            _AmountRow(label: l10n.tax, amount: 0.0),
            const Divider(height: 24),
            _AmountRow(label: l10n.total, amount: subtotal, isTotal: true),
          ],
        ),
      ),
    );
  }
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
        ? const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0078D4),
          )
        : const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(amount.toStringAsFixed(2), style: style),
      ],
    );
  }
}
