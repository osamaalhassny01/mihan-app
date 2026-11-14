import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_theme.dart';
import '../../config/currency_helper.dart';
import '../../services/api_service.dart';
import 'presentation_widgets.dart';

class ManagementRequestActions {
  /// Opens the modal to forward/accept a request, assign a provider, and set the price.
  static void showForwardModal(
    BuildContext context, {
    required dynamic requestId,
    required String requestNumber,
    required String serviceName,
    required String customerName,
    dynamic currentPrice,
    dynamic currentBudget,
    required bool isAdmin,
    required VoidCallback onRefresh,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ForwardModalContent(
        requestId: requestId,
        requestNumber: requestNumber,
        serviceName: serviceName,
        customerName: customerName,
        currentPrice: currentPrice,
        currentBudget: currentBudget,
        isAdmin: isAdmin,
        onRefresh: onRefresh,
      ),
    );
  }

  /// Opens the dialog to cancel a request with a reason.
  static void showCancelDialog(
    BuildContext context, {
    required dynamic requestId,
    required String requestNumber,
    required bool isAdmin,
    required VoidCallback onRefresh,
  }) {
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cancel_outlined, color: AppTheme.error, size: 24),
              ),
              const SizedBox(width: 10),
              const Text('إلغاء الطلب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'هل أنت متأكد من رغبتك في إلغاء الطلب رقم #$requestNumber؟',
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 14),
              const Text(
                'سبب الإلغاء: *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'اكتب سبب الإلغاء لتوضيحه للعميل...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
              child: const Text('تراجع'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final reason = reasonController.text.trim();
                      if (reason.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('يرجى كتابة سبب الإلغاء.'),
                            backgroundColor: AppTheme.warning,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      final endpoint = isAdmin
                          ? '/api/admin/requests/$requestId/cancel'
                          : '/api/employee/requests/$requestId/cancel';

                      final res = await ApiService.post(endpoint, {'reason': reason});
                      setDialogState(() => isSubmitting = false);

                      if (context.mounted) {
                        Navigator.of(dialogCtx).pop();
                        if (res.success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم إلغاء الطلب بنجاح وإشعار العميل.'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                          onRefresh();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res.message.isNotEmpty ? res.message : 'فشل إلغاء الطلب.'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('تأكيد الإلغاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the detailed tracking modal showing journey stepper, contacts, and logs.
  static void showTrackingSheet(
    BuildContext context, {
    required dynamic requestId,
    required bool isAdmin,
    required VoidCallback onRefresh,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _TrackingSheetContent(
        requestId: requestId,
        isAdmin: isAdmin,
        onRefresh: onRefresh,
      ),
    );
  }
}

class _ForwardModalContent extends StatefulWidget {
  final dynamic requestId;
  final String requestNumber;
  final String serviceName;
  final String customerName;
  final dynamic currentPrice;
  final dynamic currentBudget;
  final bool isAdmin;
  final VoidCallback onRefresh;

  const _ForwardModalContent({
    required this.requestId,
    required this.requestNumber,
    required this.serviceName,
    required this.customerName,
    this.currentPrice,
    this.currentBudget,
    required this.isAdmin,
    required this.onRefresh,
  });

  @override
  State<_ForwardModalContent> createState() => _ForwardModalContentState();
}

class _ForwardModalContentState extends State<_ForwardModalContent> {
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoadingProviders = true;
  bool _isSubmitting = false;
  List<dynamic> _providers = [];
  dynamic _selectedProviderId;

  @override
  void initState() {
    super.initState();
    if (widget.currentPrice != null && widget.currentPrice.toString().isNotEmpty) {
      _priceController.text = CurrencyHelper.format(widget.currentPrice);
    } else if (widget.currentBudget != null && widget.currentBudget.toString().isNotEmpty) {
      _priceController.text = CurrencyHelper.format(widget.currentBudget);
    }
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    final endpoint = widget.isAdmin
        ? '/api/admin/requests/${widget.requestId}'
        : '/api/employee/requests/${widget.requestId}';

    final res = await ApiService.get(endpoint);
    if (!mounted) return;

    if (res.success && res.data != null && res.data['eligible_providers'] is List) {
      setState(() {
        _providers = res.data['eligible_providers'] as List;
        _isLoadingProviders = false;
        if (_providers.isNotEmpty) {
          _selectedProviderId = _providers[0]['provider_id'] ?? _providers[0]['id'];
        }
      });
    } else {
      // Fallback: load general providers list
      final provRes = await ApiService.get('/api/providers');
      if (!mounted) return;
      setState(() {
        _isLoadingProviders = false;
        if (provRes.success && provRes.data is List) {
          _providers = provRes.data as List;
          if (_providers.isNotEmpty) {
            _selectedProviderId = _providers[0]['id'];
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForward() async {
    final priceStr = CurrencyHelper.toLatinDigits(_priceController.text.trim());
    final price = double.tryParse(priceStr);

    if (_selectedProviderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار مقدم الخدمة.'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد السعر المعتمد للخدمة.'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final endpoint = widget.isAdmin
        ? '/api/admin/requests/${widget.requestId}/forward'
        : '/api/employee/requests/${widget.requestId}/forward';

    final res = await ApiService.post(endpoint, {
      'provider_id': _selectedProviderId,
      'price': price,
      'notes': _notesController.text.trim(),
    });

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res.success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم قبول الطلب #${widget.requestNumber} وتوجيهه بنجاح بالسعر المحدد.'),
          backgroundColor: AppTheme.success,
        ),
      );
      widget.onRefresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty ? res.message : 'فشل اعتماد وتوجيه الطلب.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'قبول وتحويل لمقدم الخدمة وتحديد السعر',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        'طلب #${widget.requestNumber} • ${widget.serviceName}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Customer Summary Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 18, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text('العميل: ${widget.customerName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (widget.currentBudget != null) ...[
                    const Text('الميزانية المقترحة: ', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    Text('${CurrencyHelper.format(widget.currentBudget)} ر.ي', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Provider Dropdown
            const Text('اختيار مقدم الخدمة المكلف: *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (_isLoadingProviders)
              const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
            else if (_providers.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Text('لم يتم العثور على فنيين معتمدين متاحين حالياً لهذا التخصص.'),
              )
            else
              DropdownButtonFormField<dynamic>(
                value: _selectedProviderId,
                isExpanded: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.handyman_outlined, color: AppTheme.secondary, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: _providers.map<DropdownMenuItem<dynamic>>((p) {
                  final id = p['provider_id'] ?? p['id'];
                  final name = p['name'] ?? 'مقدم خدمة';
                  final prof = p['profession'] ?? '';
                  final rating = p['avg_rating'] != null ? '${p['avg_rating']} ⭐' : '';
                  return DropdownMenuItem<dynamic>(
                    value: id,
                    child: Text('$name ($prof) $rating', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedProviderId = val),
              ),
            const SizedBox(height: 16),

            // Price Field
            const Text('السعر المعتمد للخدمة (بالريال): *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'أدخل السعر المتفق عليه (مثال: 5000)',
                prefixIcon: const Icon(Icons.payments_outlined, color: AppTheme.success, size: 20),
                suffixText: 'ر.ي',
                suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Instructions / Notes
            const Text('ملاحظات وتوجيهات للمهني (اختياري):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'تعليمات التنفيذ وملاحظات التنسيق مع العميل...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 22),

            // Action Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isSubmitting ? null : _submitForward,
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('تأكيد التحويل والاعتماد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingSheetContent extends StatefulWidget {
  final dynamic requestId;
  final bool isAdmin;
  final VoidCallback onRefresh;

  const _TrackingSheetContent({
    required this.requestId,
    required this.isAdmin,
    required this.onRefresh,
  });

  @override
  State<_TrackingSheetContent> createState() => _TrackingSheetContentState();
}

class _TrackingSheetContentState extends State<_TrackingSheetContent> {
  bool _isLoading = true;
  Map<String, dynamic>? _request;
  List<dynamic> _history = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final endpoint = widget.isAdmin
        ? '/api/admin/requests/${widget.requestId}'
        : '/api/employee/requests/${widget.requestId}';

    final res = await ApiService.get(endpoint);
    if (!mounted) return;

    if (res.success && res.data != null) {
      setState(() {
        _isLoading = false;
        _request = res.data['request'] as Map<String, dynamic>?;
        _history = (res.data['history'] as List?) ?? [];
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = res.message.isNotEmpty ? res.message : 'فشل جلب تفاصيل التتبع.';
      });
    }
  }

  void _copyPhone(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ الرقم: $phone'),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 40, color: AppTheme.error),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, style: const TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 14),
                        ElevatedButton(onPressed: _loadDetails, child: const Text('إعادة المحاولة')),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'متابعة الطلب #${_request?['request_number'] ?? widget.requestId}',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              Text(
                                _request?['service_name_ar'] ?? _request?['service_name'] ?? 'خدمة فنية',
                                style: const TextStyle(fontSize: 13, color: AppTheme.secondary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          StatusBadge(
                            status: _request?['status'] ?? 'pending',
                            label: _getStatusArabic(_request?['status'] ?? 'pending'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Visual Journey Stepper
                      _buildJourneyStepper(_request?['status'] ?? 'pending'),
                      const SizedBox(height: 18),

                      // Details Cards
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('العميل', _request?['customer_name'] ?? '-', icon: Icons.person_outline,
                              trailing: (_request?['customer_phone'] != null)
                                  ? InkWell(
                                      onTap: () => _copyPhone(_request!['customer_phone']),
                                      child: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.primary),
                                    )
                                  : null,
                            ),
                            const Divider(height: 16),
                            _buildInfoRow('مقدم الخدمة', _request?['provider_name'] ?? 'في انتظار توجيه الإدارة',
                              icon: Icons.handyman_outlined,
                              valueColor: _request?['provider_name'] != null ? AppTheme.success : AppTheme.warning,
                              trailing: (_request?['provider_phone'] != null)
                                  ? InkWell(
                                      onTap: () => _copyPhone(_request!['provider_phone']),
                                      child: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.secondary),
                                    )
                                  : null,
                            ),
                            const Divider(height: 16),
                            _buildInfoRow('السعر المعتمد',
                              _request?['final_price'] != null
                                  ? '${CurrencyHelper.format(_request!['final_price'])} ر.ي'
                                  : (_request?['quoted_price'] != null
                                      ? '${CurrencyHelper.format(_request!['quoted_price'])} ر.ي'
                                      : 'بانتظار تحديد الإدارة'),
                              icon: Icons.payments_outlined,
                              valueColor: AppTheme.success,
                            ),
                            if (_request?['location_name_ar'] != null || _request?['location_name'] != null) ...[
                              const Divider(height: 16),
                              _buildInfoRow('المنطقة', _request?['location_name_ar'] ?? _request?['location_name'] ?? '-', icon: Icons.location_on_outlined),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Description
                      if (_request?['description'] != null && _request!['description'].toString().isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('وصف الطلب:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              Text('${_request!['description']}', style: const TextStyle(fontSize: 13, height: 1.5)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // History Logs
                      const Text('سجل المحطات الزمنية:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      if (_history.isEmpty)
                        const Text('لا توجد سجلات تتبع إضافية.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _history.length,
                          itemBuilder: (ctx, i) {
                            final h = _history[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(top: 6, left: 8, right: 4),
                                    decoration: const BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'تغيير الحالة إلى ${_getStatusArabic(h['new_status'] ?? '')}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'بواسطة: ${h['changed_by_name'] ?? 'النظام'} • ${h['changed_at'] ?? ''}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 18),

                      // Action Buttons at bottom of tracking sheet if applicable
                      if (!['completed', 'cancelled'].contains(_request?['status'])) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.success,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                label: const Text('قبول وتوجيه', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  ManagementRequestActions.showForwardModal(
                                    context,
                                    requestId: widget.requestId,
                                    requestNumber: _request?['request_number'] ?? '${widget.requestId}',
                                    serviceName: _request?['service_name_ar'] ?? _request?['service_name'] ?? 'خدمة',
                                    customerName: _request?['customer_name'] ?? 'عميل',
                                    currentPrice: _request?['final_price'] ?? _request?['quoted_price'],
                                    currentBudget: _request?['budget'],
                                    isAdmin: widget.isAdmin,
                                    onRefresh: widget.onRefresh,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.error,
                                  side: const BorderSide(color: AppTheme.error),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.cancel_outlined, size: 18),
                                label: const Text('إلغاء الطلب', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  ManagementRequestActions.showCancelDialog(
                                    context,
                                    requestId: widget.requestId,
                                    requestNumber: _request?['request_number'] ?? '${widget.requestId}',
                                    isAdmin: widget.isAdmin,
                                    onRefresh: widget.onRefresh,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildJourneyStepper(String status) {
    final stages = ['new', 'accepted', 'in_progress', 'awaiting_confirmation', 'completed'];
    final labels = ['جديد', 'توجيه وسعر', 'تنفيذ', 'استلام', 'مكتمل'];
    int currentIdx = stages.indexOf(status);
    if (status == 'pending') currentIdx = 0;
    if (currentIdx == -1) currentIdx = status == 'cancelled' ? -1 : 0;

    if (status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel, color: AppTheme.error, size: 20),
            SizedBox(width: 8),
            Text('تم إلغاء هذا الطلب من قبل الإدارة', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
    }

    return Row(
      children: List.generate(stages.length, (i) {
        final isCompleted = currentIdx >= i;
        final isCurrent = currentIdx == i;
        return Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isCompleted ? AppTheme.success : AppTheme.border,
                child: isCompleted
                    ? (isCurrent
                        ? const Icon(Icons.circle, size: 10, color: Colors.white)
                        : const Icon(Icons.check, size: 14, color: Colors.white))
                    : Text('${i + 1}', style: const TextStyle(fontSize: 10, color: Colors.white)),
              ),
              const SizedBox(height: 4),
              Text(
                labels[i],
                style: TextStyle(fontSize: 10, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon, Color? valueColor, Widget? trailing}) {
    return Row(
      children: [
        if (icon != null) ...[Icon(icon, size: 16, color: AppTheme.textSecondary), const SizedBox(width: 6)],
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor ?? AppTheme.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  String _getStatusArabic(String status) {
    switch (status) {
      case 'new':
      case 'pending':
        return 'قيد الانتظار';
      case 'accepted':
        return 'مقبول وموجه';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'awaiting_confirmation':
        return 'بانتظار الاستلام';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }
}

/// Reusable request item card with the two buttons (Accept/Forward & Cancel) + Tracking.
class ManagementRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool isAdmin;
  final VoidCallback onRefresh;

  const ManagementRequestCard({
    super.key,
    required this.request,
    required this.isAdmin,
    required this.onRefresh,
  });

  String _getStatusArabic(String status) {
    switch (status) {
      case 'new':
      case 'pending':
        return 'قيد الانتظار';
      case 'accepted':
        return 'مقبول وموجه';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'awaiting_confirmation':
        return 'بانتظار الاستلام';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = request['status'] ?? 'pending';
    final requestId = request['id'];
    final requestNumber = request['request_number'] ?? '$requestId';
    final serviceName = request['service_name_ar'] ?? request['service_name'] ?? 'خدمة فنية';
    final customerName = request['customer_name'] ?? 'عميل';
    final providerName = request['provider_name'];
    final price = request['final_price'] ?? request['display_price'] ?? request['quoted_price'];
    final budget = request['budget'];

    final canAction = !['completed', 'cancelled'].contains(status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tappable card header & body for instant details & tracking
          InkWell(
            onTap: () => ManagementRequestActions.showTrackingSheet(
              context,
              requestId: requestId,
              isAdmin: isAdmin,
              onRefresh: onRefresh,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Request number & Status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '#$requestNumber',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.touch_app_outlined, size: 11, color: AppTheme.primary),
                                SizedBox(width: 2),
                                Text('عرض التفاصيل', style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      StatusBadge(
                        status: status,
                        label: _getStatusArabic(status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Service & Description
                  Text(
                    serviceName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  if (request['description'] != null && request['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      request['description'].toString(),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),

                  // Customer and Provider info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  customerName,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 16, color: AppTheme.border),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                providerName != null ? Icons.check_circle_outline : Icons.hourglass_top_outlined,
                                size: 14,
                                color: providerName != null ? AppTheme.success : AppTheme.warning,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  providerName ?? 'بانتظار التوجيه',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: providerName != null ? AppTheme.success : AppTheme.warning,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Price row
                  Row(
                    children: [
                      const Text('السعر: ', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      if (price != null)
                        Text(
                          '${CurrencyHelper.format(price)} ر.ي',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.success),
                        )
                      else if (budget != null)
                        Text(
                          'الميزانية: ${CurrencyHelper.format(budget)} ر.ي',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        )
                      else
                        const Text('غير محدد بعد', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Action Buttons: 1. قبول وتحويل  2. إلغاء الطلب  3. متابعة الطلب
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Button 1: Accept & Forward to Provider with Price
                if (canAction) ...[
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.how_to_reg_rounded, size: 16, color: Colors.white),
                      label: const Text(
                        'قبول وتحويل',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      onPressed: () => ManagementRequestActions.showForwardModal(
                        context,
                        requestId: requestId,
                        requestNumber: requestNumber,
                        serviceName: serviceName,
                        customerName: customerName,
                        currentPrice: price,
                        currentBudget: budget,
                        isAdmin: isAdmin,
                        onRefresh: onRefresh,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Button 2: Cancel Request
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('إلغاء', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => ManagementRequestActions.showCancelDialog(
                        context,
                        requestId: requestId,
                        requestNumber: requestNumber,
                        isAdmin: isAdmin,
                        onRefresh: onRefresh,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                // Button 3: Track Request
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.route_outlined, size: 14),
                    label: const Text('عرض وتتبع', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => ManagementRequestActions.showTrackingSheet(
                      context,
                      requestId: requestId,
                      isAdmin: isAdmin,
                      onRefresh: onRefresh,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
