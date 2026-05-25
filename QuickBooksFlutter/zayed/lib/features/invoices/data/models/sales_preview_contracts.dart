// sales_preview_contracts.dart

import '../../../../core/utils/json_utils.dart';

class PreviewSalesLineDto {
  const PreviewSalesLineDto({required this.itemId, required this.quantity, required this.unitPrice, this.description, this.discountPercent = 0, this.taxCodeId});

  final String itemId;
  final String? description;
  final double quantity;
  final double unitPrice;
  final double discountPercent;
  final String? taxCodeId;

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        if (description != null && description!.trim().isNotEmpty) 'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'discountPercent': discountPercent,
        if (taxCodeId != null && taxCodeId!.isNotEmpty) 'taxCodeId': taxCodeId,
      };
}

class PreviewInvoiceDto {
  const PreviewInvoiceDto({required this.customerId, required this.invoiceDate, required this.dueDate, required this.lines});

  final String customerId;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final List<PreviewSalesLineDto> lines;

  Map<String, dynamic> toJson() => {'customerId': customerId, 'invoiceDate': _dateOnly(invoiceDate), 'dueDate': _dateOnly(dueDate), 'lines': lines.map((line) => line.toJson()).toList()};
}

class PreviewSalesReceiptDto {
  const PreviewSalesReceiptDto({required this.customerId, required this.receiptDate, required this.depositAccountId, required this.paymentMethod, required this.lines});

  final String customerId;
  final DateTime receiptDate;
  final String depositAccountId;
  final String paymentMethod;
  final List<PreviewSalesLineDto> lines;

  Map<String, dynamic> toJson() => {'customerId': customerId, 'receiptDate': _dateOnly(receiptDate), 'depositAccountId': depositAccountId, 'paymentMethod': paymentMethod, 'lines': lines.map((line) => line.toJson()).toList()};
}

class SalesPostingPreviewModel {
  const SalesPostingPreviewModel({required this.paymentMode, required this.subtotal, required this.discountTotal, required this.taxTotal, required this.total, required this.paidAmount, required this.balanceDue, this.lines = const [], this.ledgerImpacts = const [], this.inventoryImpacts = const [], this.warnings = const []});

  final int paymentMode;
  final double subtotal;
  final double discountTotal;
  final double taxTotal;
  final double total;
  final double paidAmount;
  final double balanceDue;
  final List<SalesPostingPreviewLineModel> lines;
  final List<SalesLedgerImpactModel> ledgerImpacts;
  final List<SalesInventoryImpactModel> inventoryImpacts;
  final List<String> warnings;

  factory SalesPostingPreviewModel.fromJson(Map<String, dynamic> json) => SalesPostingPreviewModel(
        paymentMode: JsonUtils.asInt(json['paymentMode']),
        subtotal: JsonUtils.asDouble(json['subtotal']),
        discountTotal: JsonUtils.asDouble(json['discountTotal']),
        taxTotal: JsonUtils.asDouble(json['taxTotal']),
        total: JsonUtils.asDouble(json['total']),
        paidAmount: JsonUtils.asDouble(json['paidAmount']),
        balanceDue: JsonUtils.asDouble(json['balanceDue']),
        lines: JsonUtils.asList(json['lines'], (line) => SalesPostingPreviewLineModel.fromJson(line)),
        ledgerImpacts: JsonUtils.asList(json['ledgerImpacts'], (impact) => SalesLedgerImpactModel.fromJson(impact)),
        inventoryImpacts: JsonUtils.asList(json['inventoryImpacts'], (impact) => SalesInventoryImpactModel.fromJson(impact)),
        warnings: (json['warnings'] as List? ?? []).map((e) => e.toString()).toList(),
      );
}

class SalesPostingPreviewLineModel {
  const SalesPostingPreviewLineModel({required this.itemId, required this.itemName, required this.description, required this.quantity, required this.unitPrice, required this.lineTotal, this.currentStock, this.projectedStock, this.grossMargin, this.warnings = const []});

  final String itemId;
  final String itemName;
  final String description;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  final double? currentStock;
  final double? projectedStock;
  final double? grossMargin;
  final List<String> warnings;

  factory SalesPostingPreviewLineModel.fromJson(Map<String, dynamic> json) => SalesPostingPreviewLineModel(
        itemId: JsonUtils.asString(json['itemId']),
        itemName: JsonUtils.asString(json['itemName']),
        description: JsonUtils.asString(json['description']),
        quantity: JsonUtils.asDouble(json['quantity']),
        unitPrice: JsonUtils.asDouble(json['unitPrice']),
        lineTotal: JsonUtils.asDouble(json['lineTotal']),
        currentStock: json['currentStock'] == null ? null : JsonUtils.asDouble(json['currentStock']),
        projectedStock: json['projectedStock'] == null ? null : JsonUtils.asDouble(json['projectedStock']),
        grossMargin: json['grossMargin'] == null ? null : JsonUtils.asDouble(json['grossMargin']),
        warnings: (json['warnings'] as List? ?? []).map((e) => e.toString()).toList(),
      );
}

