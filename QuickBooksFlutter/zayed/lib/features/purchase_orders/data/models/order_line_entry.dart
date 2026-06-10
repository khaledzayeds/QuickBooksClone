// order_line_entry.dart
// Local form state model for transaction lines.

import 'package:flutter/material.dart';

import '../../../items/data/models/item_model.dart';

class TransactionLineEntry {
  TransactionLineEntry({
    this.itemId,
    this.itemName = '',
    this.itemType,
    this.qty = 1,
    this.rate = 0,
    this.inventoryReceiptLineId,
  }) : descCtrl = TextEditingController(),
       qtyCtrl = TextEditingController(text: qty.toString()),
       rateCtrl = TextEditingController(text: rate.toString());

  String? itemId;
  String itemName;
  ItemType? itemType;
  double qty;
  double rate;
  String? inventoryReceiptLineId;

  final TextEditingController descCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController rateCtrl;

  double get displayRate {
    final type = itemType;
    if (type == null) return rate;
    if (type.isSubtotalLine || type.postsThroughComponents) return 0;
    if (type.isAmountReducingLine) return -rate.abs();
    return rate;
  }

  double get amount => qty * displayRate;
  double get lineTotal => amount;

  void dispose() {
    descCtrl.dispose();
    qtyCtrl.dispose();
    rateCtrl.dispose();
  }
}
