import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
import '../../models/catalog_models.dart';
import '../../services/api_service.dart';
import '../widgets/presentation_widgets.dart';

class ProviderApplicationView extends StatefulWidget {
  const ProviderApplicationView({super.key});

  @override
  State<ProviderApplicationView> createState() => _ProviderApplicationViewState();
}

class _ProviderApplicationViewState extends State<ProviderApplicationView> {
  final _formKey = GlobalKey<FormState>();
  
  int? _selectedServiceId;
  int? _selectedLocationId;
  final _yearsExpController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _bioController = TextEditingController();

  List<ServiceModel> _services = [];
  List<LocationModel> _locations = [];

  File? _pickedImage;
  String? _pickedImageBase64;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isCheckingStatus = true;
  Map<String, dynamic>? _existingApp;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _loadCatalogAndStatus();
  }

  @override
  void dispose() {
    _yearsExpController.dispose();
    _nationalIdController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogAndStatus() async {
    setState(() => _isCheckingStatus = true);

    // 1. Load services & locations catalog
    final srvRes = await ApiService.get('/api/services');
    if (srvRes.success && srvRes.data is List) {
      _services = (srvRes.data as List).map((s) => ServiceModel.fromJson(s)).toList();
    }

    final locRes = await ApiService.get('/api/locations');
    if (locRes.success && locRes.data is List) {
      _locations = (locRes.data as List).map((l) => LocationModel.fromJson(l)).toList();
    }

    // 2. Load existing application status
    final res = await ApiService.get('/api/provider/application-status');
    if (res.success && res.data != null) {
      final app = res.data['application'] as Map<String, dynamic>?;
      final active = res.data['is_active'] == true;
      setState(() {
        _existingApp = app;
        _isActive = active;
        if (app != null) {
          _yearsExpController.text = (app['years_exp'] ?? '').toString();
          _nationalIdController.text = app['national_id'] ?? '';
          _bioController.text = app['bio'] ?? '';

          // Match service if found
          final profName = app['profession'] as String?;
          if (profName != null) {
            for (final s in _services) {
              if (s.nameAr == profName || profName.contains(s.nameAr)) {
                _selectedServiceId = s.id;
                break;
              }
            }
          }

          // Match location if found
          final cityName = app['city'] as String?;
          if (cityName != null) {
            for (final l in _locations) {
              if (l.nameAr == cityName || cityName.contains(l.nameAr)) {
                _selectedLocationId = l.id;
                break;
              }
            }
          }
        }
      });
    }

    setState(() => _isCheckingStatus = false);
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _pickedImage = File(image.path);
          _pickedImageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر اختيار الصورة: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار التخصص/المهنة من القائمة المتاحة'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    if (_selectedLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار منطقة التغطية من القائمة المتاحة'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    setState(() => _isLoading = true);
    final payload = <String, dynamic>{
      'service_id': _selectedServiceId,
      'location_id': _selectedLocationId,
      'years_exp': int.tryParse(_yearsExpController.text.trim()) ?? 0,
      'national_id': _nationalIdController.text.trim(),
      'bio': _bioController.text.trim(),
    };

    if (_pickedImageBase64 != null) {
      payload['certificate_base64'] = _pickedImageBase64;
    }

    final res = await ApiService.post('/api/provider/apply', payload);
    setState(() => _isLoading = false);

    if (res.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع طلبك ووثائقك بنجاح! سيتم مراجعته وتدقيقه إدارياً.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
      await _loadCatalogAndStatus();
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
        title: const Text('طلب توثيق واعتماد مهني'),
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
                            'حسابك معتمد ونشط رسمياً',
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
                    'بيانات التوثيق والمهنة الرسمية',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'اختر مهنتك ومنطقة عملك من الخدمات والمناطق المتاحة بالمنصة',
                    style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Service dropdown
                  const Row(
                    children: [
                      Icon(Icons.handyman_outlined, size: 18, color: AppTheme.primary),
                      SizedBox(width: 6),
                      Text('المهنة / التخصص المعتمد *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
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
                        hint: const Text('اختر المهنة/الخدمة من المنصة', style: TextStyle(fontSize: 13)),
                        value: _selectedServiceId,
                        items: _services.map((s) {
                          return DropdownMenuItem<int>(
                            value: s.id,
                            child: Text(s.nameAr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedServiceId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location dropdown
                  const Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 18, color: AppTheme.secondary),
                      SizedBox(width: 6),
                      Text('منطقة التغطية والعمل *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
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
                        hint: const Text('اختر المدينة أو المنطقة المتاحة', style: TextStyle(fontSize: 13)),
                        value: _selectedLocationId,
                        items: _locations.map((loc) {
                          return DropdownMenuItem<int>(
                            value: loc.id,
                            child: Text(loc.nameAr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedLocationId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

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
                          label: 'رقم الهوية / الإقامة *',
                          hint: 'للتدقيق الإداري',
                          controller: _nationalIdController,
                          prefixIcon: Icons.badge_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Image from Gallery Picker Box
                  const Row(
                    children: [
                      Icon(Icons.photo_library_outlined, size: 18, color: AppTheme.primary),
                      SizedBox(width: 6),
                      Text('إثبات المهنة / الشهادة من المعرض *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _pickImageFromGallery,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _pickedImage != null ? AppTheme.success : AppTheme.border,
                          width: _pickedImage != null ? 1.5 : 1,
                        ),
                      ),
                      child: _pickedImage != null
                          ? Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(_pickedImage!, width: 60, height: 60, fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('تم اختيار الصورة بنجاح ✅', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success, fontSize: 13)),
                                      SizedBox(height: 2),
                                      Text('اضغط لتغيير الصورة', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.check_circle, color: AppTheme.success),
                              ],
                            )
                          : (_existingApp?['certificate_url'] != null && _existingApp!['certificate_url'].toString().isNotEmpty)
                              ? Row(
                                  children: [
                                    const Icon(Icons.verified, color: AppTheme.primary, size: 36),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('يوجد وثيقة مرفوعة مسبقاً', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          Text('اضغط لاستبدالها بصورة جديدة من المعرض', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.photo_library_outlined, color: AppTheme.secondary),
                                  ],
                                )
                              : const Column(
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined, size: 42, color: AppTheme.secondary),
                                    SizedBox(height: 8),
                                    Text('اضغط لاختيار صورة الشهادة أو الرخصة من المعرض', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                                    SizedBox(height: 2),
                                    Text('يدعم صيغ JPG و PNG', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                  ],
                                ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'نبذة عن الخبرات والمهارات',
                    hint: 'اكتب نبذة مختصرة عن طبيعة عملك والشركات أو المشاريع التي عملت بها...',
                    controller: _bioController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: status == 'pending' ? 'تحديث بيانات ووثائق الطلب' : 'إرسال طلب الاعتماد والوثائق للإدارة',
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
