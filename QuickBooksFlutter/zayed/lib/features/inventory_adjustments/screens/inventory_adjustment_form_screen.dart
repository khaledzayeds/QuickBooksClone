// inventory_adjustment_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zayed/l10n/app_localizations.dart';

import '../../../../app/router.dart';
import '../../../core/widgets/qb/qb_item_cell.dart';
import '../../../core/widgets/qb/qb_widgets.dart';
import '../../../core/constants/api_enums.dart' show AccountType;
import '../../../core/widgets/app_text_field.dart';
import '../../accounts/data/models/account_model.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../items/data/models/item_model.dart';
import '../../items/providers/items_provider.dart';
import '../../printing/widgets/document_print_preview_dialog.dart';
import '../../transactions/widgets/transaction_workspace_shell.dart';
import '../data/models/inventory_adjustment_model.dart';
import '../providers/inventory_adjustments_provider.dart';

class InventoryAdjustmentLineState {
  String? itemId;
  double quantityOnHand = 0;
  double newQuantity = 0;
  double quantityDifference = 0;
  double unitCost = 0;
  String description = '';

  double get total => quantityDifference.abs() * unitCost;
  bool get hasWork =>
      itemId != null ||
      quantityDifference != 0 ||
      newQuantity != 0 ||
      description.trim().isNotEmpty;
  bool get isValid =>
      itemId != null && itemId!.isNotEmpty && quantityDifference != 0;

  InventoryAdjustmentLineState copy() => InventoryAdjustmentLineState()
    ..itemId = itemId
    ..quantityOnHand = quantityOnHand
    ..newQuantity = newQuantity
    ..quantityDifference = quantityDifference
    ..unitCost = unitCost
    ..description = description;
}

class InventoryAdjustmentFormState {
  String adjustmentType = 'Quantity';
  String? adjustmentAccountId;
  DateTime adjustmentDate = DateTime.now();
  String referenceNo = 'AUTO';
  String memo = '';
  List<InventoryAdjustmentLineState> lines = List.generate(
    8,
    (_) => InventoryAdjustmentLineState(),
  );

  double get total => lines.fold(0, (sum, line) => sum + line.total);
  int get adjustedItems => lines.where((line) => line.isValid).length;
}

final inventoryAdjustmentFormProvider =
    StateProvider.autoDispose<InventoryAdjustmentFormState>(
      (ref) => InventoryAdjustmentFormState(),
    );

final inventoryAdjustmentSavingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class InventoryAdjustmentFormScreen extends ConsumerWidget {
  const InventoryAdjustmentFormScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(inventoryAdjustmentFormProvider);
    final saving = ref.watch(inventoryAdjustmentSavingProvider);
    final itemsAsync = ref.watch(itemsProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return TransactionWorkspaceShell(
      workspaceName: 'Inventory adjustment workspace',
      saving: saving,
      posting: false,
      isEdit: false,
      readOnly: false,
      showPagination: true,
      showSaveDraft: false,
      showSaveAndPrint: false,
      showPrint: true,
      showEmail: false,
      showEditNotes: false,
      showVoid: false,
      onFind: () => context.go(AppRoutes.inventoryAdjustments),
      onPrevious: null,
      onNext: null,
      onNew: () => _reset(ref),
      onSave: saving ? null : () => _save(context, ref, resetAfterSave: false),
      onPrint: saving
          ? null
          : () => _save(
              context,
              ref,
              resetAfterSave: false,
              printAfterSave: true,
            ),
      onSaveAndNew: saving
          ? null
          : () => _save(context, ref, resetAfterSave: true),
      onClear: () => _reset(ref),
      onClose: () => context.canPop()
          ? context.pop()
          : context.go(AppRoutes.inventoryAdjustments),
      formContent: _InventoryAdjustmentWorkspace(
        form: form,
        itemsAsync: itemsAsync,
        accountsAsync: accountsAsync,
        saving: saving,
        onSaveAndClose: saving
            ? null
            : () => _save(context, ref, resetAfterSave: false),
        onSaveAndNew: saving
            ? null
            : () => _save(context, ref, resetAfterSave: true),
        onClear: () => _reset(ref),
      ),
      contextPanel: _InventoryAdjustmentSidePanel(form: form),
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref, {
    required bool resetAfterSave,
    bool printAfterSave = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final form = ref.read(inventoryAdjustmentFormProvider);
    final lines = form.lines.where((line) => line.isValid).toList();

    if (form.adjustmentAccountId == null || form.adjustmentAccountId!.isEmpty) {
      _error(context, l10n.selectPaymentAccountFirst);
      return;
    }
    if (lines.isEmpty) {
      _error(context, l10n.selectItemFirst);
      return;
    }

    ref.read(inventoryAdjustmentSavingProvider.notifier).state = true;
    String? failure;
    String? firstSavedId;
    for (final line in lines) {
      final dto = CreateInventoryAdjustmentDto(
        itemId: line.itemId!,
        adjustmentAccountId: form.adjustmentAccountId!,
        adjustmentDate: form.adjustmentDate,
        quantityChange: line.quantityDifference,
        unitCost: line.unitCost > 0 ? line.unitCost : null,
        reason: [
          line.description,
          form.memo,
        ].where((part) => part.trim().isNotEmpty).join(' - '),
      );
      final result = await ref
          .read(inventoryAdjustmentsProvider.notifier)
          .create(dto);
      if (!context.mounted) return;
      result.when(
        success: (saved) => firstSavedId ??= saved.id,
        failure: (error) => failure ??= error.message,
      );
      if (failure != null) break;
    }
    ref.read(inventoryAdjustmentSavingProvider.notifier).state = false;

    if (!context.mounted) return;
    if (failure != null) {
      _error(context, failure!);
      return;
    }

    ref.read(itemsProvider.notifier).refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.inventoryAdjustmentSavedSuccess)),
    );
    if (printAfterSave && firstSavedId != null) {
      await printDocumentUsingSettings(
        context: context,
        ref: ref,
        documentType: 'inventory-adjustment',
        documentId: firstSavedId!,
      );
      if (!context.mounted) return;
    }
    if (resetAfterSave) {
      _reset(ref);
    } else {
      context.go(AppRoutes.inventoryAdjustments);
    }
  }

  static void _error(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

void _reset(WidgetRef ref) {
  ref.read(inventoryAdjustmentFormProvider.notifier).state =
      InventoryAdjustmentFormState();
}

class _InventoryAdjustmentWorkspace extends ConsumerWidget {
  const _InventoryAdjustmentWorkspace({
    required this.form,
    required this.itemsAsync,
    required this.accountsAsync,
    required this.saving,
    required this.onClear,
    this.onSaveAndClose,
    this.onSaveAndNew,
  });

  final InventoryAdjustmentFormState form;
  final AsyncValue<List<ItemModel>> itemsAsync;
  final AsyncValue<List<AccountModel>> accountsAsync;
  final bool saving;
  final VoidCallback onClear;
  final VoidCallback? onSaveAndClose;
  final VoidCallback? onSaveAndNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryItems = itemsAsync.maybeWhen(
      data: (items) =>
          items.where((item) => item.isActive && item.isInventory).toList(),
      orElse: () => <ItemModel>[],
    );
    final adjustmentAccounts = accountsAsync.maybeWhen(
      data: (accounts) => accounts
          .where(
            (account) =>
                account.isActive &&
                (account.accountType == AccountType.expense ||
                    account.accountType == AccountType.costOfGoodsSold ||
                    account.accountType == AccountType.otherExpense ||
                    account.accountType == AccountType.income ||
                    account.accountType == AccountType.otherIncome),
          )
          .toList(),
      orElse: () => <AccountModel>[],
    );
    final safeAccountId =
        adjustmentAccounts.any(
          (account) => account.id == form.adjustmentAccountId,
        )
        ? form.adjustmentAccountId
        : null;

    return Column(
      children: [
        _AdjustmentHeader(
          form: form,
          accounts: adjustmentAccounts,
          safeAccountId: safeAccountId,
        ),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F9FA),
            border: Border(
              top: BorderSide(color: Color(0xFFB7C3CB)),
              bottom: BorderSide(color: Color(0xFFB7C3CB)),
            ),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _ensureBlankLine(ref, form),
                icon: const Icon(Icons.search, size: 16),
                label: const Text('Find & Select Items...'),
                style: _smallButton(),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: form.lines.any((line) => line.isValid)
                    ? () => _setQtyToZero(ref, form)
                    : null,
                style: _smallButton(),
                child: const Text('Set Qty to Zero'),
              ),
              const Spacer(),
              Text(
                'Tab moves across cells - negative difference reduces stock',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF596B74),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: _AdjustmentLinesGrid(form: form, items: inventoryItems),
          ),
        ),
        _AdjustmentFooter(
          form: form,
          saving: saving,
          onClear: onClear,
          onSaveAndClose: onSaveAndClose,
          onSaveAndNew: onSaveAndNew,
        ),
      ],
    );
  }

  ButtonStyle _smallButton() => OutlinedButton.styleFrom(
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    side: const BorderSide(color: Color(0xFF8FA1AB)),
  );
}

