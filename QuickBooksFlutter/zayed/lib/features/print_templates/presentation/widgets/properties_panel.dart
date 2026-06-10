import 'package:flutter/material.dart';

import '../../data/models/print_element_model.dart';
import '../../logic/print_template_controller.dart';
import '../../logic/template_field_registry.dart';

class PropertiesPanel extends StatefulWidget {
  const PropertiesPanel({super.key, required this.controller});

  final PrintTemplateController controller;

  @override
  State<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends State<PropertiesPanel> {
  @override
  Widget build(BuildContext context) {
    final element = widget.controller.selectedElement;
    return Container(
      width: 300,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(14),
      child: element == null ? _emptyState() : _editor(element),
    );
  }

  Widget _emptyState() {
    final text = _PanelText.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text.properties,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        Text(
          text.selectElementHint,
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _editor(PrintElementModel element) {
    final text = _PanelText.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text.properties,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${element.type} • ${element.id}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  'X',
                  element.x,
                  (v) => widget.controller.updateSelectedPosition(x: v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numberField(
                  'Y',
                  element.y,
                  (v) => widget.controller.updateSelectedPosition(y: v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  'W',
                  element.width,
                  (v) => widget.controller.updateSelectedPosition(width: v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numberField(
                  'H',
                  element.height,
                  (v) => widget.controller.updateSelectedPosition(height: v),
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          if (element.type == 'text')
            TextFormField(
              key: ValueKey('value-${element.id}-${element.value}'),
              initialValue: element.value,
              decoration: InputDecoration(
                labelText: text.textValue,
                border: const OutlineInputBorder(),
              ),
              onFieldSubmitted: (value) =>
                  widget.controller.updateSelectedText(value: value),
            ),
          if (element.type == 'field') ...[
            TextFormField(
              key: ValueKey('binding-${element.id}-${element.binding}'),
              initialValue: element.binding ?? '',
              decoration: InputDecoration(
                labelText: text.binding,
                border: const OutlineInputBorder(),
              ),
              onFieldSubmitted: (value) =>
                  widget.controller.updateSelectedText(binding: value),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue:
                  TemplateFieldRegistry.fields.any(
                    (field) => field.key == element.binding,
                  )
                  ? element.binding
                  : null,
              decoration: InputDecoration(
                labelText: text.knownFields,
                border: const OutlineInputBorder(),
              ),
              items: TemplateFieldRegistry.fields
                  .map(
                    (field) => DropdownMenuItem(
                      value: field.key,
                      child: Text(field.label, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  widget.controller.updateSelectedText(binding: value);
                }
              },
            ),
          ],
          const Divider(height: 28),
          _numberField(text.fontSize, element.style.fontSize, (value) {
            widget.controller.updateSelectedStyle(
              element.style.copyWith(fontSize: value),
            );
          }),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(text.bold),
            value: element.style.bold,
            onChanged: (value) => widget.controller.updateSelectedStyle(
              element.style.copyWith(bold: value),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: element.style.align,
            decoration: InputDecoration(
              labelText: text.alignment,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: 'left',
                child: Text(text.left, overflow: TextOverflow.ellipsis),
              ),
              DropdownMenuItem(
                value: 'center',
                child: Text(text.center, overflow: TextOverflow.ellipsis),
              ),
              DropdownMenuItem(
                value: 'right',
                child: Text(text.right, overflow: TextOverflow.ellipsis),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                widget.controller.updateSelectedStyle(
                  element.style.copyWith(align: value),
                );
              }
            },
          ),
          // BEGIN: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
          const Divider(height: 28),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.red.shade200),
              ),
            ),
            onPressed: () {
              widget.controller.deleteElement(element.id);
            },
            icon: const Icon(Icons.delete_outline),
            label: Text(text.deleteElement),
          ),
          // END: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
        ],
      ),
    );
  }

  Widget _numberField(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return TextFormField(
      key: ValueKey('$label-$value'),
      initialValue: value.toStringAsFixed(
        value.truncateToDouble() == value ? 0 : 1,
      ),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onFieldSubmitted: (text) {
        final parsed = double.tryParse(text);
        if (parsed != null) onChanged(parsed);
      },
    );
  }
}

class _PanelText {
  const _PanelText(this.ar);

  final bool ar;

  static _PanelText of(BuildContext context) =>
      _PanelText(Localizations.localeOf(context).languageCode == 'ar');

  String get properties => ar ? 'الخصائص' : 'Properties';
  String get selectElementHint => ar
      ? 'اختر عنصرًا من الصفحة لتعديله.'
      : 'Select an element on the page to edit it.';
  String get textValue => ar ? 'قيمة النص' : 'Text value';
  String get binding => ar ? 'الربط' : 'Binding';
  String get knownFields => ar ? 'الحقول المعروفة' : 'Known fields';
  String get fontSize => ar ? 'حجم الخط' : 'Font size';
  String get bold => ar ? 'عريض' : 'Bold';
  String get alignment => ar ? 'المحاذاة' : 'Alignment';
  String get left => ar ? 'يسار' : 'Left';
  String get center => ar ? 'وسط' : 'Center';
  String get right => ar ? 'يمين' : 'Right';
  String get deleteElement => ar ? 'حذف العنصر' : 'Delete Element';
}
