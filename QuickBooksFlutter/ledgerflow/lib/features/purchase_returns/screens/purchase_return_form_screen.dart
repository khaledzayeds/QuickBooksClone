// purchase_return_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../purchase_bills/data/models/purchase_bill_model.dart';
import '../../purchase_bills/providers/purchase_bills_provider.dart';
import '../../transactions/widgets/transaction_workspace_shell.dart';
import '../data/models/purchase_return_model.dart';
import '../providers/purchase_returns_provider.dart';

class PurchaseReturnLineState {
  PurchaseReturnLineState({
    required this.purchaseBillLineId,
    required this.description,
    required this.originalQuantity,
    required this.unitCost,
    this.quantity = 0,
  });

  final String purchaseBillLineId;
  final String description;
  final double originalQuantity;
  final double unitCost;
  double quantity;

  double get draftAmount => quantity * unitCost;
}

class PurchaseReturnFormScreen extends ConsumerStatefulWidget {
  const PurchaseReturnFormScreen({super.key, this.billId});

  final String? billId;

  @override
  ConsumerState<PurchaseReturnFormScreen> createState() =>
      _PurchaseReturnFormScreenState();
}

class _PurchaseReturnFormScreenState
    extends ConsumerState<PurchaseReturnFormScreen> {
  String? _purchaseBillId;
  final DateTime _returnDate = DateTime.now();
  List<PurchaseReturnLineState> _lines = [];
  bool _saving = false;
  bool _preselected = false;

  double get _draftTotal => _lines.fold(0, (sum, line) => sum + line.draftAmount);

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(purchaseBillsProvider);
    _tryPreselectBill(billsAsync);

    final bills = billsAsync.maybeWhen(
      data: (data) =>
          data.where((b) => b.status != 1 && b.status != 3 && b.lines.isNotEmpty).toList(),
      orElse: () => <PurchaseBillModel>[],
    );
    final selectedBill = bills.where((b) => b.id == _purchaseBillId).firstOrNull;

    final returns = ref.watch(purchaseReturnsProvider).maybeWhen(
          data: (items) => items,
          orElse: () => <PurchaseReturnModel>[],
        );

    return TransactionWorkspaceShell(
      workspaceName: 'Purchase return workspace',
      saving: _saving,
      posting: false,
      isEdit: false,
      readOnly: false,
      onFind: () => context.go(AppRoutes.purchaseReturns),
      onPrevious: returns.isNotEmpty
          ? () => context.go(
                AppRoutes.purchaseReturnDetails.replaceFirst(':id', returns.first.id),
              )
          : null,
      onNext: null,
      onNew: () {
        setState(() {
          _purchaseBillId = null;
          _lines = [];
          _preselected = false;
        });
      },
      onSave: _saving ? null : _save,
      onClear: () {
        setState(() {
          _purchaseBillId = null;
          _lines = [];
          _preselected = false;
        });
      },
      onClose: () => context.go(AppRoutes.purchaseReturns),
      showVoid: false,
      formContent: Column(
        children: [
          _ReturnHeader(
            bills: bills,
            selectedBillId: _purchaseBillId,
            returnDate: _returnDate,
            onBillChanged: _selectBill,
          ),
          Expanded(
            child: _LinesPanel(
              lines: _lines,
              onQuantityChanged: (index, qty) =>
                  setState(() => _lines[index].quantity = qty),
            ),
          ),
          _ReturnFooter(total: _draftTotal),
        ],
      ),
      contextPanel: _ReturnContextPanel(
        bill: selectedBill,
        total: _draftTotal,
        returnDate: _returnDate,
      ),
    );
  }

  void _tryPreselectBill(AsyncValue<List<PurchaseBillModel>> billsAsync) {
    if (_preselected) return;
    final billId = widget.billId;
    if (billId == null || billId.isEmpty) {
      _preselected = true;
      return;
    }
    billsAsync.whenData((bills) {
      final bill = bills.where((item) => item.id == billId).firstOrNull;
      if (bill == null) return;
      _preselected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _selectBill(bill);
      });
    });
  }

  void _selectBill(PurchaseBillModel? bill) {
    setState(() {
      if (bill == null) {
        _purchaseBillId = null;
        _lines = [];
        return;
      }
      _purchaseBillId = bill.id;
      _lines = _linesFromBill(bill);
    });
  }

  Future<void> _save() async {
    if (_purchaseBillId == null || _purchaseBillId!.isEmpty) {
      _error('Select a purchase bill first');
      return;
    }
    final validLines = _lines.where((line) => line.quantity > 0).toList();
    if (validLines.isEmpty) {
      _error('Enter a return quantity for at least one line');
      return;
    }
    for (final line in validLines) {
      if (line.quantity > line.originalQuantity) {
        _error('Return quantity cannot exceed billed quantity');
        return;
      }
    }

    final dto = CreatePurchaseReturnDto(
      purchaseBillId: _purchaseBillId!,
      returnDate: _returnDate,
      lines: validLines
          .map(
            (line) => CreatePurchaseReturnLineDto(
              purchaseBillLineId: line.purchaseBillLineId,
              quantity: line.quantity,
              unitCost: line.unitCost,
            ),
          )
          .toList(),
    );

    setState(() => _saving = true);
    final result = await ref.read(purchaseReturnsProvider.notifier).create(dto);
    if (!mounted) return;
    setState(() => _saving = false);

    result.when(
      success: (_) {
        ref.read(purchaseBillsProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase return saved and posted.')),
        );
        context.go(AppRoutes.purchaseReturns);
      },
      failure: (error) => _error(error.message),
    );
  }

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

