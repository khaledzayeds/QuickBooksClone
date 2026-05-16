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
  });

  final String id;
  final String name;
  final String documentType;
  final PrintPageModel page;
  final List<PrintElementModel> elements;
  final bool isDefault;

  PrintTemplateModel copyWith({
    String? id,
    String? name,
    String? documentType,
    PrintPageModel? page,
    List<PrintElementModel>? elements,
    bool? isDefault,
  }) {
    return PrintTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      documentType: documentType ?? this.documentType,
      page: page ?? this.page,
      elements: elements ?? this.elements,
      isDefault: isDefault ?? this.isDefault,
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
    return copyWith(
      elements: elements.map((item) => item.id == next.id ? next : item).toList(),
    );
  }

  PrintTemplateModel addElement(PrintElementModel next) {
    return copyWith(elements: [...elements, next]);
  }

  factory PrintTemplateModel.fromJson(Map<String, dynamic> json) {
    return PrintTemplateModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      documentType: json['documentType'] as String? ?? 'invoice',
      page: PrintPageModel.fromJson(
        (json['page'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      elements: ((json['elements'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => PrintElementModel.fromJson(item.cast<String, dynamic>()))
          .toList(),
      isDefault: json['isDefault'] == true,
    );
  }

  factory PrintTemplateModel.fromJsonString(String source) {
    return PrintTemplateModel.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'documentType': documentType,
      'page': page.toJson(),
      'elements': elements.map((item) => item.toJson()).toList(),
      'isDefault': isDefault,
    };
  }

  String toPrettyJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}
