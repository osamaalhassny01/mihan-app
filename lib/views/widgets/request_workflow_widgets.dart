import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/currency_helper.dart';
import '../../controllers/customer_controller.dart';
import '../../controllers/provider_controller.dart';
import '../../models/request_and_provider_models.dart';
import 'presentation_widgets.dart';

class RequestJourneyCard extends StatelessWidget {
  final ServiceRequestModel request;
  final bool isProvider;
  final bool isPaid;
  const RequestJourneyCard(
      {super.key,
      required this.request,
      this.isProvider = false,
      this.isPaid = false});

  @override
  Widget build(BuildContext context) {
    final req = request;
    if (!req.usesAgreement) {
      return RequestNextStepCard(status: req.status, isProvider: isProvider);
    }
    final stage = switch (req.status) {
      'pending' || 'new' => 0,
      'accepted' => req.quoteApproved ? 2 : 1,
      'in_progress' => 2,
      'awaiting_confirmation' => 3,
      'completed' => isPaid ? 5 : 4,
      _ => -1,
    };
    final message = switch (req.status) {
      'pending' || 'new' => isProvider
          ? 'راجع الطلب واحجزه إذا كنت متاحًا. حجزه يخصصه لك لإعداد العرض.'
          : 'نبحث عن مقدم خدمة مناسب للطلب. الميزانية المقترحة ليست سعرًا معتمدًا.',
      'accepted' => req.quoteApproved
          ? (isProvider
              ? 'اعتمد العميل العرض. يمكنك بدء التنفيذ بالسعر ونطاق العمل المتفق عليهما.'
              : 'عرضك معتمد. الخطوة التالية هي بدء مقدم الخدمة للتنفيذ.')
          : req.quoteStatus == 'pending'
              ? (isProvider
                  ? 'أرسلت العرض. انتظر موافقة العميل قبل بدء العمل.'
                  : 'لديك عرض جديد. راجع ما يشمله السعر ثم وافق أو اطلب عرضًا جديدًا.')
              : (isProvider
                  ? 'أرسل عرضًا يوضح السعر الإجمالي وما يشمله العمل قبل بدء التنفيذ.'
                  : 'حجز مقدم الخدمة طلبك. بانتظار عرضه لتراجعه قبل بدء العمل.'),
      'in_progress' => isProvider
          ? 'نفّذ نطاق العمل المعتمد. بعد الإنجاز أرسل ملخصًا ليؤكد العميل الاستلام.'
          : 'خدمتك قيد التنفيذ. السعر المعتمد ثابت، وستراجع النتيجة قبل إصدار الفاتورة.',
      'awaiting_confirmation' => isProvider
          ? 'بانتظار مراجعة العميل وتأكيد الاستلام. لا توجد فاتورة مستحقة بعد.'
          : 'راجع نتيجة العمل. أكد الاستلام لإصدار الفاتورة، أو أرسل ملاحظات للمعالجة.',
      'completed' => isPaid
          ? 'اكتملت الخدمة والسداد. يمكنك الآن مشاركة تقييمك للتجربة.'
          : 'تم الاستلام وصدرت الفاتورة بالسعر المعتمد. تابع السداد داخل المنصة.',
      'cancelled' =>
        'أُلغي هذا الطلب قبل بدء التنفيذ. يمكنك إنشاء طلب جديد عند الحاجة.',
      _ => 'تابع تحديثات الخدمة من هذه الصفحة.',
    };
    return _Surface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('رحلة خدمتك',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      const SizedBox(height: 14),
      if (stage >= 0)
        Row(children: [
          for (var index = 0; index < 5; index++)
            Expanded(
                child: Column(children: [
              CircleAvatar(
                  radius: 13,
                  backgroundColor:
                      stage >= index ? AppTheme.primary : AppTheme.border,
                  child: stage > index
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text('${index + 1}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11))),
              const SizedBox(height: 6),
              Text(
                  const [
                    'الطلب',
                    'الاتفاق',
                    'التنفيذ',
                    'الاستلام',
                    'السداد'
                  ][index],
                  style: const TextStyle(fontSize: 11)),
            ])),
        ]),
      const SizedBox(height: 14),
      Text(message, style: const TextStyle(height: 1.6)),
    ]));
  }
}

