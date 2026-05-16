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

  factory PrintPageModel.a4Portrait() => const PrintPageModel(size: 'A4', widthMm: 210, heightMm: 297);
  factory PrintPageModel.receipt80mm() => const PrintPageModel(size: 'Receipt 80mm', widthMm: 80, heightMm: 220, marginMm: 3);
  factory PrintPageModel.barcodeLabel50x25() => const PrintPageModel(size: 'Barcode Label 50x25', widthMm: 50, heightMm: 25, marginMm: 2);

  factory PrintPageModel.fromJson(Map<String, dynamic> json) => PrintPageModel(
        size: json['size'] as String? ?? 'A4',
        widthMm: (json['widthMm'] as num?)?.toDouble() ?? 210,
        heightMm: (json['heightMm'] as num?)?.toDouble() ?? 297,
        orientation: json['orientation'] as String? ?? 'portrait',
        marginMm: (json['marginMm'] as num?)?.toDouble() ?? 8,
      );

  Map<String, dynamic> toJson() => {
        'size': size,
        'widthMm': widthMm,
        'heightMm': heightMm,
        'orientation': orientation,
        'marginMm': marginMm,
      };
}
