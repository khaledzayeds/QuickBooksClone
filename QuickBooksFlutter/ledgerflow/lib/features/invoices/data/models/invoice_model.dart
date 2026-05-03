// invoice_model.dart

class InvoiceModel {
  const InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.invoiceDate,
    required this.dueDate,
    required this.paymentMode,
    required this.status,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.creditAppliedAmount,
    required this.returnedAmount,
    required this.balanceDue,
    required this.lines,
    this.customerName,
    this.salesOrderId,
    this.depositAccountId,
    this.depositAccountName,
    this.paymentMethod,
    this.receiptPaymentId,
    this.postedTransactionId,
    this.postedAt,
    this.reversalTransactionId,
    this.voidedAt,
  });

  final String id;
  final String invoiceNumber;
  final String customerId;
  final String? customerName;
  final String? salesOrderId;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final InvoicePaymentMode paymentMode;
  final String? depositAccountId;
  final String? depositAccountName;
  final String? paymentMethod;
  final String? receiptPaymentId;
  final InvoiceStatus status;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double paidAmount;
  final double creditAppliedAmount;
  final double returnedAmount;
  final double balanceDue;
  final String? postedTransactionId;
  final DateTime? postedAt;
  final String? reversalTransactionId;
  final DateTime? voidedAt;
  final List<InvoiceLineModel> lines;

  factory InvoiceModel.fromJson(Map<String, dynamic> json) => InvoiceModel(
        id: json['id']?.toString() ?? '',
        invoiceNumber: json['invoiceNumber']?.toString() ?? '',
        customerId: json['customerId']?.toString() ?? '',
        customerName: json['customerName']?.toString(),
        salesOrderId: json['salesOrderId']?.toString(),
        invoiceDate: _parseDate(json['invoiceDate']) ?? DateTime.now(),
        dueDate: _parseDate(json['dueDate']) ?? DateTime.now(),
        paymentMode: InvoicePaymentMode.fromValue(json['paymentMode']),
        depositAccountId: json['depositAccountId']?.toString(),
        depositAccountName: json['depositAccountName']?.toString(),
        paymentMethod: json['paymentMethod']?.toString(),
        receiptPaymentId: json['receiptPaymentId']?.toString(),
        status: InvoiceStatus.fromValue(json['status']),
        subtotal: _toDouble(json['subtotal']),
        discountAmount: _toDouble(json['discountAmount']),
        taxAmount: _toDouble(json['taxAmount']),
        totalAmount: _toDouble(json['totalAmount']),
        paidAmount: _toDouble(json['paidAmount']),
        creditAppliedAmount: _toDouble(json['creditAppliedAmount']),
        returnedAmount: _toDouble(json['returnedAmount']),
        balanceDue: _toDouble(json['balanceDue']),
        postedTransactionId: json['postedTransactionId']?.toString(),
        postedAt: _parseDate(json['postedAt']),
        reversalTransactionId: json['reversalTransactionId']?.toString(),
        voidedAt: _parseDate(json['voidedAt']),
        lines: ((json['lines'] as List?) ?? const [])
            .map((line) => InvoiceLineModel.fromJson(line as Map<String, dynamic>))
            .toList(),
      );

  bool get isCreditInvoice => paymentMode == InvoicePaymentMode.credit;
  bool get isSalesReceipt => paymentMode == InvoicePaymentMode.cash;
  bool get isVoid => status == InvoiceStatus.voided;
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
  final String? salesOrderLineId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double discountPercent;
  final String? taxCodeId;
  final double? taxRatePercent;
  final double taxAmount;
  final double lineTotal;

  factory InvoiceLineModel.fromJson(Map<String, dynamic> json) => InvoiceLineModel(
        id: json['id']?.toString() ?? '',
        itemId: json['itemId']?.toString() ?? '',
        salesOrderLineId: json['salesOrderLineId']?.toString(),
        description: json['description']?.toString() ?? '',
        quantity: _toDouble(json['quantity']),
        unitPrice: _toDouble(json['unitPrice']),
        discountPercent: _toDouble(json['discountPercent']),
        taxCodeId: json['taxCodeId']?.toString(),
        taxRatePercent: json['taxRatePercent'] == null ? null : _toDouble(json['taxRatePercent']),
        taxAmount: _toDouble(json['taxAmount']),
        lineTotal: _toDouble(json['lineTotal']),
      );
}

enum InvoicePaymentMode {
  credit(1, 'آجل'),
  cash(2, 'نقدي');

  const InvoicePaymentMode(this.value, this.label);
  final int value;
  final String label;

  static InvoicePaymentMode fromValue(dynamic value) {
    final text = value?.toString().toLowerCase();
    if (text == 'cash' || text == '2') return InvoicePaymentMode.cash;
    return InvoicePaymentMode.credit;
  }
}

enum InvoiceStatus {
  draft('Draft', 'مسودة'),
  sent('Sent', 'مرسلة'),
  posted('Posted', 'مرحلة'),
  partiallyPaid('PartiallyPaid', 'مدفوعة جزئيًا'),
  paid('Paid', 'مدفوعة'),
  returned('Returned', 'مرتجعة'),
  voided('Void', 'ملغاة');

  const InvoiceStatus(this.value, this.label);
  final String value;
  final String label;

  static InvoiceStatus fromValue(dynamic value) {
    final text = value?.toString();
    return InvoiceStatus.values.firstWhere(
      (status) => status.value.toLowerCase() == text?.toLowerCase(),
      orElse: () => InvoiceStatus.draft,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

double _toDouble(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;
