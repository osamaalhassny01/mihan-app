import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../widgets/presentation_widgets.dart';
import '../auth/login_view.dart';
import 'provider_application_view.dart';
import '../customer/complaints_view.dart';

class ProviderProfileView extends StatelessWidget {
  const ProviderProfileView({super.key});

  void _onLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.error),
            SizedBox(width: 10),
            Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في تسجيل الخروج من حساب الفني؟',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('تسجيل خروج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

    final isVerified = profile?.isVerified ?? false;
    final appStatus = profile?.applicationStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف المهني للفني'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<AuthController>().refreshUser();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Luxury Provider Header Card
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
                        backgroundColor: AppTheme.secondary,
                        child: Text(
                          user?.name.isNotEmpty == true ? user!.name[0] : 'م',
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
                      user?.name ?? 'مقدم الخدمة',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.profession ?? 'فني خدمات معتمد',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        String badgeText = 'بانتظار رفع طلب التوثيق';
                        Color badgeBg = AppTheme.warning.withValues(alpha: 0.25);
                        Color badgeBorder = AppTheme.warning;
                        IconData badgeIcon = Icons.hourglass_empty_rounded;

                        if (isVerified) {
                          badgeText = 'مزود خدمة موثق رسميًا';
                          badgeBg = Colors.white.withValues(alpha: 0.2);
                          badgeBorder = Colors.white.withValues(alpha: 0.4);
                          badgeIcon = Icons.verified_rounded;
                        } else if (appStatus == 'pending') {
                          badgeText = 'بانتظار التوثيق الإداري ⏳';
                          badgeBg = Colors.amber.withValues(alpha: 0.35);
                          badgeBorder = Colors.amber.shade300;
                          badgeIcon = Icons.pending_actions_rounded;
                        } else if (appStatus == 'rejected') {
                          badgeText = 'طلب التوثيق يحتاج مراجعة ⚠️';
                          badgeBg = AppTheme.error.withValues(alpha: 0.3);
                          badgeBorder = AppTheme.error;
                          badgeIcon = Icons.error_outline_rounded;
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: badgeBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(badgeIcon, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                badgeText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Performance & Experience Stats Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                          const SizedBox(height: 6),
                          Text(
                            '${profile?.avgRating ?? 5.0}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const Text('التقييم العام', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: AppTheme.secondary, size: 28),
                          const SizedBox(height: 6),
                          Text(
                            '${profile?.experienceYears ?? 0} سنوات',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const Text('سنوات الخبرة', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Provider Verification / Credentials Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: (isVerified || appStatus == 'pending')
                        ? AppTheme.primary
                        : AppTheme.primary.withValues(alpha: 0.3),
                    width: (isVerified || appStatus == 'pending') ? 1.5 : 1.0,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isVerified || appStatus == 'pending')
                          ? AppTheme.primary.withValues(alpha: 0.15)
                          : AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isVerified
                          ? Icons.verified_rounded
                          : (appStatus == 'pending' ? Icons.hourglass_top_rounded : Icons.verified_user_rounded),
                      color: AppTheme.primary,
                    ),
                  ),
                  title: const Text('طلب التوثيق والاعتماد المهني', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    isVerified
                        ? 'حسابك معتمد وموثق رسميًا من الإدارة بنجاح'
                        : (appStatus == 'pending'
                            ? 'تم رفع الطلب بنجاح وهو قيد التدقيق الإداري (اضغط للتعديل أو العرض)'
                            : (appStatus == 'rejected'
                                ? 'تم رفض الطلب - اضغط لتصحيح البيانات والشهادات'
                                : 'رفع إثبات المهنة والشهادات لمراجعة الإدارة وتفعيل الحساب')),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: appStatus == 'pending' ? AppTheme.primary : AppTheme.textSecondary,
                      fontWeight: appStatus == 'pending' ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_left_rounded, color: AppTheme.secondary),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProviderApplicationView()),
                    );
                    if (context.mounted) {
                      await context.read<AuthController>().refreshUser();
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),

            // Support & Complaints Button for Provider
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: AppTheme.secondary),
                ),
                title: const Text('الدعم الفني والشكاوى', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('التواصل المباشر مع إدارة المنصة لحل أي مشكلة', style: TextStyle(fontSize: 11.5)),
                trailing: const Icon(Icons.chevron_left_rounded, color: AppTheme.secondary),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ComplaintsView()),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Profile info card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'البيانات المهنية والتواصل',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProfileRow(Icons.email_outlined, 'البريد الإلكتروني', user?.email ?? '-', AppTheme.primary),
                  const Divider(height: 24),
                  _buildProfileRow(Icons.phone_outlined, 'رقم الجوال', user?.phone ?? 'لم يحدد', Colors.teal),
                  const Divider(height: 24),
                  _buildProfileRow(Icons.handyman_outlined, 'التخصص المعتمد', profile?.profession ?? 'خدمات فنية عامة', AppTheme.secondary),
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
      ),
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
}
