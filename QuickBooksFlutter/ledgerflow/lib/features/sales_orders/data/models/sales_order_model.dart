// sales_order_model.dart

import '../../../../core/utils/json_utils.dart';

class SalesOrderModel {
  const SalesOrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.orderDate,
    required this.expectedDate,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.lines,
    this.customerName,
    this.estimateId,
    this.openedAt,
    this.closedAt,
    this.cancelledAt,
  });

  final String id;
  final String orderNumber;
  final String customerId;
  final String? customerName;
  final String? estimateId;
  final DateTime orderDate;
  final DateTime expectedDate;
  final int status;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final DateTime? openedAt;
  final DateTime? closedAt;
  final DateTime? cancelledAt;
  final List<SalesOrderLineModel> lines;

  factory SalesOrderModel.fromJson(Map<String, dynamic> json) => SalesOrderModel(
        id: JsonUtils.asString(json['id']),
        orderNumber: JsonUtils.asString(json['orderNumber']),
        customerId: JsonUtils.asString(json['customerId']),
        customerName: JsonUtils.asNullableString(json['customerName']),
        estimateId: JsonUtils.asNullableString(json['estimateId']),
        orderDate: _parseDate(json['orderDate']),
        expectedDate: _parseDate(json['expectedDate']),
        status: JsonUtils.asInt(json['status']),
        subtotal: JsonUtils.asDouble(json['subtotal']),
        taxAmount: JsonUtils.asDouble(json['taxAmount']),
        totalAmount: JsonUtils.asDouble(json['totalAmount']),
        openedAt: _parseNullableDate(json['openedAt']),
        closedAt: _parseNullableDate(json['closedAt']),
        cancelledAt: _parseNullableDate(json['cancelledAt']),
        lines: JsonUtils.asList(json['lines'], (line) => SalesOrderLineModel.fromJson(line)),
      );

  bool get isCancelled => cancelledAt != null;
  bool get isClosed => closedAt != null;
  bool get isOpen => openedAt != null && closedAt == null && cancelledAt == null;

  static DateTime _parseDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  static DateTime? _parseNullableDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '');
}

class SalesOrderLineModel {
  const SalesOrderLineModel({
    required this.id,
    required this.itemId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.taxRatePercent,
    required this.taxAmount,
    required this.lineTotal,
    this.estimateLineId,
    this.taxCodeId,
  });

  final String id;
  final String itemId;
  final String? estimateLineId;
  final String description;
  final double quantity;
  final double unitPrice;
  final String? taxCodeId;
  final double taxRatePercent;
  final double taxAmount;
  final double lineTotal;

  factory SalesOrderLineModel.fromJson(Map<String, dynamic> json) => SalesOrderLineModel(
        id: JsonUtils.asString(json['id']),
        itemId: JsonUtils.asString(json['itemId']),
        estimateLineId: JsonUtils.asNullableString(json['estimateLineId']),
        description: JsonUtils.asString(json['description']),
        quantity: JsonUtils.asDouble(json['quantity']),
        unitPrice: JsonUtils.asDouble(json['unitPrice']),
        taxCodeId: JsonUtils.asNullableString(json['taxCodeId']),
        taxRatePercent: JsonUtils.asDouble(json['taxRatePercent']),
        taxAmount: JsonUtils.asDouble(json['taxAmount']),
        lineTotal: JsonUtils.asDouble(json['lineTotal']),
      );
}

class CreateSalesOrderDto {
  const CreateSalesOrderDto({
    required this.customerId,
    required this.orderDate,
    required this.expectedDate,
    required this.saveMode,
    required this.lines,
  });

  final String customerId;
  final DateTime orderDate;
  final DateTime expectedDate;
  final int saveMode;
  final List<CreateSalesOrderLineDto> lines;

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'orderDate': _dateOnly(orderDate),
        'expectedDate': _dateOnly(expectedDate),
        'saveMode': saveMode,
        'lines': lines.map((line) => line.toJson()).toList(),
      };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class CreateSalesOrderLineDto {
  const CreateSalesOrderLineDto({
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    this.description,
    this.taxCodeId,
  });

  final String itemId;
  final String? description;
  final double quantity;
  final double unitPrice;
  final String? taxCodeId;

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        if (description != null && description!.trim().isNotEmpty) 'description': description!.trim(),
        'quantity': quantity,
        'unitPrice': unitPrice,
        if (taxCodeId != null && taxCodeId!.isNotEmpty) 'taxCodeId': taxCodeId,
      };
}
