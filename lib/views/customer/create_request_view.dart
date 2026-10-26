import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/customer_controller.dart';
import '../widgets/presentation_widgets.dart';

class CreateRequestView extends StatefulWidget {
  final int? preselectedCategoryId;

  const CreateRequestView({super.key, this.preselectedCategoryId});

  @override
  State<CreateRequestView> createState() => _CreateRequestViewState();
}

class _CreateRequestViewState extends State<CreateRequestView> {
  int? _selectedServiceId;
  int? _selectedLocationId;
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<CustomerController>();
      if (widget.preselectedCategoryId != null) {
        ctrl.loadServicesForCategory(widget.preselectedCategoryId!);
      } else {
        ctrl.loadCatalog();
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSubmit(BuildContext context) async {
    if (_selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الخدمة الفنية المطلوبة')),
      );
      return;
    }

    final desc = _descriptionController.text.trim();
    if (desc.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال وصف تفصيلي للمشكلة لا يقل عن 5 أحرف')),
      );
      return;
    }

    final ctrl = context.read<CustomerController>();
    final success = await ctrl.createRequest(
      serviceId: _selectedServiceId!,
      locationId: _selectedLocationId,
      description: desc,
      preferredDate: _dateController.text.trim().isNotEmpty ? _dateController.text.trim() : null,
      preferredTime: _timeController.text.trim().isNotEmpty ? _timeController.text.trim() : null,
      budget: double.tryParse(_budgetController.text.trim()),
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال طلبك بنجاح! سيتم إشعار مقدمي الخدمة المتاحين'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<CustomerController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب خدمة جديدة'),
      ),
      body: customer.isLoading && customer.services.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (customer.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              customer.errorMessage!,
                              style: const TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Form Container Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service Selector
                        const Row(
                          children: [
                            Icon(Icons.build_circle_outlined, size: 18, color: AppTheme.primary),
                            SizedBox(width: 6),
                            Text(
                              'الخدمة الفنية المطلوبة *',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.secondary),
                              hint: const Text('اختر نوع الخدمة المطلوبة', style: TextStyle(fontSize: 13)),
                              value: _selectedServiceId,
                              items: customer.services.map((s) {
                                return DropdownMenuItem<int>(
                                  value: s.id,
                                  child: Text(s.nameAr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedServiceId = val),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Location Selector
                        const Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 18, color: AppTheme.secondary),
                            SizedBox(width: 6),
                            Text(
                              'المدينة أو المنطقة *',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.secondary),
                              hint: const Text('اختر المنطقة أو الفرع الأقرب إليك', style: TextStyle(fontSize: 13)),
                              value: _selectedLocationId,
                              items: customer.locations.map((loc) {
                                return DropdownMenuItem<int>(
                                  value: loc.id,
                                  child: Text(loc.nameAr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedLocationId = val),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Description
                        CustomTextField(
                          label: 'وصف المشكلة أو تفاصيل العطل *',
                          hint: 'اشرح العطل بدقة لتسهيل معاينة الفني للطلب...',
                          controller: _descriptionController,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 18),

                        // Date & Time
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'التاريخ المفضل للزيارة',
                                hint: 'مثال: 2026-11-01',
                                controller: _dateController,
                                prefixIcon: Icons.calendar_today_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                label: 'الوقت الأنسب',
                                hint: 'مثال: 10:00 صباحًا',
                                controller: _timeController,
                                prefixIcon: Icons.access_time_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Budget & Notes
                        CustomTextField(
                          label: 'الميزانية التقديرية (ريال - اختياري)',
                          hint: 'أدخل الميزانية المقترحة إن وجدت',
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.payments_outlined,
                        ),
                        const SizedBox(height: 18),

                        CustomTextField(
                          label: 'ملاحظات إضافية وتفاصيل الموقع',
                          hint: 'رقم الشقة، الدور، أو أي تفاصيل مساعدة...',
                          controller: _notesController,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'تأكيد وإرسال طلب الخدمة',
                    icon: Icons.send_rounded,
                    isLoading: customer.isCreatingRequest,
                    onPressed: () => _onSubmit(context),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
