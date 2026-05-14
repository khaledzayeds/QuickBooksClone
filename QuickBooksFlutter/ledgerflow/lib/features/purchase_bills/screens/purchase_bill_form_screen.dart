// purchase_bill_form_screen.dart
// QuickBooks-style Bill form with sidebar and Inventory Receipt linking.
// Supports direct opening from /purchases/bills/new?receiptId=...

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerflow/app/router.dart';
import 'package:ledgerflow/l10n/app_localizations.dart';

import '../../../../core/widgets/qb/qb_transaction_line_grid.dart';
import '../../../../core/widgets/qb/transaction_line_price_mode.dart';
import '../../purchase_orders/data/models/order_line_entry.dart';
import '../../receive_inventory/data/models/receive_inventory_model.dart';
import '../../receive_inventory/providers/receive_inventory_provider.dart';
import '../../transactions/widgets/transaction_context_sidebar.dart';
import '../../transactions/widgets/transaction_models.dart';
import '../../vendors/data/models/vendor_model.dart';
import '../../vendors/providers/vendors_provider.dart';
import '../data/models/billing_plan_model.dart';
import '../data/models/create_purchase_bill_dto.dart';
import '../providers/purchase_bills_provider.dart';

class PurchaseBillFormScreen extends ConsumerStatefulWidget {
  const PurchaseBillFormScreen({
    super.key,
    this.inventoryReceiptId,
    this.billId,
  });
  final String? inventoryReceiptId;
  final String? billId;

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

