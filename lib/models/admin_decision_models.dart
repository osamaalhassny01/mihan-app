class AdminKpis {
  final int totalRequests;
  final int completedRequests;
  final double completionRate;
  final int cancelledRequests;
  final double cancellationRate;
  final int rejectedRequests;
  final double rejectionRate;
  final int pendingRequests;
  final int inProgressRequests;
  final double averageRating;
  final double totalRevenue;
  final double platformCommission;
  final int totalProviders;
  final int verifiedProviders;
  final int availableProviders;
  final int openComplaints;
  final int totalComplaints;
  final double complaintResolutionRate;

  AdminKpis({
    required this.totalRequests,
    required this.completedRequests,
    required this.completionRate,
    required this.cancelledRequests,
    required this.cancellationRate,
    required this.rejectedRequests,
    required this.rejectionRate,
    required this.pendingRequests,
    required this.inProgressRequests,
    required this.averageRating,
    required this.totalRevenue,
    required this.platformCommission,
    required this.totalProviders,
    required this.verifiedProviders,
    required this.availableProviders,
    required this.openComplaints,
    required this.totalComplaints,
    required this.complaintResolutionRate,
  });

  factory AdminKpis.fromJson(Map<String, dynamic> json) {
    return AdminKpis(
      totalRequests: (json['total_requests'] as num?)?.toInt() ?? 0,
      completedRequests: (json['completed_requests'] as num?)?.toInt() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      cancelledRequests: (json['cancelled_requests'] as num?)?.toInt() ?? 0,
      cancellationRate: (json['cancellation_rate'] as num?)?.toDouble() ?? 0.0,
      rejectedRequests: (json['rejected_requests'] as num?)?.toInt() ?? 0,
      rejectionRate: (json['rejection_rate'] as num?)?.toDouble() ?? 0.0,
      pendingRequests: (json['pending_requests'] as num?)?.toInt() ?? 0,
      inProgressRequests: (json['in_progress_requests'] as num?)?.toInt() ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      platformCommission: (json['platform_commission'] as num?)?.toDouble() ?? 0.0,
      totalProviders: (json['total_providers'] as num?)?.toInt() ?? 0,
      verifiedProviders: (json['verified_providers'] as num?)?.toInt() ?? 0,
      availableProviders: (json['available_providers'] as num?)?.toInt() ?? 0,
      openComplaints: (json['open_complaints'] as num?)?.toInt() ?? 0,
      totalComplaints: (json['total_complaints'] as num?)?.toInt() ?? 0,
      complaintResolutionRate: (json['complaint_resolution_rate'] as num?)?.toDouble() ?? 100.0,
    );
  }
}

class SupplyDemandDeficitItem {
  final int locationId;
  final String nameAr;
  final String nameEn;
  final String city;
  final int requestsCount;
  final int totalProviders;
  final int availableProviders;
  final int verifiedProviders;
  final double demandToSupplyRatio;
  final String status;
  final String statusLabel;
  final String badgeColor;
  final String recommendation;

  SupplyDemandDeficitItem({
    required this.locationId,
    required this.nameAr,
    required this.nameEn,
    required this.city,
    required this.requestsCount,
    required this.totalProviders,
    required this.availableProviders,
    required this.verifiedProviders,
    required this.demandToSupplyRatio,
    required this.status,
    required this.statusLabel,
    required this.badgeColor,
    required this.recommendation,
  });

