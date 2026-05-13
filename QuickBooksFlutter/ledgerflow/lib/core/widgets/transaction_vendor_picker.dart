// transaction_vendor_picker.dart
// Reusable compact vendor selector with search dialog.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/vendors/data/models/vendor_model.dart';
import '../../features/vendors/providers/vendors_provider.dart';

class VendorPickerField extends ConsumerStatefulWidget {
  const VendorPickerField({
    super.key,
    required this.onChanged,
    this.value,
    this.label = 'Vendor',
    this.required = true,
  });

  final VendorModel? value;
  final ValueChanged<VendorModel> onChanged;
  final String label;
  final bool required;

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
    final theme = Theme.of(context);
    final selected = widget.value;

    return SizedBox(
      height: 30,
      child: InkWell(
        onTap: _openPicker,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFB7C3CB)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 16, color: Color(0xFF53656E)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  selected?.displayName ?? 'Select vendor',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: selected == null ? const Color(0xFF7B8B93) : const Color(0xFF253C47),
                    fontWeight: selected == null ? FontWeight.w600 : FontWeight.w800,
                  ),
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF53656E)),
            ],
          ),
        ),
      ),
    );
  }
}

class _VendorSearchDialog extends ConsumerStatefulWidget {
  const _VendorSearchDialog();

  @override
  ConsumerState<_VendorSearchDialog> createState() => _VendorSearchDialogState();
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
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F6F7),
                border: Border(bottom: BorderSide(color: Color(0xFFB7C3CB))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_outline, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Select Vendor',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                autofocus: true,
                onChanged: (value) => setState(() => _query = value.toLowerCase().trim()),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: vendorsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (vendors) {
                  final filtered = vendors.where((vendor) {
                    return vendor.isActive &&
                        (vendor.displayName.toLowerCase().contains(_query) ||
                            (vendor.companyName?.toLowerCase().contains(_query) ?? false));
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No vendors found'));
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final vendor = filtered[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          vendor.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: vendor.companyName == null
                            ? null
                            : Text(
                                vendor.companyName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                        trailing: vendor.balance == 0
                            ? null
                            : Text(
                                vendor.balance.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                        onTap: () => Navigator.pop(context, vendor),
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
