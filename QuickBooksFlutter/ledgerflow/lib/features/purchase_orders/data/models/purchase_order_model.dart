class PurchaseOrderModel {
  const PurchaseOrderModel({
    required this.id,
    required this.orderNumber,
    required this.vendorId,
    required this.vendorName,
    required this.status,
    required this.orderDate,
    required this.totalAmount,
    this.expectedDate,
    this.notes,
    this.lines = const [],
  });

  final String                   id;
  final String                   orderNumber;
  final String                   vendorId;
  final String                   vendorName;
  final String                   status;
  final DateTime                 orderDate;
  final double                   totalAmount;
  final DateTime?                expectedDate;
  final String?                  notes;
  final List<PurchaseOrderLine>  lines;

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> j) =>
      PurchaseOrderModel(
        id:           j['id'].toString(),
        orderNumber:  j['orderNumber'] as String? ?? '',
        vendorId:     j['vendorId'].toString(),
        vendorName:   j['vendorName'] as String? ?? '',
        status:       j['status']    as String? ?? 'Draft',
        orderDate:    DateTime.parse(j['orderDate'] as String),
        totalAmount:  (j['totalAmount'] as num?)?.toDouble() ?? 0,
        expectedDate: j['expectedDate'] != null
            ? DateTime.tryParse(j['expectedDate'] as String)
            : null,
        notes: j['notes'] as String?,
        lines: (j['lines'] as List<dynamic>? ?? [])
            .map((e) => PurchaseOrderLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // Status helpers
  bool get isDraft     => status == 'Draft';
  bool get isOpen      => status == 'Open';
  bool get isClosed    => status == 'Closed';
  bool get isCancelled => status == 'Cancelled';
  bool get canReceive  => isOpen;
  bool get canEdit     => isDraft;
  bool get canCancel   => isDraft || isOpen;
}

// ─── Line ─────────────────────────────────────────────────────────────
class PurchaseOrderLine {
  const PurchaseOrderLine({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitCost,
    required this.lineTotal,
    this.description,
    this.receivedQuantity = 0,
  });

  final String  id;
  final String  itemId;
  final String  itemName;
  final double  quantity;
  final double  unitCost;
  final double  lineTotal;
  final String? description;
  final double  receivedQuantity;

  double get remainingQuantity => quantity - receivedQuantity;

  factory PurchaseOrderLine.fromJson(Map<String, dynamic> j) =>
      PurchaseOrderLine(
        id:               j['id'].toString(),
        itemId:           j['itemId'].toString(),
        itemName:         j['itemName'] as String? ?? '',
        quantity:         (j['quantity']         as num).toDouble(),
        unitCost:         (j['unitCost']          as num).toDouble(),
        lineTotal:        (j['lineTotal']         as num?)?.toDouble() ?? 0,
        description:      j['description']        as String?,
        receivedQuantity: (j['receivedQuantity']  as num?)?.toDouble() ?? 0,
      );
}

// ─── Create DTO ───────────────────────────────────────────────────────
class CreatePurchaseOrderDto {
  const CreatePurchaseOrderDto({
    required this.vendorId,
    required this.orderDate,
    required this.lines,
    this.expectedDate,
    this.notes,
    this.saveMode = SaveMode.draft,
  });

  final String                      vendorId;
  final DateTime                    orderDate;
  final List<CreatePurchaseLineDto> lines;
  final DateTime?                   expectedDate;
  final String?                     notes;
  final SaveMode                    saveMode;

  Map<String, dynamic> toJson() => {
    'vendorId':   vendorId,
    'orderDate':  orderDate.toIso8601String(),
    'saveMode':   saveMode.value,
    if (expectedDate != null) 'expectedDate': expectedDate!.toIso8601String(),
    if (notes != null) 'notes': notes,
    'lines': lines.map((l) => l.toJson()).toList(),
  };
}

class CreatePurchaseLineDto {
  const CreatePurchaseLineDto({
    required this.itemId,
    required this.quantity,
    required this.unitCost,
    this.description,
  });

  final String  itemId;
  final double  quantity;
  final double  unitCost;
  final String? description;

  Map<String, dynamic> toJson() => {
    'itemId':      itemId,
    'quantity':    quantity,
    'unitCost':    unitCost,
    if (description != null) 'description': description,
  };
}

enum SaveMode {
  draft(1, 'Draft'),
  saveAndOpen(2, 'SaveAndOpen');

  const SaveMode(this.value, this.label);
  final int    value;
  final String label;
}