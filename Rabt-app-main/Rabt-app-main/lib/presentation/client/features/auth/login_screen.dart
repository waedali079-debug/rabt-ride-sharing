import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/rabt_button.dart';
import '../../../../shared/widgets/rabt_input.dart';
import '../../../../core/constants/design_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../shared/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _phoneController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    }
    // Error is shown via auth.error
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('تسجيل الدخول', style: theme.textTheme.headlineMedium),
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
                  hintText: 'أدخل كلمة المرور',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: RabtDesignConstants.spaceLg),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return RabtButton(
                      type: RabtButtonType.primary,
                      label: auth.isLoading ? 'جاري تسجيل الدخول...' : 'تسجيل الدخول',
                      onPressed: auth.isLoading ? null : _handleLogin,
                      width: double.infinity,
                    );
                  },
                ),
                const SizedBox(height: RabtDesignConstants.spaceMd),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/register');
                  },
                  child: const Text('ليس لديك حساب؟ إنشاء حساب جديد'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
