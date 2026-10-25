import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/provider_controller.dart';
import '../widgets/presentation_widgets.dart';

class ProviderDashboardView extends StatefulWidget {
  const ProviderDashboardView({super.key});

  @override
  State<ProviderDashboardView> createState() => _ProviderDashboardViewState();
}

class _ProviderDashboardViewState extends State<ProviderDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderController>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final provider = context.watch<ProviderController>();
    final data = provider.dashboardData;
    final stats = data?['stats'];
    final fin = data?['finance'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم مقدم الخدمة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadDashboard(),
          ),
        ],
      ),
      body: provider.isLoading && data == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.loadDashboard(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Availability Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: provider.isAvailable
                            ? AppTheme.success.withValues(alpha: 0.12)
                            : AppTheme.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: provider.isAvailable
                              ? AppTheme.success.withValues(alpha: 0.3)
                              : AppTheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            provider.isAvailable
                                ? Icons.check_circle
                                : Icons.do_not_disturb_on,
                            color: provider.isAvailable
                                ? AppTheme.success
                                : AppTheme.error,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.isAvailable
                                      ? 'أنت متاح للعمل الآن'
                                      : 'غير متاح للعمل حاليًا',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: provider.isAvailable
                                        ? AppTheme.success
                                        : AppTheme.error,
                                  ),
                                ),
                                Text(
                                  provider.isAvailable
                                      ? 'يمكن للعملاء إرسال طلبات جديدة إليك'
                                      : 'لن تظهر في نتائج بحث العملاء',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: provider.isAvailable,
                            activeColor: AppTheme.success,
                            onChanged: provider.isActionLoading
                                ? null
                                : (_) => provider.toggleAvailability(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Provider Welcome Card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: AppTheme.heroGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryDark.withValues(alpha: 0.3),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: AppTheme.tealGradient,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.secondary.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                auth.currentUser?.name.isNotEmpty == true
                                    ? auth.currentUser!.name[0]
                                    : 'م',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auth.currentUser?.name ?? 'مقدم الخدمة',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  auth.providerProfile?.profession ??
                                      'فني معتمد',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${data?['profile']?['avg_rating'] ?? 5.0}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Request Stats
                    const Text(
                      'إحصائيات الطلبات',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'طلبات جديدة',
                            value: '${stats?['pending_requests'] ?? 0}',
                            icon: Icons.notifications_active_outlined,
                            color: AppTheme.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'قيد التنفيذ',
                            value: '${stats?['active_requests'] ?? 0}',
                            icon: Icons.engineering_outlined,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'الطلبات المكتملة',
                            value: '${stats?['completed_requests'] ?? 0}',
                            icon: Icons.task_alt,
                            color: AppTheme.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'إجمالي الطلبات',
                            value: '${stats?['total_requests'] ?? 0}',
                            icon: Icons.list_alt,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Financial Summary Card
                    const Text(
                      'المستحقات والأرباح',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'إجمالي قيمة الخدمات المنفذة:',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              Text(
                                '${fin?['gross_amount'] ?? 0} ريال',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'صافي مستحقاتك (بعد العمولة):',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              Text(
                                '${fin?['provider_net_amount'] ?? 0} ريال',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.success,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'المبالغ المستلمة بحسابك:',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              Text(
                                '${fin?['paid_amount'] ?? 0} ريال',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
