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
                            color: AppTheme.success.withValues(alpha: 0.1),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primary, size: 22),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      req.requestNumber,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                StatusBadge(status: req.status, label: req.statusArabic),
                              ],
                            ),
                            const Divider(height: 28),
                            _buildInfoRow(Icons.build_rounded, 'الخدمة الفنية:', req.serviceNameAr ?? 'خدمة عامة', AppTheme.secondary),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.location_on_outlined, 'المنطقة والموقع:', req.locationName ?? 'غير محدد', Colors.redAccent),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.calendar_today_rounded, 'تاريخ وتوقيت الطلب:', req.createdAt, AppTheme.primary),
                            if (req.budget != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.payments_outlined, 'الميزانية المقترحة:', '${req.budget} ريال', Colors.teal),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Description
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.description_outlined, size: 18, color: AppTheme.secondary),
                                SizedBox(width: 8),
                                Text(
                                  'تفاصيل المشكلة / العطل',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              req.description,
                              style: const TextStyle(color: AppTheme.textPrimary, height: 1.6, fontSize: 13.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Assigned Provider Card
                      if (req.providerName != null) ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.secondary.withValues(alpha: 0.05),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.handyman_rounded, color: AppTheme.secondary, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('مقدم الخدمة الفني المعتمد', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                    const SizedBox(height: 2),
                                    Text(
                                      req.providerName!,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'فني معتمد',
                                  style: TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Invoice Card (if generated)
                      if (inv != null) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: inv.isPaid ? AppTheme.success.withValues(alpha: 0.5) : AppTheme.warning,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (inv.isPaid ? AppTheme.success : AppTheme.warning).withValues(alpha: 0.06),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.receipt_rounded,
                                        color: inv.isPaid ? AppTheme.success : AppTheme.warning,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'فاتورة رقم ${inv.invoiceNumber}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  StatusBadge(
                                    status: inv.isPaid ? 'completed' : 'pending',
                                    label: inv.isPaid ? 'مدفوعة بالكامل' : 'مستحقة السداد',
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(Icons.calculate_outlined, 'إجمالي قيمة الخدمة:', '${inv.totalAmount} ريال', AppTheme.textPrimary),
                              const SizedBox(height: 10),
                              _buildInfoRow(Icons.account_balance_wallet_outlined, 'المبلغ المتبقي:', '${inv.balance} ريال', inv.isPaid ? AppTheme.success : AppTheme.error),
                              if (!inv.isPaid && inv.balance > 0) ...[
                                const SizedBox(height: 20),
                                CustomButton(
                                  text: 'سداد الفاتورة الآن (${inv.balance} ريال)',
                                  icon: Icons.credit_card_rounded,
                                  isLoading: customer.isPaying,
                                  onPressed: () => customer.payInvoice(inv.id),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Review Section
                      if (req.isCompleted && inv != null && inv.isPaid) ...[
                        if (customer.selectedReview != null) ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('تقييمك لمستوى الخدمة:', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                Row(
                                  children: List.generate(5, (i) {
                                    final rating = customer.selectedReview?['rating'] ?? 5;
                                    return Icon(
                                      i < (rating as num).toInt() ? Icons.star_rounded : Icons.star_border_rounded,
                                      color: Colors.amber,
                                      size: 24,
                                    );
                                  }),
                                ),
                                if (customer.selectedReview?['comment'] != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    customer.selectedReview!['comment'].toString(),
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ] else ...[
                          CustomButton(
                            text: 'تقييم الخدمة ومقدم الخدمة',
                            icon: Icons.star_rounded,
                            backgroundColor: Colors.amber[800],
                            onPressed: () => _showReviewDialog(context, customer),
                          ),
                        ],
                        const SizedBox(height: 18),
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

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 13)),
      ],
    );
  }
}
