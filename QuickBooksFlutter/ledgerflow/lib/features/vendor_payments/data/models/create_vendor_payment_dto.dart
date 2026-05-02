// create_vendor_payment_dto.dart
// Aligned with backend CreateVendorPaymentRequest.

class CreateVendorPaymentDto {
  const CreateVendorPaymentDto({
    required this.purchaseBillId,
    required this.paymentAccountId,
    required this.paymentDate,
    required this.amount,
    this.paymentMethod = 'Cash',
  });

  final String purchaseBillId;
  final String paymentAccountId;
  final DateTime paymentDate;
  final double amount;
  final String paymentMethod;

  Map<String, dynamic> toJson() => {
        'purchaseBillId': purchaseBillId,
        'paymentAccountId': paymentAccountId,
        'paymentDate': _dateOnly(paymentDate),
        'amount': amount,
        'paymentMethod': paymentMethod,
      };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
