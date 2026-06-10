class HotelContractRateModel {
  const HotelContractRateModel({
    required this.id,
    required this.roomTypeId,
    required this.roomTypeName,
    required this.mealPlanId,
    required this.mealPlanName,
    required this.rate,
  });

  final String id;
  final String roomTypeId;
  final String roomTypeName;
  final String mealPlanId;
  final String mealPlanName;
  final double rate;

  factory HotelContractRateModel.fromJson(Map<String, dynamic> json) =>
      HotelContractRateModel(
        id: json['id']?.toString() ?? '',
        roomTypeId: json['roomTypeId']?.toString() ?? '',
        roomTypeName: json['roomTypeName']?.toString() ?? '',
        mealPlanId: json['mealPlanId']?.toString() ?? '',
        mealPlanName: json['mealPlanName']?.toString() ?? '',
        rate: double.tryParse(json['rate']?.toString() ?? '') ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'roomTypeId': roomTypeId,
    'mealPlanId': mealPlanId,
    'rate': rate,
  };
}

class HotelContractModel {
  const HotelContractModel({
    required this.id,
    required this.contractNumber,
    required this.hotelId,
    required this.hotelName,
    required this.startDate,
    required this.endDate,
    required this.currency,
    required this.isActive,
    required this.rates,
    this.agentId,
    this.agentName,
    this.notes,
  });

  final String id;
  final String contractNumber;
  final String hotelId;
  final String hotelName;
  final String? agentId;
  final String? agentName;
  final DateTime startDate;
  final DateTime endDate;
  final String currency;
  final String? notes;
  final bool isActive;
  final List<HotelContractRateModel> rates;

  factory HotelContractModel.fromJson(Map<String, dynamic> json) {
    final rawRates = json['rates'];
    return HotelContractModel(
      id: json['id']?.toString() ?? '',
      contractNumber: json['contractNumber']?.toString() ?? '',
      hotelId: json['hotelId']?.toString() ?? '',
      hotelName: json['hotelName']?.toString() ?? '',
      agentId: _optional(json['agentId']),
      agentName: _optional(json['agentName']),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      currency: json['currency']?.toString() ?? 'SAR',
      notes: _optional(json['notes']),
      isActive: json['isActive'] != false,
      rates: rawRates is List
          ? rawRates
                .whereType<Map<String, dynamic>>()
                .map(HotelContractRateModel.fromJson)
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'contractNumber': contractNumber,
    'hotelId': hotelId,
    if (agentId?.isNotEmpty == true) 'agentId': agentId,
    'startDate': _formatDate(startDate),
    'endDate': _formatDate(endDate),
    'currency': currency,
    if (notes?.isNotEmpty == true) 'notes': notes,
    'rates': rates.map((rate) => rate.toJson()).toList(),
  };
}

class HotelAllotmentModel {
  const HotelAllotmentModel({
    required this.id,
    required this.contractId,
    required this.contractNumber,
    required this.hotelId,
    required this.hotelName,
    required this.startDate,
    required this.endDate,
    required this.rooms,
    required this.allotmentType,
    required this.isOverAllotment,
    required this.isActive,
    this.agentId,
    this.agentName,
  });

  final String id;
  final String contractId;
  final String contractNumber;
  final String hotelId;
  final String hotelName;
  final String? agentId;
  final String? agentName;
  final DateTime startDate;
  final DateTime endDate;
  final int rooms;
  final String allotmentType;
  final bool isOverAllotment;
  final bool isActive;

  factory HotelAllotmentModel.fromJson(Map<String, dynamic> json) =>
      HotelAllotmentModel(
        id: json['id']?.toString() ?? '',
        contractId: json['contractId']?.toString() ?? '',
        contractNumber: json['contractNumber']?.toString() ?? '',
        hotelId: json['hotelId']?.toString() ?? '',
        hotelName: json['hotelName']?.toString() ?? '',
        agentId: _optional(json['agentId']),
        agentName: _optional(json['agentName']),
        startDate: _parseDate(json['startDate']),
        endDate: _parseDate(json['endDate']),
        rooms: int.tryParse(json['rooms']?.toString() ?? '') ?? 1,
        allotmentType: json['allotmentType']?.toString() ?? 'hotel',
        isOverAllotment: json['isOverAllotment'] == true,
        isActive: json['isActive'] != false,
      );

  Map<String, dynamic> toJson() => {
    'contractId': contractId,
    'hotelId': hotelId,
    if (agentId?.isNotEmpty == true) 'agentId': agentId,
    'startDate': _formatDate(startDate),
    'endDate': _formatDate(endDate),
    'rooms': rooms,
    'allotmentType': allotmentType,
    'isOverAllotment': isOverAllotment,
  };
}

DateTime _parseDate(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

String _formatDate(DateTime value) {
  return value.toIso8601String().substring(0, 10);
}

String? _optional(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
