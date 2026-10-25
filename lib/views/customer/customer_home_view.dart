import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/customer_controller.dart';
import '../widgets/presentation_widgets.dart';
import 'create_request_view.dart';
import 'customer_requests_view.dart';

class CustomerHomeView extends StatefulWidget {
  const CustomerHomeView({super.key});

  @override
  State<CustomerHomeView> createState() => _CustomerHomeViewState();
}

class _CustomerHomeViewState extends State<CustomerHomeView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String name, String? iconName) {
    final lower = name.toLowerCase();
    if (lower.contains('كهرباء') || (iconName?.contains('bolt') ?? false)) {
      return Icons.bolt_rounded;
    }
    if (lower.contains('سباكة') || (iconName?.contains('faucet') ?? false)) {
      return Icons.water_drop_rounded;
    }
    if (lower.contains('تكييف') || (iconName?.contains('fan') ?? false)) {
      return Icons.ac_unit_rounded;
    }
    if (lower.contains('نجارة') || (iconName?.contains('hammer') ?? false)) {
      return Icons.carpenter_rounded;
    }
    if (lower.contains('دهان') || (iconName?.contains('paint') ?? false)) {
      return Icons.format_paint_rounded;
    }
    if (lower.contains('تنظيف') || (iconName?.contains('broom') ?? false)) {
      return Icons.cleaning_services_rounded;
    }
    if (lower.contains('سيار') || (iconName?.contains('car') ?? false)) {
      return Icons.directions_car_rounded;
    }
    if (lower.contains('هاتف') || lower.contains('حواسيب') || (iconName?.contains('laptop') ?? false)) {
      return Icons.devices_other_rounded;
    }
    if (lower.contains('حدادة') || lower.contains('ألمنيوم')) {
      return Icons.hardware_rounded;
    }
    if (lower.contains('سيراميك') || lower.contains('بلاط')) {
      return Icons.grid_view_rounded;
    }
    if (lower.contains('أجهزة') || lower.contains('منزلية')) {
      return Icons.kitchen_rounded;
    }
    return Icons.handyman_rounded;
  }

  Color _getCategoryColor(int index) {
    final colors = [
      const Color(0xFF00897B), // Teal
      const Color(0xFF0284C7), // Sky Blue
      const Color(0xFFD97706), // Amber
      const Color(0xFF7C3AED), // Violet
      const Color(0xFFE11D48), // Rose
      const Color(0xFF059669), // Emerald
      const Color(0xFF4F46E5), // Indigo
      const Color(0xFFEA580C), // Orange
      const Color(0xFF0891B2), // Cyan
      const Color(0xFF65A30D), // Lime
      const Color(0xFF475569), // Slate
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final customer = context.watch<CustomerController>();

    final filteredCategories = customer.categories.where((cat) {
      if (_searchQuery.trim().isEmpty) return true;
      return cat.nameAr.contains(_searchQuery.trim()) ||
          (cat.nameEn ?? '').toLowerCase().contains(_searchQuery.trim().toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.handyman, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text('منصة مِهَن'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              customer.loadDashboard();
              customer.loadCatalog();
            },
          ),
        ],
      ),
      body: customer.isLoading && customer.categories.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondary)),
                  SizedBox(height: 16),
                  Text('جاري تحميل خدمات مِهَن...', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppTheme.secondary,
              onRefresh: () async {
                await customer.loadDashboard();
                await customer.loadCatalog();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Welcome Hero Card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: AppTheme.heroGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.tealGradient,
                                  shape: BoxShape.circle,
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
                                        : 'ع',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'أهلاً بك، سعداء بخدمتك 👋',
                                      style: TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      auth.currentUser?.name ?? 'عميل مِهَن',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'هل تواجه مشكلة فنية في منزلك أو منشأتك؟',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 14),
                          CustomButton(
                            text: 'اطلب خدمة فنية جديدة الآن',
                            icon: Icons.add_task_rounded,
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

                    // Quick Stats Cards
                    if (customer.dashboardStats != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const CustomerRequestsView()),
                                );
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: StatCard(
                                title: 'الطلبات النشطة',
                                value: '${customer.dashboardStats?['active_requests'] ?? 0}',
                                subtitle: 'قيد المتابعة والتنفيذ',
                                icon: Icons.pending_actions_rounded,
                                color: AppTheme.warning,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const CustomerRequestsView()),
                                );
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: StatCard(
                                title: 'الطلبات المكتملة',
                                value: '${customer.dashboardStats?['completed_requests'] ?? 0}',
                                subtitle: 'تم تنفيذها بنجاح',
                                icon: Icons.verified_rounded,
                                color: AppTheme.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Search input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'ابحث عن مجال الخدمة (سباكة، كهرباء، تكييف...)',
                          hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.secondary),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section Header
                    SectionHeader(
                      title: 'أقسام الخدمات الفنية (${filteredCategories.length})',
                      actionText: 'طلب مخصص',
                      onAction: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CreateRequestView()),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Categories Grid
                    if (filteredCategories.isEmpty)
                      EmptyStateWidget(
                        icon: Icons.search_off_rounded,
                        title: 'لا توجد نتائج مطابقة',
                        message: 'لم يتم العثور على أقسام تطابق "$_searchQuery"',
                        onRetry: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.15,
                        ),
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          final cat = filteredCategories[index];
                          final catColor = _getCategoryColor(index);
                          final catIcon = _getCategoryIcon(cat.nameAr, cat.icon);

                          return InkWell(
                            borderRadius: BorderRadius.circular(20),
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
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: catColor.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      catIcon,
                                      color: catColor,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    cat.nameAr,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.background,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.border),
                                    ),
                                    child: Text(
                                      '${cat.servicesCount} خدمات',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
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
