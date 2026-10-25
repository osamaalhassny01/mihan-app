import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../widgets/presentation_widgets.dart';
import '../customer/customer_main_view.dart';
import '../provider/provider_main_view.dart';
import '../employee/employee_main_view.dart';
import '../admin/admin_main_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _professionController = TextEditingController(text: 'فني خدمات عامة');
  final _roleDetailController = TextEditingController(text: 'دعم ومتابعة العمليات');
  bool _obscurePassword = true;

  // Supports all 4 platform roles: 'customer', 'provider', 'employee', 'admin'
  String _selectedRole = 'customer';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _professionController.dispose();
    _roleDetailController.dispose();
    super.dispose();
  }

  void _onRegisterPressed(BuildContext context) async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final profession = _selectedRole == 'provider'
        ? _professionController.text.trim()
        : _roleDetailController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول المطلوبة'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('كلمة المرور يجب أن لا تقل عن 6 خانات'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final auth = context.read<AuthController>();
    final success = await auth.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: _selectedRole,
      profession: profession.isNotEmpty ? profession : null,
    );

    if (success && mounted) {
      final roleName = auth.currentUser?.roleTitle ?? 'المستخدم';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إنشاء حساب ($roleName) بنجاح! مرحبًا بك في مِهَن'),
          backgroundColor: AppTheme.success,
        ),
      );

      if (auth.isCustomer) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CustomerMainView()),
          (route) => false,
        );
      } else if (auth.isProvider) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ProviderMainView()),
          (route) => false,
        );
      } else if (auth.isEmployee) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const EmployeeMainView()),
          (route) => false,
        );
      } else if (auth.isAdmin) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminMainView()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CustomerMainView()),
          (route) => false,
        );
      }
    }
  }

  String get _buttonLabel {
    switch (_selectedRole) {
      case 'provider':
        return 'إنشاء حساب مقدم خدمة جديد';
      case 'employee':
        return 'إنشاء حساب موظف منصة جديد';
      case 'admin':
        return 'إنشاء حساب مدير نظام جديد';
      case 'customer':
      default:
        return 'إنشاء حساب عميل مستفيد جديد';
    }
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : activeColor,
                  size: 26,
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Colors.white : AppTheme.textSecondary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 12, color: activeColor)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.3,
                  color: isSelected ? Colors.white70 : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer<AuthController>(
          builder: (context, auth, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.badge_rounded, color: AppTheme.secondary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'اختر فئة الحساب المطلوبة',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'اختر حساب عميل مستفيد أو مقدم خدمة فنية معتمد',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 2 Selected Roles for Mobile App (Customer & Provider)
                  Row(
                    children: [
                      Expanded(
                        child: _buildRoleCard(
                          role: 'customer',
                          title: 'عميل مستفيد',
                          subtitle: 'طلب وحجز الخدمات الفنية والمنزلية بسهولة',
                          icon: Icons.person_rounded,
                          activeColor: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildRoleCard(
                          role: 'provider',
                          title: 'مقدم خدمة / فني',
                          subtitle: 'استقبال طلبات الصيانة وزيادة الدخل',
                          icon: Icons.handyman_rounded,
                          activeColor: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Error alert if any
                  if (auth.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              auth.errorMessage!,
                              style: const TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          label: 'الاسم الكامل',
                          hint: 'الاسم الثلاثي أو اسم المنشأة',
                          controller: _nameController,
                          prefixIcon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 14),

                        CustomTextField(
                          label: 'البريد الإلكتروني',
                          hint: 'name@example.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 14),

                        CustomTextField(
                          label: 'رقم الهاتف',
                          hint: '777000000',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                        ),
                        const SizedBox(height: 14),

                        // Role specific field
                        if (_selectedRole == 'provider') ...[
                          CustomTextField(
                            label: 'المهنة أو التخصص الفني',
                            hint: 'مثال: فني سباكة، كهربائي منازل، تكييف وتبريد',
                            controller: _professionController,
                            prefixIcon: Icons.build_outlined,
                          ),
                          const SizedBox(height: 14),
                        ] else if (_selectedRole == 'employee') ...[
                          CustomTextField(
                            label: 'القسم أو الصفة الوظيفية',
                            hint: 'مثال: دعم فني ومتابعة العمليات',
                            controller: _roleDetailController,
                            prefixIcon: Icons.work_outline_rounded,
                          ),
                          const SizedBox(height: 14),
                        ] else if (_selectedRole == 'admin') ...[
                          CustomTextField(
                            label: 'المسمى الإداري',
                            hint: 'مثال: مشرف عام المنصة',
                            controller: _roleDetailController,
                            prefixIcon: Icons.verified_user_outlined,
                          ),
                          const SizedBox(height: 14),
                        ],

                        CustomTextField(
                          label: 'كلمة المرور',
                          hint: '6 خانات على الأقل',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  CustomButton(
                    text: _buttonLabel,
                    icon: Icons.person_add_rounded,
                    isLoading: auth.isLoading,
                    onPressed: () => _onRegisterPressed(context),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'لديك حساب بالفعل؟ ',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          auth.clearError();
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'سجل دخولك الآن',
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
