class TransactionPrintLine {
  const TransactionPrintLine({
    required this.itemName,
    required this.description,
    required this.quantity,
    required this.rate,
    required this.amount,
  });

  final String itemName;
  final String description;
  final double quantity;
  final double rate;
  final double amount;
}

class TransactionPrintTotals {
  const TransactionPrintTotals({
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.total,
    required this.paid,
    required this.balanceDue,
    required this.currency,
  });

  final double subtotal;
  final double discountTotal;
  final double taxTotal;
  final double total;
  final double paid;
  final double balanceDue;
  final String currency;
}

class TransactionPrintModel {
  const TransactionPrintModel({
    required this.documentTitle,
    required this.documentNumber,
    required this.documentDate,
    required this.partyLabel,
    required this.partyName,
    required this.lines,
    required this.totals,
    this.dueDate,
    this.reference,
    this.paymentMethod,
  });

  final String documentTitle;
  final String documentNumber;
  final DateTime documentDate;
  final DateTime? dueDate;
  final String partyLabel;
  final String partyName;
  final String? reference;
  final String? paymentMethod;
  final List<TransactionPrintLine> lines;
  final TransactionPrintTotals totals;
}
