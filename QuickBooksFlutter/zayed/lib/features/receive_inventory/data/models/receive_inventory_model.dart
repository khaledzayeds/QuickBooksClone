// receive_inventory_model.dart

import 'receive_inventory_line_model.dart';

class ReceiveInventoryModel {
  const ReceiveInventoryModel({
    required this.id,
    required this.receiptNumber,
    required this.purchaseOrderId,
    required this.vendorId,
    required this.vendorName,
    required this.receiptDate,
    required this.status,
    this.notes,
    this.lines = const [],
  });

  final String id;
  final String receiptNumber;
  final String purchaseOrderId;
  final String vendorId;
  final String vendorName;
  final DateTime receiptDate;
  final String status;
  final String? notes;
  final List<ReceiveInventoryLineModel> lines;
  
  double get totalAmount => lines.fold(0.0, (sum, line) => sum + line.lineTotal);

  factory ReceiveInventoryModel.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List<dynamic>? ?? [];
    return ReceiveInventoryModel(
      id:              json['id']?.toString() ?? '',
      receiptNumber:   json['receiptNumber']?.toString() ?? '',
      purchaseOrderId: json['purchaseOrderId']?.toString() ?? '',
      vendorId:        json['vendorId']?.toString() ?? '',
      vendorName:      json['vendorName']?.toString() ?? '',
      receiptDate:     DateTime.tryParse(json['receiptDate']?.toString() ?? '') ?? DateTime.now(),
      status:          json['status']?.toString() ?? 'Posted',
      notes:           json['notes']?.toString(),
      lines: rawLines
          .map((e) => ReceiveInventoryLineModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
