import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../controllers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../widgets/presentation_widgets.dart';
import 'register_view.dart';
import '../customer/customer_main_view.dart';
import '../provider/provider_main_view.dart';
import '../employee/employee_main_view.dart';
import '../admin/admin_main_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Server health state
  bool _isCheckingServer = true;
  bool _isServerConnected = false;
  int _serverLatencyMs = 0;
  String _currentServerUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _checkServerConnectivity();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkServerConnectivity({String? testUrl}) async {
    setState(() {
      _isCheckingServer = true;
    });

    final targetUrl = testUrl ?? await StorageService.getBaseUrl();
    final result = await ApiService.checkHealth(customUrl: targetUrl);

    if (!mounted) return;
    setState(() {
      _isCheckingServer = false;
      _isServerConnected = result.isConnected;
      _serverLatencyMs = result.latencyMs;
      _currentServerUrl = targetUrl;
    });
  }

  void _showServerSettings(BuildContext context) async {
    final currentUrl = await StorageService.getBaseUrl();
    final urlController = TextEditingController(text: currentUrl);
    bool testingUrl = false;
    String? pingResultMsg;
    bool? pingSuccess;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              top: 24,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.cloud_sync_outlined, color: AppTheme.secondary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إعدادات خادم الباك إند',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            Text(
                              'اختر السيرفر أو أدخل عنوان الخادم المخصص',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Presets
                  const Text(
                    'الخوادم الجاهزة:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 10),

                  ...ApiConfig.serverPresets.map((preset) {
                    final isSelected = urlController.text.trim() == preset['url'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          setModalState(() {
                            urlController.text = preset['url']!;
                            pingResultMsg = null;
                            pingSuccess = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.secondary.withValues(alpha: 0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppTheme.secondary : AppTheme.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      preset['name']!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? AppTheme.secondary : AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      preset['url']!,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      textDirection: TextDirection.ltr,
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: AppTheme.secondary, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 12),
                  // Custom input
                  TextField(
                    controller: urlController,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'عنوان السيرفر (Base URL)',
                      prefixIcon: const Icon(Icons.link),
                      suffixIcon: IconButton(
                        icon: testingUrl
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.network_ping, color: AppTheme.secondary),
                        tooltip: 'اختبار الاتصال',
                        onPressed: testingUrl
                            ? null
                            : () async {
                                final checkUrl = urlController.text.trim();
                                if (checkUrl.isEmpty) return;
                                setModalState(() {
                                  testingUrl = true;
                                  pingResultMsg = null;
                                });
                                final res = await ApiService.checkHealth(customUrl: checkUrl);
                                setModalState(() {
                                  testingUrl = false;
                                  pingSuccess = res.isConnected;
                                  pingResultMsg = res.isConnected
                                      ? '✅ ${res.message} (${res.latencyMs} ms)'
                                      : '❌ ${res.message}';
                                });
                              },
                      ),
                    ),
                  ),

                  if (pingResultMsg != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (pingSuccess == true ? AppTheme.success : AppTheme.error).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pingResultMsg!,
                        style: TextStyle(
                          fontSize: 12,
                          color: pingSuccess == true ? AppTheme.success : AppTheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            setModalState(() {
                              urlController.text = ApiConfig.baseUrl;
                              pingResultMsg = null;
                              pingSuccess = null;
                            });
                          },
                          child: const Text('استعادة الافتراضي'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () async {
                            final newUrl = urlController.text.trim();
                            if (newUrl.isNotEmpty) {
                              await StorageService.setBaseUrl(newUrl);
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم ضبط رابط السيرفر: $newUrl'),
                                    backgroundColor: AppTheme.success,
                                  ),
                                );
                                _checkServerConnectivity(testUrl: newUrl);
                              }
                            }
                          },
                          child: const Text('حفظ وتطبيق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _fillDemoAccount(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم ملء بيانات: $email'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onLoginPressed(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال البريد الإلكتروني وكلمة المرور'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final auth = context.read<AuthController>();
    final success = await auth.login(email, password);

    if (!mounted) return;
    if (success) {
      if (auth.isCustomer) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CustomerMainView()),
          (route) => false,
        );
      } else if (auth.isProvider) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ProviderMainView()),
          (route) => false,
        );
      } else if (auth.isEmployee) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const EmployeeMainView()),
          (route) => false,
        );
      } else if (auth.isAdmin) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminMainView()),
          (route) => false,
        );
      } else {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CustomerMainView()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<AuthController>(
          builder: (context, auth, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Live Server Pill
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ServerStatusBadge(
                      isConnected: _isServerConnected,
                      isChecking: _isCheckingServer,
                      latencyMs: _serverLatencyMs,
                      url: _currentServerUrl,
                      onTap: () => _showServerSettings(context),
                      onRefresh: () => _checkServerConnectivity(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Brand Emblem & Title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            gradient: AppTheme.heroGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'مِهَن',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'منصة الخدمات الفنية الذكية ودعم القرار',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Error Message Banner
                  if (auth.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppTheme.error,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              auth.errorMessage!,
                              style: const TextStyle(
                                color: AppTheme.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Email Input
                  CustomTextField(
                    label: 'البريد الإلكتروني',
                    hint: 'customer1@mihan.test',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Password Input
                  CustomTextField(
                    label: 'كلمة المرور',
                    hint: '••••••••',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Action Button
                  CustomButton(
                    text: 'دخول إلى المنصة',
                    icon: Icons.login,
                    isLoading: auth.isLoading,
                    onPressed: () => _onLoginPressed(context),
                  ),
                  const SizedBox(height: 24),

                  // Quick Demo Accounts Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flash_on, color: AppTheme.accent, size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              'الدخول السريع بحسابات تجريبية:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Passw0rd!',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accent),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickChip(
                                label: '👤 عميل مستفيد',
                                email: 'customer1@mihan.test',
                                password: 'Passw0rd!',
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildQuickChip(
                                label: '🛠️ مهني / فني خدمة',
                                email: 'provider1@mihan.test',
                                password: 'Passw0rd!',
                                color: AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'ليس لديك حساب بعد؟ ',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          auth.clearError();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterView(),
                            ),
                          );
                        },
                        child: const Text(
                          'أنشئ حسابك الآن',
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required String email,
    required String password,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _fillDemoAccount(email, password),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
