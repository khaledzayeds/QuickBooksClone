// sales_receipt_models.dart

import '../../../../core/utils/json_utils.dart';

class SalesReceiptModel {
  const SalesReceiptModel({
    required this.id,
    required this.receiptNumber,
    required this.customerId,
    required this.customerName,
    required this.receiptDate,
    required this.depositAccountId,
    required this.depositAccountName,
    required this.paymentMethod,
    required this.status,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceDue,
    this.receiptPaymentId,
    this.postedAt,
    this.voidedAt,
    this.lines = const [],
  });

  final String id;
  final String receiptNumber;
  final String customerId;
  final String customerName;
  final DateTime receiptDate;
  final String? depositAccountId;
  final String? depositAccountName;
  final String? paymentMethod;
  final int status;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double paidAmount;
  final double balanceDue;
  final String? receiptPaymentId;
  final DateTime? postedAt;
  final DateTime? voidedAt;
  final List<SalesReceiptLineModel> lines;

  factory SalesReceiptModel.fromJson(Map<String, dynamic> json) =>
      SalesReceiptModel(
        id: JsonUtils.asString(json['id']),
        receiptNumber: JsonUtils.asString(json['invoiceNumber']),
        customerId: JsonUtils.asString(json['customerId']),
        customerName: JsonUtils.asString(json['customerName']),
        receiptDate: _parseDate(json['invoiceDate']),
        depositAccountId: JsonUtils.asNullableString(json['depositAccountId']),
        depositAccountName: JsonUtils.asNullableString(json['depositAccountName']),
        paymentMethod: JsonUtils.asNullableString(json['paymentMethod']),
        receiptPaymentId: JsonUtils.asNullableString(json['receiptPaymentId']),
        status: JsonUtils.asInt(json['status']),
        subtotal: JsonUtils.asDouble(json['subtotal']),
        discountAmount: JsonUtils.asDouble(json['discountAmount']),
        taxAmount: JsonUtils.asDouble(json['taxAmount']),
        totalAmount: JsonUtils.asDouble(json['totalAmount']),
        paidAmount: JsonUtils.asDouble(json['paidAmount']),
        balanceDue: JsonUtils.asDouble(json['balanceDue']),
        postedAt: _parseNullableDate(json['postedAt']),
        voidedAt: _parseNullableDate(json['voidedAt']),
        lines: JsonUtils.asList(
          json['lines'],
          (line) => SalesReceiptLineModel.fromJson(line),
        ),
      );

  bool get isVoid => status == 3 || voidedAt != null;

  static DateTime _parseDate(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

  static DateTime? _parseNullableDate(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '');
}

class SalesReceiptLineModel {
  const SalesReceiptLineModel({
    required this.id,
    required this.itemId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.discountPercent,
    required this.taxAmount,
    required this.lineTotal,
    this.taxCodeId,
  });

  final String id;
  final String itemId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double discountPercent;
  final double taxAmount;
  final double lineTotal;
  final String? taxCodeId;

  factory SalesReceiptLineModel.fromJson(Map<String, dynamic> json) =>
      SalesReceiptLineModel(
        id: JsonUtils.asString(json['id']),
        itemId: JsonUtils.asString(json['itemId']),
        description: JsonUtils.asString(json['description']),
        quantity: JsonUtils.asDouble(json['quantity']),
        unitPrice: JsonUtils.asDouble(json['unitPrice']),
        discountPercent: JsonUtils.asDouble(json['discountPercent']),
        taxCodeId: JsonUtils.asNullableString(json['taxCodeId']),
        taxAmount: JsonUtils.asDouble(json['taxAmount']),
        lineTotal: JsonUtils.asDouble(json['lineTotal']),
      );
}

class CreateSalesReceiptDto {
  const CreateSalesReceiptDto({
    required this.customerId,
    required this.receiptDate,
    required this.depositAccountId,
    required this.paymentMethod,
    required this.lines,
  });

  final String customerId;
  final DateTime receiptDate;
  final String depositAccountId;
  final String paymentMethod;
  final List<CreateSalesReceiptLineDto> lines;

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'receiptDate': _dateOnly(receiptDate),
        'depositAccountId': depositAccountId,
        'paymentMethod': paymentMethod,
        'lines': lines.map((line) => line.toJson()).toList(),
      };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class CreateSalesReceiptLineDto {
  const CreateSalesReceiptLineDto({
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    this.description,
    this.discountPercent = 0,
    this.taxCodeId,
  });

  final String itemId;
  final double quantity;
  final double unitPrice;
  final String? description;
  final double discountPercent;
  final String? taxCodeId;

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        if (description != null && description!.trim().isNotEmpty)
          'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'discountPercent': discountPercent,
        if (taxCodeId != null && taxCodeId!.isNotEmpty) 'taxCodeId': taxCodeId,
      };
}
