// order_line_entry.dart
// Local form state model for transaction lines.

import 'package:flutter/material.dart';

class TransactionLineEntry {
  TransactionLineEntry({
    this.itemId,
    this.itemName = '',
    this.qty = 1,
    this.rate = 0,
  })  : descCtrl = TextEditingController(),
        qtyCtrl  = TextEditingController(text: qty.toString()),
        rateCtrl = TextEditingController(text: rate.toString());

  String? itemId;
  String  itemName;
  double  qty;
  double  rate;

  final TextEditingController descCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController rateCtrl;

  double get amount => qty * rate;
  double get lineTotal => amount;

  void dispose() {
    descCtrl.dispose();
    qtyCtrl.dispose();
    rateCtrl.dispose();
  }
}