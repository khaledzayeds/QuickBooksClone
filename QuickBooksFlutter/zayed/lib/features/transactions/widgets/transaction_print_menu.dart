import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'transaction_models.dart';

class TransactionPrintMenu extends StatelessWidget {
  const TransactionPrintMenu({super.key, this.onSelected});

  final ValueChanged<TransactionPrintAction>? onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<TransactionPrintAction>(
      tooltip: l10n.previewAndPrint,
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: TransactionPrintAction.preview,
          child: _PrintMenuRow(
            icon: Icons.visibility_outlined,
            label: l10n.previewA4,
          ),
        ),
        PopupMenuItem(
          value: TransactionPrintAction.printA4,
          child: _PrintMenuRow(icon: Icons.print_outlined, label: l10n.printA4),
        ),
        PopupMenuItem(
          value: TransactionPrintAction.printThermal,
          child: _PrintMenuRow(
            icon: Icons.receipt_long_outlined,
            label: l10n.printThermal,
          ),
        ),
        PopupMenuItem(
          value: TransactionPrintAction.emailOrShare,
          child: _PrintMenuRow(
            icon: Icons.share_outlined,
            label: l10n.emailShare,
          ),
        ),
      ],
      child: _PrintMenuButton(label: l10n.print),
    );
  }
}

class _PrintMenuButton extends StatelessWidget {
  const _PrintMenuButton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.print_outlined, size: 18),
          const SizedBox(width: 8),
          Text(label),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
    );
  }
}

class _PrintMenuRow extends StatelessWidget {
  const _PrintMenuRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Icon(icon, size: 18), const SizedBox(width: 10), Text(label)],
    );
  }
}
