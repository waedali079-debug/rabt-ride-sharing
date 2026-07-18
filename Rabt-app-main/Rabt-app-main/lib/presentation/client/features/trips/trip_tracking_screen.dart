import 'package:flutter/material.dart';
import '../../../../shared/widgets/rabt_button.dart';
import '../../../../core/constants/design_constants.dart';

class TripTrackingScreen extends StatelessWidget {
  const TripTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('تتبع الرحلة', style: theme.textTheme.headlineMedium),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(RabtDesignConstants.spaceLg),
        child: Column(
          children: [
            // خريطة التتبع
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
              ),
              child: Center(
                child: Icon(
                  Icons.map,
                  size: 60,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ),
            const SizedBox(height: RabtDesignConstants.spaceLg),
            // معلومات السائق
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              title: Text('السائق', style: theme.textTheme.titleMedium),
              subtitle: Text(
                '4.8 ⭐ • جاري التحميل...',
                style: theme.textTheme.bodyMedium,
              ),
              trailing: RabtButton(
                type: RabtButtonType.iconRound,
                icon: Icon(Icons.phone, color: theme.colorScheme.primary),
                onPressed: () {
                  // TODO: الاتصال بالسائق
                },
              ),
            ),
            const Spacer(),
            RabtButton(
              type: RabtButtonType.primary,
              label: 'تم الوصول',
              onPressed: () {
                Navigator.pushNamed(context, '/trip-payment');
              },
            ),
          ],
        ),
      ),
    );
  }
}