class ServiceWorkflowPanel extends StatelessWidget {
  final ServiceRequestModel request;
  final bool isProvider;
  const ServiceWorkflowPanel(
      {super.key, required this.request, this.isProvider = false});

  Future<void> _sendQuote(BuildContext context) async {
    final draft = await showDialog<_QuoteDraft>(
        context: context, builder: (_) => _QuoteDialog(request: request));
    if (draft == null || !context.mounted) return;
    await context.read<ProviderController>().submitQuote(
        request.id, draft.price, draft.details,
        visitAt: draft.visitAt);
  }

  Future<void> _decide(BuildContext context, bool approve) async {
    if (approve) {
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text('اعتماد عرض الخدمة'),
                content: Text(
                    'توافق على نطاق العمل الموضح بإجمالي ${CurrencyHelper.format(request.quotedPrice)} ريال. يصدر مبلغ الفاتورة نفسه بعد تأكيد استلام الخدمة.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('مراجعة العرض')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('أوافق على العرض'))
                ],
              ));
      if (confirmed != true || !context.mounted) return;
    }
    await context
        .read<CustomerController>()
        .decideQuote(request.id, request.quoteId!, approve: approve);
  }

  Future<void> _finish(BuildContext context) async {
    final notes = await showDialog<String>(
        context: context,
        builder: (_) => const _NotesDialog(
              title: 'تسليم العمل للعميل',
              label: 'ما العمل الذي أنجزته؟',
              hint: 'اذكر ما تم إصلاحه أو تركيبه وأي إرشادات للاستخدام.',
              action: 'إرسال لتأكيد الاستلام',
            ));
    if (notes == null || !context.mounted) return;
    await context
        .read<ProviderController>()
        .requestCompletion(request.id, notes);
  }

  Future<void> _rework(BuildContext context) async {
    final notes = await showDialog<String>(
        context: context,
        builder: (_) => const _NotesDialog(
              title: 'ملاحظات قبل الاستلام',
              label: 'ما الذي يحتاج إلى معالجة؟',
              hint: 'صف المشكلة المتبقية ضمن العمل المتفق عليه.',
              action: 'إرسال الملاحظات',
            ));
    if (notes == null || !context.mounted) return;
    await context.read<CustomerController>().requestRework(request.id, notes);
  }

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('تأكيد استلام الخدمة'),
              content: Text(
                  'هل راجعت العمل واستلمته؟ ستصدر فاتورة بقيمة ${CurrencyHelper.format(request.quotedPrice)} ريال بالسعر المعتمد.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('رجوع')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('نعم، استلمت الخدمة'))
              ],
            ));
    if (confirmed != true || !context.mounted) return;
    await context.read<CustomerController>().confirmCompletion(request.id);
  }

  @override
  Widget build(BuildContext context) {
    final req = request;
    if (!req.usesAgreement) return const SizedBox.shrink();
    final busy = isProvider
        ? context.watch<ProviderController>().isActionLoading
        : context.watch<CustomerController>().isWorkflowAction;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (req.quoteId != null)
        _Surface(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Row(children: [
                const Icon(Icons.handshake_outlined, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        req.quoteApproved
                            ? 'اتفاق الخدمة المعتمد'
                            : 'عرض الخدمة',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)))
              ]),
              const SizedBox(height: 12),
              Text('${CurrencyHelper.format(req.quotedPrice)} ريال',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary)),
              const Text('إجمالي السعر حسب البنود الموضحة',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const Divider(height: 24),
              Text(req.quoteDetails ?? '', style: const TextStyle(height: 1.6)),
              if (req.visitAt != null)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('موعد الزيارة: ${req.visitAt}')),
              const SizedBox(height: 10),
              Text(
                  switch (req.quoteStatus) {
                    'approved' => 'اعتمده العميل • السعر ثابت',
                    'declined' => 'طُلب عرض جديد',
                    _ => 'بانتظار موافقة العميل'
                  },
                  style: TextStyle(
                      color: req.quoteApproved
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.bold)),
              if (!isProvider &&
                  req.isAccepted &&
                  req.quoteStatus == 'pending') ...[
                const SizedBox(height: 16),
                CustomButton(
                    text: 'الموافقة على العرض',
                    icon: Icons.check_circle_outline,
                    isLoading: busy,
                    onPressed: () => _decide(context, true)),
                TextButton(
                    onPressed: busy ? null : () => _decide(context, false),
                    child: const Text('أحتاج عرضًا جديدًا')),
              ],
            ])),
      if (isProvider && req.isAccepted && !req.quoteApproved)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CustomButton(
              text: req.quoteId == null
                  ? 'إعداد عرض الخدمة'
                  : 'تعديل وإرسال عرض جديد',
              icon: Icons.request_quote_outlined,
              isLoading: busy,
              onPressed: () => _sendQuote(context)),
        ),
      if (req.isInProgress && (req.reworkNotes?.isNotEmpty ?? false))
        _Surface(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ملاحظات العميل للمعالجة',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.deepOrange)),
          const SizedBox(height: 8),
          Text(req.reworkNotes!, style: const TextStyle(height: 1.6)),
        ])),
      if (isProvider && req.isInProgress)
        Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CustomButton(
              text: 'أنجزت العمل • طلب الاستلام',
              icon: Icons.task_alt,
              isLoading: busy,
              onPressed: () => _finish(context),
            )),
      if (req.isAwaitingConfirmation)
        _Surface(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              const Text('ملخص العمل المنجز',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Text(req.completionNotes ?? '',
                  style: const TextStyle(height: 1.6)),
              if (!isProvider) ...[
                const SizedBox(height: 16),
                CustomButton(
                    text: 'تأكيد الاستلام وإصدار الفاتورة',
                    isLoading: busy,
                    icon: Icons.verified_outlined,
                    onPressed: () => _confirm(context)),
                TextButton(
                    onPressed: busy ? null : () => _rework(context),
                    child: const Text('توجد ملاحظات قبل الاستلام')),
              ],
            ])),
    ]);
  }
}