  bool _loadingInitialReceipt = false;
  bool _loadingPlan = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _lines.add(TransactionLineEntry());
    if (widget.billId != null && widget.billId!.isNotEmpty) {
      Future.microtask(_loadExistingBill);
    } else if (widget.inventoryReceiptId != null &&
        widget.inventoryReceiptId!.isNotEmpty) {
      Future.microtask(_loadInitialReceipt);
    }
  }

  Future<void> _loadExistingBill() async {
    final billId = widget.billId;
    if (billId == null || billId.isEmpty) return;

    setState(() => _loadingInitialReceipt = true);
    try {
      final result = await ref
          .read(purchaseBillsRepositoryProvider)
          .getBill(billId);
      if (!mounted) return;
      result.when(
        success: (bill) {
          setState(() {
            _selectedVendor = VendorModel(
              id: bill.vendorId,
              displayName: bill.vendorName,
              isActive: true,
              balance: bill.balanceDue,
              creditBalance: bill.creditAppliedAmount,
            );
            _billDate = bill.billDate;
            _dueDate = bill.dueDate;
            _memoCtrl.text = bill.memo ?? '';
            _clearLines();
            _lines.addAll(
              bill.lines.isEmpty
                  ? [TransactionLineEntry()]
                  : bill.lines.map((line) {
                      final entry = TransactionLineEntry(
                        itemId: line.itemId,
                        itemName: line.itemName.isEmpty
                            ? line.description
                            : line.itemName,
                        qty: line.quantity,
                        rate: line.unitCost,
                        inventoryReceiptLineId: line.inventoryReceiptLineId,
                      );
                      entry.descCtrl.text = line.description;
                      entry.qtyCtrl.text = line.quantity.toStringAsFixed(2);
                      entry.rateCtrl.text = line.unitCost.toStringAsFixed(2);
                      return entry;
                    }).toList(),
            );
          });
        },
        failure: (e) => _showError(e.message),
      );
    } finally {
      if (mounted) setState(() => _loadingInitialReceipt = false);
    }
  }

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

  Future<void> _loadInitialReceipt() async {
    final receiptId = widget.inventoryReceiptId;
    if (receiptId == null || receiptId.isEmpty) return;

    setState(() => _loadingInitialReceipt = true);
    try {
      final result = await ref
          .read(receiveInventoryRepoProvider)
          .getById(receiptId);
      if (!mounted) return;
      result.when(
        success: (receipt) async {
          setState(() {
            _selectedVendor = VendorModel(
              id: receipt.vendorId,
              displayName: receipt.vendorName,
              isActive: true,
              balance: 0,
              creditBalance: 0,
            );
          });
          await _onReceiptChanged(receipt);
        },
        failure: (e) => _showError(e.message),
      );
    } finally {
      if (mounted) setState(() => _loadingInitialReceipt = false);
    }
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
      if (receipt != null) {
        _selectedVendor = VendorModel(
          id: receipt.vendorId,
          displayName: receipt.vendorName,
          isActive: true,
          balance: _selectedVendor?.balance ?? 0,
          creditBalance: _selectedVendor?.creditBalance ?? 0,
        );
      }
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
              entry.qtyCtrl.text = lp.suggestedBillQuantity.toStringAsFixed(2);
              entry.rateCtrl.text = lp.unitCost.toStringAsFixed(2);
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

    if (_dueDate.isBefore(_billDate)) {
      _showError('${l10n.dueDate} < ${l10n.billDate}');
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
          ref.invalidate(receiveInventoryListProvider);
          if (_selectedReceipt != null) {
            ref.invalidate(
              receiveInventoryDetailsProvider(_selectedReceipt!.id),
            );
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.billCreatedSuccess)));
          if (context.canPop()) {
            context.pop();
          } else if (_selectedReceipt != null) {
            context.go(
              AppRoutes.receiveInventoryDetails.replaceFirst(
                ':id',
                _selectedReceipt!.id,
              ),
            );
          } else {
            context.go(AppRoutes.purchaseBills);
          }
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
    final vendors = ref
        .watch(vendorsProvider)
        .maybeWhen(
          data: (items) => items.where((vendor) => vendor.isActive).toList(),
          orElse: () => const <VendorModel>[],
        );

    if (_loadingInitialReceipt) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF0),
      body: SafeArea(
        child: Column(
          children: [
            _BillCommandBar(
              saving: _saving || _loadingPlan,
              onFind: () => context.go(AppRoutes.purchaseBills),
              onNew: () => context.go(AppRoutes.purchaseBillNew),
              onSave: _saving || _loadingPlan ? null : _save,
              onClear: () {
                setState(() {
                  _selectedVendor = null;
                  _selectedReceipt = null;
                  _activePlan = null;
                  _billDate = DateTime.now();
                  _dueDate = DateTime.now().add(const Duration(days: 30));
                  _memoCtrl.clear();
                  _clearLines();
                  _lines.add(TransactionLineEntry());
                });
              },
              onClose: () => context.go(AppRoutes.purchaseBills),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(10, 8, 0, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFB9C3CA)),
                      ),
                      child: Column(
                        children: [
                          _BillHeader(
                            l10n: l10n,
                            vendors: vendors,
                            selectedVendor: _selectedVendor,
                            selectedReceipt: _selectedReceipt,
                            billDate: _billDate,
                            dueDate: _dueDate,
                            onVendorChanged: _onVendorChanged,
                            onReceiptChanged: _onReceiptChanged,
                            onBillDateChanged: (d) =>
                                setState(() => _billDate = d),
                            onDueDateChanged: (d) =>
                                setState(() => _dueDate = d),
                          ),
                          _LinesHeader(
                            loading: _loadingPlan,
                            onAddLine: () => setState(
                              () => _lines.add(TransactionLineEntry()),
                            ),
                          ),
                          Expanded(
                            child: _loadingPlan
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      8,
                                      8,
                                      8,
                                      0,
                                    ),
                                    child: QbTransactionLineGrid(
                                      lines: _lines,
                                      onChanged: () => setState(() {}),
                                      priceMode:
                                          TransactionLinePriceMode.purchase,
                                      fillWidth: true,
                                      compact: true,
                                      showAddLineFooter: false,
                                    ),
                                  ),
                          ),
                          _BillFooter(
                            l10n: l10n,
                            lines: _lines,
                            memoCtrl: _memoCtrl,
                            saving: _saving,
                            onSave: _saving || _loadingPlan ? null : _save,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _CollapsibleBillPanel(
                    child: _BillContextPanel(
                      vendor: _selectedVendor,
                      receipt: _selectedReceipt,
                      total: _lines.fold<double>(
                        0,
                        (sum, line) => sum + line.amount,
                      ),
                      notes: _memoCtrl.text,
                      onViewAll: _selectedVendor == null
                          ? null
                          : () => context.go(AppRoutes.purchaseBills),
                    ),
                  ),
                ],
              ),
            ),
            const _BillShortcutStrip(),
          ],
        ),
      ),
    );
  }
}

