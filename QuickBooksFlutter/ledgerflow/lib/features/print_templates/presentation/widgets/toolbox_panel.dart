import 'package:flutter/material.dart';

import '../../data/models/print_template_model.dart';
import '../../logic/print_template_controller.dart';

class ToolboxPanel extends StatelessWidget {
  const ToolboxPanel({super.key, required this.controller});

  final PrintTemplateController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Print Designer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(controller.template.name, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          _toolButton('Text', Icons.text_fields, controller.addText),
          _toolButton('Field', Icons.data_object, controller.addField),
          _toolButton('Rectangle', Icons.crop_square, controller.addRectangle),
          _toolButton('Line', Icons.horizontal_rule, controller.addLine),
          _toolButton('Table', Icons.table_chart_outlined, controller.addTable),
          _toolButton('QR', Icons.qr_code_2, controller.addQr),
          _toolButton('Barcode', Icons.view_week_outlined, controller.addBarcode),
          const Divider(height: 24),
          OutlinedButton.icon(
            onPressed: controller.isBusy ? null : controller.loadTemplates,
            icon: const Icon(Icons.cloud_download_outlined),
            label: const Text('Load Saved'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: controller.isBusy ? null : controller.saveTemplate,
            icon: controller.isBusy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: const Text('Save Template'),
          ),
          if (controller.lastMessage != null) ...[
            const SizedBox(height: 10),
            Text(controller.lastMessage!, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
          ],
          const SizedBox(height: 10),
          Expanded(child: _savedTemplatesList(context)),
          OutlinedButton.icon(
            onPressed: () => _showJson(context),
            icon: const Icon(Icons.code),
            label: const Text('Show JSON'),
          ),
        ],
      ),
    );
  }

  Widget _savedTemplatesList(BuildContext context) {
    if (controller.savedTemplates.isEmpty) {
      return const Center(
        child: Text('No saved templates loaded yet.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
      );
    }

    return ListView.separated(
      itemCount: controller.savedTemplates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final template = controller.savedTemplates[index];
        return _SavedTemplateTile(
          template: template,
          selected: template.backendId == controller.template.backendId,
          onTap: () => controller.loadTemplate(template),
        );
      },
    );
  }

  Widget _toolButton(String title, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Align(alignment: Alignment.centerLeft, child: Text(title)),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), alignment: Alignment.centerLeft),
      ),
    );
  }

  void _showJson(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Template JSON'),
        content: SizedBox(width: 720, height: 520, child: SingleChildScrollView(child: SelectableText(controller.exportJson()))),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }
}

class _SavedTemplateTile extends StatelessWidget {
  const _SavedTemplateTile({required this.template, required this.selected, required this.onTap});

  final PrintTemplateModel template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      selected: selected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: Colors.white,
      selectedTileColor: const Color(0xFFEFF6FF),
      title: Text(template.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${template.documentType} • ${template.pageSize}', maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}
