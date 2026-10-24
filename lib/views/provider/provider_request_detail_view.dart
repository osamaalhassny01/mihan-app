import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/provider_controller.dart';
import '../widgets/presentation_widgets.dart';

class ProviderRequestDetailView extends StatefulWidget {
  final int requestId;

  const ProviderRequestDetailView({super.key, required this.requestId});

  @override
  State<ProviderRequestDetailView> createState() => _ProviderRequestDetailViewState();
}

class _ProviderRequestDetailViewState extends State<ProviderRequestDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderController>().loadRequestDetails(widget.requestId);
    });
  }

  void _showCompleteDialog(BuildContext context, ProviderController ctrl) {
    final priceController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إكمال الخدمة وإصدار الفاتورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('يرجى تأكيد السعر النهائي المتفق عليه للخدمة لإصدار الفاتورة للعميل:'),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ الإجمالي (ريال)',
                hintText: 'مثال: 5000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceController.text.trim()) ?? 0.0;
              if (price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')),
                );
                return;
              }
              Navigator.of(ctx).pop();
              await ctrl.completeRequest(widget.requestId, price);
            },
            child: const Text('إكمال وإصدار الفاتورة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderController>();
    final req = provider.selectedRequest;

    return Scaffold(
      appBar: AppBar(
        title: Text(req?.requestNumber ?? 'تفاصيل الطلب'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : req == null
              ? EmptyStateWidget(
                  title: 'تعذر تحميل الطلب',
                  message: provider.errorMessage ?? 'الطلب غير موجود أو غير مخصص لك',
                  onRetry: () => provider.loadRequestDetails(widget.requestId),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (provider.successMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            provider.successMessage!,
                            style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Header Status Card
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  req.requestNumber,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
                                ),
                                StatusBadge(status: req.status, label: req.statusArabic),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildInfoRow('الخدمة المطلوبة:', req.serviceNameAr ?? 'خدمة عامة'),
                            const SizedBox(height: 8),
                            _buildInfoRow('اسم العميل:', req.customerName ?? 'عميل مِهَن'),
                            const SizedBox(height: 8),
                            _buildInfoRow('المنطقة / الموقع:', req.locationName ?? 'غير محدد'),
                            const SizedBox(height: 8),
                            _buildInfoRow('تاريخ الطلب:', req.createdAt),
                            if (req.budget != null) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow('الميزانية المقترحة من العميل:', '${req.budget} ريال'),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Problem Description
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
                            const Text('وصف العمل المطلوب من العميل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(req.description, style: const TextStyle(color: AppTheme.textPrimary, height: 1.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Status Actions
                      if (req.isPending) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                                icon: const Icon(Icons.check, color: Colors.white),
                                label: const Text('قبول الطلب'),
                                onPressed: () => provider.acceptRequest(req.id),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
                                icon: const Icon(Icons.close, color: AppTheme.error),
                                label: const Text('رفض الطلب'),
                                onPressed: () => provider.rejectRequest(req.id),
                              ),
                            ),
                          ],
                        ),
                      ] else if (req.isAccepted) ...[
                        CustomButton(
                          text: 'بدء التنفيذ والتوجه للموقع',
                          icon: Icons.play_arrow,
                          isLoading: provider.isActionLoading,
                          onPressed: () => provider.startRequest(req.id),
                        ),
                      ] else if (req.isInProgress) ...[
                        CustomButton(
                          text: 'إكمال العمل وإصدار الفاتورة للعميل',
                          icon: Icons.check_circle_outline,
                          backgroundColor: AppTheme.success,
                          isLoading: provider.isActionLoading,
                          onPressed: () => _showCompleteDialog(context, provider),
                        ),
                      ] else if (req.isCompleted) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                          ),
                          child: const Center(
                            child: Text(
                              'تم اكتمال هذا الطلب بنجاح وإصدار الفاتورة',
                              style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 13)),
      ],
    );
  }
}
