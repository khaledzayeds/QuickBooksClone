class HotelReservationModel {
  const HotelReservationModel({
    required this.id,
    required this.reservationNumber,
    required this.contractId,
    required this.contractNumber,
    required this.hotelId,
    required this.hotelName,
    required this.roomTypeId,
    required this.roomTypeName,
    required this.mealPlanId,
    required this.mealPlanName,
    required this.guestName,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.rooms,
    required this.adults,
    required this.children,
    required this.nightlyRate,
    required this.totalAmount,
    required this.status,
    required this.isActive,
    required this.availableRooms,
    this.agentId,
    this.agentName,
    this.guestPhone,
  });

  final String id;
  final String reservationNumber;
  final String contractId;
  final String contractNumber;
  final String hotelId;
  final String hotelName;
  final String? agentId;
  final String? agentName;
  final String roomTypeId;
  final String roomTypeName;
  final String mealPlanId;
  final String mealPlanName;
  final String guestName;
  final String? guestPhone;
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final int rooms;
  final int adults;
  final int children;
  final double nightlyRate;
  final double totalAmount;
  final String status;
  final bool isActive;
  final int availableRooms;

  factory HotelReservationModel.fromJson(
    Map<String, dynamic> json,
  ) => HotelReservationModel(
    id: json['id']?.toString() ?? '',
    reservationNumber: json['reservationNumber']?.toString() ?? '',
    contractId: json['contractId']?.toString() ?? '',
    contractNumber: json['contractNumber']?.toString() ?? '',
    hotelId: json['hotelId']?.toString() ?? '',
    hotelName: json['hotelName']?.toString() ?? '',
    agentId: _optional(json['agentId']),
    agentName: _optional(json['agentName']),
    roomTypeId: json['roomTypeId']?.toString() ?? '',
    roomTypeName: json['roomTypeName']?.toString() ?? '',
    mealPlanId: json['mealPlanId']?.toString() ?? '',
    mealPlanName: json['mealPlanName']?.toString() ?? '',
    guestName: json['guestName']?.toString() ?? '',
    guestPhone: _optional(json['guestPhone']),
    checkIn: _parseDate(json['checkIn']),
    checkOut: _parseDate(json['checkOut']),
    nights: int.tryParse(json['nights']?.toString() ?? '') ?? 1,
    rooms: int.tryParse(json['rooms']?.toString() ?? '') ?? 1,
    adults: int.tryParse(json['adults']?.toString() ?? '') ?? 1,
    children: int.tryParse(json['children']?.toString() ?? '') ?? 0,
    nightlyRate: double.tryParse(json['nightlyRate']?.toString() ?? '') ?? 0,
    totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '') ?? 0,
    status: json['status']?.toString() ?? 'confirmed',
    isActive: json['isActive'] != false,
    availableRooms: int.tryParse(json['availableRooms']?.toString() ?? '') ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'reservationNumber': reservationNumber,
    'contractId': contractId,
    'hotelId': hotelId,
    if (agentId?.isNotEmpty == true) 'agentId': agentId,
    'roomTypeId': roomTypeId,
    'mealPlanId': mealPlanId,
    'guestName': guestName,
    if (guestPhone?.isNotEmpty == true) 'guestPhone': guestPhone,
    'checkIn': _formatDate(checkIn),
    'checkOut': _formatDate(checkOut),
    'rooms': rooms,
    'adults': adults,
    'children': children,
    'nightlyRate': nightlyRate,
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
