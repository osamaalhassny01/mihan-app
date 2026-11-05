import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../widgets/presentation_widgets.dart';

class ProviderApplicationView extends StatefulWidget {
  const ProviderApplicationView({super.key});

  @override
  State<ProviderApplicationView> createState() => _ProviderApplicationViewState();
}

class _ProviderApplicationViewState extends State<ProviderApplicationView> {
  final _formKey = GlobalKey<FormState>();
  final _professionController = TextEditingController();
  final _yearsExpController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final _certificateUrlController = TextEditingController();

  bool _isLoading = false;
  bool _isCheckingStatus = true;
  Map<String, dynamic>? _existingApp;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  void dispose() {
    _professionController.dispose();
    _yearsExpController.dispose();
    _nationalIdController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _certificateUrlController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    setState(() => _isCheckingStatus = true);
    final res = await ApiService.get('/api/provider/application-status');
    if (res.success && res.data != null) {
      final app = res.data['application'] as Map<String, dynamic>?;
      final active = res.data['is_active'] == true;
      setState(() {
        _existingApp = app;
        _isActive = active;
        if (app != null) {
          _professionController.text = app['profession'] ?? '';
          _yearsExpController.text = (app['years_exp'] ?? '').toString();
          _nationalIdController.text = app['national_id'] ?? '';
          _cityController.text = app['city'] ?? '';
          _bioController.text = app['bio'] ?? '';
          _certificateUrlController.text = app['certificate_url'] ?? '';
        }
      });
    }
    setState(() => _isCheckingStatus = false);
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final res = await ApiService.post('/api/provider/apply', {
      'profession': _professionController.text.trim(),
      'years_exp': int.tryParse(_yearsExpController.text.trim()) ?? 0,
      'national_id': _nationalIdController.text.trim(),
      'city': _cityController.text.trim(),
      'bio': _bioController.text.trim(),
      'certificate_url': _certificateUrlController.text.trim(),
    });

    setState(() => _isLoading = false);

    if (res.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع طلبك بنجاح! سيتم مراجعته وتدقيقه من إدارة المنصة.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
      await _checkStatus();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingStatus) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final status = _existingApp?['status'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب اعتماد مقدم خدمة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status banner if applied
            if (status == 'pending') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded, color: Colors.amber.shade800, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'طلبك قيد التدقيق الإداري',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'يقوم فريق إدارة المنصة حالياً بمراجعة بياناتك وإثباتاتك المهنية للموافقة وتفعيل حسابك.',
                            style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else if (status == 'approved' && _isActive) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_rounded, color: Colors.green.shade700, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'حسابك معتمد ونشط رسميًا',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'تم تدقيق وقبول شهاداتك من إدارة مِهَن، ويمكنك استقبال ومباشرة كافة الطلبات.',
                            style: TextStyle(color: Colors.green.shade900, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Application Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'بيانات التوثيق والمهنة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'يرجى تعبئة بياناتك بدقة لإثبات مؤهلك وخبراتك للمدير المسؤول',
                    style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'المهنة أو التخصص الفني *',
                    hint: 'مثال: كهربائي منازل، فني تكييف، نجار...',
                    controller: _professionController,
                    prefixIcon: Icons.handyman_outlined,
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'سنوات الخبرة *',
                          hint: 'مثال: 5',
                          controller: _yearsExpController,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.timer_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'المدينة / المنطقة *',
                          hint: 'مثال: صنعاء، عدن...',
                          controller: _cityController,
                          prefixIcon: Icons.location_city_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    label: 'رقم الهوية الوطنية أو الإقامة',
                    hint: 'رقم الهوية الرسمية للتحقق',
                    controller: _nationalIdController,
                    prefixIcon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    label: 'رابط الشهادة أو وثيقة إثبات المهنة (إن وجد)',
                    hint: 'رابط صورة الشهادة أو الرخصة المهنية',
                    controller: _certificateUrlController,
                    prefixIcon: Icons.link_rounded,
                  ),
                  const SizedBox(height: 14),

                  CustomTextField(
                    label: 'نبذة عن الخبرة السابقة والإنجازات',
                    hint: 'اكتب نبذة مختصرة عن طبيعة عملك والشركات أو المشاريع التي عملت بها...',
                    controller: _bioController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: status == 'pending' ? 'تحديث بيانات طلب الانضمام' : 'إرسال طلب الاعتماد للإدارة',
                    icon: Icons.send_rounded,
                    isLoading: _isLoading,
                    onPressed: _submitApplication,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
