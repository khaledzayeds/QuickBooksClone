// report_models.dart

import '../../../../core/constants/api_enums.dart' show AccountType;
import '../../../../core/utils/json_utils.dart';

class TrialBalanceReportModel {
  const TrialBalanceReportModel({required this.asOfDate, required this.items, required this.totalDebit, required this.totalCredit});

  final DateTime asOfDate;
  final List<TrialBalanceRowModel> items;
  final double totalDebit;
  final double totalCredit;

  factory TrialBalanceReportModel.fromJson(Map<String, dynamic> json) => TrialBalanceReportModel(
        asOfDate: _parseDate(json['asOfDate']),
        items: JsonUtils.asList(json['items'], (row) => TrialBalanceRowModel.fromJson(row)),
        totalDebit: JsonUtils.asDouble(json['totalDebit']),
        totalCredit: JsonUtils.asDouble(json['totalCredit']),
      );
}

class TrialBalanceRowModel {
  const TrialBalanceRowModel({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    required this.totalDebit,
    required this.totalCredit,
    required this.closingDebit,
    required this.closingCredit,
  });

  final String accountId;
  final String accountCode;
  final String accountName;
  final AccountType accountType;
  final double totalDebit;
  final double totalCredit;
  final double closingDebit;
  final double closingCredit;

  factory TrialBalanceRowModel.fromJson(Map<String, dynamic> json) => TrialBalanceRowModel(
        accountId: JsonUtils.asString(json['accountId']),
        accountCode: JsonUtils.asString(json['accountCode']),
        accountName: JsonUtils.asString(json['accountName']),
        accountType: AccountType.fromValue(JsonUtils.asInt(json['accountType'], defaultValue: 14)),
        totalDebit: JsonUtils.asDouble(json['totalDebit']),
        totalCredit: JsonUtils.asDouble(json['totalCredit']),
        closingDebit: JsonUtils.asDouble(json['closingDebit']),
        closingCredit: JsonUtils.asDouble(json['closingCredit']),
      );
}

class FinancialStatementReportModel {
  const FinancialStatementReportModel({
    required this.asOfDate,
    required this.sections,
    this.totalAssets = 0,
    this.totalLiabilities = 0,
    this.totalEquity = 0,
    this.totalLiabilitiesAndEquity = 0,
  });

  final DateTime asOfDate;
  final List<FinancialSectionModel> sections;
  final double totalAssets;
  final double totalLiabilities;
  final double totalEquity;
  final double totalLiabilitiesAndEquity;

  factory FinancialStatementReportModel.fromBalanceSheetJson(Map<String, dynamic> json) => FinancialStatementReportModel(
        asOfDate: _parseDate(json['asOfDate']),
        sections: JsonUtils.asList(json['sections'], (section) => FinancialSectionModel.fromJson(section)),
        totalAssets: JsonUtils.asDouble(json['totalAssets']),
        totalLiabilities: JsonUtils.asDouble(json['totalLiabilities']),
        totalEquity: JsonUtils.asDouble(json['totalEquity']),
        totalLiabilitiesAndEquity: JsonUtils.asDouble(json['totalLiabilitiesAndEquity']),
      );
}

