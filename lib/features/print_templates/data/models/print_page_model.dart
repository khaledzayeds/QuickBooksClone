class PrintPageModel {
  const PrintPageModel({
    required this.size,
    required this.widthMm,
    required this.heightMm,
    this.orientation = 'portrait',
    this.marginMm = 8,
  });

  final String size;
  final double widthMm;
  final double heightMm;
  final String orientation;
  final double marginMm;

  bool get isLandscape => orientation.toLowerCase() == 'landscape';

  double get effectiveWidthMm => isLandscape ? heightMm : widthMm;

  double get effectiveHeightMm => isLandscape ? widthMm : heightMm;

  PrintPageModel copyWith({
    String? size,
    double? widthMm,
    double? heightMm,
    String? orientation,
    double? marginMm,
  }) {
    return PrintPageModel(
      size: size ?? this.size,
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      orientation: orientation ?? this.orientation,
      marginMm: marginMm ?? this.marginMm,
    );
  }

  factory PrintPageModel.a4Portrait() {
    return const PrintPageModel(
      size: 'A4',
      widthMm: 210,
      heightMm: 297,
      orientation: 'portrait',
      marginMm: 8,
    );
  }

  factory PrintPageModel.receipt80mm() {
    return const PrintPageModel(
      size: 'Receipt 80mm',
      widthMm: 80,
      heightMm: 220,
      orientation: 'portrait',
      marginMm: 3,
    );
  }

  factory PrintPageModel.barcodeLabel50x25() {
    return const PrintPageModel(
      size: 'Barcode Label 50x25',
      widthMm: 50,
      heightMm: 25,
      orientation: 'portrait',
      marginMm: 2,
    );
  }

  factory PrintPageModel.fromJson(Map<String, dynamic> json) {
    return PrintPageModel(
      size: json['size'] as String? ?? 'A4',
      widthMm: (json['widthMm'] as num?)?.toDouble() ?? 210,
      heightMm: (json['heightMm'] as num?)?.toDouble() ?? 297,
      orientation: json['orientation'] as String? ?? 'portrait',
      marginMm: (json['marginMm'] as num?)?.toDouble() ?? 8,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'widthMm': widthMm,
      'heightMm': heightMm,
      'orientation': orientation,
      'marginMm': marginMm,
    };
  }
}
