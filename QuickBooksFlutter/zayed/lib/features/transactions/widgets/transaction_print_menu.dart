import 'package:flutter/material.dart';

import 'transaction_models.dart';

class TransactionPrintMenu extends StatelessWidget {
  const TransactionPrintMenu({super.key, this.onSelected});

  final ValueChanged<TransactionPrintAction>? onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TransactionPrintAction>(
      tooltip: 'Preview and print',
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: TransactionPrintAction.preview,
          child: _PrintMenuRow(
            icon: Icons.visibility_outlined,
            label: 'Preview A4',
          ),
        ),
        PopupMenuItem(
          value: TransactionPrintAction.printA4,
          child: _PrintMenuRow(icon: Icons.print_outlined, label: 'Print A4'),
        ),
        PopupMenuItem(
          value: TransactionPrintAction.printThermal,
          child: _PrintMenuRow(
            icon: Icons.receipt_long_outlined,
            label: 'Print Thermal',
          ),
        ),
        PopupMenuItem(
          value: TransactionPrintAction.emailOrShare,
          child: _PrintMenuRow(
            icon: Icons.share_outlined,
            label: 'Email / Share',
          ),
        ),
      ],
      child: const _PrintMenuButton(),
    );
  }
}

class _PrintMenuButton extends StatelessWidget {
  const _PrintMenuButton();

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
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.print_outlined, size: 18),
          SizedBox(width: 8),
          Text('Print'),
          SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, size: 18),
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
