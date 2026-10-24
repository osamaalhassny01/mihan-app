import 'package:flutter/material.dart';
import '../models/request_and_provider_models.dart';
import '../models/finance_models.dart';
import '../models/catalog_models.dart';
import '../services/api_service.dart';

class ProviderController extends ChangeNotifier {
  Map<String, dynamic>? _dashboardData;
  List<ServiceRequestModel> _requests = [];
  ServiceRequestModel? _selectedRequest;
  InvoiceModel? _selectedInvoice;
  List<dynamic> _requestHistory = [];

  bool _isAvailable = true;
  List<ServiceModel> _myServices = [];
  List<LocationModel> _myLocations = [];
  List<LocationModel> _allLocations = [];

  ProviderFinanceModel? _financeSummary;
  List<dynamic> _invoices = [];

  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  Map<String, dynamic>? get dashboardData => _dashboardData;
  List<ServiceRequestModel> get requests => _requests;
  ServiceRequestModel? get selectedRequest => _selectedRequest;
  InvoiceModel? get selectedInvoice => _selectedInvoice;
  List<dynamic> get requestHistory => _requestHistory;

  bool get isAvailable => _isAvailable;
  List<ServiceModel> get myServices => _myServices;
  List<LocationModel> get myLocations => _myLocations;
  List<LocationModel> get allLocations => _allLocations;

  ProviderFinanceModel? get financeSummary => _financeSummary;
  List<dynamic> get invoices => _invoices;

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.get('/api/provider/dashboard');
    if (res.success && res.data != null) {
      _dashboardData = res.data as Map<String, dynamic>;
      final profile = _dashboardData?['profile'];
      if (profile != null) {
        _isAvailable = (profile['is_available'] == 1 || profile['is_available'] == true);
      }
    } else {
      _errorMessage = res.message;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.get('/api/provider/requests');
    if (res.success && res.data is List) {
      _requests = (res.data as List).map((r) => ServiceRequestModel.fromJson(r)).toList();
    } else {
      _errorMessage = res.message;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRequestDetails(int requestId) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedRequest = null;
    _selectedInvoice = null;
    _requestHistory = [];
    notifyListeners();

    final res = await ApiService.get('/api/provider/requests/$requestId');
    if (res.success && res.data != null) {
      if (res.data['request'] != null) {
        _selectedRequest = ServiceRequestModel.fromJson(res.data['request']);
      }
      if (res.data['invoice'] != null) {
        _selectedInvoice = InvoiceModel.fromJson(res.data['invoice']);
      }
      _requestHistory = (res.data['history'] as List?) ?? [];
    } else {
      _errorMessage = res.message;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> acceptRequest(int requestId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.post('/api/provider/requests/$requestId/accept', {});
    _isActionLoading = false;

    if (res.success) {
      _successMessage = 'تم قبول الطلب بنجاح!';
      await loadRequestDetails(requestId);
      await loadRequests();
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectRequest(int requestId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.post('/api/provider/requests/$requestId/reject', {});
    _isActionLoading = false;

    if (res.success) {
      _successMessage = 'تم رفض الطلب';
      await loadRequests();
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> startRequest(int requestId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.post('/api/provider/requests/$requestId/start', {});
    _isActionLoading = false;

    if (res.success) {
      _successMessage = 'بدأ العمل على تنفيذ الطلب';
      await loadRequestDetails(requestId);
      await loadRequests();
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeRequest(int requestId, double finalPrice) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.post('/api/provider/requests/$requestId/complete', {
      'final_price': finalPrice,
    });
    _isActionLoading = false;

    if (res.success) {
      _successMessage = 'تم إكمال الطلب بنجاح وإصدار الفاتورة!';
      await loadRequestDetails(requestId);
      await loadRequests();
      await loadFinance();
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadProfileAndCoverage() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final profRes = await ApiService.get('/api/provider/profile');
    if (profRes.success && profRes.data != null) {
      final prof = profRes.data['profile'];
      if (prof != null) {
        _isAvailable = (prof['is_available'] == 1 || prof['is_available'] == true);
      }
      if (profRes.data['services'] is List) {
        _myServices = (profRes.data['services'] as List).map((s) => ServiceModel.fromJson(s)).toList();
      }
      if (profRes.data['locations'] is List) {
        _myLocations = (profRes.data['locations'] as List).map((l) => LocationModel.fromJson(l)).toList();
      }
    }

    final allLocsRes = await ApiService.get('/api/locations');
    if (allLocsRes.success && allLocsRes.data is List) {
      _allLocations = (allLocsRes.data as List).map((l) => LocationModel.fromJson(l)).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> toggleAvailability() async {
    _isActionLoading = true;
    notifyListeners();

    final newStatus = !_isAvailable;
    final res = await ApiService.post('/api/provider/availability', {
      'is_available': newStatus ? 1 : 0,
    });

    _isActionLoading = false;
    if (res.success) {
      _isAvailable = newStatus;
      _successMessage = res.message;
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateLocations(List<int> locationIds) async {
    _isActionLoading = true;
    notifyListeners();

    final res = await ApiService.post('/api/provider/locations', {
      'location_ids': locationIds,
    });

    _isActionLoading = false;
    if (res.success) {
      _successMessage = 'تم تحديث مناطق التغطية بنجاح';
      await loadProfileAndCoverage();
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadFinance() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.get('/api/provider/finance');
    if (res.success && res.data != null) {
      if (res.data['summary'] != null) {
        _financeSummary = ProviderFinanceModel.fromJson(res.data['summary']);
      }
      _invoices = (res.data['invoices'] as List?) ?? [];
    } else {
      _errorMessage = res.message;
    }
    _isLoading = false;
    notifyListeners();
  }
}
