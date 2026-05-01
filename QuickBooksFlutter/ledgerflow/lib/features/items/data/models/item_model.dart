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
        id:                        json['id']?.toString() ?? '',
        name:                      json['name']?.toString() ?? '',
        itemType:                  ItemType.fromValue(
                                     int.tryParse(json['itemType']?.toString() ?? '') ?? 1),
        salesPrice:                double.tryParse(json['salesPrice']?.toString() ?? '') ?? 0,
        purchasePrice:             double.tryParse(json['purchasePrice']?.toString() ?? '') ?? 0,
        quantityOnHand:            double.tryParse(json['quantityOnHand']?.toString() ?? '') ?? 0,
        isActive:                  json['isActive'] == true || json['isActive'] == 1,
        sku:                       json['sku']?.toString(),
        barcode:                   json['barcode']?.toString(),
        unit:                      json['unit']?.toString(),
        incomeAccountId:           json['incomeAccountId']?.toString(),
        incomeAccountName:         json['incomeAccountName']?.toString(),
        inventoryAssetAccountId:   json['inventoryAssetAccountId']?.toString(),
        inventoryAssetAccountName: json['inventoryAssetAccountName']?.toString(),
        cogsAccountId:             json['cogsAccountId']?.toString(),
        cogsAccountName:           json['cogsAccountName']?.toString(),
        expenseAccountId:          json['expenseAccountId']?.toString(),
        expenseAccountName:        json['expenseAccountName']?.toString(),
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