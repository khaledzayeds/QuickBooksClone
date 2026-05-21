import 'package:flutter/material.dart';

import '../../../settings/data/models/printing_settings_model.dart';
import '../../data/models/print_template_model.dart';
import '../../logic/print_template_controller.dart';

class ToolboxPanel extends StatelessWidget {
  const ToolboxPanel({super.key, required this.controller});

  final PrintTemplateController controller;

  @override
  Widget build(BuildContext context) {
    final selectedDocumentType =
        printDocumentTypeOptions.any(
          (item) => item.key == controller.template.documentType,
        )
        ? controller.template.documentType
        : printDocumentTypeOptions.first.key;
    return Container(
      width: 292,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(14),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Print Designer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              controller.template.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: selectedDocumentType,
              decoration: const InputDecoration(
                labelText: 'Screen / document',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: printDocumentTypeOptions
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.key,
                      child: Text(
                        '${item.group} - ${item.label}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) controller.loadDefaultForDocument(value);
              },
            ),
            const SizedBox(height: 14),
            _toolButton('Text', Icons.text_fields, controller.addText),
            _toolButton('Field', Icons.data_object, controller.addField),
            _toolButton('Rectangle', Icons.crop_square, controller.addRectangle),
            _toolButton('Line', Icons.horizontal_rule, controller.addLine),
            _toolButton('Table', Icons.table_chart_outlined, controller.addTable),
            _toolButton('QR', Icons.qr_code_2, controller.addQr),
            _toolButton(
              'Barcode',
              Icons.view_week_outlined,
              controller.addBarcode,
            ),
            const Divider(height: 24),
            OutlinedButton.icon(
              onPressed: controller.isBusy
                  ? null
                  : controller.duplicateCurrentAsCustom,
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Create Custom Copy'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: controller.isBusy ? null : controller.loadTemplates,
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Load Saved'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: controller.isBusy ? null : controller.saveTemplate,
              icon: controller.isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save Template'),
            ),
            if (controller.lastMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                controller.lastMessage!,
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
              ),
            ],
            const SizedBox(height: 10),
            _templatesList(context),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _showJson(context),
              icon: const Icon(Icons.code),
              label: const Text('Show JSON'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _templatesList(BuildContext context) {
    final templates = controller.visibleTemplates;
    if (templates.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'No templates available yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: templates.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final template = templates[index];
        return _SavedTemplateTile(
          template: template,
          selected:
              template.id == controller.template.id ||
              (template.backendId != null &&
                  template.backendId == controller.template.backendId),
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
          child: SingleChildScrollView(
            child: SelectableText(controller.exportJson()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SavedTemplateTile extends StatelessWidget {
  const _SavedTemplateTile({
    required this.template,
    required this.selected,
    required this.onTap,
  });

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
      subtitle: Text(
        '${template.documentType} • ${template.pageSize}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: template.isDefault
          ? const Icon(
              Icons.verified_outlined,
              size: 18,
              color: Color(0xFF229C1B),
            )
          : const Icon(Icons.edit_note_outlined, size: 18),
      onTap: onTap,
    );
  }
}
