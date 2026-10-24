class ProviderProfileModel {
  final int id;
  final int userId;
  final String profession;
  final int experienceYears;
  final double avgRating;
  final int reviewsCount;
  final bool isVerified;
  final bool isAvailable;
  final String? bio;
  final String? providerName;
  final String? profilePhoto;

  const ProviderProfileModel({
    required this.id,
    required this.userId,
    required this.profession,
    this.experienceYears = 0,
    this.avgRating = 0.0,
    this.reviewsCount = 0,
    this.isVerified = false,
    this.isAvailable = true,
    this.bio,
    this.providerName,
    this.profilePhoto,
  });

  factory ProviderProfileModel.fromJson(Map<String, dynamic> json) {
    return ProviderProfileModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      profession: json['profession']?.toString() ?? '',
      experienceYears: json['experience_years'] is int
          ? json['experience_years']
          : int.tryParse(json['experience_years']?.toString() ?? '0') ?? 0,
      avgRating: json['avg_rating'] is num
          ? (json['avg_rating'] as num).toDouble()
          : double.tryParse(json['avg_rating']?.toString() ?? '0') ?? 0.0,
      reviewsCount: json['reviews_count'] is int
          ? json['reviews_count']
          : int.tryParse(json['reviews_count']?.toString() ?? '0') ?? 0,
      isVerified: (json['is_verified']?.toString() == '1' || json['is_verified'] == true),
      isAvailable: (json['is_available']?.toString() == '1' || json['is_available'] == true),
      bio: json['bio']?.toString(),
      providerName: json['name']?.toString() ?? json['provider_name']?.toString(),
      profilePhoto: json['profile_photo']?.toString(),
    );
  }
}

class ServiceRequestModel {
  final int id;
  final String requestNumber;
  final int customerId;
  final int serviceId;
  final int? providerId;
  final int? locationId;
  final String description;
  final String status;
  final String? preferredDate;
  final String? preferredTime;
  final double? budget;
  final String? notes;
  final String createdAt;
  final String? serviceNameAr;
  final String? customerName;
  final String? providerName;
  final String? locationName;

  const ServiceRequestModel({
    required this.id,
    required this.requestNumber,
    required this.customerId,
    required this.serviceId,
    this.providerId,
    this.locationId,
    required this.description,
    required this.status,
    this.preferredDate,
    this.preferredTime,
    this.budget,
    this.notes,
    required this.createdAt,
    this.serviceNameAr,
    this.customerName,
    this.providerName,
    this.locationName,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isRejected => status == 'rejected';

  String get statusArabic {
    switch (status) {
      case 'new': return 'جديد';
      case 'pending': return 'بانتظار الموافقة';
      case 'accepted': return 'مقبول';
      case 'in_progress': return 'قيد التنفيذ';
      case 'completed': return 'مكتمل';
      case 'cancelled': return 'ملغي';
      case 'rejected': return 'مرفوض';
      default: return status;
    }
  }

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      requestNumber: json['request_number']?.toString() ?? '',
      customerId: json['customer_id'] is int ? json['customer_id'] : int.tryParse(json['customer_id']?.toString() ?? '0') ?? 0,
      serviceId: json['service_id'] is int ? json['service_id'] : int.tryParse(json['service_id']?.toString() ?? '0') ?? 0,
      providerId: json['provider_id'] != null ? int.tryParse(json['provider_id'].toString()) : null,
      locationId: json['location_id'] != null ? int.tryParse(json['location_id'].toString()) : null,
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      preferredDate: json['preferred_date']?.toString(),
      preferredTime: json['preferred_time']?.toString(),
      budget: json['budget'] != null ? double.tryParse(json['budget'].toString()) : null,
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      serviceNameAr: json['service_name_ar']?.toString() ?? json['service_name']?.toString(),
      customerName: json['customer_name']?.toString(),
      providerName: json['provider_name']?.toString(),
      locationName: json['location_name']?.toString(),
    );
  }
}
