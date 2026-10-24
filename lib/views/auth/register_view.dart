import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../widgets/presentation_widgets.dart';
import '../customer/customer_main_view.dart';
import '../provider/provider_main_view.dart';

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
  final _professionController = TextEditingController(text: 'مقدم خدمة فنية');

  String _selectedRole = 'customer'; // 'customer' or 'provider'

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  void _onRegisterPressed(BuildContext context) async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final profession = _professionController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
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
      profession: _selectedRole == 'provider' ? profession : null,
    );

    if (success && mounted) {
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
      ),
      body: SafeArea(
        child: Consumer<AuthController>(
          builder: (context, auth, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'اختر نوع الحساب في مِهَن',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = 'customer'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'customer' ? AppTheme.primary : AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedRole == 'customer' ? AppTheme.primary : AppTheme.border,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  color: _selectedRole == 'customer' ? Colors.white : AppTheme.textSecondary,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'عميل مستفيد',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedRole == 'customer' ? Colors.white : AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = 'provider'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'provider' ? AppTheme.secondary : AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedRole == 'provider' ? AppTheme.secondary : AppTheme.border,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.handyman_outlined,
                                  color: _selectedRole == 'provider' ? Colors.white : AppTheme.textSecondary,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'مقدم خدمة فنية',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedRole == 'provider' ? Colors.white : AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (auth.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                      ),
                      child: Text(
                        auth.errorMessage!,
                        style: const TextStyle(color: AppTheme.error, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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

                  if (_selectedRole == 'provider') ...[
                    CustomTextField(
                      label: 'المهنة أو التخصص',
                      hint: 'مثال: فني سباكة، كهربائي منازل، تكييف',
                      controller: _professionController,
                      prefixIcon: Icons.build_outlined,
                    ),
                    const SizedBox(height: 14),
                  ],

                  CustomTextField(
                    label: 'كلمة المرور',
                    hint: '8 أحرف أو أرقام على الأقل',
                    controller: _passwordController,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: _selectedRole == 'customer' ? 'إنشاء حساب عميل' : 'إنشاء حساب مقدم خدمة',
                    isLoading: auth.isLoading,
                    onPressed: () => _onRegisterPressed(context),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('لديك حساب بالفعل؟ ', style: TextStyle(color: AppTheme.textSecondary)),
                      GestureDetector(
                        onTap: () {
                          auth.clearError();
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'سجل دخولك',
                          style: TextStyle(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.bold,
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
}
