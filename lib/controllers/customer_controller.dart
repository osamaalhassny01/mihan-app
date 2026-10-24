import 'package:flutter/material.dart';
import '../models/catalog_models.dart';
import '../models/request_and_provider_models.dart';
import '../models/finance_models.dart';
import '../services/api_service.dart';

class CustomerController extends ChangeNotifier {
  List<CategoryModel> _categories = [];
  List<ServiceModel> _services = [];
  List<LocationModel> _locations = [];
  List<ServiceRequestModel> _requests = [];

  Map<String, dynamic>? _dashboardStats;
  ServiceRequestModel? _selectedRequest;
  InvoiceModel? _selectedInvoice;
  Map<String, dynamic>? _selectedReview;
  List<dynamic> _requestHistory = [];

  bool _isLoading = false;
  bool _isCreatingRequest = false;
  bool _isPaying = false;
  bool _isSubmittingReview = false;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  List<CategoryModel> get categories => _categories;
  List<ServiceModel> get services => _services;
  List<LocationModel> get locations => _locations;
  List<ServiceRequestModel> get requests => _requests;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  ServiceRequestModel? get selectedRequest => _selectedRequest;
  InvoiceModel? get selectedInvoice => _selectedInvoice;
  Map<String, dynamic>? get selectedReview => _selectedReview;
  List<dynamic> get requestHistory => _requestHistory;

  bool get isLoading => _isLoading;
  bool get isCreatingRequest => _isCreatingRequest;
  bool get isPaying => _isPaying;
  bool get isSubmittingReview => _isSubmittingReview;
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

    final res = await ApiService.get('/api/customer/dashboard');
    if (res.success && res.data != null) {
      _dashboardStats = res.data['stats'] as Map<String, dynamic>?;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCatalog() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final catsRes = await ApiService.get('/api/categories');
    if (catsRes.success && catsRes.data is List) {
      _categories = (catsRes.data as List).map((c) => CategoryModel.fromJson(c)).toList();
    }

    final locsRes = await ApiService.get('/api/locations');
    if (locsRes.success && locsRes.data is List) {
      _locations = (locsRes.data as List).map((l) => LocationModel.fromJson(l)).toList();
    }

    final srvRes = await ApiService.get('/api/services');
    if (srvRes.success && srvRes.data is List) {
      _services = (srvRes.data as List).map((s) => ServiceModel.fromJson(s)).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadServicesForCategory(int categoryId) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiService.get('/api/services?category_id=$categoryId');
    if (res.success && res.data is List) {
      _services = (res.data as List).map((s) => ServiceModel.fromJson(s)).toList();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRequests({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final endpoint = status != null ? '/api/customer/requests?status=$status' : '/api/customer/requests';
    final res = await ApiService.get(endpoint);

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
    _selectedReview = null;
    _requestHistory = [];
    notifyListeners();

    final res = await ApiService.get('/api/customer/requests/$requestId');
    if (res.success && res.data != null) {
      if (res.data['request'] != null) {
        _selectedRequest = ServiceRequestModel.fromJson(res.data['request']);
      }
      if (res.data['invoice'] != null) {
        _selectedInvoice = InvoiceModel.fromJson(res.data['invoice']);
      }
      _selectedReview = res.data['review'] as Map<String, dynamic>?;
      _requestHistory = (res.data['history'] as List?) ?? [];
    } else {
      _errorMessage = res.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createRequest({
    required int serviceId,
    int? locationId,
    required String description,
    String? preferredDate,
    String? preferredTime,
    double? budget,
    String? notes,
  }) async {
    _isCreatingRequest = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.post('/api/customer/requests', {
      'service_id': serviceId,
      'location_id': locationId,
      'description': description.trim(),
      'preferred_date': preferredDate,
      'preferred_time': preferredTime,
      'budget': budget,
      'notes': notes,
    });

    _isCreatingRequest = false;
    if (res.success) {
      _successMessage = 'تم إرسال طلب الخدمة بنجاح!';
      await loadRequests();
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelRequest(int requestId) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiService.post('/api/customer/requests/$requestId/cancel', {});
    _isLoading = false;

    if (res.success) {
      _successMessage = 'تم إلغاء الطلب بنجاح';
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

  Future<bool> payInvoice(int invoiceId, {String method = 'simulated_wallet'}) async {
    _isPaying = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.post('/api/customer/invoices/$invoiceId/pay', {
      'method': method,
    });

    _isPaying = false;
    if (res.success) {
      _successMessage = 'تم سداد الفاتورة بنجاح!';
      if (_selectedRequest != null) {
        await loadRequestDetails(_selectedRequest!.id);
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitReview({
    required int requestId,
    required int rating,
    required String comment,
  }) async {
    _isSubmittingReview = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.post('/api/customer/requests/$requestId/review', {
      'rating': rating,
      'comment': comment.trim(),
    });

    _isSubmittingReview = false;
    if (res.success) {
      _successMessage = 'شكرًا لك! تم تسجيل التقييم بنجاح';
      await loadRequestDetails(requestId);
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }
}
