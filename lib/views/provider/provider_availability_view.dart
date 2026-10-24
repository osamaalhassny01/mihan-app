import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/provider_controller.dart';
import '../widgets/presentation_widgets.dart';

class ProviderAvailabilityView extends StatefulWidget {
  const ProviderAvailabilityView({super.key});

  @override
  State<ProviderAvailabilityView> createState() => _ProviderAvailabilityViewState();
}

class _ProviderAvailabilityViewState extends State<ProviderAvailabilityView> {
  final Set<int> _selectedLocationIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctrl = context.read<ProviderController>();
      await ctrl.loadProfileAndCoverage();
      setState(() {
        _selectedLocationIds.clear();
        for (final loc in ctrl.myLocations) {
          _selectedLocationIds.add(loc.id);
        }
      });
    });
  }

  void _onSaveLocations(BuildContext context, ProviderController ctrl) async {
    final success = await ctrl.updateLocations(_selectedLocationIds.toList());
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ مناطق التغطية بنجاح!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('التوافر ومناطق التغطية'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Availability Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'حالة التوافر الحالية',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'عند تفعيل التوافر، ستظهر للعملاء في البحث وتستقبل طلبات الصيانة المباشرة.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            provider.isAvailable ? 'متاح لاستقبال الطلبات' : 'غير متاح للعمل الآن',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: provider.isAvailable ? AppTheme.success : AppTheme.error,
                            ),
                          ),
                          subtitle: Text(provider.isAvailable ? 'حسابك نشط ويتلقى الطلبات' : 'متوقف مؤقتًا'),
                          value: provider.isAvailable,
                          activeColor: AppTheme.success,
                          onChanged: provider.isActionLoading
                              ? null
                              : (_) => provider.toggleAvailability(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Coverage Areas Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'مناطق تغطية الخدمة',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                      ),
                      Text(
                        '${_selectedLocationIds.length} مناطق محددة',
                        style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'حدد المدن والمناطق التي يمكنك الانتقال إليها وتقديم خدماتك فيها:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 14),

                  if (provider.allLocations.isEmpty)
                    const EmptyStateWidget(
                      title: 'لا توجد مناطق متاحة',
                      message: 'جاري تحميل قائمة المناطق...',
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.allLocations.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final loc = provider.allLocations[index];
                          final isChecked = _selectedLocationIds.contains(loc.id);
                          return CheckboxListTile(
                            title: Text(loc.nameAr, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: loc.city != null ? Text(loc.city!) : null,
                            value: isChecked,
                            activeColor: AppTheme.secondary,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedLocationIds.add(loc.id);
                                } else {
                                  _selectedLocationIds.remove(loc.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'حفظ مناطق التغطية',
                    icon: Icons.save_outlined,
                    isLoading: provider.isActionLoading,
                    onPressed: () => _onSaveLocations(context, provider),
                  ),
                ],
              ),
            ),
    );
  }
}
