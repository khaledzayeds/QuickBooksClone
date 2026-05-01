// order_status_badge.dart
// Updated to work with PurchaseOrderStatus enum.

import 'package:flutter/material.dart';
import '../data/models/purchase_order_model.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});
  final PurchaseOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      PurchaseOrderStatus.draft     => (const Color(0xFFE8F0FE), const Color(0xFF1A56DB)),
      PurchaseOrderStatus.open      => (const Color(0xFFDEF7EC), const Color(0xFF057A55)),
      PurchaseOrderStatus.closed    => (const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
      PurchaseOrderStatus.cancelled => (const Color(0xFFFDE8E8), const Color(0xFFE02424)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.labelAr,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}