class MahirProfessionModel {
  final int id;
  final String name;
  final String? nameEn;
  final String category;
  final String icon;
  final String? description;
  final String? systemPromptExtra;
  final bool isActive;
  final int sortOrder;

  const MahirProfessionModel({
    required this.id,
    required this.name,
    this.nameEn,
    required this.category,
    required this.icon,
    this.description,
    this.systemPromptExtra,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory MahirProfessionModel.fromJson(Map<String, dynamic> json) {
    return MahirProfessionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      nameEn: json['name_en']?.toString(),
      category: json['category']?.toString() ?? 'عام',
      icon: (json['icon'] != null && json['icon'].toString().isNotEmpty)
          ? json['icon'].toString()
          : _getDefaultIcon(json['category']?.toString() ?? ''),
      description: json['description']?.toString(),
      systemPromptExtra: json['system_prompt_extra']?.toString(),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      sortOrder: json['sort_order'] is int
          ? json['sort_order']
          : int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
    );
  }

  static String _getDefaultIcon(String cat) {
    switch (cat) {
      case 'صيانة_منزلية':
        return '🔧';
      case 'طعام':
        return '🍳';
      case 'تقنية':
        return '💻';
      case 'زراعة':
        return '🌿';
      case 'سيارات':
        return '🚗';
      case 'يدوية':
        return '✂️';
      default:
        return '🛠️';
    }
  }

  String get categoryLabel {
    switch (category) {
      case 'صيانة_منزلية':
        return 'صيانة منزلية';
      case 'طعام':
        return 'طعام وطبخ';
      case 'تقنية':
        return 'تقنية وإلكترونيات';
      case 'زراعة':
        return 'زراعة وحدائق';
      case 'سيارات':
        return 'صيانة سيارات';
      case 'يدوية':
        return 'حرف يدوية وخياطة';
      default:
        return category;
    }
  }
}

class MahirMessageModel {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  MahirMessageModel({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory MahirMessageModel.fromJson(Map<String, dynamic> json) {
    return MahirMessageModel(
      role: json['role']?.toString() ?? 'assistant',
      content: json['content']?.toString() ?? '',
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
  };
}