class _BillCommandBar extends StatelessWidget {
  const _BillCommandBar({
    required this.saving,
    required this.onFind,
    required this.onNew,
    required this.onClear,
    required this.onClose,
    this.onSave,
  });

  final bool saving;
  final VoidCallback onFind;
  final VoidCallback onNew;
  final VoidCallback onClear;
  final VoidCallback onClose;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F6F7),
        border: Border(bottom: BorderSide(color: Color(0xFFB7C3CB))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const _Tool(icon: Icons.arrow_back, label: 'Prev'),
          const _Tool(icon: Icons.arrow_forward, label: 'Next'),
          _Tool(
            icon: Icons.search,
            label: 'Find',
            onTap: saving ? null : onFind,
          ),
          _Tool(
            icon: Icons.note_add_outlined,
            label: 'New',
            onTap: saving ? null : onNew,
          ),
          _Tool(
            icon: saving ? Icons.hourglass_top : Icons.save_outlined,
            label: saving ? 'Saving' : 'Save',
            onTap: onSave,
          ),
          _Tool(
            icon: Icons.delete_outline,
            label: 'Clear',
            onTap: saving ? null : onClear,
          ),
          const _Separator(),
          const _Tool(icon: Icons.print_outlined, label: 'Print'),
          const _Tool(icon: Icons.mail_outline, label: 'Email'),
          const Spacer(),
          _Tool(
            icon: Icons.close,
            label: 'Close',
            onTap: saving ? null : onClose,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _BillHeader extends StatelessWidget {
  const _BillHeader({
    required this.l10n,
    required this.vendors,
    required this.selectedVendor,
    required this.selectedReceipt,
    required this.billDate,
    required this.dueDate,
    required this.onVendorChanged,
    required this.onReceiptChanged,
    required this.onBillDateChanged,
    required this.onDueDateChanged,
  });

  final AppLocalizations l10n;
  final List<VendorModel> vendors;
  final VendorModel? selectedVendor;
  final ReceiveInventoryModel? selectedReceipt;
  final DateTime billDate;
  final DateTime dueDate;
  final ValueChanged<VendorModel> onVendorChanged;
  final ValueChanged<ReceiveInventoryModel?> onReceiptChanged;
  final ValueChanged<DateTime> onBillDateChanged;
  final ValueChanged<DateTime> onDueDateChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF264D5B),
              border: Border(bottom: BorderSide(color: Color(0xFF183642))),
            ),
            child: Row(
              children: [
                const _StripLabel('VENDOR'),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: _InlineVendorField(
                    vendors: vendors,
                    selected: selectedVendor,
                    onSelected: (vendor) {
                      if (vendor != null) onVendorChanged(vendor);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                const _StripLabel('RECEIPT'),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _ReceiptPicker(
                    vendorId: selectedVendor?.id,
                    value: selectedReceipt,
                    onChanged: onReceiptChanged,
                    compact: true,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 128,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 230,
                    child: Text(
                      'Enter Bills',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF243E4A),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: Column(
                      children: [
                        _HorizontalField(
                          label: 'DATE',
                          child: _DatePickerField(
                            label: '',
                            value: billDate,
                            onChanged: onBillDateChanged,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const _HorizontalField(
                          label: 'BILL #',
                          child: _StaticBox(text: 'AUTO'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 240,
                    child: _DatePickerField(
                      label: 'DUE DATE',
                      value: dueDate,
                      onChanged: onDueDateChanged,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineVendorField extends StatelessWidget {
  const _InlineVendorField({
    required this.vendors,
    required this.selected,
    required this.onSelected,
  });

  final List<VendorModel> vendors;
  final VendorModel? selected;
  final ValueChanged<VendorModel?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<VendorModel>(
      key: ValueKey(selected?.id ?? 'bill-vendor'),
      displayStringForOption: (vendor) => vendor.displayName,
      initialValue: TextEditingValue(text: selected?.displayName ?? ''),
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return vendors.take(20);
        return vendors
            .where((vendor) => vendor.displayName.toLowerCase().contains(query))
            .take(20);
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return SizedBox(
          height: 30,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(Icons.search, size: 16),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              border: OutlineInputBorder(),
              hintText: 'Select vendor',
            ),
          ),
        );
      },
    );
  }
}

class _LinesHeader extends StatelessWidget {
  const _LinesHeader({required this.loading, required this.onAddLine});

  final bool loading;
  final VoidCallback onAddLine;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFE9EFF2),
        border: Border(
          top: BorderSide(color: Color(0xFFB7C3CB)),
          bottom: BorderSide(color: Color(0xFFB7C3CB)),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Products and Services',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF233F4C),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Tab moves across cells • Enter commits row',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF596B74),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: loading ? null : onAddLine,
            icon: const Icon(Icons.add, size: 15),
            label: const Text('Add Line'),
          ),
        ],
      ),
    );
  }
}

class _BillFooter extends StatelessWidget {
  const _BillFooter({
    required this.l10n,
    required this.lines,
    required this.memoCtrl,
    required this.saving,
    this.onSave,
  });

  final AppLocalizations l10n;
  final List<TransactionLineEntry> lines;
  final TextEditingController memoCtrl;
  final bool saving;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8F9),
        border: Border(top: BorderSide(color: Color(0xFFB7C3CB))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('MEMO'),
                const SizedBox(height: 4),
                SizedBox(
                  height: 34,
                  child: TextField(
                    controller: memoCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Optional',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(
            width: 310,
            child: Column(
              children: [
                _TotalsCard(lines: lines, l10n: l10n),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: onSave,
                      style: _smallButton(),
                      child: Text(saving ? 'Saving...' : 'Save & Close'),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: null,
                      style: _smallButton(),
                      child: const Text('Save & New'),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: null,
                      style: _smallButton(),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _smallButton() => OutlinedButton.styleFrom(
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    side: const BorderSide(color: Color(0xFF8FA1AB)),
  );
}

class _CollapsibleBillPanel extends StatefulWidget {
  const _CollapsibleBillPanel({required this.child});
  final Widget child;

  @override
  State<_CollapsibleBillPanel> createState() => _CollapsibleBillPanelState();
}

class _CollapsibleBillPanelState extends State<_CollapsibleBillPanel> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: _expanded ? 258 : 38,
      margin: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: const Color(0xFFB9C3CA)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          if (_expanded) Positioned.fill(child: widget.child),
          Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: const Color(0xFFE6EEF2),
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    _expanded ? Icons.chevron_right : Icons.chevron_left,
                    size: 22,
                    color: const Color(0xFF2B4A56),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillContextPanel extends StatelessWidget {
  const _BillContextPanel({
    required this.vendor,
    required this.receipt,
    required this.total,
    required this.notes,
    this.onViewAll,
  });

  final VendorModel? vendor;
  final ReceiveInventoryModel? receipt;
  final double total;
  final String notes;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final v = vendor;
    return TransactionContextSidebar(
      title: v?.displayName ?? '',
      subtitle: v?.companyName,
      initials: v == null ? null : _initials(v.displayName),
      emptyTitle: 'Select a vendor',
      emptyMessage: 'Choose a vendor to see open bills and recent activity.',
      partyTabLabel: 'Vendor',
      warning: v == null
          ? null
          : receipt == null
          ? 'Standalone vendor bill.'
          : 'Billing receipt ${receipt!.receiptNumber.isEmpty ? receipt!.id.substring(0, 8) : receipt!.receiptNumber}.',
      metrics: [
        TransactionContextMetric(
          label: 'Bill value',
          value: '${total.toStringAsFixed(2)} EGP',
          icon: Icons.receipt_long_outlined,
        ),
        TransactionContextMetric(
          label: 'Receipt',
          value: receipt?.receiptNumber.isNotEmpty == true
              ? receipt!.receiptNumber
              : 'Standalone',
          icon: Icons.inventory_2_outlined,
        ),
      ],
      activities: [
        if (receipt != null)
          TransactionContextActivity(
            title: receipt!.receiptNumber.isEmpty
                ? receipt!.id.substring(0, 8)
                : receipt!.receiptNumber,
            subtitle: 'Inventory receipt',
            amount: '${receipt!.totalAmount.toStringAsFixed(2)} EGP',
          ),
      ],
      notes: notes,
      totals: TransactionTotalsUiModel(
        subtotal: total,
        total: total,
        paid: 0,
        balanceDue: total,
        currency: 'EGP',
      ),
      onViewAll: onViewAll,
    );
  }

  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'V';
    final parts = trimmed.split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _BillShortcutStrip extends StatelessWidget {
  const _BillShortcutStrip();

  @override
  Widget build(BuildContext context) => Container(
    height: 24,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    alignment: Alignment.centerLeft,
    decoration: const BoxDecoration(
      color: Color(0xFFD4DDE3),
      border: Border(top: BorderSide(color: Color(0xFFAFBBC4))),
    ),
    child: Text(
      'Enter bills workspace  •  Save & Close  •  Ctrl+P Print  •  Esc Close',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: const Color(0xFF33434C),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled ? const Color(0xFF234C5D) : const Color(0xFF7D8B93);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        height: 74,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: enabled ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 48,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: const Color(0xFFC4D0D6),
  );
}

class _StripLabel extends StatelessWidget {
  const _StripLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: const Color(0xFF53656E),
      fontWeight: FontWeight.w900,
    ),
  );
}

class _StaticBox extends StatelessWidget {
  const _StaticBox({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    height: 34,
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFB7C3CB)),
    ),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );
}

class _HorizontalField extends StatelessWidget {
  const _HorizontalField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 82, child: _FieldLabel(label)),
      Expanded(child: child),
    ],
  );
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
  const _ReceiptPicker({
    this.vendorId,
    this.value,
    required this.onChanged,
    this.compact = false,
  });
  final String? vendorId;
  final ReceiveInventoryModel? value;
  final ValueChanged<ReceiveInventoryModel?> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (vendorId == null) {
      return IgnorePointer(
        child: Opacity(
          opacity: 0.5,
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: compact ? null : l10n.linkToRI,
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 7,
              ),
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
        final uniqueReceipts = <ReceiveInventoryModel>[];
        final seenReceiptIds = <String>{};
        for (final receipt in activeReceipts) {
          if (seenReceiptIds.add(receipt.id)) {
            uniqueReceipts.add(receipt);
          }
        }

        if (uniqueReceipts.isEmpty) {
          return InputDecorator(
            decoration: InputDecoration(
              labelText: compact ? null : l10n.linkToRI,
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 7,
              ),
            ),
            child: Text(
              l10n.noPendingRI,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          );
        }

        final selectedReceiptId =
            value != null && seenReceiptIds.contains(value!.id)
            ? value!.id
            : null;

        return DropdownButtonFormField<String?>(
          initialValue: selectedReceiptId,
          decoration: InputDecoration(
            labelText: compact ? null : l10n.linkToRI,
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 7,
            ),
            prefixIcon: compact ? null : const Icon(Icons.link),
          ),
          hint: Text(l10n.selectRI),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(l10n.clear)),
            ...uniqueReceipts.map(
              (r) => DropdownMenuItem<String?>(
                value: r.id,
                child: Text(
                  '${r.receiptNumber} (${r.totalAmount.toStringAsFixed(2)})',
                ),
              ),
            ),
          ],
          onChanged: (id) {
            final receipt = id == null
                ? null
                : uniqueReceipts
                      .where((receipt) => receipt.id == id)
                      .firstOrNull;
            onChanged(receipt);
          },
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
    final draftSubtotal = lines.fold<double>(0, (sum, l) => sum + l.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AmountRow(label: 'TOTAL', amount: draftSubtotal),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE7F1F4),
            border: Border.all(color: const Color(0xFF9DB2BC)),
          ),
          child: _AmountRow(
            label: 'BILL TOTAL',
            amount: draftSubtotal,
            isTotal: true,
          ),
        ),
      ],
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
