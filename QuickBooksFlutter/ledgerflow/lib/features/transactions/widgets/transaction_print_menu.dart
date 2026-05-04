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
        PopupMenuItem(value: TransactionPrintAction.preview, child: _PrintMenuRow(icon: Icons.visibility_outlined, label: 'Preview A4')),
        PopupMenuItem(value: TransactionPrintAction.printA4, child: _PrintMenuRow(icon: Icons.print_outlined, label: 'Print A4')),
        PopupMenuItem(value: TransactionPrintAction.printThermal, child: _PrintMenuRow(icon: Icons.receipt_long_outlined, label: 'Print Thermal')),
        PopupMenuItem(value: TransactionPrintAction.emailOrShare, child: _PrintMenuRow(icon: Icons.share_outlined, label: 'Email / Share')),
      ],
      child: OutlinedButton.icon(onPressed: null, icon: const Icon(Icons.print_outlined), label: const Text('Print')),
    );
  }
}

class _PrintMenuRow extends StatelessWidget {
  const _PrintMenuRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, size: 18), const SizedBox(width: 10), Text(label)]);
  }
}