class SalesLedgerImpactModel {
  const SalesLedgerImpactModel({required this.accountRole, required this.accountName, required this.debit, required this.credit, required this.memo, this.accountId});

  final String accountRole;
  final String? accountId;
  final String accountName;
  final double debit;
  final double credit;
  final String memo;

  factory SalesLedgerImpactModel.fromJson(Map<String, dynamic> json) => SalesLedgerImpactModel(
        accountRole: JsonUtils.asString(json['accountRole']),
        accountId: JsonUtils.asNullableString(json['accountId']),
        accountName: JsonUtils.asString(json['accountName']),
        debit: JsonUtils.asDouble(json['debit']),
        credit: JsonUtils.asDouble(json['credit']),
        memo: JsonUtils.asString(json['memo']),
      );
}

class SalesInventoryImpactModel {
  const SalesInventoryImpactModel({required this.itemId, required this.itemName, required this.quantityChange, required this.memo, this.currentStock, this.projectedStock});

  final String itemId;
  final String itemName;
  final double quantityChange;
  final double? currentStock;
  final double? projectedStock;
  final String memo;

  factory SalesInventoryImpactModel.fromJson(Map<String, dynamic> json) => SalesInventoryImpactModel(
        itemId: JsonUtils.asString(json['itemId']),
        itemName: JsonUtils.asString(json['itemName']),
        quantityChange: JsonUtils.asDouble(json['quantityChange']),
        currentStock: json['currentStock'] == null ? null : JsonUtils.asDouble(json['currentStock']),
        projectedStock: json['projectedStock'] == null ? null : JsonUtils.asDouble(json['projectedStock']),
        memo: JsonUtils.asString(json['memo']),
      );
}

class CustomerSalesActivityModel {
  const CustomerSalesActivityModel({required this.customerId, required this.customerName, required this.currency, required this.openBalance, required this.creditBalance, this.recentInvoices = const [], this.recentSalesReceipts = const [], this.recentPayments = const [], this.warnings = const []});

  final String customerId;
  final String customerName;
  final String currency;
  final double openBalance;
  final double creditBalance;
  final List<CustomerSalesActivityItemModel> recentInvoices;
  final List<CustomerSalesActivityItemModel> recentSalesReceipts;
  final List<CustomerPaymentActivityItemModel> recentPayments;
  final List<String> warnings;

  factory CustomerSalesActivityModel.fromJson(Map<String, dynamic> json) => CustomerSalesActivityModel(
        customerId: JsonUtils.asString(json['customerId']),
        customerName: JsonUtils.asString(json['customerName']),
        currency: JsonUtils.asString(json['currency']),
        openBalance: JsonUtils.asDouble(json['openBalance']),
        creditBalance: JsonUtils.asDouble(json['creditBalance']),
        recentInvoices: JsonUtils.asList(json['recentInvoices'], (item) => CustomerSalesActivityItemModel.fromJson(item)),
        recentSalesReceipts: JsonUtils.asList(json['recentSalesReceipts'], (item) => CustomerSalesActivityItemModel.fromJson(item)),
        recentPayments: JsonUtils.asList(json['recentPayments'], (item) => CustomerPaymentActivityItemModel.fromJson(item)),
        warnings: (json['warnings'] as List? ?? []).map((e) => e.toString()).toList(),
      );
}

class CustomerSalesActivityItemModel {
  const CustomerSalesActivityItemModel({required this.id, required this.number, required this.date, required this.totalAmount, required this.balanceDue});

  final String id;
  final String number;
  final DateTime date;
  final double totalAmount;
  final double balanceDue;

  factory CustomerSalesActivityItemModel.fromJson(Map<String, dynamic> json) => CustomerSalesActivityItemModel(
        id: JsonUtils.asString(json['id']),
        number: JsonUtils.asString(json['number']),
        date: _parseDate(json['date']),
        totalAmount: JsonUtils.asDouble(json['totalAmount']),
        balanceDue: JsonUtils.asDouble(json['balanceDue']),
      );
}

class CustomerPaymentActivityItemModel {
  const CustomerPaymentActivityItemModel({required this.id, required this.number, required this.paymentDate, required this.amount, required this.paymentMethod});

  final String id;
  final String number;
  final DateTime paymentDate;
  final double amount;
  final String paymentMethod;

  factory CustomerPaymentActivityItemModel.fromJson(Map<String, dynamic> json) => CustomerPaymentActivityItemModel(
        id: JsonUtils.asString(json['id']),
        number: JsonUtils.asString(json['number']),
        paymentDate: _parseDate(json['paymentDate']),
        amount: JsonUtils.asDouble(json['amount']),
        paymentMethod: JsonUtils.asString(json['paymentMethod']),
      );
}

String _dateOnly(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
DateTime _parseDate(dynamic value) => DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
