// sales_return_model.dart

import '../../../../core/utils/json_utils.dart';

class SalesReturnModel {
  const SalesReturnModel({
    required this.id,
    required this.returnNumber,
    required this.invoiceId,
    required this.customerId,
    required this.returnDate,
    required this.status,
    required this.totalAmount,
    required this.lines,
    this.invoiceNumber,
    this.customerName,
    this.postedTransactionId,
    this.postedAt,
    this.reversalTransactionId,
    this.voidedAt,
  });

  final String id;
  final String returnNumber;
  final String invoiceId;
  final String? invoiceNumber;
  final String customerId;
  final String? customerName;
  final DateTime returnDate;
  final int status;
  final double totalAmount;
  final String? postedTransactionId;
  final DateTime? postedAt;
  final String? reversalTransactionId;
  final DateTime? voidedAt;
  final List<SalesReturnLineModel> lines;

  factory SalesReturnModel.fromJson(Map<String, dynamic> json) => SalesReturnModel(
        id: JsonUtils.asString(json['id']),
        returnNumber: JsonUtils.asString(json['returnNumber']),
        invoiceId: JsonUtils.asString(json['invoiceId']),
        invoiceNumber: JsonUtils.asNullableString(json['invoiceNumber']),
        customerId: JsonUtils.asString(json['customerId']),
        customerName: JsonUtils.asNullableString(json['customerName']),
        returnDate: _parseDate(json['returnDate']),
        status: JsonUtils.asInt(json['status']),
        totalAmount: JsonUtils.asDouble(json['totalAmount']),
        postedTransactionId: JsonUtils.asNullableString(json['postedTransactionId']),
        postedAt: _parseNullableDate(json['postedAt']),
        reversalTransactionId: JsonUtils.asNullableString(json['reversalTransactionId']),
        voidedAt: _parseNullableDate(json['voidedAt']),
        lines: JsonUtils.asList(
          json['lines'],
          (line) => SalesReturnLineModel.fromJson(line),
        ),
      );

  bool get isVoid => voidedAt != null;

  static DateTime _parseDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  static DateTime? _parseNullableDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '');
}

class SalesReturnLineModel {
  const SalesReturnLineModel({
    required this.id,
    required this.invoiceLineId,
    required this.itemId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.discountPercent,
    required this.lineTotal,
  });

  final String id;
  final String invoiceLineId;
  final String itemId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double discountPercent;
  final double lineTotal;

  factory SalesReturnLineModel.fromJson(Map<String, dynamic> json) => SalesReturnLineModel(
        id: JsonUtils.asString(json['id']),
        invoiceLineId: JsonUtils.asString(json['invoiceLineId']),
        itemId: JsonUtils.asString(json['itemId']),
        description: JsonUtils.asString(json['description']),
        quantity: JsonUtils.asDouble(json['quantity']),
        unitPrice: JsonUtils.asDouble(json['unitPrice']),
        discountPercent: JsonUtils.asDouble(json['discountPercent']),
        lineTotal: JsonUtils.asDouble(json['lineTotal']),
      );
}

class CreateSalesReturnDto {
  const CreateSalesReturnDto({
    required this.invoiceId,
    required this.returnDate,
    required this.lines,
  });

  final String invoiceId;
  final DateTime returnDate;
  final List<CreateSalesReturnLineDto> lines;

  Map<String, dynamic> toJson() => {
        'invoiceId': invoiceId,
        'returnDate': _dateOnly(returnDate),
        'lines': lines.map((line) => line.toJson()).toList(),
      };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class CreateSalesReturnLineDto {
  const CreateSalesReturnLineDto({
    required this.invoiceLineId,
    required this.quantity,
    this.unitPrice,
    this.discountPercent = 0,
  });

  final String invoiceLineId;
  final double quantity;
  final double? unitPrice;
  final double discountPercent;

  Map<String, dynamic> toJson() => {
        'invoiceLineId': invoiceLineId,
        'quantity': quantity,
        if (unitPrice != null && unitPrice! > 0) 'unitPrice': unitPrice,
        'discountPercent': discountPercent,
      };
}
