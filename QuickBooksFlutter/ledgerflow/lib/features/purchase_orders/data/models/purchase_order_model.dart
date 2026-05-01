// purchase_order_model.dart
// Aligned with backend contract and super-safe against type errors.

class PurchaseOrderModel {
  const PurchaseOrderModel({
    required this.id,
    required this.orderNumber,
    required this.vendorId,
    required this.vendorName,
    required this.status,
    required this.orderDate,
    required this.expectedDate,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    this.openedAt,
    this.closedAt,
    this.cancelledAt,
    this.lines = const [],
  });

  final String                   id;
  final String                   orderNumber;
  final String                   vendorId;
  final String                   vendorName;
  final PurchaseOrderStatus      status;
  final DateTime                 orderDate;
  final DateTime                 expectedDate;
  final double                   subtotal;
  final double                   taxAmount;
  final double                   totalAmount;
  final DateTime?                openedAt;
  final DateTime?                closedAt;
  final DateTime?                cancelledAt;
  final List<PurchaseOrderLine>  lines;

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> j) {
    return PurchaseOrderModel(
      id:           j['id']?.toString() ?? '',
      orderNumber:  j['orderNumber']?.toString() ?? '',
      vendorId:     j['vendorId']?.toString() ?? '',
      vendorName:   j['vendorName']?.toString() ?? '',
      status:       PurchaseOrderStatus.fromValue(j['status']),
      orderDate:    DateTime.tryParse(j['orderDate']?.toString() ?? '') ?? DateTime.now(),
      expectedDate: DateTime.tryParse(j['expectedDate']?.toString() ?? '') ?? DateTime.now(),
      subtotal:     double.tryParse(j['subtotal']?.toString() ?? '') ?? 0,
      taxAmount:    double.tryParse(j['taxAmount']?.toString() ?? '') ?? 0,
      totalAmount:  double.tryParse(j['totalAmount']?.toString() ?? '') ?? 0,
      openedAt:     j['openedAt'] != null ? DateTime.tryParse(j['openedAt'].toString()) : null,
      closedAt:     j['closedAt'] != null ? DateTime.tryParse(j['closedAt'].toString()) : null,
      cancelledAt:  j['cancelledAt'] != null ? DateTime.tryParse(j['cancelledAt'].toString()) : null,
      lines: (j['lines'] as List<dynamic>? ?? [])
          .map((e) => PurchaseOrderLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isDraft     => status == PurchaseOrderStatus.draft;
  bool get isOpen      => status == PurchaseOrderStatus.open;
  bool get isClosed    => status == PurchaseOrderStatus.closed;
  bool get isCancelled => status == PurchaseOrderStatus.cancelled;
  bool get canReceive  => isOpen;
  bool get canEdit     => isDraft;
  bool get canCancel   => isDraft || isOpen;
}

enum PurchaseOrderStatus {
  draft(1, 'Draft', 'مسودة'),
  open(2, 'Open', 'مفتوح'),
  closed(3, 'Closed', 'مغلق'),
  cancelled(4, 'Cancelled', 'ملغي');

  const PurchaseOrderStatus(this.value, this.label, this.labelAr);
  final int    value;
  final String label;
  final String labelAr;

  static PurchaseOrderStatus fromValue(dynamic v) {
    // Check if it's the int value directly
    final intVal = int.tryParse(v?.toString() ?? '');
    if (intVal != null) {
      return PurchaseOrderStatus.values.firstWhere(
        (e) => e.value == intVal,
        orElse: () => PurchaseOrderStatus.draft,
      );
    }
    // Check if it's the label string
    final s = v?.toString() ?? '';
    return PurchaseOrderStatus.values.firstWhere(
      (e) => e.label.toLowerCase() == s.toLowerCase(),
      orElse: () => PurchaseOrderStatus.draft,
    );
  }
}

class PurchaseOrderLine {
  const PurchaseOrderLine({
    required this.id,
    required this.itemId,
    required this.description,
    required this.quantity,
    required this.unitCost,
    required this.lineTotal,
    this.taxCodeId,
    this.taxRatePercent = 0,
    this.taxAmount = 0,
  });

  final String  id;
  final String  itemId;
  final String  description;
  final double  quantity;
  final double  unitCost;
  final double  lineTotal;
  final String? taxCodeId;
  final double  taxRatePercent;
  final double  taxAmount;

  factory PurchaseOrderLine.fromJson(Map<String, dynamic> j) =>
      PurchaseOrderLine(
        id:              j['id']?.toString() ?? '',
        itemId:          j['itemId']?.toString() ?? '',
        description:     j['description']?.toString() ?? '',
        quantity:        double.tryParse(j['quantity']?.toString() ?? '') ?? 0,
        unitCost:        double.tryParse(j['unitCost']?.toString() ?? '') ?? 0,
        lineTotal:       double.tryParse(j['lineTotal']?.toString() ?? '') ?? 0,
        taxCodeId:       j['taxCodeId']?.toString(),
        taxRatePercent:  double.tryParse(j['taxRatePercent']?.toString() ?? '') ?? 0,
        taxAmount:       double.tryParse(j['taxAmount']?.toString() ?? '') ?? 0,
      );
}

class CreatePurchaseOrderDto {
  const CreatePurchaseOrderDto({
    required this.vendorId,
    required this.orderDate,
    required this.expectedDate,
    required this.lines,
    this.saveMode = SaveMode.saveAsOpen,
  });

  final String                      vendorId;
  final DateTime                    orderDate;
  final DateTime                    expectedDate;
  final List<CreatePurchaseLineDto> lines;
  final SaveMode                    saveMode;

  Map<String, dynamic> toJson() => {
    'vendorId':     vendorId,
    'orderDate':    _dateOnly(orderDate),
    'expectedDate': _dateOnly(expectedDate),
    'saveMode':     saveMode.value,
    'lines':        lines.map((l) => l.toJson()).toList(),
  };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class CreatePurchaseLineDto {
  const CreatePurchaseLineDto({
    required this.itemId,
    required this.quantity,
    required this.unitCost,
    this.description,
    this.taxCodeId,
  });

  final String  itemId;
  final double  quantity;
  final double  unitCost;
  final String? description;
  final String? taxCodeId;

  Map<String, dynamic> toJson() => {
    'itemId':      itemId,
    'quantity':    quantity,
    'unitCost':    unitCost,
    if (description != null) 'description': description,
    if (taxCodeId != null)   'taxCodeId':   taxCodeId,
  };
}

enum SaveMode {
  draft(1, 'Draft'),
  saveAsOpen(2, 'SaveAsOpen');

  const SaveMode(this.value, this.label);
  final int    value;
  final String label;
}