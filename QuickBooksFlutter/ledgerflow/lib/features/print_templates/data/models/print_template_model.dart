import 'dart:convert';

import 'print_element_model.dart';
import 'print_page_model.dart';

class PrintTemplateModel {
  const PrintTemplateModel({
    required this.id,
    required this.name,
    required this.documentType,
    required this.page,
    required this.elements,
    this.isDefault = false,
    this.backendId,
    this.pageSize = 'A4',
  });

  final String id;
  final String name;
  final String documentType;
  final PrintPageModel page;
  final List<PrintElementModel> elements;
  final bool isDefault;
  final String? backendId;
  final String pageSize;

  PrintTemplateModel copyWith({
    String? id,
    String? name,
    String? documentType,
    PrintPageModel? page,
    List<PrintElementModel>? elements,
    bool? isDefault,
    String? backendId,
    String? pageSize,
  }) {
    return PrintTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      documentType: documentType ?? this.documentType,
      page: page ?? this.page,
      elements: elements ?? this.elements,
      isDefault: isDefault ?? this.isDefault,
      backendId: backendId ?? this.backendId,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  PrintElementModel? elementById(String? selectedId) {
    if (selectedId == null) return null;
    for (final item in elements) {
      if (item.id == selectedId) return item;
    }
    return null;
  }

  PrintTemplateModel updateElement(PrintElementModel next) {
    return copyWith(elements: elements.map((item) => item.id == next.id ? next : item).toList());
  }

  PrintTemplateModel addElement(PrintElementModel next) {
    return copyWith(elements: [...elements, next]);
  }

  factory PrintTemplateModel.fromJson(Map<String, dynamic> json) {
    return PrintTemplateModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      documentType: json['documentType'] as String? ?? 'invoice',
      page: PrintPageModel.fromJson((json['page'] as Map?)?.cast<String, dynamic>() ?? const {}),
      elements: ((json['elements'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => PrintElementModel.fromJson(item.cast<String, dynamic>()))
          .toList(),
      isDefault: json['isDefault'] == true,
      backendId: json['backendId'] as String?,
      pageSize: json['pageSize'] as String? ?? ((json['page'] as Map?)?['size'] as String? ?? 'A4'),
    );
  }

  factory PrintTemplateModel.fromJsonString(String source) => PrintTemplateModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

  factory PrintTemplateModel.fromApiJson(Map<String, dynamic> json) {
    final content = json['jsonContent'] as String? ?? '{}';
    final template = PrintTemplateModel.fromJsonString(content);
    return template.copyWith(
      backendId: json['id']?.toString(),
      name: json['name'] as String? ?? template.name,
      documentType: json['documentType'] as String? ?? template.documentType,
      pageSize: json['pageSize'] as String? ?? template.pageSize,
      isDefault: json['isDefault'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'documentType': documentType,
        'page': page.toJson(),
        'elements': elements.map((item) => item.toJson()).toList(),
        'isDefault': isDefault,
        if (backendId != null) 'backendId': backendId,
        'pageSize': pageSize,
      };

  Map<String, dynamic> toApiJson() => {
        'name': name,
        'documentType': documentType,
        'pageSize': pageSize,
        'jsonContent': toPrettyJson(),
        'isDefault': isDefault,
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}
