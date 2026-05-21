import 'package:flutter/material.dart';

import '../../logic/print_template_controller.dart';
import '../widgets/properties_panel.dart';
import '../widgets/template_canvas.dart';
import '../widgets/toolbox_panel.dart';

class PrintTemplateDesignerPage extends StatefulWidget {
  const PrintTemplateDesignerPage({super.key});

  @override
  State<PrintTemplateDesignerPage> createState() =>
      _PrintTemplateDesignerPageState();
}

class _PrintTemplateDesignerPageState extends State<PrintTemplateDesignerPage> {
  late final PrintTemplateController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PrintTemplateController()..addListener(_refresh);
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final template = _controller.template;
    final isThermal = _isThermalTemplate;
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F7),
      appBar: AppBar(
        titleSpacing: 0,
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Print Template Designer'),
              const SizedBox(width: 14),
              _HeaderChip(
                label: template.name,
                icon: Icons.view_quilt_outlined,
              ),
              const SizedBox(width: 8),
              _HeaderChip(label: template.page.size, icon: Icons.straighten),
              const SizedBox(width: 8),
              _HeaderChip(
                label: template.documentType,
                icon: Icons.description_outlined,
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _controller.isBusy ? null : _controller.loadTemplates,
            icon: const Icon(Icons.cloud_download_outlined),
            label: const Text('Load'),
          ),
          TextButton.icon(
            onPressed: _controller.isBusy ? null : _controller.saveTemplate,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
          TextButton.icon(
            onPressed: _controller.isBusy
                ? null
                : _controller.duplicateCurrentAsCustom,
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('Custom Copy'),
          ),
          TextButton.icon(
            onPressed: _controller.isBusy ? null : _controller.previewPrint,
            icon: const Icon(Icons.print_outlined),
            label: const Text('Preview Print'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          ToolboxPanel(controller: _controller),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFD8DEE8)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Design canvas',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 16),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('A4'),
                            icon: Icon(Icons.description_outlined),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Thermal 80mm'),
                            icon: Icon(Icons.receipt_long_outlined),
                          ),
                        ],
                        selected: {isThermal},
                        showSelectedIcon: false,
                        onSelectionChanged: (value) {
                          final thermal = value.first;
                          if (thermal) {
                            _controller.loadThermalDefault();
                          } else {
                            _controller.loadA4Default();
                          }
                        },
                      ),
                      const Spacer(),
                      Text(
                        '${template.page.effectiveWidthMm.toStringAsFixed(0)} x ${template.page.effectiveHeightMm.toStringAsFixed(0)} mm',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    child: TemplateCanvas(controller: _controller),
                  ),
                ),
              ],
            ),
          ),
          PropertiesPanel(controller: _controller),
        ],
      ),
    );
  }

  bool get _isThermalTemplate {
    final pageSize = _controller.template.pageSize.toLowerCase();
    return pageSize.contains('receipt') ||
        pageSize.contains('thermal') ||
        _controller.template.page.widthMm <= 90;
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