class RequestActivityTimeline extends StatelessWidget {
  final List<dynamic> history;
  final ServiceRequestModel request;
  const RequestActivityTimeline(
      {super.key, required this.history, required this.request});

  @override
  Widget build(BuildContext context) {
    const labels = {
      'pending': 'تم إرسال الطلب',
      'accepted': 'حجز مقدم الخدمة الطلب',
      'in_progress': 'بدأ التنفيذ / معالجة الملاحظات',
      'awaiting_confirmation': 'أُرسل العمل لتأكيد الاستلام',
      'completed': 'تم الاستلام وإصدار الفاتورة',
      'cancelled': 'أُلغي الطلب',
      'rejected': 'اعتذر مقدم الخدمة'
    };
    final events = history
        .whereType<Map>()
        .map((row) => <String, String>{
              'title': labels[row['new_status']] ?? 'تحديث الطلب',
              'time': row['changed_at']?.toString() ?? '',
            })
        .toList();
    if (request.quoteCreatedAt != null) {
      events.add({
        'title': 'أُرسل عرض الخدمة الحالي',
        'time': request.quoteCreatedAt!
      });
    }
    if (request.quoteDecidedAt != null) {
      events.add({
        'title': request.quoteApproved
            ? 'اعتمد العميل العرض'
            : 'طلب العميل عرضًا جديدًا',
        'time': request.quoteDecidedAt!
      });
    }
    events.sort((a, b) => b['time']!.compareTo(a['time']!));
    if (events.isEmpty) return const SizedBox.shrink();
    return _Surface(
        child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('سجل رحلة الخدمة',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${events.length} تحديثات مسجلة'),
            children: events
                .map((event) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          const Icon(Icons.history, color: AppTheme.primary),
                      title: Text(event['title']!),
                      subtitle: Text(event['time']!),
                    ))
                .toList()));
  }
}

class _Surface extends StatelessWidget {
  final Widget child;
  const _Surface({required this.child});
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border)),
      child: child);
}

class _QuoteDraft {
  final double price;
  final String details;
  final String? visitAt;
  const _QuoteDraft(this.price, this.details, this.visitAt);
}

