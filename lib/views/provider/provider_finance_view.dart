import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/provider_controller.dart';
import '../widgets/presentation_widgets.dart';

class ProviderFinanceView extends StatefulWidget {
  const ProviderFinanceView({super.key});

  @override
  State<ProviderFinanceView> createState() => _ProviderFinanceViewState();
}

class _ProviderFinanceViewState extends State<ProviderFinanceView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderController>().loadFinance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderController>();
    final fin = provider.financeSummary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المستحقات المالية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadFinance(),
          ),
        ],
      ),
      body: provider.isLoading && fin == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.loadFinance(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Financial Metric Cards
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'صافي الأرباح',
                            value: '${fin?.providerNetAmount ?? 0} ريال',
                            icon: Icons.account_balance_wallet,
                            color: AppTheme.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'المبالغ المستلمة',
                            value: '${fin?.paidAmount ?? 0} ريال',
                            icon: Icons.payments_outlined,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'إجمالي الأعمال',
                            value: '${fin?.grossAmount ?? 0} ريال',
                            icon: Icons.receipt_long_outlined,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'رصيد معلق',
                            value: '${fin?.outstandingAmount ?? 0} ريال',
                            icon: Icons.hourglass_empty,
                            color: AppTheme.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Invoices Section
                    const Text(
                      'سجل الفواتير والمستحقات',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),

                    if (provider.invoices.isEmpty)
                      const EmptyStateWidget(
                        icon: Icons.receipt_outlined,
                        title: 'لا توجد فواتير بعد',
                        message: 'عند إكمال أي طلب خدمة سيتم إصدار فاتورته واحتساب أرباحك تلقائيًا هنا.',
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.invoices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final inv = provider.invoices[index] as Map<String, dynamic>;
                          final isPaid = inv['payment_status'] == 'paid';
                          return Container(
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
                                      inv['invoice_number']?.toString() ?? 'فاتورة',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary),
                                    ),
                                    StatusBadge(
                                      status: isPaid ? 'completed' : 'pending',
                                      label: isPaid ? 'مدفوعة' : 'غير مدفوعة',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  inv['service_name']?.toString() ?? 'خدمة منفذة',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'الطلب رقم: ${inv['request_number'] ?? '-'}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                const Divider(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('قيمة الخدمة:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                    Text('${inv['service_price'] ?? 0} ريال', style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('عمولة المنصة:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                    Text('-${inv['commission_amount'] ?? 0} ريال', style: const TextStyle(color: AppTheme.error, fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('صافي مستحقك:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(
                                      '${inv['provider_net'] ?? 0} ريال',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success, fontSize: 15),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
