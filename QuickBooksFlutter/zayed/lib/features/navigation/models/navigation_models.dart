class NavigationMenuItem {
  const NavigationMenuItem({
    required this.id,
    required this.moduleCode,
    required this.titleAr,
    required this.titleEn,
    required this.icon,
    required this.sortOrder,
    required this.children,
    this.parentId,
    this.route,
  });

  final String id;
  final String? parentId;
  final String moduleCode;
  final String titleAr;
  final String titleEn;
  final String? route;
  final String icon;
  final int sortOrder;
  final List<NavigationMenuItem> children;

  factory NavigationMenuItem.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    return NavigationMenuItem(
      id: json['id']?.toString() ?? '',
      parentId: json['parentId']?.toString(),
      moduleCode: json['moduleCode']?.toString() ?? '',
      titleAr: json['titleAr']?.toString() ?? '',
      titleEn: json['titleEn']?.toString() ?? '',
      route: json['route']?.toString(),
      icon: json['icon']?.toString() ?? 'circle',
      sortOrder: int.tryParse(json['sortOrder']?.toString() ?? '') ?? 0,
      children: rawChildren is List
          ? rawChildren
                .whereType<Map<String, dynamic>>()
                .map(NavigationMenuItem.fromJson)
                .toList()
          : const [],
    );
  }

  String titleFor(String languageCode) {
    if (languageCode == 'ar' && titleAr.trim().isNotEmpty) return titleAr;
    if (titleEn.trim().isNotEmpty) return titleEn;
    return titleAr;
  }
}

class CurrentCompanyModules {
  const CurrentCompanyModules({
    required this.businessType,
    required this.enabledModules,
  });

  final String businessType;
  final List<String> enabledModules;

  factory CurrentCompanyModules.fromJson(Map<String, dynamic> json) {
    final rawModules = json['enabledModules'];
    return CurrentCompanyModules(
      businessType: json['businessType']?.toString() ?? 'retail',
      enabledModules: rawModules is List
          ? rawModules.map((module) => module.toString()).toList()
          : const [],
    );
  }

  bool hasModule(String moduleCode) {
    return enabledModules.any(
      (module) => module.toLowerCase() == moduleCode.toLowerCase(),
    );
  }
}
