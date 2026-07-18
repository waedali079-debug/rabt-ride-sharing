import 'package:flutter/material.dart';
import '../../../../shared/widgets/rabt_button.dart';
import '../../../../shared/widgets/rabt_input.dart';
import '../../../../core/constants/design_constants.dart';

class SectorRequestScreen extends StatelessWidget {
  final String sectorId;

  const SectorRequestScreen({
    super.key,
    required this.sectorId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectorColor = Color(RabtDesignConstants.sectorColors[sectorId] ?? RabtDesignConstants.primaryLight);

    return Scaffold(
      appBar: AppBar(
        title: Text('طلب خدمة', style: theme.textTheme.headlineMedium),
        backgroundColor: sectorColor.withOpacity(0.1),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(RabtDesignConstants.spaceLg),
        child: Column(
          children: [
            RabtInput(
              label: 'موقع الالتقاط',
              hintText: 'أدخل عنوان الالتقاط',
              prefixIcon: Icon(Icons.location_on, color: sectorColor),
            ),
            const SizedBox(height: RabtDesignConstants.spaceMd),
            RabtInput(
              label: 'موقع الوصول',
              hintText: 'أدخل عنوان الوصول',
              prefixIcon: Icon(Icons.place, color: sectorColor),
            ),
            const SizedBox(height: RabtDesignConstants.spaceMd),
            RabtInput(
              label: 'ملاحظات إضافية',
              hintText: 'أدخل أي ملاحظات',
              keyboardType: TextInputType.multiline,
            ),
            const Spacer(),
            RabtButton(
              type: RabtButtonType.primarySector,
              sectorId: sectorId,
              label: 'طلب الخدمة',
              onPressed: () {
                Navigator.pushNamed(context, '/trip-searching');
              },
            ),
          ],
        ),
      ),
    );
  }
}
