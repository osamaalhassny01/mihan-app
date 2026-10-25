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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        customer.errorMessage!,
                        style: const TextStyle(color: AppTheme.error, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Service Selector
                  const Text(
                    'الخدمة المطلوبة *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        hint: const Text('اختر نوع الخدمة'),
                        value: _selectedServiceId,
                        items: customer.services.map((s) {
                          return DropdownMenuItem<int>(
                            value: s.id,
                            child: Text(s.nameAr),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedServiceId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location Selector
                  const Text(
                    'المنطقة أو المدينة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        hint: const Text('اختر المنطقة'),
                        value: _selectedLocationId,
                        items: customer.locations.map((loc) {
                          return DropdownMenuItem<int>(
                            value: loc.id,
                            child: Text(loc.nameAr),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedLocationId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  CustomTextField(
                    label: 'وصف المشكلة أو الطلب *',
                    hint: 'اشرح العطل أو متطلبات العمل بدقة...',
                    controller: _descriptionController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),

                  // Date & Time
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'التاريخ المفضل',
                          hint: '2026-11-01',
                          controller: _dateController,
                          prefixIcon: Icons.calendar_today_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'الوقت المفضل',
                          hint: '10:00 صباحًا',
                          controller: _timeController,
                          prefixIcon: Icons.access_time_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Budget & Notes
                  CustomTextField(
                    label: 'الميزانية التقديرية (ريال)',
                    hint: 'مثال: 5000',
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.attach_money_outlined,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'ملاحظات إضافية',
                    hint: 'أي تفاصيل عن الموقع أو أدوات العمل...',
                    controller: _notesController,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 28),

                  CustomButton(
                    text: 'تأكيد وإرسال الطلب',
                    icon: Icons.send_outlined,
                    isLoading: customer.isCreatingRequest,
                    onPressed: () => _onSubmit(context),
                  ),
                ],
              ),
            ),
    );
  }
}
