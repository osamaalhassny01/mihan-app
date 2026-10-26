import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../services/api_service.dart';
import '../widgets/presentation_widgets.dart';
import '../auth/login_view.dart';

class AdminMainView extends StatefulWidget {
  const AdminMainView({super.key});

  @override
  State<AdminMainView> createState() => _AdminMainViewState();
}

class _AdminMainViewState extends State<AdminMainView> {
  int _currentIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _usersList = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final dashRes = await ApiService.get('/api/admin/dashboard');
    final usersRes = await ApiService.get('/api/admin/users');

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (dashRes.success && dashRes.data != null) {
        _dashboardData = dashRes.data as Map<String, dynamic>?;
      } else {
        _errorMessage = dashRes.message;
      }

      if (usersRes.success && usersRes.data is List) {
        _usersList = usersRes.data as List;
      }
    });
  }

  void _onLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج من لوحة تحكم الإدارة؟'),
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
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text('لوحة تحكم مدير النظام'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAdminData,
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
          selectedItemColor: const Color(0xFF0F172A),
          unselectedItemColor: AppTheme.textSecondary,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics_rounded),
              label: 'لوحة القيادة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people_rounded),
              label: 'المستخدمون',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              activeIcon: Icon(Icons.account_circle_rounded),
              label: 'حساب المدير',
            ),
          ],
        ),
      ),
      body: _buildCurrentTab(user),
    );
  }

  Widget _buildCurrentTab(dynamic user) {
    if (_isLoading && _dashboardData == null) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppTheme.primary)));
    }

    if (_errorMessage != null && _dashboardData == null) {
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
                onPressed: _loadAdminData,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return IndexedStack(
      index: _currentIndex,
      children: [
        _buildDashboardTab(user),
        _buildUsersTab(),
        _buildProfileTab(user),
      ],
    );
  }

  Widget _buildDashboardTab(dynamic user) {
    final d = _dashboardData;
    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFF59E0B),
                    child: Text(
                      user?.name.isNotEmpty == true ? user.name[0] : 'أ',
                      style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الإدارة العامة والتحكم الكامل بالمنصة', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(
                          user?.name ?? 'مدير النظام',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Admin Authority • Full Access', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Platform Metrics Grid
            const Text(
              'إحصائيات المنصة الشاملة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'إجمالي المستخدمين',
                    value: '${d?['users_count'] ?? 0}',
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'إجمالي الطلبات',
                    value: '${d?['requests_count'] ?? 0}',
                    icon: Icons.receipt_long_rounded,
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
                    title: 'مقدمو الخدمة',
                    value: '${d?['providers_count'] ?? 0}',
                    icon: Icons.handyman_rounded,
                    color: AppTheme.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'العملاء المسجلون',
                    value: '${d?['customers_count'] ?? 0}',
                    icon: Icons.person_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'عمولات المنصة',
                    value: '${d?['platform_commission'] ?? 0} ر.ي',
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'طاقم العمل',
                    value: '${d?['employees_count'] ?? 0} موظف',
                    icon: Icons.badge_rounded,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Web Dashboard Notification Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.language_rounded, color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'لوحة تحكم الويب المتقدمة',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'تتيح لوحة تحكم الويب لإدارة النظام إدارة النماذج الذكية للـ AI، إعدادات النظام، الترحيلات، والتقارير المالية الموسعة.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'الرابط: ${d?['web_portal_url'] ?? "https://mihan-backend-production.up.railway.app/login"}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.secondary, fontWeight: FontWeight.bold),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: _usersList.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.group_off_rounded,
              title: 'لا يوجد مستخدمون',
              message: 'لم يتم استرجاع قائمة المستخدمين.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _usersList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final u = _usersList[i];
                final role = u['role']?.toString() ?? 'customer';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _getRoleColor(role).withValues(alpha: 0.15),
                        child: Icon(_getRoleIcon(role), color: _getRoleColor(role), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              u['email'] ?? '',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              textDirection: TextDirection.ltr,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(role).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getRoleArabic(role),
                          style: TextStyle(
                            color: _getRoleColor(role),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 46,
            backgroundColor: const Color(0xFF0F172A),
            child: Text(
              user?.name.isNotEmpty == true ? user.name[0] : 'أ',
              style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'مدير النظام',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'حساب مدير عام المنصة (Admin)',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                _buildProfileRow(Icons.email_outlined, 'البريد الإلكتروني', user?.email ?? '-'),
                const Divider(height: 24),
                _buildProfileRow(Icons.phone_outlined, 'رقم الهاتف', user?.phone ?? '-'),
                const Divider(height: 24),
                _buildProfileRow(Icons.verified_user_outlined, 'الدور والنطاق', 'مدير النظام الكامل (Full Superadmin)'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          CustomButton(
            text: 'تسجيل الخروج',
            icon: Icons.logout,
            backgroundColor: AppTheme.error,
            onPressed: () => _onLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 22),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFF0F172A);
      case 'employee':
        return const Color(0xFF6366F1);
      case 'provider':
        return AppTheme.secondary;
      case 'customer':
      default:
        return AppTheme.info;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'employee':
        return Icons.badge_rounded;
      case 'provider':
        return Icons.handyman_rounded;
      case 'customer':
      default:
        return Icons.person_rounded;
    }
  }

  String _getRoleArabic(String role) {
    switch (role) {
      case 'admin':
        return 'مدير النظام';
      case 'employee':
        return 'موظف منصة';
      case 'provider':
        return 'مقدم خدمة';
      case 'customer':
      default:
        return 'عميل';
    }
  }
}
