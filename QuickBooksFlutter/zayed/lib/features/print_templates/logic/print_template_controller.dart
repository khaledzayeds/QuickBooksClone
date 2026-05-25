import 'package:flutter/foundation.dart';

import '../data/models/print_element_model.dart';
import '../data/models/print_page_model.dart';
import '../data/models/print_template_model.dart';
import '../data/print_template_repository.dart';
import '../data/sample_templates.dart';
import 'print_template_pdf_service.dart';
// BEGIN: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
import '../../settings/data/printing_settings_repository.dart';
import '../../settings/data/models/printing_settings_model.dart';
// END: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]

class PrintTemplateController extends ChangeNotifier {
  PrintTemplateController({
    PrintTemplateModel? initialTemplate,
    PrintTemplateRepository? repository,
    PrintTemplatePdfService? pdfService,
  }) : _template = initialTemplate ?? SamplePrintTemplates.arabicA4Invoice(),
       _repository = repository ?? const PrintTemplateRepository(),
       _pdfService = pdfService ?? const PrintTemplatePdfService();

  final PrintTemplateRepository _repository;
  final PrintTemplatePdfService _pdfService;
  PrintTemplateModel _template;
  String? _selectedElementId;
  int _nextElementNumber = 1;
  bool _isBusy = false;
  String? _lastMessage;
  List<PrintTemplateModel> _savedTemplates = const [];

  PrintTemplateModel get template => _template;
  String? get selectedElementId => _selectedElementId;
  PrintElementModel? get selectedElement =>
      _template.elementById(_selectedElementId);
  bool get isBusy => _isBusy;
  String? get lastMessage => _lastMessage;
  List<PrintTemplateModel> get savedTemplates => _savedTemplates;
  List<PrintTemplateModel> get visibleTemplates => [
    ...SamplePrintTemplates.defaults(),
    ..._savedTemplates,
  ];

  bool get isSystemTemplate =>
      _template.backendId == null ||
      _template.backendId!.isEmpty ||
      _template.isDefault;

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

  Future<void> open({
    String? documentType,
    String? paperKind,
    String? templateId,
  }) async {
    await _runBusy(() async {
      _savedTemplates = await _repository.list(documentType: documentType);
      final loaded = await _resolveInitialTemplate(
        documentType: documentType,
        paperKind: paperKind,
        templateId: templateId,
      );
      _template = loaded;
      _selectedElementId = null;
      _lastMessage = 'Loaded ${loaded.name}';
    });
  }

  void loadDefaultForDocument(String documentType, {String? pageKind}) {
    final defaults = SamplePrintTemplates.defaults();
    final preferred = defaults.where((item) {
      if (item.documentType != documentType) return false;
      if (pageKind == null) return true;
      return _pageMatches(item, pageKind);
    });
    final template = preferred.isNotEmpty
        ? preferred.first
        : _fallbackTemplateFor(documentType, pageKind ?? 'thermal');
    loadTemplate(template);
  }

  void loadA4Default() {
    loadDefaultForDocument(_template.documentType, pageKind: 'a4');
  }

  void loadThermalDefault() {
    loadDefaultForDocument(_template.documentType, pageKind: 'thermal');
  }

  void duplicateCurrentAsCustom() {
    final now = DateTime.now();
    _template = _template.copyWith(
      id: '${_template.documentType}_${now.millisecondsSinceEpoch}',
      backendId: '',
      name: '${_template.name} - Custom',
      isDefault: false,
    );
    _lastMessage = 'Custom copy ready. Rename and save it.';
    notifyListeners();
  }

  Future<void> loadTemplates() async {
    await _runBusy(() async {
      _savedTemplates = await _repository.list(
        documentType: _template.documentType,
      );
      _lastMessage = 'Loaded ${_savedTemplates.length} template(s)';
    });
  }

  Future<void> saveTemplate() async {
    await _runBusy(() async {
      if (isSystemTemplate) {
        final now = DateTime.now();
        _template = _template.copyWith(
          id: '${_template.documentType}_${now.millisecondsSinceEpoch}',
          backendId: '',
          name: '${_template.name} - Custom',
          isDefault: false,
        );
      }
      _template = await _repository.save(_template.copyWith(isDefault: false));
      _savedTemplates = await _repository.list(
        documentType: _template.documentType,
      );
      _lastMessage = 'Template saved';
    });
  }

  Future<void> saveAs(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _runBusy(() async {
      final now = DateTime.now();
      _template = await _repository.save(
        _template.copyWith(
          id: '${_template.documentType}_${now.millisecondsSinceEpoch}',
          backendId: '',
          name: trimmed,
          isDefault: false,
        ),
      );
      _savedTemplates = await _repository.list(
        documentType: _template.documentType,
      );
      _lastMessage = 'Template saved as $trimmed';
    });
  }

  Future<void> renameTemplate(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _runBusy(() async {
      _template = _template.copyWith(name: trimmed);
      if (!isSystemTemplate) {
        _template = await _repository.save(
          _template.copyWith(isDefault: false),
        );
      }
      _savedTemplates = await _repository.list(
        documentType: _template.documentType,
      );
      _lastMessage = 'Template renamed';
    });
  }

  Future<void> changeDocumentAndPaper(String documentType, String paperKind) {
    return _runBusy(() async {
      _savedTemplates = await _repository.list(documentType: documentType);
      _template = await _resolveInitialTemplate(
        documentType: documentType,
        paperKind: paperKind,
      );
      _selectedElementId = null;
      _lastMessage = 'Loaded ${_template.name}';
    });
  }

