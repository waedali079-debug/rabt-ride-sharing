import 'package:flutter/material.dart';
import '../../../../shared/widgets/rabt_button.dart';
import '../../../../shared/widgets/rabt_input.dart';
import '../../../../shared/widgets/rating_widget.dart';
import '../../../../core/constants/design_constants.dart';

class TripPaymentScreen extends StatelessWidget {
  const TripPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('الدفع والتقييم', style: theme.textTheme.headlineMedium),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(RabtDesignConstants.spaceLg),
        child: Column(
          children: [
            // تفاصيل الرحلة
            Card(
              child: Padding(
                padding: const EdgeInsets.all(RabtDesignConstants.spaceLg),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المسافة'),
                        Text('12.5 كم', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: RabtDesignConstants.spaceSm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('المدة'),
                        Text('18 دقيقة', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: RabtDesignConstants.spaceSm),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('السعر'),
                        Text(
                          '45.00 ر.س',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: RabtDesignConstants.spaceLg),
            Text('كيف كانت تجربتك؟', style: theme.textTheme.titleMedium),
            const SizedBox(height: RabtDesignConstants.spaceMd),
            const RatingWidget(),
            const SizedBox(height: RabtDesignConstants.spaceLg),
            RabtInput(
              label: 'ملاحظات إضافية',
              hintText: 'شاركنا بتجربتك...',
              keyboardType: TextInputType.multiline,
            ),
            const Spacer(),
            RabtButton(
              type: RabtButtonType.primary,
              label: 'تأكيد الدفع والتقييم',
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
