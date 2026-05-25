import 'package:flutter/material.dart';

import 'transaction_models.dart';

class TransactionPartySelector extends StatelessWidget {
  const TransactionPartySelector({
    super.key,
    required this.partyType,
    required this.label,
    required this.controller,
    this.selectedDisplayName,
    this.balanceText,
    this.creditText,
    this.onSearch,
    this.onClear,
    this.onCreateNew,
  });

  final TransactionPartyType partyType;
  final String label;
  final TextEditingController controller;
  final String? selectedDisplayName;
  final String? balanceText;
  final String? creditText;
  final VoidCallback? onSearch;
  final VoidCallback? onClear;
  final VoidCallback? onCreateNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icon, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
                if (onCreateNew != null)
                  TextButton.icon(
                    onPressed: onCreateNew,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: _hint,
                prefixIcon: Icon(_icon, size: 18),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onClear != null) IconButton(onPressed: onClear, icon: const Icon(Icons.clear), tooltip: 'Clear'),
                    IconButton(onPressed: onSearch, icon: const Icon(Icons.search), tooltip: 'Search'),
                  ],
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => onSearch?.call(),
            ),
            if (selectedDisplayName?.isNotEmpty == true || balanceText != null || creditText != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (selectedDisplayName?.isNotEmpty == true) _InfoChip(icon: _icon, text: selectedDisplayName!),
                  if (balanceText != null) _InfoChip(icon: Icons.account_balance_wallet_outlined, text: balanceText!),
                  if (creditText != null) _InfoChip(icon: Icons.credit_score_outlined, text: creditText!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (partyType) {
        TransactionPartyType.customer => Icons.person_outline,
        TransactionPartyType.vendor => Icons.store_outlined,
        TransactionPartyType.account => Icons.account_tree_outlined,
        TransactionPartyType.none => Icons.info_outline,
      };

  String get _hint => switch (partyType) {
        TransactionPartyType.customer => 'Search customer by name, phone, or email...',
        TransactionPartyType.vendor => 'Search vendor by name, phone, or email...',
        TransactionPartyType.account => 'Search account...',
        TransactionPartyType.none => 'Search...',
      };
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: cs.primary), const SizedBox(width: 5), Text(text, style: Theme.of(context).textTheme.labelSmall)]),
    );
  }
}
