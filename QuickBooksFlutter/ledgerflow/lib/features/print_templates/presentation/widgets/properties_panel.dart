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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Properties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        SizedBox(height: 20),
        Text('Select an element on the page to edit it.', style: TextStyle(color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _editor(PrintElementModel element) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Properties', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${element.type} • ${element.id}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _numberField('X', element.x, (v) => widget.controller.updateSelectedPosition(x: v))),
            const SizedBox(width: 8),
            Expanded(child: _numberField('Y', element.y, (v) => widget.controller.updateSelectedPosition(y: v))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _numberField('W', element.width, (v) => widget.controller.updateSelectedPosition(width: v))),
            const SizedBox(width: 8),
            Expanded(child: _numberField('H', element.height, (v) => widget.controller.updateSelectedPosition(height: v))),
          ]),
          const Divider(height: 28),
          if (element.type == 'text')
            TextFormField(
              key: ValueKey('value-${element.id}-${element.value}'),
              initialValue: element.value,
              decoration: const InputDecoration(labelText: 'Text value', border: OutlineInputBorder()),
              onFieldSubmitted: (value) => widget.controller.updateSelectedText(value: value),
            ),
          if (element.type == 'field') ...[
            TextFormField(
              key: ValueKey('binding-${element.id}-${element.binding}'),
              initialValue: element.binding ?? '',
              decoration: const InputDecoration(labelText: 'Binding', border: OutlineInputBorder()),
              onFieldSubmitted: (value) => widget.controller.updateSelectedText(binding: value),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: TemplateFieldRegistry.fields.any((field) => field.key == element.binding) ? element.binding : null,
              decoration: const InputDecoration(labelText: 'Known fields', border: OutlineInputBorder()),
              items: TemplateFieldRegistry.fields.map((field) => DropdownMenuItem(value: field.key, child: Text(field.label))).toList(),
              onChanged: (value) {
                if (value != null) widget.controller.updateSelectedText(binding: value);
              },
            ),
          ],
          const Divider(height: 28),
          _numberField('Font size', element.style.fontSize, (value) {
            widget.controller.updateSelectedStyle(element.style.copyWith(fontSize: value));
          }),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bold'),
            value: element.style.bold,
            onChanged: (value) => widget.controller.updateSelectedStyle(element.style.copyWith(bold: value)),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: element.style.align,
            decoration: const InputDecoration(labelText: 'Alignment', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'left', child: Text('Left')),
              DropdownMenuItem(value: 'center', child: Text('Center')),
              DropdownMenuItem(value: 'right', child: Text('Right')),
            ],
            onChanged: (value) {
              if (value != null) widget.controller.updateSelectedStyle(element.style.copyWith(align: value));
            },
          ),
        ],
      ),
    );
  }

  Widget _numberField(String label, double value, ValueChanged<double> onChanged) {
    return TextFormField(
      key: ValueKey('$label-$value'),
      initialValue: value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onFieldSubmitted: (text) {
        final parsed = double.tryParse(text);
        if (parsed != null) onChanged(parsed);
      },
    );
  }
}
