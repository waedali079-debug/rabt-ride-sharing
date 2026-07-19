import 'package:flutter/material.dart';
import 'package:rabt_app/features/sectors/data/sector_service.dart';
import 'package:rabt_app/features/sectors/domain/sector_model.dart';

class LandingHubScreen extends StatefulWidget {
  const LandingHubScreen({Key? key}) : super(key: key);

  @override
  State<LandingHubScreen> createState() => _LandingHubScreenState();
}

class _LandingHubScreenState extends State<LandingHubScreen> {
  final SectorService _sectorService = SectorService();
  late Future<List<Sector>> _sectorsFuture;

  @override
  void initState() {
    super.initState();
    _sectorsFuture = _sectorService.fetchSectors();
  }

  int _getCrossAxisCount(double width) {
    if (width >= 1200) return 5;
    if (width >= 600) return 4;
    return 3;
  }

  double _getCardSize(double width, int crossAxisCount) {
    double spacing = 20.0;
    double padding = 32.0;
    return (width - padding - (spacing * (crossAxisCount - 1))) / crossAxisCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر خدمتك'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<List<Sector>>(
          future: _sectorsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Text('حدث خطأ في تحميل القطاعات: ${snapshot.error}'),
              );
            }

            final sectors = snapshot.data!;

            return LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
                final cardSize = _getCardSize(constraints.maxWidth, crossAxisCount);

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSmartSuggestion(context),
                        const SizedBox(height: 32),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: sectors.length,
                          itemBuilder: (context, index) {
                            final sector = sectors[index];
                            return _SectorCard(
                              sector: sector,
                              size: cardSize,
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSmartSuggestion(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb, color: Theme.of(context).primaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('اقتراح ذكي', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'بناءً على وقت اليوم، ننصح بطلب خدمة الركاب',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Theme.of(context).primaryColor, size: 16),
        ],
      ),
    );
  }
}

class _SectorCard extends StatelessWidget {
  final Sector sector;
  final double size;

  const _SectorCard({Key? key, required this.sector, required this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم اختيار: ${sector.nameAr}')),
        );
      },
      borderRadius: BorderRadius.circular(20.0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: sector.color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: sector.color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: sector.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(sector.icon, color: sector.color, size: 28.0),
            ),
            const SizedBox(height: 8.0),
            Text(
              sector.nameAr,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2.0),
            Text(
              sector.code,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 10.0,
                color: sector.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
