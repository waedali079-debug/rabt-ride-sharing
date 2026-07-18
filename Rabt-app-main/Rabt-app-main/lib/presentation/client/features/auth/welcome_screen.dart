import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/rabt_button.dart';
import '../../../../core/constants/design_constants.dart';
import '../../../shared/providers/auth_provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final auth = context.read<AuthProvider>();
    final restored = await auth.tryRestoreSession();
    if (restored && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(RabtDesignConstants.spaceLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(RabtDesignConstants.primaryLight),
                      const Color(RabtDesignConstants.accessibleLight),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: RabtDesignConstants.spaceXl),
              Text(
                'Rabt',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: RabtDesignConstants.spaceMd),
              Text(
                'منصة النقل الذكية لجميع احتياجاتك',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              RabtButton(
                type: RabtButtonType.primary,
                label: 'تسجيل الدخول',
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                width: double.infinity,
              ),
              const SizedBox(height: RabtDesignConstants.spaceMd),
              RabtButton(
                type: RabtButtonType.secondary,
                label: 'إنشاء حساب جديد',
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                width: double.infinity,
              ),
              const SizedBox(height: RabtDesignConstants.spaceSm),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/sectors-hub');
                },
                child: const Text('استكشاف التطبيق'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
