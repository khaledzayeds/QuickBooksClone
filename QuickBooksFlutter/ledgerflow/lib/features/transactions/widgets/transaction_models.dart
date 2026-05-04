import 'package:flutter/material.dart';

enum TransactionScreenKind {
  invoice,
  salesReceipt,
  purchaseOrder,
  receiveInventory,
  purchaseBill,
  payment,
  vendorPayment,
  returnDocument,
  credit,
  inventoryAdjustment,
  journalEntry,
}

enum TransactionDocumentStatus { draft, saved, posted, voided }

enum TransactionPartyType { customer, vendor, account, none }

enum TransactionPrintAction { preview, printA4, printThermal, emailOrShare }

class TransactionLineUiModel {
  const TransactionLineUiModel({
    required this.lineNumber,
    this.itemId,
    this.itemName,
    this.barcode,
    this.description,
    this.quantity = 1,
    this.unit,
    this.rate = 0,
    this.discount = 0,
    this.taxAmount = 0,
    this.amount = 0,
    this.stockOnHand,
    this.warning,
  });

  final int lineNumber;
  final String? itemId;
  final String? itemName;
  final String? barcode;
  final String? description;
  final double quantity;
  final String? unit;
  final double rate;
  final double discount;
  final double taxAmount;
  final double amount;
  final double? stockOnHand;
  final String? warning;

  TransactionLineUiModel copyWith({
    int? lineNumber,
    String? itemId,
    String? itemName,
    String? barcode,
    String? description,
    double? quantity,
    String? unit,
    double? rate,
    double? discount,
    double? taxAmount,
    double? amount,
    double? stockOnHand,
    String? warning,
  }) {
    return TransactionLineUiModel(
      lineNumber: lineNumber ?? this.lineNumber,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      rate: rate ?? this.rate,
      discount: discount ?? this.discount,
      taxAmount: taxAmount ?? this.taxAmount,
      amount: amount ?? this.amount,
      stockOnHand: stockOnHand ?? this.stockOnHand,
      warning: warning ?? this.warning,
    );
  }
}

class TransactionTotalsUiModel {
  const TransactionTotalsUiModel({
    this.subtotal = 0,
    this.discountTotal = 0,
    this.taxTotal = 0,
    this.shipping = 0,
    this.total = 0,
    this.paid = 0,
    this.balanceDue = 0,
    this.currency = 'EGP',
  });

  final double subtotal;
  final double discountTotal;
  final double taxTotal;
  final double shipping;
  final double total;
  final double paid;
  final double balanceDue;
  final String currency;
}

class TransactionContextMetric {
  const TransactionContextMetric({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;
}

class TransactionContextActivity {
  const TransactionContextActivity({required this.title, required this.subtitle, this.amount, this.status});

  final String title;
  final String subtitle;
  final String? amount;
  final String? status;
}

extension TransactionDocumentStatusLabel on TransactionDocumentStatus {
  String get label => switch (this) {
        TransactionDocumentStatus.draft => 'Draft',
        TransactionDocumentStatus.saved => 'Saved',
        TransactionDocumentStatus.posted => 'Posted',
        TransactionDocumentStatus.voided => 'Voided',
      };

  IconData get icon => switch (this) {
        TransactionDocumentStatus.draft => Icons.edit_note_outlined,
        TransactionDocumentStatus.saved => Icons.save_outlined,
        TransactionDocumentStatus.posted => Icons.verified_outlined,
        TransactionDocumentStatus.voided => Icons.block_outlined,
      };
}

extension TransactionScreenKindLabel on TransactionScreenKind {
  String get label => switch (this) {
        TransactionScreenKind.invoice => 'Invoice',
        TransactionScreenKind.salesReceipt => 'Sales Receipt',
        TransactionScreenKind.purchaseOrder => 'Purchase Order',
        TransactionScreenKind.receiveInventory => 'Receive Inventory',
        TransactionScreenKind.purchaseBill => 'Purchase Bill',
        TransactionScreenKind.payment => 'Payment',
        TransactionScreenKind.vendorPayment => 'Vendor Payment',
        TransactionScreenKind.returnDocument => 'Return',
        TransactionScreenKind.credit => 'Credit',
        TransactionScreenKind.inventoryAdjustment => 'Inventory Adjustment',
        TransactionScreenKind.journalEntry => 'Journal Entry',
      };
}
