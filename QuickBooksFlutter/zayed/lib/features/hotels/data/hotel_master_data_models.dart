abstract class HotelMasterDataRecord {
  const HotelMasterDataRecord();

  String get id;
  String get title;
  String get subtitle;
  bool get isActive;
  Map<String, dynamic> toJson();
}

class HotelPropertyModel extends HotelMasterDataRecord {
  const HotelPropertyModel({
    required this.id,
    required this.name,
    required this.country,
    required this.city,
    required this.isActive,
    this.address,
    this.phone,
    this.email,
  });

  @override
  final String id;
  final String name;
  final String country;
  final String city;
  final String? address;
  final String? phone;
  final String? email;
  @override
  final bool isActive;

  factory HotelPropertyModel.fromJson(Map<String, dynamic> json) =>
      HotelPropertyModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        country: json['country']?.toString() ?? 'Saudi Arabia',
        city: json['city']?.toString() ?? '',
        address: json['address']?.toString(),
        phone: json['phone']?.toString(),
        email: json['email']?.toString(),
        isActive: json['isActive'] != false,
      );

  @override
  String get title => name;

  @override
  String get subtitle => [city, country, phone].where(_hasText).join(' - ');

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'country': country,
    'city': city,
    if (_hasText(address)) 'address': address,
    if (_hasText(phone)) 'phone': phone,
    if (_hasText(email)) 'email': email,
  };
}

class HotelRoomTypeModel extends HotelMasterDataRecord {
  const HotelRoomTypeModel({
    required this.id,
    required this.code,
    required this.name,
    required this.capacity,
    required this.isActive,
    this.description,
  });

  @override
  final String id;
  final String code;
  final String name;
  final int capacity;
  final String? description;
  @override
  final bool isActive;

  factory HotelRoomTypeModel.fromJson(Map<String, dynamic> json) =>
      HotelRoomTypeModel(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        capacity: int.tryParse(json['capacity']?.toString() ?? '') ?? 1,
        description: json['description']?.toString(),
        isActive: json['isActive'] != false,
      );

  @override
  String get title => '$code - $name';

  @override
  String get subtitle =>
      'Capacity: $capacity${_hasText(description) ? ' - $description' : ''}';

  @override
  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'capacity': capacity,
    if (_hasText(description)) 'description': description,
  };
}

class HotelMealPlanModel extends HotelMasterDataRecord {
  const HotelMealPlanModel({
    required this.id,
    required this.code,
    required this.name,
    required this.isActive,
    this.description,
  });

  @override
  final String id;
  final String code;
  final String name;
  final String? description;
  @override
  final bool isActive;

  factory HotelMealPlanModel.fromJson(Map<String, dynamic> json) =>
      HotelMealPlanModel(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        isActive: json['isActive'] != false,
      );

  @override
  String get title => '$code - $name';

  @override
  String get subtitle => description ?? '';

  @override
  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    if (_hasText(description)) 'description': description,
  };
}

class HotelAgentModel extends HotelMasterDataRecord {
  const HotelAgentModel({
    required this.id,
    required this.name,
    required this.currency,
    required this.isActive,
    this.contactName,
    this.email,
    this.phone,
  });

  @override
  final String id;
  final String name;
  final String currency;
  final String? contactName;
  final String? email;
  final String? phone;
  @override
  final bool isActive;

  factory HotelAgentModel.fromJson(Map<String, dynamic> json) =>
      HotelAgentModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        contactName: json['contactName']?.toString(),
        email: json['email']?.toString(),
        phone: json['phone']?.toString(),
        currency: json['currency']?.toString() ?? 'SAR',
        isActive: json['isActive'] != false,
      );

  @override
  String get title => name;

  @override
  String get subtitle =>
      [contactName, phone, currency].where(_hasText).join(' - ');

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    if (_hasText(contactName)) 'contactName': contactName,
    if (_hasText(email)) 'email': email,
    if (_hasText(phone)) 'phone': phone,
    'currency': currency,
  };
}

bool _hasText(Object? value) => value?.toString().trim().isNotEmpty == true;
