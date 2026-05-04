// print_data_contracts.dart

import '../../../../core/utils/json_utils.dart';

class DocumentPrintDataModel {
  const DocumentPrintDataModel({
    required this.documentId,
    required this.documentType,
    required this.documentNumber,
    required this.status,
    required this.company,
    required this.customer,
    required this.documentDate,
    required this.dueDate,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.creditAppliedAmount,
    required this.returnedAmount,
    required this.balanceDue,
    required this.lines,
    required this.summaryRows,
    required this.generatedAt,
    this.payment,
    this.notes,
    this.terms,
  });

  final String documentId;
  final String documentType;
  final String documentNumber;
  final String status;
  final PrintCompanyModel company;
  final PrintCustomerModel customer;
  final PrintPaymentModel? payment;
  final DateTime documentDate;
  final DateTime dueDate;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double paidAmount;
  final double creditAppliedAmount;
  final double returnedAmount;
  final double balanceDue;
  final List<PrintLineModel> lines;
  final List<PrintSummaryRowModel> summaryRows;
  final DateTime generatedAt;
  final String? notes;
  final String? terms;

  factory DocumentPrintDataModel.fromJson(Map<String, dynamic> json) => DocumentPrintDataModel(
        documentId: JsonUtils.asString(json['documentId']),
        documentType: JsonUtils.asString(json['documentType']),
        documentNumber: JsonUtils.asString(json['documentNumber']),
        status: JsonUtils.asString(json['status']),
        company: PrintCompanyModel.fromJson(json['company'] as Map<String, dynamic>? ?? const {}),
        customer: PrintCustomerModel.fromJson(json['customer'] as Map<String, dynamic>? ?? const {}),
        payment: json['payment'] == null ? null : PrintPaymentModel.fromJson(json['payment'] as Map<String, dynamic>),
        documentDate: _parseDate(json['documentDate']),
        dueDate: _parseDate(json['dueDate']),
        subtotal: JsonUtils.asDouble(json['subtotal']),
        discountAmount: JsonUtils.asDouble(json['discountAmount']),
        taxAmount: JsonUtils.asDouble(json['taxAmount']),
        totalAmount: JsonUtils.asDouble(json['totalAmount']),
        paidAmount: JsonUtils.asDouble(json['paidAmount']),
        creditAppliedAmount: JsonUtils.asDouble(json['creditAppliedAmount']),
        returnedAmount: JsonUtils.asDouble(json['returnedAmount']),
        balanceDue: JsonUtils.asDouble(json['balanceDue']),
        lines: JsonUtils.asList(json['lines'], (line) => PrintLineModel.fromJson(line)),
        summaryRows: JsonUtils.asList(json['summaryRows'], (row) => PrintSummaryRowModel.fromJson(row)),
        generatedAt: _parseDate(json['generatedAt']),
        notes: JsonUtils.asNullableString(json['notes']),
        terms: JsonUtils.asNullableString(json['terms']),
      );
}

class PrintCompanyModel {
  const PrintCompanyModel({required this.companyName, required this.currency, required this.country, this.legalName, this.email, this.phone});

  final String companyName;
  final String? legalName;
  final String? email;
  final String? phone;
  final String currency;
  final String country;

  factory PrintCompanyModel.fromJson(Map<String, dynamic> json) => PrintCompanyModel(
        companyName: JsonUtils.asString(json['companyName']),
        legalName: JsonUtils.asNullableString(json['legalName']),
        email: JsonUtils.asNullableString(json['email']),
        phone: JsonUtils.asNullableString(json['phone']),
        currency: JsonUtils.asString(json['currency']),
        country: JsonUtils.asString(json['country']),
      );
}

class PrintCustomerModel {
  const PrintCustomerModel({required this.customerId, required this.displayName, required this.currency, required this.openBalance, required this.creditBalance, this.email, this.phone});

  final String customerId;
  final String displayName;
  final String? email;
  final String? phone;
  final String currency;
  final double openBalance;
  final double creditBalance;

  factory PrintCustomerModel.fromJson(Map<String, dynamic> json) => PrintCustomerModel(
        customerId: JsonUtils.asString(json['customerId']),
        displayName: JsonUtils.asString(json['displayName']),
        email: JsonUtils.asNullableString(json['email']),
        phone: JsonUtils.asNullableString(json['phone']),
        currency: JsonUtils.asString(json['currency']),
        openBalance: JsonUtils.asDouble(json['openBalance']),
        creditBalance: JsonUtils.asDouble(json['creditBalance']),
      );
}

class PrintPaymentModel {
  const PrintPaymentModel({this.depositAccountId, this.depositAccountName, this.paymentMethod, this.linkedPaymentId});

  final String? depositAccountId;
  final String? depositAccountName;
  final String? paymentMethod;
  final String? linkedPaymentId;

  factory PrintPaymentModel.fromJson(Map<String, dynamic> json) => PrintPaymentModel(
        depositAccountId: JsonUtils.asNullableString(json['depositAccountId']),
        depositAccountName: JsonUtils.asNullableString(json['depositAccountName']),
        paymentMethod: JsonUtils.asNullableString(json['paymentMethod']),
        linkedPaymentId: JsonUtils.asNullableString(json['linkedPaymentId']),
      );
}

class PrintLineModel {
  const PrintLineModel({required this.lineNumber, required this.itemId, required this.itemName, required this.description, required this.quantity, required this.unitPrice, required this.discountPercent, required this.taxRatePercent, required this.taxAmount, required this.lineTotal});

  final int lineNumber;
  final String itemId;
  final String itemName;
  final String description;
  final double quantity;
  final double unitPrice;
  final double discountPercent;
  final double taxRatePercent;
  final double taxAmount;
  final double lineTotal;

  factory PrintLineModel.fromJson(Map<String, dynamic> json) => PrintLineModel(
        lineNumber: JsonUtils.asInt(json['lineNumber']),
        itemId: JsonUtils.asString(json['itemId']),
        itemName: JsonUtils.asString(json['itemName']),
        description: JsonUtils.asString(json['description']),
        quantity: JsonUtils.asDouble(json['quantity']),
        unitPrice: JsonUtils.asDouble(json['unitPrice']),
        discountPercent: JsonUtils.asDouble(json['discountPercent']),
        taxRatePercent: JsonUtils.asDouble(json['taxRatePercent']),
        taxAmount: JsonUtils.asDouble(json['taxAmount']),
        lineTotal: JsonUtils.asDouble(json['lineTotal']),
      );
}

class PrintSummaryRowModel {
  const PrintSummaryRowModel({required this.label, required this.amount, required this.isStrong});

  final String label;
  final double amount;
  final bool isStrong;

  factory PrintSummaryRowModel.fromJson(Map<String, dynamic> json) => PrintSummaryRowModel(
        label: JsonUtils.asString(json['label']),
        amount: JsonUtils.asDouble(json['amount']),
        isStrong: json['isStrong'] == true,
      );
}

DateTime _parseDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
