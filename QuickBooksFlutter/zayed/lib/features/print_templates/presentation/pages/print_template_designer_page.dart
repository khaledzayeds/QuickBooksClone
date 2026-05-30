import 'package:flutter/material.dart';

import '../../../settings/data/models/printing_settings_model.dart';
import '../../data/models/print_page_model.dart';
import '../../data/models/print_template_model.dart';
import '../../logic/print_template_controller.dart';
import '../widgets/properties_panel.dart';
import '../widgets/template_canvas.dart';
import '../widgets/toolbox_panel.dart';

class PrintTemplateDesignerPage extends StatefulWidget {
  const PrintTemplateDesignerPage({
    super.key,
    this.documentType,
    this.paperKind,
    this.templateId,
  });

  final String? documentType;
  final String? paperKind;
  final String? templateId;

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
    Future.microtask(
      () => _controller.open(
        documentType: widget.documentType,
        paperKind: widget.paperKind,
        templateId: widget.templateId,
      ),
    );
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
    final paperKind = isThermal ? 'thermal' : 'a4';
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F7),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const Text('Print Template Designer'),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                template.name,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // BEGIN: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
          TextButton.icon(
            onPressed: _controller.isBusy ? null : _controller.saveTemplate,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
          TextButton.icon(
            onPressed: _controller.isBusy ? null : _controller.previewPrint,
            icon: const Icon(Icons.print_outlined),
            label: const Text('Preview Print'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More actions',
            onSelected: (value) {
              switch (value) {
                case 'load':
                  _controller.loadTemplates();
                  break;
                case 'save_as':
                  _saveAs(context);
                  break;
                case 'rename':
                  _rename(context);
                  break;
                case 'custom_copy':
                  _controller.duplicateCurrentAsCustom();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'load',
                enabled: !_controller.isBusy,
                child: const Row(
                  children: [
                    Icon(Icons.cloud_download_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Load Saved'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'save_as',
                enabled: !_controller.isBusy,
                child: const Row(
                  children: [
                    Icon(Icons.save_as_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Save As...'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'rename',
                enabled: !_controller.isBusy,
                child: const Row(
                  children: [
                    Icon(Icons.drive_file_rename_outline, size: 18),
                    SizedBox(width: 8),
                    Text('Rename...'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'custom_copy',
                enabled: !_controller.isBusy,
                child: const Row(
                  children: [
                    Icon(Icons.copy_all_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Custom Copy'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // END: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 294,
            child: Column(
              children: [
                Expanded(
                  child: _TemplateNavigator(
                    controller: _controller,
                    paperKind: paperKind,
                    onDocumentChanged: (documentType) => _controller
                        .changeDocumentAndPaper(documentType, paperKind),
                    onPaperChanged: (nextPaper) =>
                        _controller.changeDocumentAndPaper(
                          template.documentType,
                          nextPaper,
                        ),
                  ),
                ),
                Expanded(child: ToolboxPanel(controller: _controller)),
              ],
            ),
          ),
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final tight = constraints.maxWidth < 720;
                      return Row(
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
                          const SizedBox(width: 12),
                          SegmentedButton<String>(
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            segments: const [
                              ButtonSegment<String>(
                                value: 'a4',
                                label: Text('A4'),
                              ),
                              ButtonSegment<String>(
                                value: 'thermal_80',
                                label: Text('80mm'),
                              ),
                              ButtonSegment<String>(
                                value: 'thermal_58',
                                label: Text('58mm'),
                              ),
                            ],
                            selected: {
                              if (template.page.size == 'A4' ||
                                  template.page.widthMm > 90)
                                'a4'
                              else if (template.page.widthMm <= 60)
                                'thermal_58'
                              else
                                'thermal_80',
                            },
                            showSelectedIcon: false,
                            onSelectionChanged: (values) {
                              final selected = values.first;
                              if (selected == 'a4') {
                                _controller.updatePage(
                                  PrintPageModel.a4Portrait(),
                                );
                              } else if (selected == 'thermal_80') {
                                _controller.updatePage(
                                  PrintPageModel.receipt80mm(),
                                );
                              } else if (selected == 'thermal_58') {
                                _controller.updatePage(
                                  PrintPageModel.receipt58mm(),
                                );
                              }
                            },
                          ),
                          if (!tight) ...[
                            const SizedBox(width: 12),
                            if (_controller.isSystemTemplate)
                              const _StatusBadge(
                                text: 'Save creates custom copy',
                              )
                            else
                              const _StatusBadge(text: 'Saved custom template'),
                          ],
                          const Spacer(),
                          if (!tight)
                            Text(
                              '${template.page.effectiveWidthMm.toStringAsFixed(0)} x ${template.page.effectiveHeightMm.toStringAsFixed(0)} mm',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      );
                    },
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

  Future<void> _saveAs(BuildContext context) async {
    final name = await _askForName(
      context,
      title: 'Save template as',
      initialValue: _controller.template.name,
    );
    if (name != null) await _controller.saveAs(name);
  }

  Future<void> _rename(BuildContext context) async {
    final name = await _askForName(
      context,
      title: 'Rename template',
      initialValue: _controller.template.name,
    );
    if (name != null) await _controller.renameTemplate(name);
  }

  Future<String?> _askForName(
    BuildContext context, {
    required String title,
    required String initialValue,
  }) async {
    var value = initialValue;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextFormField(
            initialValue: initialValue,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Template name',
              border: OutlineInputBorder(),
            ),
            onChanged: (next) => value = next,
            onFieldSubmitted: (next) => Navigator.of(context).pop(next),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(value),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _TemplateNavigator extends StatelessWidget {
  const _TemplateNavigator({
    required this.controller,
    required this.paperKind,
    required this.onDocumentChanged,
    required this.onPaperChanged,
  });

  final PrintTemplateController controller;
  final String paperKind;
  final ValueChanged<String> onDocumentChanged;
  final ValueChanged<String> onPaperChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final template = controller.template;
    final visible = controller.visibleTemplates
        .where((item) => item.documentType == template.documentType)
        .where((item) => _matchesPaper(item, paperKind))
        .toList();
    if (!visible.any(
      (item) => item.id == template.id || item.backendId == template.backendId,
    )) {
      visible.insert(0, template);
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFD8DEE8))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Template Library',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          // BEGIN: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
          DropdownButtonFormField<String>(
            key: ValueKey('document-${template.documentType}'),
            initialValue:
                printDocumentTypeOptions.any(
                  (item) => item.key == template.documentType,
                )
                ? template.documentType
                : printDocumentTypeOptions.first.key,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Document',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: printDocumentTypeOptions
                .map(
                  (item) => DropdownMenuItem(
                    value: item.key,
                    child: Text(
                      '${item.group} - ${item.label}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onDocumentChanged(value);
            },
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'a4',
                label: Text('A4'),
                icon: Icon(Icons.description_outlined),
              ),
              ButtonSegment(
                value: 'thermal',
                label: Text('Thermal'),
                icon: Icon(Icons.receipt_long_outlined),
              ),
            ],
            selected: {paperKind},
            showSelectedIcon: false,
            onSelectionChanged: (value) => onPaperChanged(value.first),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final item = visible[index];
                final selected =
                    item.id == template.id ||
                    item.backendId == template.backendId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.3,
                            )
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      selected: selected,
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.dividerColor.withValues(alpha: 0.5),
                          width: selected ? 1.5 : 1.0,
                        ),
                      ),
                      leading: Icon(
                        item.backendId == null
                            ? Icons.lock_outline
                            : Icons.edit_document,
                        size: 18,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        item.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        item.backendId == null ? 'Built-in' : 'Saved',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? theme.colorScheme.primary.withValues(alpha: 0.8)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: () => controller.loadTemplate(item),
                    ),
                  ),
                );
              },
            ),
          ),
          // END: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
          const SizedBox(height: 8),
          Text(
            'Use Printing Settings to assign saved templates to live documents.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesPaper(PrintTemplateModel template, String paperKind) {
    final size = template.pageSize.toLowerCase();
    final thermal =
        size.contains('receipt') ||
        size.contains('thermal') ||
        template.page.widthMm <= 90;
    return paperKind == 'thermal' ? thermal : !thermal;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
