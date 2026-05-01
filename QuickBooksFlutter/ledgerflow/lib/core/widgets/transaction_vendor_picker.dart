// transaction_vendor_picker.dart
// Reusable vendor/customer selector with search dialog — used in PO, Bills, Payments, etc.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/vendors/data/models/vendor_model.dart';
import '../../features/vendors/providers/vendors_provider.dart';

/// Drop-in field that opens a search dialog to pick a vendor.
/// [value] is the currently selected vendor (nullable).
/// [onChanged] fires with the newly selected vendor.
class VendorPickerField extends ConsumerStatefulWidget {
  const VendorPickerField({
    super.key,
    required this.onChanged,
    this.value,
    this.label = 'المورد | Vendor',
    this.required = true,
  });

  final VendorModel?           value;
  final ValueChanged<VendorModel> onChanged;
  final String                 label;
  final bool                   required;

  @override
  ConsumerState<VendorPickerField> createState() => _VendorPickerFieldState();
}

class _VendorPickerFieldState extends ConsumerState<VendorPickerField> {
  Future<void> _openPicker() async {
    final picked = await showDialog<VendorModel>(
      context: context,
      builder: (_) => const _VendorSearchDialog(),
    );
    if (picked != null) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final cs       = theme.colorScheme;
    final selected = widget.value;

    return GestureDetector(
      onTap: _openPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected == null && widget.required
                ? cs.outline
                : cs.outline,
          ),
          borderRadius: BorderRadius.circular(8),
          color: cs.surfaceContainerLowest,
        ),
        child: Row(
          children: [
            if (selected != null) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  selected.initials,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 10),
            ] else
              Icon(Icons.person_search_outlined, color: cs.outline, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.outline),
                  ),
                  Text(
                    selected?.displayName ?? 'اختر موردًا...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected != null
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: selected != null ? null : cs.outline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: cs.outline),
          ],
        ),
      ),
    );
  }
}

// ── Internal Search Dialog ──────────────────────────────────────────────
class _VendorSearchDialog extends ConsumerStatefulWidget {
  const _VendorSearchDialog();

  @override
  ConsumerState<_VendorSearchDialog> createState() =>
      _VendorSearchDialogState();
}

class _VendorSearchDialogState extends ConsumerState<_VendorSearchDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(vendorsProvider);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 420,
        height: 520,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.people_outline),
                  const SizedBox(width: 8),
                  Text('اختر موردًا | Select Vendor',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Search ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'بحث... | Search...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 10, horizontal: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),

            // ── List ───────────────────────────────────────────────────
            Expanded(
              child: vendorsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (vendors) {
                  final filtered = vendors
                      .where((v) =>
                          v.isActive &&
                          (v.displayName.toLowerCase().contains(_query) ||
                              (v.companyName
                                      ?.toLowerCase()
                                      .contains(_query) ??
                                  false)))
                      .toList();

                  if (filtered.isEmpty) {
                    return const Center(
                        child: Text('لا توجد نتائج | No results'));
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final v = filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          child: Text(v.initials,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                        title: Text(v.displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: v.companyName != null
                            ? Text(v.companyName!)
                            : null,
                        trailing: v.balance != 0
                            ? Text(
                                '${v.balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                    color: v.balance > 0
                                        ? Colors.orange
                                        : Colors.green,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12),
                              )
                            : null,
                        onTap: () => Navigator.pop(context, v),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
