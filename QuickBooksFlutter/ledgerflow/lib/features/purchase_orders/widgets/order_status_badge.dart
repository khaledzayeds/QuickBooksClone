import 'package:flutter/material.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  (String, Color, Color) _resolve(String status) => switch (status) {
        'Draft'     => ('مسودة',    const Color(0xFFE8F0FE), const Color(0xFF1A56DB)),
        'Open'      => ('مفتوح',    const Color(0xFFDEF7EC), const Color(0xFF057A55)),
        'Closed'    => ('مغلق',     const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
        'Cancelled' => ('ملغي',     const Color(0xFFFDE8E8), const Color(0xFFE02424)),
        _           => (status,     const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
      };
}