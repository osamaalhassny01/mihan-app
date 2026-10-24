import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../widgets/presentation_widgets.dart';
import '../auth/login_view.dart';

class CustomerProfileView extends StatelessWidget {
  const CustomerProfileView({super.key});

  void _onLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('تسجيل خروج'),
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
        title: const Text('الملف الشخصي'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 46,
              backgroundColor: AppTheme.primary,
              child: Text(
                user?.name.isNotEmpty == true ? user!.name[0] : 'ع',
                style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? 'العميل',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'حساب عميل مستفيد',
                style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold, fontSize: 12),
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
                  _buildProfileRow(Icons.verified_user_outlined, 'حالة الحساب', 'نشط ومفعل'),
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
}