class _AdjustmentHeader extends ConsumerWidget {
  const _AdjustmentHeader({
    required this.form,
    required this.accounts,
    required this.safeAccountId,
  });

  final InventoryAdjustmentFormState form;
  final List<AccountModel> accounts;
  final String? safeAccountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('dd/MM/yyyy');
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
                const QbStripLabel('ADJUSTMENT ACCOUNT'),
                const SizedBox(width: 8),
                Expanded(
                  child: _AccountDropdown(
                    value: safeAccountId,
                    accounts: accounts,
                    onChanged: (value) =>
                        _update(ref, form..adjustmentAccountId = value),
                  ),
                ),
                const SizedBox(width: 16),
                const QbStripLabel('ADJUSTMENT TYPE'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 190,
                  height: 30,
                  child: DropdownButtonFormField<String>(
                    initialValue: form.adjustmentType,
                    decoration: const InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Quantity',
                        child: Text('Quantity'),
                      ),
                      DropdownMenuItem(value: 'Value', child: Text('Value')),
                    ],
                    onChanged: (value) => _update(
                      ref,
                      form..adjustmentType = value ?? 'Quantity',
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 150,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 320,
                    child: Text(
                      'Inventory Adjustment',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w300,
                            color: const Color(0xFF243E4A),
                          ),
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    child: Column(
                      children: [
                        QbHorizontalField(
                          label: 'DATE',
                          labelWidth: 100,
                          child: QbDateBox(
                            text: dateFmt.format(form.adjustmentDate),
                            enabled: true,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: form.adjustmentDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                _update(ref, form..adjustmentDate = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 6),
                        QbHorizontalField(
                          label: 'REFERENCE NO.',
                          labelWidth: 100,
                          child: QbStaticBox(text: form.referenceNo),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: QbStackedField(
                      label: 'MEMO',
                      child: AppTextField(
                        label: '',
                        initialValue: form.memo,
                        onChanged: (value) => _update(ref, form..memo = value),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustmentLinesGrid extends ConsumerWidget {
  const _AdjustmentLinesGrid({required this.form, required this.items});

  final InventoryAdjustmentFormState form;
  final List<ItemModel> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF9EADB6)),
      ),
      child: Column(
        children: [
          Container(
            height: 30,
            color: const Color(0xFFDDE8ED),
            child: const Row(
              children: [
                _HeaderCell('ITEM', flex: 4),
                _HeaderCell('DESCRIPTION', flex: 5),
                _HeaderCell('QTY ON HAND', flex: 2, right: true),
                _HeaderCell('NEW QUANTITY', flex: 2, right: true),
                _HeaderCell('QTY DIFFERENCE', flex: 2, right: true),
                _HeaderCell('UNIT COST', flex: 2, right: true),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: form.lines.length,
              itemBuilder: (context, index) {
                final line = form.lines[index];
                final selectedItem = items
                    .where((item) => item.id == line.itemId)
                    .firstOrNull;
                return _AdjustmentLineRow(
                  shaded: index.isEven,
                  line: line,
                  selectedItem: selectedItem,
                  items: items,
                  onChanged: () => _update(ref, form),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustmentLineRow extends StatefulWidget {
  const _AdjustmentLineRow({
    required this.shaded,
    required this.line,
    required this.selectedItem,
    required this.items,
    required this.onChanged,
  });

  final bool shaded;
  final InventoryAdjustmentLineState line;
  final ItemModel? selectedItem;
  final List<ItemModel> items;
  final VoidCallback onChanged;

  @override
  State<_AdjustmentLineRow> createState() => _AdjustmentLineRowState();
}

class _AdjustmentLineRowState extends State<_AdjustmentLineRow> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasFocus = _focusNode.hasFocus;

    return Container(
      height: 44,
      color: widget.shaded ? const Color(0xFFDDEFF4) : Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasFocus ? cs.primary : const Color(0xFFB7C3CB),
                    width: hasFocus ? 1.5 : 1.0,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
                child: QbItemCell(
                  initialValue: widget.selectedItem?.name ?? '',
                  items: widget.items,
                  loadingItems: false,
                  compact: true,
                  focusNode: _focusNode,
                  rateForItem: (item) => item.purchasePrice,
                  onPicked: (item) {
                    widget.line
                      ..itemId = item.id
                      ..quantityOnHand = item.quantityOnHand
                      ..newQuantity = item.quantityOnHand
                      ..quantityDifference = 0
                      ..unitCost = item.purchasePrice
                      ..description = item.name;
                    widget.onChanged();
                  },
                ),
              ),
            ),
          ),
          _TextCell(widget.line.description, flex: 5),
          _TextCell(
            widget.line.quantityOnHand.toStringAsFixed(2),
            flex: 2,
            right: true,
          ),
          _NumberCell(
            value: widget.line.itemId == null
                ? ''
                : widget.line.newQuantity.toStringAsFixed(2),
            flex: 2,
            onChanged: (value) {
              final parsed = double.tryParse(value);
              if (parsed == null) return;
              widget.line
                ..newQuantity = parsed
                ..quantityDifference = parsed - widget.line.quantityOnHand;
              widget.onChanged();
            },
          ),
          _NumberCell(
            value: widget.line.quantityDifference == 0
                ? ''
                : widget.line.quantityDifference.toStringAsFixed(2),
            flex: 2,
            signed: true,
            onChanged: (value) {
              final parsed = double.tryParse(value);
              if (parsed == null) return;
              widget.line
                ..quantityDifference = parsed
                ..newQuantity = widget.line.quantityOnHand + parsed;
              widget.onChanged();
            },
          ),
          _NumberCell(
            value: widget.line.unitCost == 0
                ? ''
                : widget.line.unitCost.toStringAsFixed(2),
            flex: 2,
            onChanged: (value) {
              widget.line.unitCost = double.tryParse(value) ?? 0;
              widget.onChanged();
            },
          ),
        ],
      ),
    );
  }
}

class _AdjustmentFooter extends StatelessWidget {
  const _AdjustmentFooter({
    required this.form,
    required this.saving,
    required this.onClear,
    this.onSaveAndClose,
    this.onSaveAndNew,
  });

  final InventoryAdjustmentFormState form;
  final bool saving;
  final VoidCallback onClear;
  final VoidCallback? onSaveAndClose;
  final VoidCallback? onSaveAndNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8F9),
        border: Border(top: BorderSide(color: Color(0xFFB7C3CB))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          SizedBox(
            width: 320,
            child: Column(
              children: [
                _TotalLine(
                  label: 'Total Value of Adjustment',
                  value: form.total.toStringAsFixed(2),
                ),
                const SizedBox(height: 6),
                _TotalLine(
                  label: 'Number of Item Adjustments',
                  value: form.adjustedItems.toString(),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: saving ? null : onSaveAndClose,
                      style: _smallButton(),
                      child: Text(saving ? 'Saving...' : 'Save & Close'),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: saving ? null : onSaveAndNew,
                      style: _smallButton(),
                      child: const Text('Save & New'),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: onClear,
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

class _InventoryAdjustmentSidePanel extends StatelessWidget {
  const _InventoryAdjustmentSidePanel({required this.form});

  final InventoryAdjustmentFormState form;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
          decoration: const BoxDecoration(
            color: Color(0xFF264D5B),
            border: Border(bottom: BorderSide(color: Color(0xFF183642))),
          ),
          child: const Text(
            'Inventory Adjustment',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
          color: form.adjustedItems == 0
              ? const Color(0xFFFFE7C4)
              : const Color(0xFFDFF0E4),
          child: Text(
            form.adjustedItems == 0
                ? 'Select items and enter quantity differences.'
                : '${form.adjustedItems} item adjustment(s) ready.',
            style: TextStyle(
              color: form.adjustedItems == 0
                  ? const Color(0xFF714600)
                  : const Color(0xFF1B7D2B),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        QbSideSection(
          title: 'Summary',
          child: Column(
            children: [
              QbInfoRow(label: 'Type', value: form.adjustmentType),
              QbInfoRow(label: 'Items', value: form.adjustedItems.toString()),
              QbInfoRow(
                label: 'Value',
                value: form.total.toStringAsFixed(2),
                strong: true,
              ),
            ],
          ),
        ),
        Expanded(
          child: QbSideSection(
            title: 'Memo',
            child: Text(
              form.memo.trim().isEmpty ? 'No memo added.' : form.memo.trim(),
              style: const TextStyle(color: Color(0xFF4E616A)),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.value,
    required this.accounts,
    required this.onChanged,
  });

  final String? value;
  final List<AccountModel> accounts;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(),
        ),
        hint: const Text('Select account'),
        items: accounts
            .map(
              (account) => DropdownMenuItem(
                value: account.id,
                child: Text('${account.code}  ${account.name}'),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {required this.flex, this.right = false});
  final String text;
  final int flex;
  final bool right;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        textAlign: right ? TextAlign.end : TextAlign.start,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF53656E),
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _TextCell extends StatelessWidget {
  const _TextCell(this.text, {required this.flex, this.right = false});
  final String text;
  final int flex;
  final bool right;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Container(
      height: double.infinity,
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFB8C6CE))),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF273F4B),
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _NumberCell extends StatelessWidget {
  const _NumberCell({
    required this.value,
    required this.flex,
    required this.onChanged,
    this.signed = false,
  });

  final String value;
  final int flex;
  final bool signed;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: TextFormField(
        initialValue: value,
        textAlign: TextAlign.end,
        keyboardType: TextInputType.numberWithOptions(
          decimal: true,
          signed: signed,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            RegExp(signed ? r'[-0-9.]' : r'[0-9.]'),
          ),
        ],
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        ),
        onChanged: onChanged,
      ),
    ),
  );
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF263C46),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Text(
        value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF263C46),
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

void _ensureBlankLine(WidgetRef ref, InventoryAdjustmentFormState form) {
  if (form.lines.any((line) => !line.hasWork)) return;
  form.lines.add(InventoryAdjustmentLineState());
  _update(ref, form);
}

void _setQtyToZero(WidgetRef ref, InventoryAdjustmentFormState form) {
  for (final line in form.lines.where((line) => line.itemId != null)) {
    line
      ..newQuantity = 0
      ..quantityDifference = -line.quantityOnHand;
  }
  _update(ref, form);
}

void _update(WidgetRef ref, InventoryAdjustmentFormState old) {
  ref
      .read(inventoryAdjustmentFormProvider.notifier)
      .state = InventoryAdjustmentFormState()
    ..adjustmentType = old.adjustmentType
    ..adjustmentAccountId = old.adjustmentAccountId
    ..adjustmentDate = old.adjustmentDate
    ..referenceNo = old.referenceNo
    ..memo = old.memo
    ..lines = old.lines.map((line) => line.copy()).toList();
}
