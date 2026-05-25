// banking_models.dart

import '../../../../core/utils/json_utils.dart';

class BankAccountModel {
  const BankAccountModel({
    required this.id,
    required this.code,
    required this.name,
    required this.accountType,
    required this.balance,
    required this.isActive,
  });

  final String id;
  final String code;
  final String name;
  final int accountType;
  final double balance;
  final bool isActive;

  String get displayName => code.isEmpty ? name : '$code - $name';

  factory BankAccountModel.fromJson(Map<String, dynamic> json) => BankAccountModel(
        id: JsonUtils.asString(json['id']),
        code: JsonUtils.asString(json['code']),
        name: JsonUtils.asString(json['name']),
        accountType: JsonUtils.asInt(json['accountType']),
        balance: JsonUtils.asDouble(json['balance']),
        isActive: json['isActive'] == true || json['isActive']?.toString().toLowerCase() == 'true',
      );
}

class BankRegisterResponseModel {
  const BankRegisterResponseModel({
    required this.accountId,
    required this.accountName,
    required this.openingBalance,
    required this.endingBalance,
    required this.items,
  });

  final String accountId;
  final String accountName;
  final double openingBalance;
  final double endingBalance;
  final List<BankRegisterLineModel> items;

  factory BankRegisterResponseModel.fromJson(Map<String, dynamic> json) => BankRegisterResponseModel(
        accountId: JsonUtils.asString(json['accountId']),
        accountName: JsonUtils.asString(json['accountName']),
        openingBalance: JsonUtils.asDouble(json['openingBalance']),
        endingBalance: JsonUtils.asDouble(json['endingBalance']),
        items: JsonUtils.asList(json['items'], (line) => BankRegisterLineModel.fromJson(line)),
      );
}

class BankRegisterLineModel {
  const BankRegisterLineModel({
    required this.transactionId,
    required this.transactionDate,
    required this.transactionType,
    required this.referenceNumber,
    required this.description,
    required this.debit,
    required this.credit,
    required this.amount,
    required this.runningBalance,
    this.sourceEntityType,
    this.sourceEntityId,
  });

  final String transactionId;
  final DateTime transactionDate;
  final String transactionType;
  final String referenceNumber;
  final String description;
  final double debit;
  final double credit;
  final double amount;
  final double runningBalance;
  final String? sourceEntityType;
  final String? sourceEntityId;

  factory BankRegisterLineModel.fromJson(Map<String, dynamic> json) => BankRegisterLineModel(
        transactionId: JsonUtils.asString(json['transactionId']),
        transactionDate: DateTime.tryParse(json['transactionDate']?.toString() ?? '') ?? DateTime.now(),
        transactionType: JsonUtils.asString(json['transactionType']),
        referenceNumber: JsonUtils.asString(json['referenceNumber']),
        description: JsonUtils.asString(json['description']),
        debit: JsonUtils.asDouble(json['debit']),
        credit: JsonUtils.asDouble(json['credit']),
        amount: JsonUtils.asDouble(json['amount']),
        runningBalance: JsonUtils.asDouble(json['runningBalance']),
        sourceEntityType: JsonUtils.asNullableString(json['sourceEntityType']),
        sourceEntityId: JsonUtils.asNullableString(json['sourceEntityId']),
      );
}

class BankReconcilePreviewModel {
  const BankReconcilePreviewModel({
    required this.accountId,
    required this.accountName,
    required this.statementDate,
    required this.bookBalance,
    required this.statementEndingBalance,
    required this.difference,
    required this.isBalanced,
    required this.registerLines,
  });

  final String accountId;
  final String accountName;
  final DateTime statementDate;
  final double bookBalance;
  final double statementEndingBalance;
  final double difference;
  final bool isBalanced;
  final List<BankRegisterLineModel> registerLines;

  factory BankReconcilePreviewModel.fromJson(Map<String, dynamic> json) => BankReconcilePreviewModel(
        accountId: JsonUtils.asString(json['accountId']),
        accountName: JsonUtils.asString(json['accountName']),
        statementDate: DateTime.tryParse(json['statementDate']?.toString() ?? '') ?? DateTime.now(),
        bookBalance: JsonUtils.asDouble(json['bookBalance']),
        statementEndingBalance: JsonUtils.asDouble(json['statementEndingBalance']),
        difference: JsonUtils.asDouble(json['difference']),
        isBalanced: json['isBalanced'] == true || json['isBalanced']?.toString().toLowerCase() == 'true',
        registerLines: JsonUtils.asList(json['registerLines'], (line) => BankRegisterLineModel.fromJson(line)),
      );
}

class CreateBankTransferDto {
  const CreateBankTransferDto({required this.fromAccountId, required this.toAccountId, required this.transferDate, required this.amount, this.memo});
  final String fromAccountId;
  final String toAccountId;
  final DateTime transferDate;
  final double amount;
  final String? memo;
  Map<String, dynamic> toJson() => {'fromAccountId': fromAccountId, 'toAccountId': toAccountId, 'transferDate': _dateOnly(transferDate), 'amount': amount, if (memo != null && memo!.trim().isNotEmpty) 'memo': memo!.trim()};
}

class CreateBankDepositDto {
  const CreateBankDepositDto({required this.depositAccountId, required this.offsetAccountId, required this.depositDate, required this.amount, this.receivedFrom, this.memo});
  final String depositAccountId;
  final String offsetAccountId;
  final DateTime depositDate;
  final double amount;
  final String? receivedFrom;
  final String? memo;
  Map<String, dynamic> toJson() => {'depositAccountId': depositAccountId, 'offsetAccountId': offsetAccountId, 'depositDate': _dateOnly(depositDate), 'amount': amount, if (receivedFrom != null && receivedFrom!.trim().isNotEmpty) 'receivedFrom': receivedFrom!.trim(), if (memo != null && memo!.trim().isNotEmpty) 'memo': memo!.trim()};
}

class CreateBankCheckDto {
  const CreateBankCheckDto({required this.bankAccountId, required this.expenseAccountId, required this.checkDate, required this.amount, this.payee, this.memo});
  final String bankAccountId;
  final String expenseAccountId;
  final DateTime checkDate;
  final double amount;
  final String? payee;
  final String? memo;
  Map<String, dynamic> toJson() => {'bankAccountId': bankAccountId, 'expenseAccountId': expenseAccountId, 'checkDate': _dateOnly(checkDate), 'amount': amount, if (payee != null && payee!.trim().isNotEmpty) 'payee': payee!.trim(), if (memo != null && memo!.trim().isNotEmpty) 'memo': memo!.trim()};
}

class BankReconcilePreviewDto {
  const BankReconcilePreviewDto({required this.accountId, required this.statementDate, required this.statementEndingBalance});
  final String accountId;
  final DateTime statementDate;
  final double statementEndingBalance;
  Map<String, dynamic> toJson() => {'accountId': accountId, 'statementDate': _dateOnly(statementDate), 'statementEndingBalance': statementEndingBalance};
}

String _dateOnly(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
