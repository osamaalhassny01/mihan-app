import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../widgets/presentation_widgets.dart';
import '../auth/login_view.dart';

class ProviderProfileView extends StatelessWidget {
  const ProviderProfileView({super.key});

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
    final profile = auth.providerProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الفني لمقدم الخدمة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 46,
              backgroundColor: AppTheme.secondary,
              child: Text(
                user?.name.isNotEmpty == true ? user!.name[0] : 'م',
                style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? 'مقدم الخدمة',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              profile?.profession ?? 'فني خدمات معتمد',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: (profile?.isVerified ?? false)
                    ? AppTheme.success.withOpacity(0.12)
                    : AppTheme.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    (profile?.isVerified ?? false) ? Icons.verified : Icons.pending,
                    color: (profile?.isVerified ?? false) ? AppTheme.success : AppTheme.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    (profile?.isVerified ?? false) ? 'مزود خدمة موثق رسميًا' : 'بانتظار التوثيق الإداري',
                    style: TextStyle(
                      color: (profile?.isVerified ?? false) ? AppTheme.success : AppTheme.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
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
                  _buildProfileRow(Icons.star_outline, 'متوسط تقييم العملاء', '${profile?.avgRating ?? 5.0} من 5'),
                  const Divider(height: 24),
                  _buildProfileRow(Icons.history, 'سنوات الخبرة', '${profile?.experienceYears ?? 0} سنوات'),
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
