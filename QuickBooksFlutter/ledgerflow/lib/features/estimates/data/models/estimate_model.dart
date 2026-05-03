// estimate_model.dart

import '../../../../core/utils/json_utils.dart';

class EstimateModel {
  const EstimateModel({
    required this.id,
    required this.estimateNumber,
    required this.customerId,
    required this.estimateDate,
    required this.expirationDate,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.lines,
    this.customerName,
    this.sentAt,
    this.acceptedAt,
    this.declinedAt,
    this.cancelledAt,
  });

  final String id;
  final String estimateNumber;
  final String customerId;
  final String? customerName;
  final DateTime estimateDate;
  final DateTime expirationDate;
  final int status;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final DateTime? sentAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final DateTime? cancelledAt;
  final List<EstimateLineModel> lines;

  factory EstimateModel.fromJson(Map<String, dynamic> json) => EstimateModel(
        id: JsonUtils.asString(json['id']),
        estimateNumber: JsonUtils.asString(json['estimateNumber']),
        customerId: JsonUtils.asString(json['customerId']),
        customerName: JsonUtils.asNullableString(json['customerName']),
        estimateDate: _parseDate(json['estimateDate']),
        expirationDate: _parseDate(json['expirationDate']),
        status: JsonUtils.asInt(json['status']),
        subtotal: JsonUtils.asDouble(json['subtotal']),
        taxAmount: JsonUtils.asDouble(json['taxAmount']),
        totalAmount: JsonUtils.asDouble(json['totalAmount']),
        sentAt: _parseNullableDate(json['sentAt']),
        acceptedAt: _parseNullableDate(json['acceptedAt']),
        declinedAt: _parseNullableDate(json['declinedAt']),
        cancelledAt: _parseNullableDate(json['cancelledAt']),
        lines: JsonUtils.asList(json['lines'], (line) => EstimateLineModel.fromJson(line)),
      );

  bool get isCancelled => cancelledAt != null;
  bool get isAccepted => acceptedAt != null;
  bool get isDeclined => declinedAt != null;

  static DateTime _parseDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  static DateTime? _parseNullableDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '');
}

class EstimateLineModel {
  const EstimateLineModel({
    required this.id,
    required this.itemId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.taxRatePercent,
    required this.taxAmount,
    required this.lineTotal,
    this.taxCodeId,
  });

  final String id;
  final String itemId;
  final String description;
  final double quantity;
  final double unitPrice;
  final String? taxCodeId;
  final double taxRatePercent;
  final double taxAmount;
  final double lineTotal;

  factory EstimateLineModel.fromJson(Map<String, dynamic> json) => EstimateLineModel(
        id: JsonUtils.asString(json['id']),
        itemId: JsonUtils.asString(json['itemId']),
        description: JsonUtils.asString(json['description']),
        quantity: JsonUtils.asDouble(json['quantity']),
        unitPrice: JsonUtils.asDouble(json['unitPrice']),
        taxCodeId: JsonUtils.asNullableString(json['taxCodeId']),
        taxRatePercent: JsonUtils.asDouble(json['taxRatePercent']),
        taxAmount: JsonUtils.asDouble(json['taxAmount']),
        lineTotal: JsonUtils.asDouble(json['lineTotal']),
      );
}

class CreateEstimateDto {
  const CreateEstimateDto({
    required this.customerId,
    required this.estimateDate,
    required this.expirationDate,
    required this.saveMode,
    required this.lines,
  });

  final String customerId;
  final DateTime estimateDate;
  final DateTime expirationDate;
  final int saveMode;
  final List<CreateEstimateLineDto> lines;

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'estimateDate': _dateOnly(estimateDate),
        'expirationDate': _dateOnly(expirationDate),
        'saveMode': saveMode,
        'lines': lines.map((line) => line.toJson()).toList(),
      };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class CreateEstimateLineDto {
  const CreateEstimateLineDto({
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
