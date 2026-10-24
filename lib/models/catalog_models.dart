class CategoryModel {
  final int id;
  final String nameAr;
  final String? nameEn;
  final String? icon;
  final int servicesCount;

  const CategoryModel({
    required this.id,
    required this.nameAr,
    this.nameEn,
    this.icon,
    this.servicesCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nameAr: json['name_ar']?.toString() ?? '',
      nameEn: json['name_en']?.toString(),
      icon: json['icon']?.toString(),
      servicesCount: json['services_count'] is int
          ? json['services_count']
          : int.tryParse(json['services_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name_ar': nameAr,
    'name_en': nameEn,
    'icon': icon,
    'services_count': servicesCount,
  };
}

class ServiceModel {
  final int id;
  final int categoryId;
  final String nameAr;
  final String? nameEn;
  final String? description;
  final double basePrice;

  const ServiceModel({
    required this.id,
    required this.categoryId,
    required this.nameAr,
    this.nameEn,
    this.description,
    this.basePrice = 0.0,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id']?.toString() ?? '0') ?? 0,
      nameAr: json['name_ar']?.toString() ?? '',
      nameEn: json['name_en']?.toString(),
      description: json['description']?.toString(),
      basePrice: json['base_price'] is num ? (json['base_price'] as num).toDouble() : double.tryParse(json['base_price']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class LocationModel {
  final int id;
  final String nameAr;
  final String? city;

  const LocationModel({
    required this.id,
    required this.nameAr,
    this.city,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nameAr: json['name_ar']?.toString() ?? '',
      city: json['city']?.toString(),
    );
  }
}
