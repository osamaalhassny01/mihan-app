import 'package:flutter/foundation.dart';
import '../models/mahir_models.dart';
import '../services/mahir_service.dart';

class MahirController extends ChangeNotifier {
  Map<String, List<MahirProfessionModel>> _categories = {};
  List<MahirProfessionModel> _allProfessions = [];
  List<MahirProfessionModel> _filteredProfessions = [];

  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isLoading = false;

  // حالة المحادثة الحالية
  bool _isChatLoading = false;
  bool _isSending = false;
  String? _sessionToken;
  MahirProfessionModel? _currentProfession;
  final List<MahirMessageModel> _messages = [];
  String? _errorMessage;

  // Getters
  Map<String, List<MahirProfessionModel>> get categories => _categories;
  List<MahirProfessionModel> get allProfessions => _allProfessions;
  List<MahirProfessionModel> get filteredProfessions => _filteredProfessions;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isChatLoading => _isChatLoading;
  bool get isSending => _isSending;
  String? get sessionToken => _sessionToken;
  MahirProfessionModel? get currentProfession => _currentProfession;
  List<MahirMessageModel> get messages => List.unmodifiable(_messages);
  String? get errorMessage => _errorMessage;

  /// تحميل قائمة المهن
  Future<void> loadProfessions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await MahirService.getProfessions();
      final List<MahirProfessionModel> list = [];
      _categories.forEach((_, items) => list.addAll(items));
      _allProfessions = list;
      _applyFilter();
    } catch (e) {
      _errorMessage = 'تعذر تحميل المهن: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تصفية المهن حسب البحث والفئة
  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilter();
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    _filteredProfessions = _allProfessions.where((p) {
      final matchesCategory = _selectedCategory == 'all' || p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery) ||
          (p.nameEn != null && p.nameEn!.toLowerCase().contains(_searchQuery)) ||
          (p.description != null && p.description!.toLowerCase().contains(_searchQuery));
      return matchesCategory && matchesSearch;
    }).toList();
  }

  /// بدء محادثة لمهنة معينة
  Future<bool> startChatForProfession(MahirProfessionModel profession) async {
    _currentProfession = profession;
    return await _initializeSession(professionId: profession.id);
  }

  /// بدء محادثة عامة مع ماهر
  Future<bool> startGeneralChat() async {
    _currentProfession = null;
    return await _initializeSession();
  }

  Future<bool> _initializeSession({int? professionId}) async {
    _isChatLoading = true;
    _messages.clear();
    _errorMessage = null;
    notifyListeners();

    final result = await MahirService.startSession(professionId: professionId);

    _isChatLoading = false;
    if (result.success && result.sessionToken != null) {
      _sessionToken = result.sessionToken;
      if (result.welcomeMessage != null && result.welcomeMessage!.isNotEmpty) {
        _messages.add(MahirMessageModel(
          role: 'assistant',
          content: result.welcomeMessage!,
        ));
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.errorMessage ?? 'تعذر بدء الجلسة مع ماهر';
      notifyListeners();
      return false;
    }
  }

  /// إرسال رسالة لماهر AI
  Future<bool> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _sessionToken == null || _isSending) {
      return false;
    }

    // إضافة رسالة المستخدم فوراً للواجهة
    _messages.add(MahirMessageModel(
      role: 'user',
      content: cleanText,
    ));
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    final res = await MahirService.sendMessage(
      sessionToken: _sessionToken!,
      message: cleanText,
    );

    _isSending = false;

    if (res.success && res.data != null && res.data['reply'] != null) {
      final reply = res.data['reply'].toString();
      _messages.add(MahirMessageModel(
        role: 'assistant',
        content: reply,
      ));
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message.isNotEmpty ? res.message : 'لم يتمكن ماهر من الرد حالياً';
      _messages.add(MahirMessageModel(
        role: 'assistant',
        content: '⚠️ عذراً، حدث خطأ أثناء معالجة ردك: ${_errorMessage!}',
      ));
      notifyListeners();
      return false;
    }
  }

  /// إعادة تعيين المحادثة
  void resetChat() {
    _sessionToken = null;
    _currentProfession = null;
    _messages.clear();
    _errorMessage = null;
    _isSending = false;
    _isChatLoading = false;
    notifyListeners();
  }
}

