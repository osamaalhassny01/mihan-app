class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? profilePhoto;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profilePhoto,
  });

  bool get isCustomer => role == 'customer';
  bool get isProvider => role == 'provider';
  bool get isEmployee => role == 'employee';
  bool get isAdmin => role == 'admin';

  String get roleTitle {
    switch (role) {
      case 'provider':
        return 'مقدم خدمة فنية';
      case 'employee':
        return 'موظف منصة';
      case 'admin':
        return 'مدير النظام';
      case 'customer':
      default:
        return 'عميل مستفيد';
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'customer',
      profilePhoto: json['profile_photo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'profile_photo': profilePhoto,
    };
  }
}
