import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/customer_controller.dart';
import '../widgets/presentation_widgets.dart';
import 'create_request_view.dart';

class CustomerHomeView extends StatefulWidget {
  const CustomerHomeView({super.key});

  @override
  State<CustomerHomeView> createState() => _CustomerHomeViewState();
}

class _CustomerHomeViewState extends State<CustomerHomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customerCtrl = context.read<CustomerController>();
      customerCtrl.loadDashboard();
      customerCtrl.loadCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final customer = context.watch<CustomerController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة مِهَن'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              customer.loadDashboard();
              customer.loadCatalog();
            },
          ),
        ],
      ),
      body: customer.isLoading && customer.categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await customer.loadDashboard();
                await customer.loadCatalog();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, Color(0xFF2C3E50)],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.secondary,
                                child: Text(
                                  auth.currentUser?.name.isNotEmpty == true
                                      ? auth.currentUser!.name[0]
                                      : 'ع',
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('مرحبًا بك،', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                    Text(
                                      auth.currentUser?.name ?? 'عميل مِهَن',
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          CustomButton(
                            text: 'اطلب خدمة فنية الآن',
                            icon: Icons.add_circle_outline,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const CreateRequestView()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Stats
                    if (customer.dashboardStats != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'الطلبات النشطة',
                              value: '${customer.dashboardStats?['active_requests'] ?? 0}',
                              icon: Icons.hourglass_top_outlined,
                              color: AppTheme.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              title: 'الطلبات المكتملة',
                              value: '${customer.dashboardStats?['completed_requests'] ?? 0}',
                              icon: Icons.check_circle_outline,
                              color: AppTheme.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Categories Section
                    const Text(
                      'أقسام الخدمات الفنية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (customer.categories.isEmpty)
                      const EmptyStateWidget(
                        title: 'لا توجد أقسام متاحة',
                        message: 'يتم تحديث قائمة الخدمات حاليًا.',
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
                        ),
                        itemCount: customer.categories.length,
                        itemBuilder: (context, index) {
                          final cat = customer.categories[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CreateRequestView(preselectedCategoryId: cat.id),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.handyman_outlined,
                                      color: AppTheme.secondary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    cat.nameAr,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${cat.servicesCount} خدمة',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
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
