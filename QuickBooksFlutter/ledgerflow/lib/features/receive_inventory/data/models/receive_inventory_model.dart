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

  factory ReceiveInventoryModel.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List<dynamic>? ?? [];

    return ReceiveInventoryModel(
      id: json['id'].toString(),
      receiptNumber: json['receiptNumber'] as String? ?? '',
      purchaseOrderId: json['purchaseOrderId'].toString(),
      vendorId: json['vendorId'].toString(),
      vendorName: json['vendorName'] as String? ?? '',
      receiptDate: DateTime.parse(json['receiptDate'] as String),
      status: json['status'] as String? ?? 'Draft',
      notes: json['notes'] as String?,
      lines: rawLines
          .map((item) => ReceiveInventoryLineModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
