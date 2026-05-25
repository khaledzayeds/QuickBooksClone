// transaction_model.dart

import '../../../../core/utils/json_utils.dart';

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.transactionType,
    required this.transactionDate,
    required this.referenceNumber,
    required this.status,
    required this.totalDebit,
    required this.totalCredit,
    required this.lines,
    this.sourceEntityType,
    this.sourceEntityId,
  });

  final String id;
  final String transactionType;
  final DateTime transactionDate;
  final String referenceNumber;
  final String? sourceEntityType;
  final String? sourceEntityId;
  final String status;
  final double totalDebit;
  final double totalCredit;
  final List<TransactionLineModel> lines;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: JsonUtils.asString(json['id']),
        transactionType: JsonUtils.asString(json['transactionType']),
        transactionDate:
            DateTime.tryParse(json['transactionDate']?.toString() ?? '') ??
            DateTime.now(),
        referenceNumber: JsonUtils.asString(json['referenceNumber']),
        sourceEntityType: JsonUtils.asNullableString(json['sourceEntityType']),
        sourceEntityId: JsonUtils.asNullableString(json['sourceEntityId']),
        status: JsonUtils.asString(json['status']),
        totalDebit: JsonUtils.asDouble(json['totalDebit']),
        totalCredit: JsonUtils.asDouble(json['totalCredit']),
        lines: JsonUtils.asList(
          json['lines'],
          (line) => TransactionLineModel.fromJson(line),
        ),
      );

  bool get isVoided =>
      status.toLowerCase() == 'void' || status.toLowerCase() == 'voided';
}

class TransactionLineModel {
  const TransactionLineModel({
    required this.id,
    required this.accountId,
    required this.description,
    required this.debit,
    required this.credit,
    this.accountCode,
    this.accountName,
  });

  final String id;
  final String accountId;
  final String? accountCode;
  final String? accountName;
  final String description;
  final double debit;
  final double credit;

  factory TransactionLineModel.fromJson(Map<String, dynamic> json) =>
      TransactionLineModel(
        id: JsonUtils.asString(json['id']),
        accountId: JsonUtils.asString(json['accountId']),
        accountCode: JsonUtils.asNullableString(json['accountCode']),
        accountName: JsonUtils.asNullableString(json['accountName']),
        description: JsonUtils.asString(json['description']),
        debit: JsonUtils.asDouble(json['debit']),
        credit: JsonUtils.asDouble(json['credit']),
      );
}
