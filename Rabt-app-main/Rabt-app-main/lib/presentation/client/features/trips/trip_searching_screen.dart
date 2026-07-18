import 'package:flutter/material.dart';
import '../../../../shared/widgets/rabt_button.dart';
import '../../../../core/constants/design_constants.dart';

class TripSearchingScreen extends StatelessWidget {
  const TripSearchingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('البحث عن سائق', style: theme.textTheme.headlineMedium),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              strokeWidth: 3,
            ),
            const SizedBox(height: RabtDesignConstants.spaceLg),
            Text(
              'جاري البحث عن سائق مناسب...',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: RabtDesignConstants.spaceMd),
            Text(
              'قد تستغرق العملية بضع دقائق',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: RabtDesignConstants.spaceXl),
            RabtButton(
              type: RabtButtonType.secondary,
              label: 'إلغاء الطلب',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
