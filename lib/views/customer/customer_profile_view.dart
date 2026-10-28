import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../services/chunked_upload_service.dart';
import '../widgets/presentation_widgets.dart';
import '../auth/login_view.dart';

class CustomerProfileView extends StatelessWidget {
  const CustomerProfileView({super.key});

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
          'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟',
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

  void _testChunkedUpload(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        double progress = 0.0;
        int currentChunk = 0;
        int totalChunks = 0;
        String statusText = 'جاري تحضير ملف الاختبار (4 ميجابايت)...';
        bool isDone = false;
        bool isSuccess = false;
        bool started = false;
        String? finalUrl;

        return StatefulBuilder(
          builder: (ctx, setState) {
            void startUpload() async {
              started = true;
              try {
                final tempFile = File(
                  '${Directory.systemTemp.path}/test_chunk_${DateTime.now().millisecondsSinceEpoch}.bin',
                );
                final chunk = List<int>.filled(1024 * 1024, 65);
                final sink = tempFile.openWrite();
                for (int i = 0; i < 4; i++) {
                  sink.add(chunk);
                }
                await sink.flush();
                await sink.close();

                setState(() {
                  statusText = 'بدء إرسال الأجزاء إلى السيرفر...';
                });

                final res = await ChunkedUploadService.uploadLargeFile(
                  file: tempFile,
                  chunkSize: 1024 * 1024,
                  onProgress: (p) {
                    setState(() {
                      progress = p.percentage;
                      currentChunk = p.currentChunk;
                      totalChunks = p.totalChunks;
                      statusText = 'جاري رفع الجزء $currentChunk من $totalChunks (${(p.percentage * 100).toInt()}%)';
                    });
                  },
                );

                if (await tempFile.exists()) {
                  await tempFile.delete();
                }

                setState(() {
                  isDone = true;
                  isSuccess = res.success;
                  if (res.success && res.data != null) {
                    finalUrl = res.data['file_url']?.toString();
                    statusText = 'تم استلام وتجميع كافة الأجزاء بنجاح على السيرفر!';
                  } else {
                    statusText = res.message.isNotEmpty ? res.message : 'فشل الرفع';
                  }
                });
              } catch (e) {
                setState(() {
                  isDone = true;
                  isSuccess = false;
                  statusText = 'خطأ: $e';
                });
              }
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!started) {
                startUpload();
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.cloud_upload_rounded, color: Colors.indigo),
                  SizedBox(width: 10),
                  Text('اختبار الرفع المجزأ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(statusText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: isDone ? (isSuccess ? 1.0 : 0.0) : progress,
                    backgroundColor: Colors.grey.shade200,
                    color: isSuccess ? Colors.green : (isDone ? Colors.red : Colors.indigo),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  if (finalUrl != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('المسار: $finalUrl', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ),
                  ],
                ],
              ),
              actions: [
                if (isDone)
                  ElevatedButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSuccess ? Colors.green : AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('إغلاق', style: TextStyle(color: Colors.white)),
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
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Luxury Avatar Header Card
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
                        user?.name.isNotEmpty == true ? user!.name[0] : 'ع',
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
                    user?.name ?? 'العميل الكريم',
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
                        Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'حساب عميل معتمد ومفعل',
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

            // Account Details Card
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
                    'بيانات الحساب',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProfileRow(
                    Icons.person_outline_rounded,
                    'الاسم الكامل',
                    user?.name ?? '-',
                    AppTheme.primary,
                  ),
                  const Divider(height: 24),
                  _buildProfileRow(
                    Icons.email_outlined,
                    'البريد الإلكتروني',
                    user?.email ?? '-',
                    AppTheme.secondary,
                  ),
                  const Divider(height: 24),
                  _buildProfileRow(
                    Icons.phone_outlined,
                    'رقم الجوال',
                    user?.phone ?? 'لم يحدد',
                    Colors.teal,
                  ),
                  const Divider(height: 24),
                  _buildProfileRow(
                    Icons.badge_outlined,
                    'نوع الحساب',
                    'عميل مستفيد',
                    Colors.orange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Help & Settings Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  _buildActionTile(
                    icon: Icons.support_agent_rounded,
                    title: 'الدعم والمساعدة والشكاوى',
                    subtitle: 'تواصل مع فريق مِهَن',
                    color: AppTheme.primary,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('خدمة العملاء متاحة على مدار الساعة')),
                      );
                    },
                  ),
                  const Divider(height: 16),
                  _buildActionTile(
                    icon: Icons.cloud_upload_outlined,
                    title: 'اختبار رفع الملفات المجزأة (Chunked Upload)',
                    subtitle: 'تجربة رفع ملف تجريبي بحجم 4 ميجابايت على أجزاء',
                    color: Colors.indigo,
                    onTap: () => _testChunkedUpload(context),
                  ),
                  const Divider(height: 16),
                  _buildActionTile(
                    icon: Icons.shield_outlined,
                    title: 'سياسة الخصوصية والشروط',
                    subtitle: 'اتفاقية الاستخدام وحماية البيانات',
                    color: AppTheme.secondary,
                    onTap: () {},
                  ),
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
              Text(
                title,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
