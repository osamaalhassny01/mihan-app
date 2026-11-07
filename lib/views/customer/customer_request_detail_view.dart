import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/currency_helper.dart';
import '../../controllers/customer_controller.dart';
import '../widgets/presentation_widgets.dart';
import '../widgets/request_workflow_widgets.dart';

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
                      RequestJourneyCard(request: req, isPaid: inv?.isPaid ?? false),
                      ServiceWorkflowPanel(request: req),
                      RequestActivityTimeline(history: customer.requestHistory, request: req),
                      if (customer.errorMessage != null) ...[
                        Text(customer.errorMessage!, style: const TextStyle(color: AppTheme.error)),
                        const SizedBox(height: 12),
                      ],
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
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
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
                                    Flexible(child: Text(
                                      req.requestNumber,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    )),
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
                              _buildInfoRow(Icons.payments_outlined, 'الميزانية المقترحة:', CurrencyHelper.format(req.budget), Colors.teal),
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
                                Expanded(child: Text(
                                  'تفاصيل المشكلة / العطل',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                                )),
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

                      // Assigned Provider Card (Without phone number, communication via platform)
                      if (req.providerName != null) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.4)),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.secondary.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: AppTheme.secondary.withValues(alpha: 0.15),
                                    child: Text(
                                      req.providerName!.isNotEmpty ? req.providerName![0] : 'ف',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                req.providerName!,
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (req.providerIsVerified) ...[
                                              const SizedBox(width: 6),
                                              const Icon(Icons.verified, color: AppTheme.primary, size: 18),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          req.providerProfession ?? req.serviceNameAr ?? 'فني متخصص',
                                          style: const TextStyle(fontSize: 13, color: AppTheme.secondary, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (req.providerAvgRating != null) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.amber.shade200),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${req.providerAvgRating}',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (req.providerExperienceYears != null && req.providerExperienceYears! > 0) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: Text(
                                        'خبرة ${req.providerExperienceYears} سنوات',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue.shade900),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (req.providerIsVerified) Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: const Text(
                                      'معتمد رسمياً في المنصة',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.shield_outlined, size: 16, color: AppTheme.primary),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'حماية الخصوصية: التواصل ومتابعة تنفيذ الخدمة يتم حصراً عبر المنصة الرسمية دون كشف أرقام الهواتف.',
                                        style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary, height: 1.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ] else if (req.isPending) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.hourglass_top_rounded, color: Colors.blue.shade700, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الطلب قيد الإرسال للمهنيين المعتمدين',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 13.5),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'سيصلك إشعار فوري وتظهر هنا هوية وبيانات المهني المعتمد فور قبوله للطلب.',
                                      style: TextStyle(color: Colors.blue.shade800, fontSize: 11.5),
                                    ),
                                  ],
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
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                spacing: 12,
                                runSpacing: 10,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.receipt_rounded,
                                        color: inv.isPaid ? AppTheme.success : AppTheme.warning,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(child: Text(
                                        'فاتورة رقم ${inv.invoiceNumber}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      )),
                                    ],
                                  ),
                                  StatusBadge(
                                    status: inv.isPaid ? 'completed' : 'pending',
                                    label: inv.isPaid ? 'مدفوعة بالكامل' : 'مستحقة السداد',
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(Icons.calculate_outlined, 'إجمالي قيمة الخدمة:', CurrencyHelper.format(inv.totalAmount), AppTheme.textPrimary),
                              const SizedBox(height: 10),
                              _buildInfoRow(Icons.account_balance_wallet_outlined, 'المبلغ المتبقي:', CurrencyHelper.format(inv.balance), inv.isPaid ? AppTheme.success : AppTheme.error),
                              if (!inv.isPaid && inv.balance > 0) ...[
                                const SizedBox(height: 20),
                                CustomButton(
                                  text: 'سداد الفاتورة الآن (${CurrencyHelper.format(inv.balance)})',
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
                      if (req.canCancel) ...[
                        CustomButton(
                          text: 'إلغاء الطلب',
                          icon: Icons.cancel_outlined,
                          backgroundColor: AppTheme.error,
                          isLoading: customer.isLoading,
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                              title: const Text('إلغاء الطلب؟'),
                              content: const Text('سيُلغى الطلب قبل بدء التنفيذ. يمكنك إنشاء طلب جديد لاحقًا.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('الاحتفاظ بالطلب')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('نعم، إلغاء الطلب')),
                              ],
                            ));
                            if (confirmed == true && context.mounted) await customer.cancelRequest(req.id);
                          },
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
        const SizedBox(width: 8),
        Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 13))),
      ],
    );
  }
}
