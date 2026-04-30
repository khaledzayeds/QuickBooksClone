// order_lines_editor.dart

import 'package:flutter/material.dart';
import '../data/models/order_line_entry.dart';

class OrderLinesEditor extends StatelessWidget {
  const OrderLinesEditor({
    super.key,
    required this.lines,
    required this.onRemove,
  });

  final List<OrderLineEntry>      lines;   // ← public الآن
  final void Function(int index)  onRemove;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border:       Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'لم تتم إضافة أصناف بعد',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.4),
                ),
          ),
        ),
      );
    }

    return Column(
      children: lines.asMap().entries.map((entry) {
        final i    = entry.key;
        final line = entry.value;
        return _OrderLineRow(
          line:     line,
          index:    i,
          onRemove: lines.length > 1 ? () => onRemove(i) : null,
        );
      }).toList(),
    );
  }
}

// ─── Row Widget ───────────────────────────────────
class _OrderLineRow extends StatefulWidget {
  const _OrderLineRow({
    required this.line,
    required this.index,
    this.onRemove,
  });
  final OrderLineEntry line;       // ← public
  final int            index;
  final VoidCallback?  onRemove;

  @override
  State<_OrderLineRow> createState() => _OrderLineRowState();
}

class _OrderLineRowState extends State<_OrderLineRow> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row Header ──────────────────────
            Row(
              children: [
                Text(
                  'صنف ${widget.index + 1}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const Spacer(),
                if (widget.onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        size: 18, color: Colors.red),
                    onPressed: widget.onRemove,
                    tooltip:     'حذف',
                    padding:     EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Item Selector ───────────────────
            InkWell(
              onTap: () async {
               
              },
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText:  'الصنف *',
                  suffixIcon: Icon(Icons.arrow_drop_down),
                  isDense:    true,
                ),
                child: Text(
                  widget.line.itemName.isEmpty
                      ? 'اختر صنفاً...'
                      : widget.line.itemName,
                  style: TextStyle(
                    color: widget.line.itemName.isEmpty
                        ? Theme.of(context).hintColor
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Qty + Cost + Total ──────────────
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.line.qtyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'الكمية',
                      isDense:   true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'كمية غير صحيحة';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: widget.line.costCtrl,
                    decoration: const InputDecoration(
                      labelText: 'سعر الشراء',
                      isDense:   true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0) return 'سعر غير صحيح';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Line Total
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.line.lineTotal.toStringAsFixed(2), // ← إصلاح warning
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:      Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}