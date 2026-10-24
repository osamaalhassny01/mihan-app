import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/request_and_provider_models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthController extends ChangeNotifier {
  UserModel? _currentUser;
  ProviderProfileModel? _providerProfile;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  ProviderProfileModel? get providerProfile => _providerProfile;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _currentUser != null;
  bool get isCustomer => _currentUser?.isCustomer ?? false;
  bool get isProvider => _currentUser?.isProvider ?? false;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        final res = await ApiService.get('/api/me');
        if (res.success && res.data != null) {
          final userMap = res.data['user'] as Map<String, dynamic>;
          _currentUser = UserModel.fromJson(userMap);
          await StorageService.saveUser(_currentUser!);

          if (res.data['provider_profile'] != null) {
            _providerProfile = ProviderProfileModel.fromJson(res.data['provider_profile']);
          }
        } else {
          // Token expired or invalid
          await StorageService.clearAuth();
          _currentUser = null;
          _providerProfile = null;
        }
      }
    } catch (_) {
      // Offline fallback: try reading cached user
      _currentUser = await StorageService.getUser();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.post('/api/login', {
      'email': email.trim(),
      'password': password,
    }, withAuth: false);

    _isLoading = false;
    if (res.success && res.data != null) {
      final token = res.data['token']?.toString() ?? '';
      await StorageService.saveToken(token);

      final userMap = res.data['user'] as Map<String, dynamic>;
      _currentUser = UserModel.fromJson(userMap);
      await StorageService.saveUser(_currentUser!);

      if (res.data['provider_profile'] != null) {
        _providerProfile = ProviderProfileModel.fromJson(res.data['provider_profile']);
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message.isNotEmpty ? res.message : 'فشل تسجيل الدخول';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    String? profession,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.post('/api/register', {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
      'role': role,
      'profession': profession ?? 'مقدم خدمة فنية',
    }, withAuth: false);

    _isLoading = false;
    if (res.success && res.data != null) {
      final token = res.data['token']?.toString() ?? '';
      await StorageService.saveToken(token);

      final userMap = res.data['user'] as Map<String, dynamic>;
      _currentUser = UserModel.fromJson(userMap);
      await StorageService.saveUser(_currentUser!);

      if (res.data['provider_profile'] != null) {
        _providerProfile = ProviderProfileModel.fromJson(res.data['provider_profile']);
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message.isNotEmpty ? res.message : 'فشل إنشاء الحساب';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await StorageService.clearAuth();
    _currentUser = null;
    _providerProfile = null;
    _errorMessage = null;

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
