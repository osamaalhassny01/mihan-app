import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/currency_helper.dart';
import '../../controllers/customer_controller.dart';
import '../widgets/presentation_widgets.dart';
import 'customer_request_detail_view.dart';

class CreateRequestView extends StatefulWidget {
  final int? preselectedCategoryId;
  const CreateRequestView({super.key, this.preselectedCategoryId});
  @override
  State<CreateRequestView> createState() => _CreateRequestViewState();
}

class _CreateRequestViewState extends State<CreateRequestView> {
  final _detailsForm = GlobalKey<FormState>();
  final _timingForm = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _budget = TextEditingController();
  int _step = 0;
  int? _serviceId, _locationId;
  bool _loadingCatalog = true;
  bool _scheduled = false;
  DateTime? _date;
  TimeOfDay? _time;
  String? _localError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCatalog());
  }

  Future<void> _loadCatalog() async {
    final controller = context.read<CustomerController>();
    await controller.loadCatalog();
    if (mounted && widget.preselectedCategoryId != null) {
      await controller.loadServicesForCategory(widget.preselectedCategoryId!);
    }
    if (mounted) setState(() => _loadingCatalog = false);
  }

  @override
  void dispose() {
    _description.dispose();
    _address.dispose();
    _budget.dispose();
    super.dispose();
  }

  String get _dateText => _date == null
      ? 'اختيار اليوم'
      : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}';
  String get _timeText => _time == null
      ? 'اختيار الوقت'
      : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}';
  double? get _budgetValue => double.tryParse(
      CurrencyHelper.toLatinDigits(_budget.text.trim()).replaceAll('٫', '.'));

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
        context: context,
        initialDate: _date ?? now,
        firstDate: now,
        lastDate: now.add(const Duration(days: 90)),
        helpText: 'موعد الزيارة المفضل',
        cancelText: 'رجوع',
        confirmText: 'اختيار');
    if (selected != null && mounted) setState(() => _date = selected);
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
        context: context,
        initialTime: _time ?? TimeOfDay.now(),
        helpText: 'وقت الزيارة المفضل',
        cancelText: 'رجوع',
        confirmText: 'اختيار');
    if (selected != null && mounted) setState(() => _time = selected);
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step == 0 && !(_detailsForm.currentState?.validate() ?? false)) return;
    if (_step == 1) {
      if (!(_timingForm.currentState?.validate() ?? false)) return;
      if (_scheduled) {
        if (_date == null || _time == null) {
          setState(() => _localError = 'اختر اليوم والوقت المفضلين للزيارة');
          return;
        }
        final visit = DateTime(
            _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
        if (!visit.isAfter(DateTime.now())) {
          setState(() => _localError = 'اختر موعدًا قادمًا للزيارة');
          return;
        }
      }
    }
    setState(() {
      _localError = null;
      _step++;
    });
  }

  Future<void> _submit() async {
    final controller = context.read<CustomerController>();
    if (controller.isCreatingRequest) return;
    final success = await controller.createRequest(
        serviceId: _serviceId!,
        locationId: _locationId,
        description: _description.text.trim(),
        preferredDate: _scheduled ? _dateText : null,
        preferredTime: _scheduled ? '$_timeText:00' : null,
        budget: _budgetValue,
        notes: _address.text.trim());
    if (!mounted || !success) return;
    final id = controller.createdRequestId;
    if (id != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
          builder: (_) => CustomerRequestDetailView(requestId: id)));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CustomerController>();
    final busy = controller.isCreatingRequest;
    return PopScope(
      canPop: _step == 0 && !busy,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !busy && _step > 0) setState(() => _step--);
      },
      child: Scaffold(
        appBar: AppBar(
            title: const Text('طلب خدمة'),
            leading: IconButton(
                tooltip: 'رجوع',
                icon: const Icon(Icons.arrow_back),
                onPressed: busy
                    ? null
                    : () {
                        if (_step > 0) {
                          setState(() => _step--);
                        } else {
                          Navigator.pop(context);
                        }
                      })),
        bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.all(16),
            child: CustomButton(
              text: _step == 2 ? 'تأكيد وإرسال الطلب' : 'التالي',
              icon: _step == 2 ? Icons.send_rounded : Icons.arrow_back_rounded,
              isLoading: busy,
              onPressed: _loadingCatalog || controller.services.isEmpty
                  ? null
                  : _step == 2
                      ? _submit
                      : _next,
            )),
        body: _loadingCatalog
            ? const Center(child: CircularProgressIndicator())
            : controller.services.isEmpty || controller.locations.isEmpty
                ? EmptyStateWidget(
                    title: 'تعذر تجهيز نموذج الطلب',
                    message: 'نحتاج قائمة الخدمات والمناطق لإنشاء طلبك.',
                    onRetry: _loadCatalog)
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            for (var i = 0; i < 3; i++)
                              Expanded(
                                  child: Column(children: [
                                Text(
                                    '${i + 1}. ${const [
                                      'الخدمة',
                                      'الموعد',
                                      'المراجعة'
                                    ][i]}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: i <= _step
                                            ? AppTheme.primary
                                            : AppTheme.textSecondary)),
                                const SizedBox(height: 8),
                                Container(
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    decoration: BoxDecoration(
                                        color: i <= _step
                                            ? AppTheme.primary
                                            : AppTheme.border,
                                        borderRadius:
                                            BorderRadius.circular(3))),
                              ]))
                          ]),
                          const SizedBox(height: 24),
                          if (_localError != null ||
                              controller.errorMessage != null)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                    _localError ?? controller.errorMessage!,
                                    style: const TextStyle(
                                        color: AppTheme.error))),
                          if (_step == 0) _details(controller),
                          if (_step == 1) _timing(),
                          if (_step == 2) _review(controller),
                        ])),
      ),
    );
  }

  Widget _details(CustomerController controller) => Form(
      key: _detailsForm,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('ما الخدمة التي تحتاجها؟',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
            'وصف واضح وموقع دقيق يساعدان مقدم الخدمة على تقديم عرض مناسب.',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.6)),
        const SizedBox(height: 24),
        DropdownButtonFormField<int>(
            value: _serviceId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'الخدمة المطلوبة'),
            items: controller.services
                .map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.nameAr, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (value) => setState(() => _serviceId = value),
            validator: (value) =>
                value == null ? 'اختر الخدمة المطلوبة' : null),
        const SizedBox(height: 18),
        DropdownButtonFormField<int>(
            value: _locationId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'منطقة تنفيذ الخدمة'),
            items: controller.locations
                .map(
                    (l) => DropdownMenuItem(value: l.id, child: Text(l.nameAr)))
                .toList(),
            onChanged: (value) => setState(() => _locationId = value),
            validator: (value) =>
                value == null ? 'اختر منطقة تنفيذ الخدمة' : null),
        const SizedBox(height: 18),
        CustomTextField(
            label: 'صف المشكلة أو العمل المطلوب',
            hint: 'ما الذي لا يعمل؟ منذ متى؟ ما النتيجة التي تريدها؟',
            controller: _description,
            maxLines: 4,
            validator: (value) => (value?.trim().length ?? 0) < 5
                ? 'اكتب وصفًا للمشكلة من 5 أحرف على الأقل'
                : null),
        const SizedBox(height: 18),
        CustomTextField(
            label: 'العنوان التفصيلي',
            hint: 'الحي، الشارع، المبنى، وأقرب معلم',
            controller: _address,
            maxLines: 2,
            validator: (value) => (value?.trim().length ?? 0) < 5
                ? 'أضف عنوانًا يساعد مقدم الخدمة على الوصول'
                : null),
      ]));

  Widget _timing() => Form(
      key: _timingForm,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('متى يناسبك؟',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        const SizedBox(height: 18),
        Wrap(spacing: 10, children: [
          ChoiceChip(
              label: const Text('أقرب وقت متاح'),
              selected: !_scheduled,
              onSelected: (_) => setState(() {
                    _scheduled = false;
                    _localError = null;
                  })),
          ChoiceChip(
              label: const Text('موعد أفضله'),
              selected: _scheduled,
              onSelected: (_) => setState(() => _scheduled = true)),
        ]),
        const SizedBox(height: 12),
        const Text(
            'التوفر يعتمد على مقدمي الخدمة. يُعتمد الموعد النهائي ضمن عرض الخدمة.',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.6)),
        if (_scheduled) ...[
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 8, children: [
            OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(_dateText)),
            OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time),
                label: Text(_timeText))
          ]),
        ],
        const SizedBox(height: 28),
        CustomTextField(
            label: 'ميزانية مقترحة (اختياري)',
            hint: 'يمكنك تركها فارغة',
            controller: _budget,
            prefixIcon: Icons.payments_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value?.trim().isEmpty ?? true) return null;
              return _budgetValue == null ||
                      !_budgetValue!.isFinite ||
                      _budgetValue! <= 0 ||
                      _budgetValue! > 99999999.99
                  ? 'أدخل مبلغًا صحيحًا أكبر من صفر'
                  : null;
            }),
        const SizedBox(height: 10),
        const Text(
            'الميزانية توضح توقعك فقط. ستوافق على السعر الفعلي قبل بدء العمل.',
            style: TextStyle(color: AppTheme.textSecondary, height: 1.6)),
      ]));

  Widget _review(CustomerController controller) {
    final service = controller.services.firstWhere((s) => s.id == _serviceId);
    final location =
        controller.locations.firstWhere((l) => l.id == _locationId);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('راجع طلبك قبل إرساله',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
      const SizedBox(height: 18),
      Card(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(service.nameAr,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 28),
                    Text('الموقع: ${location.nameAr}\n${_address.text.trim()}',
                        style: const TextStyle(height: 1.6)),
                    const SizedBox(height: 14),
                    Text(_description.text.trim(),
                        style: const TextStyle(height: 1.6)),
                    const SizedBox(height: 14),
                    Text(_scheduled
                        ? 'الموعد المفضل: $_dateText • $_timeText'
                        : 'الموعد: أقرب وقت متاح'),
                    if (_budgetValue != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                              'ميزانيتك المقترحة: ${CurrencyHelper.format(_budgetValue)} ريال')),
                  ]))),
      const SizedBox(height: 16),
      const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.handshake_outlined, color: AppTheme.primary),
          title: Text('ماذا يحدث بعد الإرسال؟'),
          subtitle: Text(
              'يحجز مقدم خدمة الطلب، ثم يرسل عرضًا. بعد موافقتك ينفذ العمل، وتؤكد استلامه قبل إصدار الفاتورة.',
              style: TextStyle(height: 1.7))),
      TextButton.icon(
          onPressed: () => setState(() => _step = 0),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('تعديل بيانات الطلب')),
    ]);
  }
}
