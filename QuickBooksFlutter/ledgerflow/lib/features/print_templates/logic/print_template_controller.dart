import 'package:flutter/foundation.dart';

import '../data/models/print_element_model.dart';
import '../data/models/print_template_model.dart';
import '../data/print_template_repository.dart';
import '../data/sample_templates.dart';

class PrintTemplateController extends ChangeNotifier {
  PrintTemplateController({PrintTemplateModel? initialTemplate, PrintTemplateRepository? repository})
      : _template = initialTemplate ?? SamplePrintTemplates.classicA4Invoice(),
        _repository = repository ?? const PrintTemplateRepository();

  final PrintTemplateRepository _repository;
  PrintTemplateModel _template;
  String? _selectedElementId;
  int _nextElementNumber = 1;
  bool _isBusy = false;
  String? _lastMessage;
  List<PrintTemplateModel> _savedTemplates = const [];

  PrintTemplateModel get template => _template;
  String? get selectedElementId => _selectedElementId;
  PrintElementModel? get selectedElement => _template.elementById(_selectedElementId);
  bool get isBusy => _isBusy;
  String? get lastMessage => _lastMessage;
  List<PrintTemplateModel> get savedTemplates => _savedTemplates;

  void selectElement(String? elementId) {
    _selectedElementId = elementId;
    notifyListeners();
  }

  void loadTemplate(PrintTemplateModel template) {
    _template = template;
    _selectedElementId = null;
    _lastMessage = 'Loaded ${template.name}';
    notifyListeners();
  }

  Future<void> loadTemplates() async {
    await _runBusy(() async {
      _savedTemplates = await _repository.list(documentType: _template.documentType);
      _lastMessage = 'Loaded ${_savedTemplates.length} template(s)';
    });
  }

  Future<void> saveTemplate() async {
    await _runBusy(() async {
      _template = await _repository.save(_template);
      await loadTemplates();
      _lastMessage = 'Template saved';
    });
  }

  void addText() => _addElement('text');
  void addField() => _addElement('field');
  void addRectangle() => _addElement('rectangle');
  void addLine() => _addElement('line');
  void addTable() => _addElement('table');
  void addQr() => _addElement('qr');
  void addBarcode() => _addElement('barcode');

  void _addElement(String type) {
    final id = '${type}_${_nextElementNumber++}';
    final element = PrintElementModel(
      id: id,
      type: type,
      x: 18 + (_nextElementNumber * 2),
      y: 30 + (_nextElementNumber * 3),
      width: type == 'line' ? 60 : 42,
      height: type == 'line' ? 1 : 12,
      value: _defaultValue(type),
      binding: type == 'field' ? '{{Invoice.Number}}' : null,
      columns: type == 'table'
          ? const [
              PrintTableColumnModel(title: 'Item', field: 'itemName', width: 60),
              PrintTableColumnModel(title: 'Qty', field: 'quantity', width: 20),
              PrintTableColumnModel(title: 'Total', field: 'lineTotal', width: 30),
            ]
          : const [],
      style: PrintElementStyleModel(
        fontSize: type == 'text' ? 12 : 10,
        borderWidth: type == 'rectangle' || type == 'table' ? 0.4 : 0,
      ),
    );

    _template = _template.addElement(element);
    _selectedElementId = element.id;
    notifyListeners();
  }

  String _defaultValue(String type) {
    switch (type) {
      case 'text':
        return 'New Text';
      case 'qr':
        return '{{Invoice.QrPayload}}';
      case 'barcode':
        return '{{Item.Barcode}}';
      default:
        return '';
    }
  }

  void updateSelected(PrintElementModel element) {
    _template = _template.updateElement(element);
    _selectedElementId = element.id;
    notifyListeners();
  }

  void updateSelectedPosition({double? x, double? y, double? width, double? height}) {
    final element = selectedElement;
    if (element == null) return;
    updateSelected(element.copyWith(x: x, y: y, width: width, height: height));
  }

  void updateSelectedText({String? value, String? binding}) {
    final element = selectedElement;
    if (element == null) return;
    updateSelected(element.copyWith(value: value, binding: binding));
  }

  void updateSelectedStyle(PrintElementStyleModel style) {
    final element = selectedElement;
    if (element == null) return;
    updateSelected(element.copyWith(style: style));
  }

  String exportJson() => _template.toPrettyJson();

  Future<void> _runBusy(Future<void> Function() action) async {
    _isBusy = true;
    _lastMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      _lastMessage = error.toString();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
