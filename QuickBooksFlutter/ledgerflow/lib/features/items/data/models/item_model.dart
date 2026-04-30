// item_model.dart
// item_model.dart

class ItemModel {
  const ItemModel({
    required this.id,
    required this.name,
    required this.itemType,
    required this.salesPrice,
    required this.purchasePrice,
    required this.quantityOnHand,
    required this.isActive,
    this.sku,
    this.barcode,
    this.unit,
    this.incomeAccountId,
    this.incomeAccountName,
    this.inventoryAssetAccountId,
    this.inventoryAssetAccountName,
    this.cogsAccountId,
    this.cogsAccountName,
    this.expenseAccountId,
    this.expenseAccountName,
  });

  final String   id;
  final String   name;
  final ItemType itemType;
  final double   salesPrice;
  final double   purchasePrice;
  final double   quantityOnHand;
  final bool     isActive;
  final String?  sku;
  final String?  barcode;
  final String?  unit;
  final String?  incomeAccountId;
  final String?  incomeAccountName;
  final String?  inventoryAssetAccountId;
  final String?  inventoryAssetAccountName;
  final String?  cogsAccountId;
  final String?  cogsAccountName;
  final String?  expenseAccountId;
  final String?  expenseAccountName;

  factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel(
        id:                       json['id'] as String,
        name:                     json['name'] as String,
        itemType:                 ItemType.fromValue(json['itemType'] as int),
        salesPrice:               (json['salesPrice'] as num).toDouble(),
        purchasePrice:            (json['purchasePrice'] as num).toDouble(),
        quantityOnHand:           (json['quantityOnHand'] as num).toDouble(),
        isActive:                 json['isActive'] as bool,
        sku:                      json['sku'] as String?,
        barcode:                  json['barcode'] as String?,
        unit:                     json['unit'] as String?,
        incomeAccountId:          json['incomeAccountId'] as String?,
        incomeAccountName:        json['incomeAccountName'] as String?,
        inventoryAssetAccountId:  json['inventoryAssetAccountId'] as String?,
        inventoryAssetAccountName:json['inventoryAssetAccountName'] as String?,
        cogsAccountId:            json['cogsAccountId'] as String?,
        cogsAccountName:          json['cogsAccountName'] as String?,
        expenseAccountId:         json['expenseAccountId'] as String?,
        expenseAccountName:       json['expenseAccountName'] as String?,
      );

  Map<String, dynamic> toCreateJson() => {
        'name':         name,
        'itemType':     itemType.value,
        'salesPrice':   salesPrice,
        'purchasePrice':purchasePrice,
        'quantityOnHand': quantityOnHand,
        if (sku != null)     'sku':     sku,
        if (barcode != null) 'barcode': barcode,
        if (unit != null)    'unit':    unit,
        if (incomeAccountId != null)
          'incomeAccountId': incomeAccountId,
        if (inventoryAssetAccountId != null)
          'inventoryAssetAccountId': inventoryAssetAccountId,
        if (cogsAccountId != null)
          'cogsAccountId': cogsAccountId,
        if (expenseAccountId != null)
          'expenseAccountId': expenseAccountId,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name':          name,
        'salesPrice':    salesPrice,
        'purchasePrice': purchasePrice,
        if (sku != null)     'sku':     sku,
        if (barcode != null) 'barcode': barcode,
        if (unit != null)    'unit':    unit,
        if (incomeAccountId != null)
          'incomeAccountId': incomeAccountId,
        if (inventoryAssetAccountId != null)
          'inventoryAssetAccountId': inventoryAssetAccountId,
        if (cogsAccountId != null)
          'cogsAccountId': cogsAccountId,
        if (expenseAccountId != null)
          'expenseAccountId': expenseAccountId,
      };

  bool get isInventory    => itemType == ItemType.inventory;
  bool get isService      => itemType == ItemType.service;
  bool get isNonInventory => itemType == ItemType.nonInventory;
  bool get isBundle       => itemType == ItemType.bundle;
  bool get hasStock       => isInventory && quantityOnHand > 0;
}

// ─── ItemType Enum ────────────────────────────────
enum ItemType {
  inventory(1,    'مخزون'),
  nonInventory(2, 'غير مخزون'),
  service(3,      'خدمة'),
  bundle(4,       'حزمة');

  const ItemType(this.value, this.label);
  final int    value;
  final String label;

  static ItemType fromValue(int v) =>
      ItemType.values.firstWhere((e) => e.value == v,
          orElse: () => ItemType.inventory);
}