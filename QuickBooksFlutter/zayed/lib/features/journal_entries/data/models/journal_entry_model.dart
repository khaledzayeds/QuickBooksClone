// journal_entry_model.dart

import '../../../../core/utils/json_utils.dart';

class JournalEntryModel {
  const JournalEntryModel({
    required this.id,
    required this.entryNumber,
    required this.entryDate,
    required this.memo,
    required this.status,
    required this.totalDebit,
    required this.totalCredit,
    required this.lines,
    this.postedTransactionId,
    this.reversalTransactionId,
    this.postedAt,
    this.voidedAt,
  });

  final String id;
  final String entryNumber;
  final DateTime entryDate;
  final String memo;
  final int status;
  final double totalDebit;
  final double totalCredit;
  final String? postedTransactionId;
  final String? reversalTransactionId;
  final DateTime? postedAt;
  final DateTime? voidedAt;
  final List<JournalEntryLineModel> lines;

  factory JournalEntryModel.fromJson(Map<String, dynamic> json) => JournalEntryModel(
        id: JsonUtils.asString(json['id']),
        entryNumber: JsonUtils.asString(json['entryNumber']),
        entryDate: _parseDate(json['entryDate']),
        memo: JsonUtils.asString(json['memo']),
        status: JsonUtils.asInt(json['status']),
        totalDebit: JsonUtils.asDouble(json['totalDebit']),
        totalCredit: JsonUtils.asDouble(json['totalCredit']),
        postedTransactionId: JsonUtils.asNullableString(json['postedTransactionId']),
        reversalTransactionId: JsonUtils.asNullableString(json['reversalTransactionId']),
        postedAt: _parseNullableDate(json['postedAt']),
        voidedAt: _parseNullableDate(json['voidedAt']),
        lines: JsonUtils.asList(json['lines'], (line) => JournalEntryLineModel.fromJson(line)),
      );

  bool get isPosted => postedAt != null;
  bool get isVoid => voidedAt != null;

  static DateTime _parseDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  static DateTime? _parseNullableDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '');
}

class JournalEntryLineModel {
  const JournalEntryLineModel({
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

  factory JournalEntryLineModel.fromJson(Map<String, dynamic> json) => JournalEntryLineModel(
        id: JsonUtils.asString(json['id']),
        accountId: JsonUtils.asString(json['accountId']),
        accountCode: JsonUtils.asNullableString(json['accountCode']),
        accountName: JsonUtils.asNullableString(json['accountName']),
        description: JsonUtils.asString(json['description']),
        debit: JsonUtils.asDouble(json['debit']),
        credit: JsonUtils.asDouble(json['credit']),
      );
}

class CreateJournalEntryDto {
  const CreateJournalEntryDto({
    required this.entryDate,
    required this.memo,
    required this.saveMode,
    required this.lines,
  });

  final DateTime entryDate;
  final String memo;
  final int saveMode;
  final List<CreateJournalEntryLineDto> lines;

  Map<String, dynamic> toJson() => {
        'entryDate': _dateOnly(entryDate),
        if (memo.trim().isNotEmpty) 'memo': memo.trim(),
        'saveMode': saveMode,
        'lines': lines.map((line) => line.toJson()).toList(),
      };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class CreateJournalEntryLineDto {
  const CreateJournalEntryLineDto({
    required this.accountId,
    required this.debit,
    required this.credit,
    this.description,
  });

  final String accountId;
  final String? description;
  final double debit;
  final double credit;

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        if (description != null && description!.trim().isNotEmpty) 'description': description!.trim(),
        'debit': debit,
        'credit': credit,
      };
}