  factory SupplyDemandDeficitItem.fromJson(Map<String, dynamic> json) {
    return SupplyDemandDeficitItem(
      locationId: (json['location_id'] as num?)?.toInt() ?? 0,
      nameAr: json['name_ar'] ?? '',
      nameEn: json['name_en'] ?? '',
      city: json['city'] ?? '',
      requestsCount: (json['requests_count'] as num?)?.toInt() ?? 0,
      totalProviders: (json['total_providers'] as num?)?.toInt() ?? 0,
      availableProviders: (json['available_providers'] as num?)?.toInt() ?? 0,
      verifiedProviders: (json['verified_providers'] as num?)?.toInt() ?? 0,
      demandToSupplyRatio: (json['demand_to_supply_ratio'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'balanced',
      statusLabel: json['status_label'] ?? 'متوازن',
      badgeColor: json['badge_color'] ?? 'success',
      recommendation: json['recommendation'] ?? '',
    );
  }
}

class ProviderPerformanceItem {
  final int providerId;
  final int userId;
  final String name;
  final String phone;
  final String email;
  final String profession;
  final int yearsExp;
  final double avgRating;
  final int totalReviews;
  final int completedJobs;
  final int totalAssigned;
  final double completionRate;
  final double rejectionRate;
  final int complaintsCount;
  final bool isVerified;
  final bool isAvailable;
  final double compositeScore;
  final String tier;
  final String tierLabel;
  final String badgeColor;
  final String adminAction;

  ProviderPerformanceItem({
    required this.providerId,
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    required this.profession,
    required this.yearsExp,
    required this.avgRating,
    required this.totalReviews,
    required this.completedJobs,
    required this.totalAssigned,
    required this.completionRate,
    required this.rejectionRate,
    required this.complaintsCount,
    required this.isVerified,
    required this.isAvailable,
    required this.compositeScore,
    required this.tier,
    required this.tierLabel,
    required this.badgeColor,
    required this.adminAction,
  });

  factory ProviderPerformanceItem.fromJson(Map<String, dynamic> json) {
    return ProviderPerformanceItem(
      providerId: (json['provider_id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      profession: json['profession'] ?? '',
      yearsExp: (json['years_exp'] as num?)?.toInt() ?? 0,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      completedJobs: (json['completed_jobs'] as num?)?.toInt() ?? 0,
      totalAssigned: (json['total_assigned'] as num?)?.toInt() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      rejectionRate: (json['rejection_rate'] as num?)?.toDouble() ?? 0.0,
      complaintsCount: (json['complaints_count'] as num?)?.toInt() ?? 0,
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      isAvailable: json['is_available'] == true || json['is_available'] == 1,
      compositeScore: (json['composite_score'] as num?)?.toDouble() ?? 0.0,
      tier: json['tier'] ?? 'normal',
      tierLabel: json['tier_label'] ?? '',
      badgeColor: json['badge_color'] ?? 'primary',
      adminAction: json['admin_action'] ?? '',
    );
  }
}

class ProviderPerformanceMatrix {
  final int totalEvaluated;
  final int topPerformersCount;
  final int needsAttentionCount;
  final List<ProviderPerformanceItem> topPerformers;
  final List<ProviderPerformanceItem> needsAttention;

  ProviderPerformanceMatrix({
    required this.totalEvaluated,
    required this.topPerformersCount,
    required this.needsAttentionCount,
    required this.topPerformers,
    required this.needsAttention,
  });

  factory ProviderPerformanceMatrix.fromJson(Map<String, dynamic> json) {
    return ProviderPerformanceMatrix(
      totalEvaluated: (json['total_evaluated'] as num?)?.toInt() ?? 0,
      topPerformersCount: (json['top_performers_count'] as num?)?.toInt() ?? 0,
      needsAttentionCount: (json['needs_attention_count'] as num?)?.toInt() ?? 0,
      topPerformers: (json['top_performers'] as List?)
              ?.map((e) => ProviderPerformanceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      needsAttention: (json['needs_attention'] as List?)
              ?.map((e) => ProviderPerformanceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ServiceDemandItem {
  final int serviceId;
  final String nameAr;
  final String nameEn;
  final String categoryName;
  final double basePrice;
  final int requestsCount;
  final int activeProvidersCount;
  final int completedCount;
  final int cancelledCount;
  final double totalRevenue;
  final double marketSharePercent;
  final String? deficitUrgency;
  final String? recommendation;

  ServiceDemandItem({
    required this.serviceId,
    required this.nameAr,
    required this.nameEn,
    required this.categoryName,
    required this.basePrice,
    required this.requestsCount,
    required this.activeProvidersCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.totalRevenue,
    required this.marketSharePercent,
    this.deficitUrgency,
    this.recommendation,
  });

  factory ServiceDemandItem.fromJson(Map<String, dynamic> json) {
    return ServiceDemandItem(
      serviceId: (json['service_id'] as num?)?.toInt() ?? 0,
      nameAr: json['name_ar'] ?? '',
      nameEn: json['name_en'] ?? '',
      categoryName: json['category_name'] ?? '',
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      requestsCount: (json['requests_count'] as num?)?.toInt() ?? 0,
      activeProvidersCount: (json['active_providers_count'] as num?)?.toInt() ?? 0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      cancelledCount: (json['cancelled_count'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      marketSharePercent: (json['market_share_percent'] as num?)?.toDouble() ?? 0.0,
      deficitUrgency: json['deficit_urgency'],
      recommendation: json['recommendation'],
    );
  }
}

class ServiceDemandAnalysis {
  final List<ServiceDemandItem> mostDemanded;
  final List<ServiceDemandItem> leastDemanded;
  final List<ServiceDemandItem> specializationDeficit;

  ServiceDemandAnalysis({
    required this.mostDemanded,
    required this.leastDemanded,
    required this.specializationDeficit,
  });

  factory ServiceDemandAnalysis.fromJson(Map<String, dynamic> json) {
    return ServiceDemandAnalysis(
      mostDemanded: (json['most_demanded'] as List?)
              ?.map((e) => ServiceDemandItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      leastDemanded: (json['least_demanded'] as List?)
              ?.map((e) => ServiceDemandItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      specializationDeficit: (json['specialization_deficit'] as List?)
              ?.map((e) => ServiceDemandItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ComplaintsHotspotsData {
  final int totalComplaints;
  final Map<String, dynamic> statusBreakdown;
  final List<Map<String, dynamic>> hotspotsByService;
  final List<Map<String, dynamic>> hotspotsByLocation;
  final List<Map<String, dynamic>> repeatedProviders;

  ComplaintsHotspotsData({
    required this.totalComplaints,
    required this.statusBreakdown,
    required this.hotspotsByService,
    required this.hotspotsByLocation,
    required this.repeatedProviders,
  });

  factory ComplaintsHotspotsData.fromJson(Map<String, dynamic> json) {
    return ComplaintsHotspotsData(
      totalComplaints: (json['total_complaints'] as num?)?.toInt() ?? 0,
      statusBreakdown: (json['status_breakdown'] as Map<String, dynamic>?) ?? {},
      hotspotsByService: (json['hotspots_by_service'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      hotspotsByLocation: (json['hotspots_by_location'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      repeatedProviders: (json['repeated_providers'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}

class AiRecommendationItem {
  final String id;
  final String pillar;
  final String severity; // urgent, warning, opportunity, info
  final String title;
  final String explanation;
  final String recommendation;
  final String actionLabel;
  final String actionType;
  final int targetId;

  AiRecommendationItem({
    required this.id,
    required this.pillar,
    required this.severity,
    required this.title,
    required this.explanation,
    required this.recommendation,
    required this.actionLabel,
    required this.actionType,
    required this.targetId,
  });

  factory AiRecommendationItem.fromJson(Map<String, dynamic> json) {
    return AiRecommendationItem(
      id: json['id'] ?? '',
      pillar: json['pillar'] ?? 'overview',
      severity: json['severity'] ?? 'info',
      title: json['title'] ?? '',
      explanation: json['explanation'] ?? '',
      recommendation: json['recommendation'] ?? '',
      actionLabel: json['action_label'] ?? 'عرض التفاصيل',
      actionType: json['action_type'] ?? '',
      targetId: (json['target_id'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminDecisionSupportData {
  final String generatedAt;
  final AdminKpis kpis;
  final List<SupplyDemandDeficitItem> supplyDemandDeficit;
  final ProviderPerformanceMatrix providerPerformance;
  final ServiceDemandAnalysis serviceDemand;
  final ComplaintsHotspotsData complaintsHotspots;
  final List<AiRecommendationItem> aiRecommendations;

  AdminDecisionSupportData({
    required this.generatedAt,
    required this.kpis,
    required this.supplyDemandDeficit,
    required this.providerPerformance,
    required this.serviceDemand,
    required this.complaintsHotspots,
    required this.aiRecommendations,
  });

  factory AdminDecisionSupportData.fromJson(Map<String, dynamic> json) {
    return AdminDecisionSupportData(
      generatedAt: json['generated_at'] ?? '',
      kpis: AdminKpis.fromJson(json['kpis'] ?? {}),
      supplyDemandDeficit: (json['supply_demand_deficit'] as List?)
              ?.map((e) => SupplyDemandDeficitItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      providerPerformance: ProviderPerformanceMatrix.fromJson(json['provider_performance'] ?? {}),
      serviceDemand: ServiceDemandAnalysis.fromJson(json['service_demand'] ?? {}),
      complaintsHotspots: ComplaintsHotspotsData.fromJson(json['complaints_hotspots'] ?? {}),
      aiRecommendations: (json['ai_recommendations'] as List?)
              ?.map((e) => AiRecommendationItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
