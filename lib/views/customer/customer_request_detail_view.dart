import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/customer_controller.dart';
import '../widgets/presentation_widgets.dart';

class CustomerRequestDetailView extends StatefulWidget {
  final int requestId;

  const CustomerRequestDetailView({super.key, required this.requestId});

  @override
  State<CustomerRequestDetailView> createState() => _CustomerRequestDetailViewState();
}

class _CustomerRequestDetailViewState extends State<CustomerRequestDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerController>().loadRequestDetails(widget.requestId);
    });
  }

  void _showReviewDialog(BuildContext context, CustomerController ctrl) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('تقييم الخدمة ومقدم الخدمة'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ما مدى رضاك عن مستوى تنفيذ الخدمة؟'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return IconButton(
                        icon: Icon(
                          starIndex <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() => rating = starIndex);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'اكتب رأيك أو ملاحظاتك هنا...',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogCtx).pop();
                    await ctrl.submitReview(
                      requestId: widget.requestId,
                      rating: rating,
                      comment: commentController.text.trim(),
                    );
                  },
                  child: const Text('إرسال التقييم'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<CustomerController>();
    final req = customer.selectedRequest;
    final inv = customer.selectedInvoice;

    return Scaffold(
      appBar: AppBar(
        title: Text(req?.requestNumber ?? 'تفاصيل الطلب'),
      ),
      body: customer.isLoading
          ? const Center(child: CircularProgressIndicator())
          : req == null
              ? EmptyStateWidget(
                  title: 'تعذر تحميل الطلب',
                  message: customer.errorMessage ?? 'الطلب غير موجود',
                  onRetry: () => customer.loadRequestDetails(widget.requestId),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (customer.successMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            customer.successMessage!,
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
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                StatusBadge(status: req.status, label: req.statusArabic),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildInfoRow('الخدمة:', req.serviceNameAr ?? 'خدمة عامة'),
                            const SizedBox(height: 8),
                            _buildInfoRow('المنطقة:', req.locationName ?? 'غير محدد'),
                            const SizedBox(height: 8),
                            _buildInfoRow('تاريخ الإنشاء:', req.createdAt),
                            if (req.budget != null) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow('الميزانية المقترحة:', '${req.budget} ريال'),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
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
                              'تفاصيل المشكلة / العطل',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              req.description,
                              style: const TextStyle(color: AppTheme.textPrimary, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Assigned Provider
                      if (req.providerName != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.secondary,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('مقدم الخدمة المعتمد:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                    Text(
                                      req.providerName!,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Invoice Card (if generated)
                      if (inv != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: inv.isPaid ? AppTheme.success : AppTheme.warning),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'فاتورة الخدمة: ${inv.invoiceNumber}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  StatusBadge(
                                    status: inv.isPaid ? 'completed' : 'pending',
                                    label: inv.isPaid ? 'مدفوعة' : 'غير مدفوعة',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow('إجمالي الفاتورة:', '${inv.totalAmount} ريال'),
                              const SizedBox(height: 6),
                              _buildInfoRow('المبلغ المتبقي:', '${inv.balance} ريال'),
                              if (!inv.isPaid && inv.balance > 0) ...[
                                const SizedBox(height: 16),
                                CustomButton(
                                  text: 'سداد الفاتورة الآن (${inv.balance} ريال)',
                                  icon: Icons.payment,
                                  isLoading: customer.isPaying,
                                  onPressed: () => customer.payInvoice(inv.id),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Review Section
                      if (req.isCompleted && inv != null && inv.isPaid) ...[
                        if (customer.selectedReview != null) ...[
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
                                const Text('تقييمك للخدمة:', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Row(
                                  children: List.generate(5, (i) {
                                    final rating = customer.selectedReview?['rating'] ?? 5;
                                    return Icon(
                                      i < (rating as num).toInt() ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 20,
                                    );
                                  }),
                                ),
                                if (customer.selectedReview?['comment'] != null) ...[
                                  const SizedBox(height: 6),
                                  Text(customer.selectedReview!['comment'].toString()),
                                ],
                              ],
                            ),
                          ),
                        ] else ...[
                          CustomButton(
                            text: 'تقييم الخدمة ومقدم الخدمة',
                            icon: Icons.star_outline,
                            backgroundColor: Colors.amber[800],
                            onPressed: () => _showReviewDialog(context, customer),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],

                      // Cancel Request Button (if pending)
                      if (req.isPending) ...[
                        CustomButton(
                          text: 'إلغاء الطلب',
                          icon: Icons.cancel_outlined,
                          backgroundColor: AppTheme.error,
                          isLoading: customer.isLoading,
                          onPressed: () => customer.cancelRequest(req.id),
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