List<PurchaseReturnLineState> _linesFromBill(PurchaseBillModel bill) =>
    bill.lines
        .map(
          (line) => PurchaseReturnLineState(
            purchaseBillLineId: line.id,
            description: line.description.isEmpty ? line.itemName : line.description,
            originalQuantity: line.quantity,
            unitCost: line.unitCost,
          ),
        )
        .toList();

// ── Form Sections ──────────────────────────────────────────────────────────

class _ReturnHeader extends StatelessWidget {
  const _ReturnHeader({
    required this.bills,
    required this.selectedBillId,
    required this.returnDate,
    required this.onBillChanged,
  });

  final List<PurchaseBillModel> bills;
  final String? selectedBillId;
  final DateTime returnDate;
  final ValueChanged<PurchaseBillModel?> onBillChanged;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final selected = bills.where((b) => b.id == selectedBillId).firstOrNull;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F7F8),
        border: Border(bottom: BorderSide(color: Color(0xFFB9C3CA))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: selectedBillId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Purchase Bill *',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt_long_outlined, size: 18),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              items: bills
                  .map(
                    (bill) => DropdownMenuItem<String>(
                      value: bill.id,
                      child: Text(
                        '${bill.billNumber}  ·  ${bill.vendorName}  ·  ${bill.totalAmount.toStringAsFixed(2)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                final bill = bills.where((b) => b.id == value).firstOrNull;
                onBillChanged(bill);
              },
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: TextFormField(
              readOnly: true,
              initialValue: fmt.format(returnDate),
              decoration: const InputDecoration(
                labelText: 'Return Date',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today_outlined, size: 16),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
          if (selected != null) ...[
            const SizedBox(width: 16),
            _HeaderStat(
              label: 'VENDOR',
              value: selected.vendorName,
            ),
            const SizedBox(width: 16),
            _HeaderStat(
              label: 'BILL TOTAL',
              value: selected.totalAmount.toStringAsFixed(2),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Color(0xFF7D8B93),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF264D5B),
            ),
          ),
        ],
      );
}

class _LinesPanel extends StatelessWidget {
  const _LinesPanel({required this.lines, required this.onQuantityChanged});

  final List<PurchaseReturnLineState> lines;
  final void Function(int index, double quantity) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.keyboard_return_outlined, size: 48, color: Color(0xFF8CA0AA)),
            const SizedBox(height: 12),
            Text(
              'Select a purchase bill to see its lines.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667A84),
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header row
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFE7EEF1),
            border: Border(bottom: BorderSide(color: Color(0xFFB9C3CA))),
          ),
          child: Row(
            children: const [
              Expanded(flex: 3, child: _ColHeader('Item / Description')),
              Expanded(child: _ColHeader('Bill Qty', right: true)),
              Expanded(child: _ColHeader('Return Qty', right: true)),
              Expanded(child: _ColHeader('Unit Cost', right: true)),
              Expanded(child: _ColHeader('Amount', right: true)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: lines.length,
            itemBuilder: (context, index) => _LineRow(
              index: index,
              line: lines[index],
              onQuantityChanged: onQuantityChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _ColHeader extends StatelessWidget {
  const _ColHeader(this.text, {this.right = false});
  final String text;
  final bool right;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          text,
          textAlign: right ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF53656E),
          ),
        ),
      );
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.index,
    required this.line,
    required this.onQuantityChanged,
  });

  final int index;
  final PurchaseReturnLineState line;
  final void Function(int index, double quantity) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E9ED))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              line.description,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E3540)),
            ),
          ),
          Expanded(
            child: Text(
              line.originalQuantity.toStringAsFixed(2),
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E3540)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: TextFormField(
                initialValue: line.quantity == 0 ? '' : line.quantity.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
                onChanged: (value) =>
                    onQuantityChanged(index, double.tryParse(value) ?? 0),
              ),
            ),
          ),
          Expanded(
            child: Text(
              line.unitCost.toStringAsFixed(2),
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E3540)),
            ),
          ),
          Expanded(
            child: Text(
              line.draftAmount.toStringAsFixed(2),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF264D5B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnFooter extends StatelessWidget {
  const _ReturnFooter({required this.total});
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F7F8),
        border: Border(top: BorderSide(color: Color(0xFFB9C3CA))),
      ),
      child: Row(
        children: [
          const Spacer(),
          const Text(
            'RETURN TOTAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF7D8B93),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            total.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF264D5B),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Context Panel ───────────────────────────────────────────────────────────

class _ReturnContextPanel extends StatelessWidget {
  const _ReturnContextPanel({
    required this.bill,
    required this.total,
    required this.returnDate,
  });

  final PurchaseBillModel? bill;
  final double total;
  final DateTime returnDate;

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
                  label: 'RETURN TOTAL',
                  value: total.toStringAsFixed(2),
                  isTotal: true,
                ),
                _Stat(label: 'RETURN DATE', value: fmt.format(returnDate)),
                if (bill != null) ...[
                  _Stat(label: 'VENDOR', value: bill!.vendorName),
                  _Stat(label: 'BILL #', value: bill!.billNumber),
                  _Stat(
                    label: 'BILL TOTAL',
                    value: bill!.totalAmount.toStringAsFixed(2),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
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
