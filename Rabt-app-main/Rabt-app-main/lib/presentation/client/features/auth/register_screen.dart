import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/rabt_button.dart';
import '../../../../shared/widgets/rabt_input.dart';
import '../../../../core/constants/design_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../shared/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      role: 'CUSTOMER', // Default role; driver registration to be added
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('إنشاء حساب', style: theme.textTheme.headlineMedium),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(RabtDesignConstants.spaceLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: RabtDesignConstants.spaceXl),
                // Error message
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.error != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: RabtDesignConstants.spaceMd),
                        child: Container(
                          padding: const EdgeInsets.all(RabtDesignConstants.spaceMd),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: theme.colorScheme.error),
                              const SizedBox(width: 8),
                              Expanded(child: Text(auth.error!, style: TextStyle(color: theme.colorScheme.onErrorContainer))),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                RabtInput(
                  label: 'الاسم الكامل',
                  hintText: 'أدخل اسمك الكامل',
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.person),
                  validator: Validators.validateName,
                ),
                const SizedBox(height: RabtDesignConstants.spaceLg),
                RabtInput(
                  label: 'رقم الهاتف',
                  hintText: '+9627XXXXXXXX',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone),
                  validator: Validators.validatePhone,
                ),
                const SizedBox(height: RabtDesignConstants.spaceLg),
                RabtInput(
                  label: 'كلمة المرور',
                  hintText: '6 أحرف على الأقل',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: RabtDesignConstants.spaceXl),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return RabtButton(
                      type: RabtButtonType.primary,
                      label: auth.isLoading ? 'جاري إنشاء الحساب...' : 'إنشاء حساب',
                      onPressed: auth.isLoading ? null : _handleRegister,
                      width: double.infinity,
                    );
                  },
                ),
                const SizedBox(height: RabtDesignConstants.spaceMd),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('لديك حساب بالفعل؟ تسجيل الدخول'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
