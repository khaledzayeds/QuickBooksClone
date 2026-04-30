// account_model.dart
// account_model.dart

import '../../../../core/constants/api_enums.dart';

class AccountModel {
  const AccountModel({
    required this.id,
    required this.code,
    required this.name,
    required this.accountType,
    required this.balance,
    required this.isActive,
    this.description,
    this.parentId,
    this.parentName,
  });

  final String id;
  final String code;
  final String name;
  final AccountType accountType;
  final double balance;
  final bool isActive;
  final String? description;
  final String? parentId;
  final String? parentName;

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
        id:          json['id'] as String,
        code:        json['code'] as String,
        name:        json['name'] as String,
        accountType: AccountType.fromValue(json['accountType'] as int),
        balance:     (json['balance'] as num).toDouble(),
        isActive:    json['isActive'] as bool,
        description: json['description'] as String?,
        parentId:    json['parentId'] as String?,
        parentName:  json['parentName'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'code':        code,
        'name':        name,
        'accountType': accountType.value,
        if (description != null) 'description': description,
        if (parentId != null)    'parentId':    parentId,
      };

  AccountModel copyWith({
    String? code,
    String? name,
    AccountType? accountType,
    String? description,
    String? parentId,
    bool? isActive,
  }) =>
      AccountModel(
        id:          id,
        code:        code ?? this.code,
        name:        name ?? this.name,
        accountType: accountType ?? this.accountType,
        balance:     balance,
        isActive:    isActive ?? this.isActive,
        description: description ?? this.description,
        parentId:    parentId ?? this.parentId,
        parentName:  parentName,
      );

  // ─── Helpers ──────────────────────────────────
  bool get isDebitNormal =>
      accountType == AccountType.bank ||
      accountType == AccountType.accountsReceivable ||
      accountType == AccountType.otherCurrentAsset ||
      accountType == AccountType.inventoryAsset ||
      accountType == AccountType.fixedAsset ||
      accountType == AccountType.costOfGoodsSold ||
      accountType == AccountType.expense ||
      accountType == AccountType.otherExpense;

  String get accountTypeName => switch (accountType) {
        AccountType.bank                  => 'بنك',
        AccountType.accountsReceivable    => 'ذمم مدينة',
        AccountType.otherCurrentAsset     => 'أصول متداولة أخرى',
        AccountType.inventoryAsset        => 'أصول مخزون',
        AccountType.fixedAsset            => 'أصول ثابتة',
        AccountType.accountsPayable       => 'ذمم دائنة',
        AccountType.creditCard            => 'بطاقة ائتمان',
        AccountType.otherCurrentLiability => 'التزامات متداولة أخرى',
        AccountType.longTermLiability     => 'التزامات طويلة الأجل',
        AccountType.equity                => 'حقوق الملكية',
        AccountType.income                => 'إيرادات',
        AccountType.otherIncome           => 'إيرادات أخرى',
        AccountType.costOfGoodsSold       => 'تكلفة المبيعات',
        AccountType.expense               => 'مصروفات',
        AccountType.otherExpense          => 'مصروفات أخرى',
      };
}