import 'package:flutter/material.dart';

import '../../logic/print_template_controller.dart';

class ToolboxPanel extends StatelessWidget {
  const ToolboxPanel({super.key, required this.controller});

  final PrintTemplateController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Print Designer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(controller.template.name, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 18),
          _toolButton('Text', Icons.text_fields, controller.addText),
          _toolButton('Field', Icons.data_object, controller.addField),
          _toolButton('Rectangle', Icons.crop_square, controller.addRectangle),
          _toolButton('Line', Icons.horizontal_rule, controller.addLine),
          _toolButton('Table', Icons.table_chart_outlined, controller.addTable),
          _toolButton('QR', Icons.qr_code_2, controller.addQr),
          _toolButton('Barcode', Icons.view_week_outlined, controller.addBarcode),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => _showJson(context),
            icon: const Icon(Icons.code),
            label: const Text('Show JSON'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _showComingSoon(context, 'Save Template'),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Template'),
          ),
        ],
      ),
    );
  }

  Widget _toolButton(String title, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Align(alignment: Alignment.centerLeft, child: Text(title)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  void _showJson(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Template JSON'),
        content: SizedBox(
          width: 720,
          height: 520,
          child: SingleChildScrollView(child: SelectableText(controller.exportJson())),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$feature will connect to the API in the next step.')));
  }
}