class _QuoteDialog extends StatefulWidget {
  final ServiceRequestModel request;
  const _QuoteDialog({required this.request});
  @override
  State<_QuoteDialog> createState() => _QuoteDialogState();
}

class _QuoteDialogState extends State<_QuoteDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _price;
  late final TextEditingController _details;
  DateTime? _visit;
  @override
  void initState() {
    super.initState();
    _price = TextEditingController(
        text: widget.request.quotedPrice?.toString() ?? '');
    _details = TextEditingController(text: widget.request.quoteDetails ?? '');
  }

  @override
  void dispose() {
    _price.dispose();
    _details.dispose();
    super.dispose();
  }

  double? get _amount => double.tryParse(
      CurrencyHelper.toLatinDigits(_price.text.trim()).replaceAll('٫', '.'));

  Future<void> _pickVisit() async {
    final now = DateTime.now();
    final date = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: now.add(const Duration(days: 90)));
    if (date == null || !mounted) return;
    final time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;
    setState(() => _visit =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('عرض واضح قبل التنفيذ'),
        content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
                child: Form(
                    key: _form,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text(
                          'اكتب إجمالي السعر وما يشمله من عمل ومواد، وأي بنود مستثناة. بعد موافقة العميل يصبح العرض ثابتًا.'),
                      const SizedBox(height: 16),
                      TextFormField(
                          controller: _price,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              labelText: 'إجمالي السعر (ريال)'),
                          validator: (_) => _amount == null ||
                                  !_amount!.isFinite ||
                                  _amount! <= 0 ||
                                  _amount! > 99999999.99
                              ? 'أدخل مبلغًا صحيحًا أكبر من صفر'
                              : null),
                      const SizedBox(height: 14),
                      TextFormField(
                          controller: _details,
                          maxLines: 4,
                          maxLength: 3000,
                          decoration: const InputDecoration(
                              labelText: 'العمل والمواد المشمولة والاستثناءات'),
                          validator: (value) => (value?.trim().length ?? 0) < 10
                              ? 'وضح بنود العرض في 10 أحرف على الأقل'
                              : null),
                      const SizedBox(height: 8),
                      TextButton.icon(
                          onPressed: _pickVisit,
                          icon: const Icon(Icons.event_available_outlined),
                          label: Text(_visit == null
                              ? 'اقتراح موعد زيارة (اختياري)'
                              : _visit.toString().substring(0, 16))),
                      if (_visit != null)
                        TextButton(
                            onPressed: () => setState(() => _visit = null),
                            child: const Text('بدون موعد محدد')),
                    ])))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('رجوع')),
          FilledButton(
              onPressed: () {
                if (!_form.currentState!.validate()) return;
                if (_visit != null && !_visit!.isAfter(DateTime.now())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('اختر موعد زيارة قادمًا')));
                  return;
                }
                final visit = _visit
                    ?.toIso8601String()
                    .replaceFirst('T', ' ')
                    .substring(0, 19);
                Navigator.pop(context,
                    _QuoteDraft(_amount!, _details.text.trim(), visit));
              },
              child: const Text('إرسال للعميل'))
        ],
      );
}

class _NotesDialog extends StatefulWidget {
  final String title, label, hint, action;
  const _NotesDialog(
      {required this.title,
      required this.label,
      required this.hint,
      required this.action});
  @override
  State<_NotesDialog> createState() => _NotesDialogState();
}

class _NotesDialogState extends State<_NotesDialog> {
  final _form = GlobalKey<FormState>();
  final _notes = TextEditingController();
  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: SingleChildScrollView(
            child: Form(
                key: _form,
                child: TextFormField(
                    controller: _notes,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 3000,
                    decoration: InputDecoration(
                        labelText: widget.label, hintText: widget.hint),
                    validator: (value) => (value?.trim().length ?? 0) < 5
                        ? 'اكتب تفاصيل من 5 أحرف على الأقل'
                        : null))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('رجوع')),
          FilledButton(
              onPressed: () {
                if (_form.currentState!.validate()) {
                  Navigator.pop(context, _notes.text.trim());
                }
              },
              child: Text(widget.action))
        ],
      );
}
