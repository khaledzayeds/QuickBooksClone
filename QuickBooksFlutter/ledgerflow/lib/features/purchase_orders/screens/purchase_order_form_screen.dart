import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../items/providers/items_provider.dart';
import '../../vendors/providers/vendors_provider.dart';
import '../providers/purchase_orders_provider.dart';
import '../data/models/purchase_order_model.dart';
import '../../../../core/widgets/app_text_field.dart';


class PurchaseOrderFormScreen extends ConsumerStatefulWidget {
  const PurchaseOrderFormScreen({super.key});

  @override
  ConsumerState<PurchaseOrderFormScreen> createState() =>
      _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState
    extends ConsumerState<PurchaseOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Header fields
  String?  _vendorId;
  String   _vendorName  = '';
  DateTime _orderDate   = DateTime.now();
  DateTime? _expectedDate;
  final    _notesCtrl   = TextEditingController();

  // Lines
  final List<_LineEntry> _lines = [];

  bool _saving = false;
  int  _step   = 0; // 0=Vendor, 1=Lines, 2=Review

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final l in _lines) l.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  double get _total =>
      _lines.fold(0, (s, l) => s + l.quantity * l.unitCost);

  Future<void> _save(SaveMode mode) async {
    if (!_formKey.currentState!.validate()) return;
    if (_vendorId == null) {
      _showError('اختر المورد أولاً');
      return;
    }
    if (_lines.isEmpty) {
      _showError('أضف صنفاً واحداً على الأقل');
      return;
    }

    setState(() => _saving = true);
    try {
      final dto = CreatePurchaseOrderDto(
        vendorId:     _vendorId!,
        orderDate:    _orderDate,
        expectedDate: _expectedDate,
        notes:        _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        saveMode: mode,
        lines: _lines
            .map((l) => CreatePurchaseLineDto(
                  itemId:      l.itemId!,
                  quantity:    l.quantity,
                  unitCost:    l.unitCost,
                  description: l.descriptionCtrl.text.trim().isEmpty
                      ? null
                      : l.descriptionCtrl.text.trim(),
                ))
            .toList(),
      );

      final result = await ref
          .read(purchaseOrdersRepoProvider)
          .create(dto);

      result.when(
        success: (_) {
          ref.read(purchaseOrdersProvider.notifier).refresh();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('تم إنشاء أمر الشراء بنجاح ✅')),
            );
            context.pop();
          }
        },
        failure: (e) => _showError(e.message),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أمر شراء جديد'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _StepIndicator(current: _step),
        ),
      ),
      body: Form(
        key: _formKey,
        child: IndexedStack(
          index: _step,
          children: [
            _buildVendorStep(),
            _buildLinesStep(),
            _buildReviewStep(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ── Step 0: Vendor ────────────────────────────────────────────────────
  Widget _buildVendorStep() {
    final vendorsAsync = ref.watch(vendorsProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Vendor dropdown
        vendorsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('خطأ: $e'),
          data: (vendors) => DropdownButtonFormField<String>(
            value: _vendorId,
            decoration: const InputDecoration(
              labelText: 'المورد *',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            items: vendors
                .map((v) => DropdownMenuItem(
                      value: v.id,
                      child: Text(v.displayName),
                    ))
                .toList(),
            onChanged: (v) {
              setState(() {
                _vendorId   = v;
                _vendorName = vendors
                    .firstWhere((x) => x.id == v)
                    .displayName;
              });
            },
            validator: (v) => v == null ? 'اختر المورد' : null,
          ),
        ),

        const SizedBox(height: 16),

        // Order Date
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today_outlined),
          title: const Text('تاريخ الأمر'),
          subtitle: Text(DateFormat('yyyy/MM/dd').format(_orderDate)),
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _orderDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (d != null) setState(() => _orderDate = d);
          },
        ),

        const Divider(),

        // Expected Date
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event_outlined),
          title: const Text('تاريخ التسليم المتوقع'),
          subtitle: Text(_expectedDate != null
              ? DateFormat('yyyy/MM/dd').format(_expectedDate!)
              : 'اختياري'),
          trailing: _expectedDate != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _expectedDate = null),
                )
              : null,
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _expectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
            );
            if (d != null) setState(() => _expectedDate = d);
          },
        ),

        const SizedBox(height: 16),

        AppTextField(
          label: 'ملاحظات',
          controller: _notesCtrl,
          maxLines: 3,
          hint: 'ملاحظات اختيارية...',
        ),
      ],
    );
  }

  // ── Step 1: Lines ─────────────────────────────────────────────────────
  Widget _buildLinesStep() {
    final itemsAsync = ref.watch(itemsProvider);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ..._lines.asMap().entries.map((e) =>
                  _LineEditor(
                    entry:      e.value,
                    index:      e.key,
                    itemsAsync: itemsAsync,
                    onDelete: () => setState(() => _lines.removeAt(e.key)),
                    onChanged: () => setState(() {}),
                  )),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('إضافة صنف'),
                onPressed: () => setState(() => _lines.add(_LineEntry())),
              ),
            ],
          ),
        ),

        // Total bar
        Container(
          color: Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.3),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الإجمالي',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${_total.toStringAsFixed(2)} ج.م',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color:
                          Theme.of(context).colorScheme.primary)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 2: Review ────────────────────────────────────────────────────
  Widget _buildReviewStep() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ReviewSection(
            title: 'بيانات الأمر',
            rows: [
              ('المورد',          _vendorName),
              ('تاريخ الأمر',
                  DateFormat('yyyy/MM/dd').format(_orderDate)),
              if (_expectedDate != null)
                ('تاريخ التسليم',
                    DateFormat('yyyy/MM/dd').format(_expectedDate!)),
              if (_notesCtrl.text.isNotEmpty)
                ('ملاحظات', _notesCtrl.text),
            ],
          ),
          const SizedBox(height: 16),
          _ReviewSection(
            title: 'الأصناف (${_lines.length})',
            rows: _lines.map((l) => (l.itemName, '${l.quantity} × ${l.unitCost} = ${(l.quantity * l.unitCost).toStringAsFixed(2)}')).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الإجمالي الكلي',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                Text('${_total.toStringAsFixed(2)} ج.م',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color:
                            Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),
        ],
      );

  // ── Bottom Bar ────────────────────────────────────────────────────────
  Widget _buildBottomBar() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_step > 0)
                OutlinedButton(
                  onPressed: () => setState(() => _step--),
                  child: const Text('السابق'),
                ),
              const Spacer(),
              if (_step < 2)
                ElevatedButton(
                  onPressed: _canNext()
                      ? () => setState(() => _step++)
                      : null,
                  child: const Text('التالي'),
                )
              else ...[
                OutlinedButton(
                  onPressed: _saving ? null : () => _save(SaveMode.draft),
                  child: const Text('حفظ كمسودة'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                      _saving ? null : () => _save(SaveMode.saveAndOpen),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('حفظ وفتح'),
                ),
              ],
            ],
          ),
        ),
      );

  bool _canNext() {
    if (_step == 0) return _vendorId != null;
    if (_step == 1) return _lines.isNotEmpty && _lines.every((l) => l.isValid);
    return true;
  }
}

