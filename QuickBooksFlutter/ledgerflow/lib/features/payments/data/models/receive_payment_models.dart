import '../../../invoices/data/models/invoice_model.dart';

class ReceivePaymentInvoiceAllocation {
  ReceivePaymentInvoiceAllocation({
    required this.invoice,
    this.selected = false,
    double? amount,
  }) : amount = amount ?? invoice.balanceDue;

  final InvoiceModel invoice;
  bool selected;
  double amount;

  String get invoiceId => invoice.id;
  String get invoiceNumber => invoice.invoiceNumber;
  String get customerId => invoice.customerId;
  String get customerName => invoice.customerName ?? '';
  DateTime get invoiceDate => invoice.invoiceDate;
  DateTime get dueDate => invoice.dueDate;
  double get originalAmount => invoice.totalAmount;
  double get paidAmount => invoice.paidAmount;
  double get balanceDue => invoice.balanceDue;
}
