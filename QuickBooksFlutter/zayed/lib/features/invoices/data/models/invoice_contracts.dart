// invoice_contracts.dart

import '../../../../core/utils/json_utils.dart';

class InvoiceModel {
  const InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.invoiceDate,
    required this.dueDate,
    required this.status,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.creditAppliedAmount,
    required this.returnedAmount,
    required this.balanceDue,
    this.salesOrderId,
    this.postedTransactionId,
    this.postedAt,
    this.reversalTransactionId,
    this.voidedAt,
    this.lines = const [],
  });

  final String id;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final int status;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double paidAmount;
  final double creditAppliedAmount;
  final double returnedAmount;
  final double balanceDue;
  final String? salesOrderId;
  final String? postedTransactionId;
  final DateTime? postedAt;
  final String? reversalTransactionId;
  final DateTime? voidedAt;
  final List<InvoiceLineModel> lines;

  factory InvoiceModel.fromJson(Map<String, dynamic> json) => InvoiceModel(
        id: JsonUtils.asString(json['id']),
        invoiceNumber: JsonUtils.asString(json['invoiceNumber']),
        customerId: JsonUtils.asString(json['customerId']),
        customerName: JsonUtils.asString(json['customerName']),
        salesOrderId: JsonUtils.asNullableString(json['salesOrderId']),
        invoiceDate: _parseDate(json['invoiceDate']),
        dueDate: _parseDate(json['dueDate']),
        status: JsonUtils.asInt(json['status']),
        subtotal: JsonUtils.asDouble(json['subtotal']),
        discountAmount: JsonUtils.asDouble(json['discountAmount']),
        taxAmount: JsonUtils.asDouble(json['taxAmount']),
        totalAmount: JsonUtils.asDouble(json['totalAmount']),
        paidAmount: JsonUtils.asDouble(json['paidAmount']),
        creditAppliedAmount: JsonUtils.asDouble(json['creditAppliedAmount']),
        returnedAmount: JsonUtils.asDouble(json['returnedAmount']),
        balanceDue: JsonUtils.asDouble(json['balanceDue']),
        postedTransactionId: JsonUtils.asNullableString(json['postedTransactionId']),
        postedAt: _parseNullableDate(json['postedAt']),
        reversalTransactionId: JsonUtils.asNullableString(json['reversalTransactionId']),
        voidedAt: _parseNullableDate(json['voidedAt']),
        lines: JsonUtils.asList(
          json['lines'],
          (line) => InvoiceLineModel.fromJson(line),
        ),
      );

  bool get isDraft => status == 1;
  bool get isPosted => status == 2;
  bool get isVoid => status == 3 || voidedAt != null;
  bool get isPartiallyPaid => status == 4;
  bool get isPaid => status == 5 || balanceDue <= 0;

  static DateTime _parseDate(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();

  static DateTime? _parseNullableDate(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '');
}

class InvoiceLineModel {
  const InvoiceLineModel({
    required this.id,
    required this.itemId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.discountPercent,
    required this.taxAmount,
    required this.lineTotal,
    this.salesOrderLineId,
    this.taxCodeId,
    this.taxRatePercent,
  });

  final String id;
  final String itemId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double discountPercent;
  final double taxAmount;
  final double lineTotal;
  final String? salesOrderLineId;
  final String? taxCodeId;
  final double? taxRatePercent;

  factory InvoiceLineModel.fromJson(Map<String, dynamic> json) => InvoiceLineModel(
        id: JsonUtils.asString(json['id']),
        itemId: JsonUtils.asString(json['itemId']),
        salesOrderLineId: JsonUtils.asNullableString(json['salesOrderLineId']),
        description: JsonUtils.asString(json['description']),
        quantity: JsonUtils.asDouble(json['quantity']),
        unitPrice: JsonUtils.asDouble(json['unitPrice']),
        discountPercent: JsonUtils.asDouble(json['discountPercent']),
        taxCodeId: JsonUtils.asNullableString(json['taxCodeId']),
        taxRatePercent: json['taxRatePercent'] == null
            ? null
            : JsonUtils.asDouble(json['taxRatePercent']),
        taxAmount: JsonUtils.asDouble(json['taxAmount']),
        lineTotal: JsonUtils.asDouble(json['lineTotal']),
      );
}

class CreateInvoiceDto {
  const CreateInvoiceDto({
    required this.customerId,
    required this.invoiceDate,
    required this.dueDate,
    required this.saveMode,
    required this.lines,
  });

  final String customerId;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final int saveMode;
  final List<CreateInvoiceLineDto> lines;

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'invoiceDate': _dateOnly(invoiceDate),
        'dueDate': _dateOnly(dueDate),
        'saveMode': saveMode,
        'lines': lines.map((line) => line.toJson()).toList(),
      };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class UpdateInvoiceDto {
  const UpdateInvoiceDto({
    required this.customerId,
    required this.invoiceDate,
    required this.dueDate,
    required this.lines,
  });

  final String customerId;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final List<CreateInvoiceLineDto> lines;

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'invoiceDate': CreateInvoiceDto._dateOnly(invoiceDate),
        'dueDate': CreateInvoiceDto._dateOnly(dueDate),
        'lines': lines.map((line) => line.toJson()).toList(),
      };
}

class CreateInvoiceLineDto {
  const CreateInvoiceLineDto({
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