class ProfitAndLossReportModel {
  const ProfitAndLossReportModel({
    required this.fromDate,
    required this.toDate,
    required this.sections,
    required this.totalIncome,
    required this.totalCostOfGoodsSold,
    required this.grossProfit,
    required this.totalExpenses,
    required this.netProfit,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final List<FinancialSectionModel> sections;
  final double totalIncome;
  final double totalCostOfGoodsSold;
  final double grossProfit;
  final double totalExpenses;
  final double netProfit;

  factory ProfitAndLossReportModel.fromJson(Map<String, dynamic> json) => ProfitAndLossReportModel(
        fromDate: _parseDate(json['fromDate']),
        toDate: _parseDate(json['toDate']),
        sections: JsonUtils.asList(json['sections'], (section) => FinancialSectionModel.fromJson(section)),
        totalIncome: JsonUtils.asDouble(json['totalIncome']),
        totalCostOfGoodsSold: JsonUtils.asDouble(json['totalCostOfGoodsSold']),
        grossProfit: JsonUtils.asDouble(json['grossProfit']),
        totalExpenses: JsonUtils.asDouble(json['totalExpenses']),
        netProfit: JsonUtils.asDouble(json['netProfit']),
      );
}

class FinancialSectionModel {
  const FinancialSectionModel({required this.key, required this.title, required this.items, required this.total});

  final String key;
  final String title;
  final List<FinancialRowModel> items;
  final double total;

  factory FinancialSectionModel.fromJson(Map<String, dynamic> json) => FinancialSectionModel(
        key: JsonUtils.asString(json['key']),
        title: JsonUtils.asString(json['title']),
        items: JsonUtils.asList(json['items'], (item) => FinancialRowModel.fromJson(item)),
        total: JsonUtils.asDouble(json['total']),
      );
}

class FinancialRowModel {
  const FinancialRowModel({required this.accountId, required this.accountCode, required this.accountName, required this.accountType, required this.amount});

  final String accountId;
  final String accountCode;
  final String accountName;
  final AccountType accountType;
  final double amount;

  factory FinancialRowModel.fromJson(Map<String, dynamic> json) => FinancialRowModel(
        accountId: JsonUtils.asString(json['accountId']),
        accountCode: JsonUtils.asString(json['accountCode']),
        accountName: JsonUtils.asString(json['accountName']),
        accountType: AccountType.fromValue(JsonUtils.asInt(json['accountType'], defaultValue: 14)),
        amount: JsonUtils.asDouble(json['amount']),
      );
}

class AgingReportModel {
  const AgingReportModel({required this.asOfDate, required this.items, required this.current, required this.days1To30, required this.days31To60, required this.days61To90, required this.over90, required this.total});

  final DateTime asOfDate;
  final List<AgingRowModel> items;
  final double current;
  final double days1To30;
  final double days31To60;
  final double days61To90;
  final double over90;
  final double total;

  factory AgingReportModel.fromJson(Map<String, dynamic> json) => AgingReportModel(
        asOfDate: _parseDate(json['asOfDate']),
        items: JsonUtils.asList(json['items'], (row) => AgingRowModel.fromJson(row)),
        current: JsonUtils.asDouble(json['current']),
        days1To30: JsonUtils.asDouble(json['days1To30']),
        days31To60: JsonUtils.asDouble(json['days31To60']),
        days61To90: JsonUtils.asDouble(json['days61To90']),
        over90: JsonUtils.asDouble(json['over90']),
        total: JsonUtils.asDouble(json['total']),
      );
}

class AgingRowModel {
  const AgingRowModel({required this.partyId, required this.partyName, required this.currency, required this.current, required this.days1To30, required this.days31To60, required this.days61To90, required this.over90, required this.total, required this.creditBalance, required this.openCount});

  final String partyId;
  final String partyName;
  final String currency;
  final double current;
  final double days1To30;
  final double days31To60;
  final double days61To90;
  final double over90;
  final double total;
  final double creditBalance;
  final int openCount;

  factory AgingRowModel.fromJson(Map<String, dynamic> json) => AgingRowModel(
        partyId: JsonUtils.asString(json['customerId'] ?? json['vendorId']),
        partyName: JsonUtils.asString(json['customerName'] ?? json['vendorName']),
        currency: JsonUtils.asString(json['currency']),
        current: JsonUtils.asDouble(json['current']),
        days1To30: JsonUtils.asDouble(json['days1To30']),
        days31To60: JsonUtils.asDouble(json['days31To60']),
        days61To90: JsonUtils.asDouble(json['days61To90']),
        over90: JsonUtils.asDouble(json['over90']),
        total: JsonUtils.asDouble(json['total']),
        creditBalance: JsonUtils.asDouble(json['creditBalance']),
        openCount: JsonUtils.asInt(json['openInvoiceCount'] ?? json['openBillCount']),
      );
}

class InventoryValuationReportModel {
  const InventoryValuationReportModel({required this.fromDate, required this.toDate, required this.items, required this.totalClosingValue});

  final DateTime fromDate;
  final DateTime toDate;
  final List<InventoryValuationRowModel> items;
  final double totalClosingValue;

  factory InventoryValuationReportModel.fromJson(Map<String, dynamic> json) => InventoryValuationReportModel(
        fromDate: _parseDate(json['fromDate']),
        toDate: _parseDate(json['toDate']),
        items: JsonUtils.asList(json['items'], (row) => InventoryValuationRowModel.fromJson(row)),
        totalClosingValue: JsonUtils.asDouble(json['totalClosingValue']),
      );
}

class InventoryValuationRowModel {
  const InventoryValuationRowModel({required this.itemId, required this.itemName, required this.sku, required this.unit, required this.unitCost, required this.closingQuantity, required this.closingValue});

  final String itemId;
  final String itemName;
  final String sku;
  final String unit;
  final double unitCost;
  final double closingQuantity;
  final double closingValue;

  factory InventoryValuationRowModel.fromJson(Map<String, dynamic> json) => InventoryValuationRowModel(
        itemId: JsonUtils.asString(json['itemId']),
        itemName: JsonUtils.asString(json['itemName']),
        sku: JsonUtils.asString(json['sku']),
        unit: JsonUtils.asString(json['unit']),
        unitCost: JsonUtils.asDouble(json['unitCost']),
        closingQuantity: JsonUtils.asDouble(json['closingQuantity']),
        closingValue: JsonUtils.asDouble(json['closingValue']),
      );
}

class TaxSummaryReportModel {
  const TaxSummaryReportModel({required this.fromDate, required this.toDate, required this.items, required this.netTaxPayable});

  final DateTime fromDate;
  final DateTime toDate;
  final List<TaxSummaryRowModel> items;
  final double netTaxPayable;

  factory TaxSummaryReportModel.fromJson(Map<String, dynamic> json) => TaxSummaryReportModel(
        fromDate: _parseDate(json['fromDate']),
        toDate: _parseDate(json['toDate']),
        items: JsonUtils.asList(json['items'], (row) => TaxSummaryRowModel.fromJson(row)),
        netTaxPayable: JsonUtils.asDouble(json['netTaxPayable']),
      );
}

class TaxSummaryRowModel {
  const TaxSummaryRowModel({required this.taxCodeId, required this.taxCode, required this.taxCodeName, required this.ratePercent, required this.outputTax, required this.inputTax, required this.netTaxPayable});

  final String taxCodeId;
  final String taxCode;
  final String taxCodeName;
  final double ratePercent;
  final double outputTax;
  final double inputTax;
  final double netTaxPayable;

  factory TaxSummaryRowModel.fromJson(Map<String, dynamic> json) => TaxSummaryRowModel(
        taxCodeId: JsonUtils.asString(json['taxCodeId']),
        taxCode: JsonUtils.asString(json['taxCode']),
        taxCodeName: JsonUtils.asString(json['taxCodeName']),
        ratePercent: JsonUtils.asDouble(json['ratePercent']),
        outputTax: JsonUtils.asDouble(json['outputTax']),
        inputTax: JsonUtils.asDouble(json['inputTax']),
        netTaxPayable: JsonUtils.asDouble(json['netTaxPayable']),
      );
}

DateTime _parseDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
