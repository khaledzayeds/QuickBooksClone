// order_line_entry.dart
// Local form state model — ليس API model

import 'package:flutter/material.dart';

class OrderLineEntry {
  OrderLineEntry({
    this.itemId,
    this.itemName = '',
  })  : descCtrl = TextEditingController(),
        qtyCtrl  = TextEditingController(text: '1'),
        costCtrl = TextEditingController(text: '0');

  String? itemId;
  String  itemName;

  final TextEditingController descCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController costCtrl;

  double get lineTotal =>
      (double.tryParse(qtyCtrl.text) ?? 0) *
      (double.tryParse(costCtrl.text) ?? 0);

  void dispose() {
    descCtrl.dispose();
    qtyCtrl.dispose();
    costCtrl.dispose();
  }
}