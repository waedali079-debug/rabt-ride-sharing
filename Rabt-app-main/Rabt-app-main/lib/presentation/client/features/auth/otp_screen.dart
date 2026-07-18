import 'package:flutter/material.dart';
import '../../../../shared/widgets/rabt_button.dart';
import '../../../../shared/widgets/rabt_input.dart';
import '../../../../core/constants/design_constants.dart';

class OtpScreen extends StatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() {
    // TODO: ربط مع API التحقق من OTP
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('تأكيد الرقم', style: theme.textTheme.headlineMedium),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(RabtDesignConstants.spaceLg),
          child: Column(
            children: [
              const SizedBox(height: RabtDesignConstants.spaceXl),
              Icon(
                Icons.sms,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: RabtDesignConstants.spaceLg),
              Text(
                'تم إرسال رمز التأكيد إلى',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: RabtDesignConstants.spaceSm),
              Text(
                widget.phone,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: RabtDesignConstants.spaceXl),
              RabtInput(
                label: 'رمز التأكيد',
                hintText: 'أدخل الرمز المكون من 6 أرقام',
                controller: _otpController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              const SizedBox(height: RabtDesignConstants.spaceXl),
              RabtButton(
                type: RabtButtonType.primary,
                label: 'تأكيد',
                onPressed: _verifyOtp,
              ),
              const SizedBox(height: RabtDesignConstants.spaceLg),
              TextButton(
                onPressed: () {
                  // TODO: إعادة إرسال OTP
                },
                child: const Text('إعادة إرسال الرمز'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