// ─── Line Entry (State) ───────────────────────────────────────────────
class _LineEntry {
  String?  itemId;
  String   itemName  = '';
  double   quantity  = 1;
  double   unitCost  = 0;
  final    descriptionCtrl = TextEditingController();
  bool get isValid => itemId != null && quantity > 0 && unitCost > 0;
  void dispose() => descriptionCtrl.dispose();
}

// ─── Line Editor Widget ───────────────────────────────────────────────
class _LineEditor extends ConsumerStatefulWidget {
  const _LineEditor({
    required this.entry,
    required this.index,
    required this.itemsAsync,
    required this.onDelete,
    required this.onChanged,
  });
  final _LineEntry     entry;
  final int            index;
  final AsyncValue     itemsAsync;
  final VoidCallback   onDelete;
  final VoidCallback   onChanged;

  @override
  ConsumerState<_LineEditor> createState() => _LineEditorState();
}

class _LineEditorState extends ConsumerState<_LineEditor> {
  final _qtyCtrl  = TextEditingController(text: '1');
  final _costCtrl = TextEditingController();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('صنف ${widget.index + 1}',
                    style: Theme.of(context).textTheme.labelSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: Theme.of(context).colorScheme.error,
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Item selector
            widget.itemsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (items) => DropdownButtonFormField<String>(
                value: widget.entry.itemId,
                decoration: const InputDecoration(
                  labelText: 'الصنف *',
                  isDense: true,
                ),
                items: (items as dynamic).map<DropdownMenuItem<String>>((i) =>
                    DropdownMenuItem(value: i.id, child: Text(i.name))).toList(),
                onChanged: (v) {
                  setState(() {
                    widget.entry.itemId   = v;
                    widget.entry.itemName = (items as dynamic)
                        .firstWhere((i) => i.id == v)
                        .name as String;
                  });
                  widget.onChanged();
                },
              ),
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyCtrl,
                    decoration: const InputDecoration(
                        labelText: 'الكمية', isDense: true),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      widget.entry.quantity =
                          double.tryParse(v) ?? 0;
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _costCtrl,
                    decoration: const InputDecoration(
                        labelText: 'التكلفة', isDense: true),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      widget.entry.unitCost =
                          double.tryParse(v) ?? 0;
                      widget.onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(widget.entry.quantity * widget.entry.unitCost).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step Indicator ───────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});
  final int current;

  static const _steps = ['المورد', 'الأصناف', 'مراجعة'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _steps.asMap().entries.map((e) {
        final active = e.key == current;
        final done   = e.key < current;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: done || active ? cs.primary : cs.outline,
                child: done
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text('${e.key + 1}',
                        style: TextStyle(
                            fontSize: 11,
                            color: active ? Colors.white : cs.onSurface)),
              ),
              const SizedBox(width: 4),
              Text(e.value,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: active
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: active ? cs.primary : cs.onSurface)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Review Section ───────────────────────────────────────────────────
class _ReviewSection extends StatelessWidget {
  const _ReviewSection({required this.title, required this.rows});
  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700)),
              const Divider(height: 16),
              ...rows.map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(r.$1,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.6))),
                        const Spacer(),
                        Text(r.$2,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      );
}