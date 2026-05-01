// vendor_model.dart
// vendor_model.dart

class VendorModel {
  const VendorModel({
    required this.id,
    required this.displayName,
    required this.isActive,
    required this.balance,
    required this.creditBalance,
    this.companyName,
    this.email,
    this.phone,
    this.currency = 'EGP',
  });

  final String id;
  final String displayName;
  final bool isActive;
  final double balance;
  final double creditBalance;
  final String? companyName;
  final String? email;
  final String? phone;
  final String currency;

  factory VendorModel.fromJson(Map<String, dynamic> json) => VendorModel(
        id:            json['id']?.toString() ?? '',
        displayName:   json['displayName']?.toString() ?? '',
        isActive:      json['isActive'] == true || json['isActive'] == 1,
        balance:       double.tryParse(json['balance']?.toString() ?? '') ?? 0,
        creditBalance: double.tryParse(json['creditBalance']?.toString() ?? '') ?? 0,
        companyName:   json['companyName']?.toString(),
        email:         json['email']?.toString(),
        phone:         json['phone']?.toString(),
        currency:      json['currency']?.toString() ?? 'EGP',
      );

  Map<String, dynamic> toCreateJson() => {
        'displayName': displayName,
        if (companyName != null) 'companyName': companyName,
        if (email != null)       'email':       email,
        if (phone != null)       'phone':       phone,
        'currency':       currency,
        'openingBalance': 0,
      };

  Map<String, dynamic> toUpdateJson() => {
        'displayName': displayName,
        if (companyName != null) 'companyName': companyName,
        if (email != null)       'email':       email,
        if (phone != null)       'phone':       phone,
        'currency': currency,
      };

  bool get hasBalance      => balance > 0;
  bool get hasCreditBalance => creditBalance > 0;

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return displayName.isNotEmpty ? displayName[0] : '?';
  }
}