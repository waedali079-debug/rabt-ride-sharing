import 'package:flutter/material.dart';
import '../../../../shared/widgets/sector_card.dart';
import '../../../../core/constants/design_constants.dart';
import '../../../../core/constants/icons.dart';

class SectorsHubScreen extends StatelessWidget {
  const SectorsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('اختر خدمتك', style: theme.textTheme.headlineMedium),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(RabtDesignConstants.spaceLg),
        child: _buildSectorsGrid(context),
      ),
    );
  }

  Widget _buildSectorsGrid(BuildContext context) {
    final sectors = [
      _SectorItem('S-01', 'ركاب', 'سفر آمن ومريح', RabtIcons.passenger),
      _SectorItem('S-02', 'غاز', 'توصيل الغاز بسرعة', RabtIcons.gas),
      _SectorItem('S-03', 'مياه', 'توصيل المياه النقية', RabtIcons.water),
      _SectorItem('S-04', 'شحن صغير', 'طرود صغيرة بدقة', RabtIcons.cargo),
      _SectorItem('S-05', 'شاحنات', 'نقل البضائع الثقيلة', RabtIcons.trucks),
      _SectorItem('S-06', 'ونشات', 'الإنقاذ والمساعدة', RabtIcons.wrecker),
      _SectorItem('S-07', 'آليات', 'معدات البناء', RabtIcons.heavy),
      _SectorItem('S-08', 'شحن كبير', 'لوجستيات متكاملة', RabtIcons.large),
      _SectorItem('S-09', 'خدمات خاصة', 'حلول مخصصة', RabtIcons.special),
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: RabtDesignConstants.spaceMd,
        mainAxisSpacing: RabtDesignConstants.spaceMd,
        childAspectRatio: 0.9,
      ),
      itemCount: sectors.length,
      itemBuilder: (context, index) {
        final sector = sectors[index];
        return SectorCard(
          sectorId: sector.id,
          title: sector.title,
          subtitle: sector.subtitle,
          iconPath: sector.iconPath,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/sector-request',
              arguments: {'sectorId': sector.id},
            );
          },
        );
      },
    );
  }
}

class _SectorItem {
  final String id;
  final String title;
  final String subtitle;
  final String iconPath;

  _SectorItem(this.id, this.title, this.subtitle, this.iconPath);
}
