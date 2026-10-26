import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../services/api_service.dart';
import '../widgets/presentation_widgets.dart';
import '../auth/login_view.dart';

class EmployeeMainView extends StatefulWidget {
  const EmployeeMainView({super.key});

  @override
  State<EmployeeMainView> createState() => _EmployeeMainViewState();
}

class _EmployeeMainViewState extends State<EmployeeMainView> {
  int _currentIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  List<dynamic> _recentRequests = [];
  List<dynamic> _complaints = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
  }

  Future<void> _loadEmployeeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final dashRes = await ApiService.get('/api/employee/dashboard');
    final compRes = await ApiService.get('/api/employee/complaints');

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (dashRes.success && dashRes.data != null) {
        _stats = dashRes.data['stats'] as Map<String, dynamic>?;
        _recentRequests = (dashRes.data['recent_requests'] as List?) ?? [];
      } else {
        _errorMessage = dashRes.message;
      }

      if (compRes.success && compRes.data is List) {
        _complaints = compRes.data as List;
      }
    });
  }

  void _onLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج من حساب الموظف؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<AuthController>().logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.badge_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text('بوابة الموظف'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadEmployeeData,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: AppTheme.textSecondary,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'لوحة المراقبة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'الطلبات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.support_agent_outlined),
              activeIcon: Icon(Icons.support_agent_rounded),
              label: 'الشكاوى والدعم',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
      ),
      body: _buildCurrentTab(user),
    );
  }

  Widget _buildCurrentTab(dynamic user) {
    if (_isLoading && _stats == null) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1))));
    }

    if (_errorMessage != null && _stats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadEmployeeData,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    switch (_currentIndex) {
      case 0:
        return _buildDashboardTab(user);
      case 1:
        return _buildRequestsTab();
      case 2:
        return _buildComplaintsTab();
      case 3:
      default:
        return _buildProfileTab(user);
    }
  }

  Widget _buildDashboardTab(dynamic user) {
    return RefreshIndicator(
      onRefresh: _loadEmployeeData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF312E81).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF6366F1),
                    child: Text(
                      user?.name.isNotEmpty == true ? user.name[0] : 'م',
                      style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('مرحبًا بك في بوابة الرقابة والعمليات', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(
                          user?.name ?? 'موظف المنصة',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('صلاحيات متابعة الطلبات والشكاوى', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Grid
            const Text(
              'مؤشرات الأداء المباشرة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'إجمالي الطلبات',
                    value: '${_stats?['total_requests'] ?? 0}',
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'طلبات جديدة',
                    value: '${_stats?['pending_requests'] ?? 0}',
                    icon: Icons.hourglass_top_rounded,
                    color: AppTheme.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'قيد التنفيذ',
                    value: '${_stats?['active_requests'] ?? 0}',
                    icon: Icons.handyman_rounded,
                    color: AppTheme.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'شكاوى مفتوحة',
                    value: '${_stats?['open_complaints'] ?? 0}',
                    icon: Icons.report_problem_rounded,
                    color: AppTheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Requests Section
            SectionHeader(
              title: 'أحدث طلبات المنصة (${_recentRequests.length})',
              actionText: 'عرض الكل',
              onAction: () => setState(() => _currentIndex = 1),
            ),
            const SizedBox(height: 12),

            if (_recentRequests.isEmpty)
              const EmptyStateWidget(
                icon: Icons.inbox_outlined,
                title: 'لا توجد طلبات مسجلة',
                message: 'لم يتم العثور على أي طلبات نشطة في المنصة حاليًا.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentRequests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final req = _recentRequests[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
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
                              req['request_number'] ?? 'REQ',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary),
                            ),
                            StatusBadge(
                              status: req['status'] ?? 'pending',
                              label: _getStatusArabic(req['status'] ?? 'pending'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          req['service_name'] ?? 'خدمة فنية',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text('العميل: ${req['customer_name'] ?? "-"}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            const Spacer(),
                            const Icon(Icons.handyman_outlined, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text('المزود: ${req['provider_name'] ?? "لم يحدد"}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
    );
  }

  Widget _buildRequestsTab() {
    return RefreshIndicator(
      onRefresh: _loadEmployeeData,
      child: _recentRequests.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.assignment_outlined,
              title: 'لا توجد طلبات',
              message: 'لم يتم العثور على طلبات لعرضها.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _recentRequests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final req = _recentRequests[i];
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
                            req['request_number'] ?? 'REQ',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary),
                          ),
                          StatusBadge(
                            status: req['status'] ?? 'pending',
                            label: _getStatusArabic(req['status'] ?? 'pending'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        req['service_name'] ?? 'خدمة فنية',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        req['description'] ?? '',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Divider(height: 18),
                      Row(
                        children: [
                          Text('العميل: ${req['customer_name'] ?? "-"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text('المزود: ${req['provider_name'] ?? "في الانتظار"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildComplaintsTab() {
    return RefreshIndicator(
      onRefresh: _loadEmployeeData,
      child: _complaints.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.sentiment_satisfied_alt_outlined,
              title: 'لا توجد شكاوى مفتوحة',
              message: 'كافة الخدمات والطلبات تسير بانتظام دون شكاوى مسجلة حاليًا.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _complaints.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final comp = _complaints[i];
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
                            comp['subject'] ?? 'شكوى بدون عنوان',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary),
                          ),
                          StatusBadge(
                            status: comp['status'] ?? 'open',
                            label: comp['status'] == 'open' ? 'مفتوحة' : 'قيد المراجعة',
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        comp['description'] ?? '',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'مقدم الشكوى: ${comp['user_name'] ?? "-"} (${comp['user_role'] ?? "-"})',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildProfileTab(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Luxury Employee Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryDark.withValues(alpha: 0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: const Color(0xFF6366F1),
                    child: Text(
                      user?.name.isNotEmpty == true ? user.name[0] : 'م',
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'موظف المنصة',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'صلاحيات الإشراف والرقابة الفنية',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Details Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
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
                const Text(
                  'بيانات الموظف والمنصب',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildProfileRow(Icons.email_outlined, 'البريد الإلكتروني', user?.email ?? '-', AppTheme.primary),
                const Divider(height: 24),
                _buildProfileRow(Icons.phone_outlined, 'رقم التواصل', user?.phone ?? 'لم يحدد', AppTheme.secondary),
                const Divider(height: 24),
                _buildProfileRow(Icons.security_outlined, 'مستوى الصلاحية', 'إشراف على الطلبات وحل الشكاوى', const Color(0xFF6366F1)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          CustomButton(
            text: 'تسجيل الخروج من الحساب',
            icon: Icons.logout_rounded,
            backgroundColor: AppTheme.error,
            onPressed: () => _onLogout(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String title, String value, Color accentColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  String _getStatusArabic(String status) {
    switch (status) {
      case 'new':
      case 'pending':
        return 'بانتظار الموافقة';
      case 'accepted':
        return 'تم القبول';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }
}
