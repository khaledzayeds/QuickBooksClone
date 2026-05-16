import 'dart:convert';

class PrintElementStyleModel {
  const PrintElementStyleModel({
    this.fontSize = 12,
    this.bold = false,
    this.italic = false,
    this.align = 'left',
    this.color = '#111827',
    this.backgroundColor = 'transparent',
    this.borderColor = '#D1D5DB',
    this.borderWidth = 0,
    this.padding = 2,
  });

  final double fontSize;
  final bool bold;
  final bool italic;
  final String align;
  final String color;
  final String backgroundColor;
  final String borderColor;
  final double borderWidth;
  final double padding;

  PrintElementStyleModel copyWith({
    double? fontSize,
    bool? bold,
    bool? italic,
    String? align,
    String? color,
    String? backgroundColor,
    String? borderColor,
    double? borderWidth,
    double? padding,
  }) {
    return PrintElementStyleModel(
      fontSize: fontSize ?? this.fontSize,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      align: align ?? this.align,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      padding: padding ?? this.padding,
    );
  }

  factory PrintElementStyleModel.fromJson(Map<String, dynamic> json) {
    return PrintElementStyleModel(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 12,
      bold: json['bold'] == true,
      italic: json['italic'] == true,
      align: json['align'] as String? ?? 'left',
      color: json['color'] as String? ?? '#111827',
      backgroundColor: json['backgroundColor'] as String? ?? 'transparent',
      borderColor: json['borderColor'] as String? ?? '#D1D5DB',
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 0,
      padding: (json['padding'] as num?)?.toDouble() ?? 2,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'bold': bold,
      'italic': italic,
      'align': align,
      'color': color,
      'backgroundColor': backgroundColor,
      'borderColor': borderColor,
      'borderWidth': borderWidth,
      'padding': padding,
    };
  }
}

class PrintTableColumnModel {
  const PrintTableColumnModel({
    required this.title,
    required this.field,
    required this.width,
  });

  final String title;
  final String field;
  final double width;

  factory PrintTableColumnModel.fromJson(Map<String, dynamic> json) {
    return PrintTableColumnModel(
      title: json['title'] as String? ?? '',
      field: json['field'] as String? ?? '',
      width: (json['width'] as num?)?.toDouble() ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'field': field,
      'width': width,
    };
  }
}

class PrintElementModel {
  const PrintElementModel({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.value = '',
    this.binding,
    this.assetPath,
    this.style = const PrintElementStyleModel(),
    this.columns = const [],
    this.metadata = const {},
  });

  final String id;
  final String type;
  final double x;
  final double y;
  final double width;
  final double height;
  final String value;
  final String? binding;
  final String? assetPath;
  final PrintElementStyleModel style;
  final List<PrintTableColumnModel> columns;
  final Map<String, dynamic> metadata;

  PrintElementModel copyWith({
    String? id,
    String? type,
    double? x,
    double? y,
    double? width,
    double? height,
    String? value,
    String? binding,
    String? assetPath,
    PrintElementStyleModel? style,
    List<PrintTableColumnModel>? columns,
    Map<String, dynamic>? metadata,
  }) {
    return PrintElementModel(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      value: value ?? this.value,
      binding: binding ?? this.binding,
      assetPath: assetPath ?? this.assetPath,
      style: style ?? this.style,
      columns: columns ?? this.columns,
      metadata: metadata ?? this.metadata,
    );
  }

  factory PrintElementModel.fromJson(Map<String, dynamic> json) {
    return PrintElementModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 20,
      height: (json['height'] as num?)?.toDouble() ?? 8,
      value: json['value'] as String? ?? '',
      binding: json['binding'] as String?,
      assetPath: json['assetPath'] as String?,
      style: PrintElementStyleModel.fromJson(
        (json['style'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      columns: ((json['columns'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => PrintTableColumnModel.fromJson(item.cast<String, dynamic>()))
          .toList(),
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  factory PrintElementModel.fromJsonString(String source) {
    return PrintElementModel.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'value': value,
      if (binding != null) 'binding': binding,
      if (assetPath != null) 'assetPath': assetPath,
      'style': style.toJson(),
      if (columns.isNotEmpty) 'columns': columns.map((item) => item.toJson()).toList(),
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }
}