  Future<void> previewPrint() async {
    await _runBusy(() async {
      await _pdfService.preview(_template);
      _lastMessage = 'Print preview opened';
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
              PrintTableColumnModel(
                title: 'Item',
                field: 'itemName',
                width: 60,
              ),
              PrintTableColumnModel(title: 'Qty', field: 'quantity', width: 20),
              PrintTableColumnModel(
                title: 'Total',
                field: 'lineTotal',
                width: 30,
              ),
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

  void updatePage(PrintPageModel page) {
    final adjustedElements = _template.elements.map((el) {
      var newX = el.x;
      var newWidth = el.width;
      if (newX + newWidth > page.effectiveWidthMm) {
        newWidth = el.width.clamp(4.0, page.effectiveWidthMm);
        newX = (page.effectiveWidthMm - newWidth).clamp(
          0.0,
          page.effectiveWidthMm - newWidth,
        );
      }
      return el.copyWith(x: newX, width: newWidth);
    }).toList();

    _template = _template.copyWith(
      page: page,
      pageSize: page.size,
      elements: adjustedElements,
    );
    notifyListeners();
  }

  void updateSelected(PrintElementModel element) {
    _template = _template.updateElement(element);
    _selectedElementId = element.id;
    notifyListeners();
  }

  // BEGIN: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
  void deleteElement(String elementId) {
    _template = _template.copyWith(
      elements: _template.elements.where((e) => e.id != elementId).toList(),
    );
    if (_selectedElementId == elementId) {
      _selectedElementId = null;
    }
    notifyListeners();
  }
  // END: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]

  void moveSelectedBy(double dxMm, double dyMm) {
    final element = selectedElement;
    if (element == null) return;
    updateSelectedPosition(
      x: _snap(element.x + dxMm),
      y: _snap(element.y + dyMm),
    );
  }

  void resizeSelectedBy(double dwMm, double dhMm) {
    final element = selectedElement;
    if (element == null) return;
    updateSelectedPosition(
      width: _snap(
        (element.width + dwMm).clamp(4, template.page.effectiveWidthMm),
      ),
      height: _snap(
        (element.height + dhMm).clamp(2, template.page.effectiveHeightMm),
      ),
    );
  }

  void updateSelectedPosition({
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    final element = selectedElement;
    if (element == null) return;
    updateSelected(
      element.copyWith(
        x: x == null
            ? null
            : _snap(x)
                  .clamp(0, template.page.effectiveWidthMm - element.width)
                  .toDouble(),
        y: y == null
            ? null
            : _snap(y)
                  .clamp(0, template.page.effectiveHeightMm - element.height)
                  .toDouble(),
        width: width == null
            ? null
            : _snap(width).clamp(4, template.page.effectiveWidthMm).toDouble(),
        height: height == null
            ? null
            : _snap(
                height,
              ).clamp(2, template.page.effectiveHeightMm).toDouble(),
      ),
    );
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

  double _snap(double value) => (value * 2).roundToDouble() / 2;

  bool _pageMatches(PrintTemplateModel template, String pageKind) {
    final normalized = pageKind.toLowerCase();
    final size = template.pageSize.toLowerCase();
    if (normalized == 'a4') return size.contains('a4');
    if (normalized == 'thermal' || normalized == 'receipt') {
      return size.contains('receipt') ||
          size.contains('thermal') ||
          template.page.widthMm <= 90;
    }
    return true;
  }

  // BEGIN: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
  PrintTemplateModel _fallbackTemplateFor(
    String documentType,
    String pageKind,
  ) {
    return SamplePrintTemplates.fallbackFor(documentType, pageKind);
  }
  // END: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]

  Future<PrintTemplateModel> _resolveInitialTemplate({
    String? documentType,
    String? paperKind,
    String? templateId,
  }) async {
    final doc = documentType?.trim().isNotEmpty == true
        ? normalizePrintDocumentType(documentType!)
        : normalizePrintDocumentType(_template.documentType);
    final paper = paperKind?.trim().isNotEmpty == true
        ? paperKind!.trim()
        : 'thermal';
    // BEGIN: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]
    String? resolvedId = templateId?.trim();
    if (resolvedId == null || resolvedId.isEmpty) {
      try {
        final settings = await PrintingSettingsRepository().load();
        final profile = settings.profileFor(doc);
        resolvedId = profile.templateIdForPaper(paper)?.trim();
      } catch (_) {
        // Fallback to defaults if settings lookup fails
      }
    }
    // END: [USER_REQUEST_REVENUE_TEMPLATES_DESIGN]

    if (resolvedId != null && resolvedId.isNotEmpty) {
      if (resolvedId.startsWith('builtin:')) {
        final builtInId = resolvedId.substring('builtin:'.length);
        for (final template in SamplePrintTemplates.defaults()) {
          if (template.id == builtInId) return template;
        }
      } else {
        try {
          return await _repository.get(resolvedId);
        } catch (_) {
          for (final template in _savedTemplates) {
            if (template.backendId == resolvedId || template.id == resolvedId) {
              return template;
            }
          }
        }
      }
    }

    final savedMatch = _savedTemplates.where(
      (template) =>
          normalizePrintDocumentType(template.documentType) == doc &&
          _pageMatches(template, paper),
    );
    if (savedMatch.isNotEmpty) return savedMatch.first;

    final defaults = SamplePrintTemplates.defaults().where(
      (template) =>
          normalizePrintDocumentType(template.documentType) == doc &&
          _pageMatches(template, paper),
    );
    if (defaults.isNotEmpty) return defaults.first;
    return _fallbackTemplateFor(doc, paper);
  }

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
