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
        id: json['id']?.toString() ?? '',
        displayName: json['displayName']?.toString() ?? '',
        isActive: json['isActive'] != false,
        balance: double.tryParse(json['balance']?.toString() ?? '') ?? 0,
        creditBalance: double.tryParse(json['creditBalance']?.toString() ?? '') ?? 0,
        companyName: json['companyName']?.toString(),
        email: json['email']?.toString(),
        phone: json['phone']?.toString(),
        currency: json['currency']?.toString() ?? 'EGP',
      );

  Map<String, dynamic> toCreateJson({double openingBalance = 0}) => {
        'displayName': displayName,
        if (companyName?.isNotEmpty == true) 'companyName': companyName,
        if (email?.isNotEmpty == true) 'email': email,
        if (phone?.isNotEmpty == true) 'phone': phone,
        'currency': currency,
        'openingBalance': openingBalance,
      };

  Map<String, dynamic> toUpdateJson() => {
        'displayName': displayName,
        if (companyName?.isNotEmpty == true) 'companyName': companyName,
        if (email?.isNotEmpty == true) 'email': email,
        if (phone?.isNotEmpty == true) 'phone': phone,
        'currency': currency,
      };

  bool get hasBalance => balance > 0;
  bool get hasCreditBalance => creditBalance > 0;
  bool get hasContactInfo => (email?.isNotEmpty == true) || (phone?.isNotEmpty == true);
  bool get needsAttention => hasBalance && !hasCreditBalance;
  double get netPayable => balance - creditBalance;

  String get primaryContact {
    if (phone?.isNotEmpty == true) return phone!;
    if (email?.isNotEmpty == true) return email!;
    return currency;
  }

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }
}
