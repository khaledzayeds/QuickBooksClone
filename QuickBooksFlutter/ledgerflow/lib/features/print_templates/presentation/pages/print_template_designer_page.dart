import 'package:flutter/material.dart';

import '../../logic/print_template_controller.dart';
import '../widgets/properties_panel.dart';
import '../widgets/template_canvas.dart';
import '../widgets/toolbox_panel.dart';

class PrintTemplateDesignerPage extends StatefulWidget {
  const PrintTemplateDesignerPage({super.key});

  @override
  State<PrintTemplateDesignerPage> createState() => _PrintTemplateDesignerPageState();
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
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: const Text('Print Template Designer'),
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
            onPressed: () => _showComingSoon('Print preview'),
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
            child: Container(
              padding: const EdgeInsets.all(18),
              child: TemplateCanvas(
                template: _controller.template,
                selectedElementId: _controller.selectedElementId,
                onSelectElement: _controller.selectElement,
              ),
            ),
          ),
          PropertiesPanel(controller: _controller),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature will be added after PDF/print export is implemented.')),
    );
  }
}
