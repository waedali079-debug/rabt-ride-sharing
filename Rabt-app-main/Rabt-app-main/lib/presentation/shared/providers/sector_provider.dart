import 'package:flutter/foundation.dart';
import '../../../data/models/sector_model.dart';
import '../../../data/datasources/api_service.dart';
import '../../../core/constants/api_config.dart';
import '../../../domain/entities/sector_entity.dart';
import '../../../core/constants/icons.dart';

/// SectorProvider handles sector listing and selection.
/// On init (or refresh) it fetches from API, with a static fallback.
class SectorProvider with ChangeNotifier {
  final ApiService _api;
  List<SectorEntity> _sectors = [];
  SectorEntity? _selectedSector;
  bool _isLoading = false;
  String? _error;

  SectorProvider(this._api);

  List<SectorEntity> get sectors => _sectors;
  SectorEntity? get selectedSector => _selectedSector;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch sectors from API. Falls back to static list on failure.
  Future<void> fetchSectors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getList(ApiConfig.sectors);
      _sectors = data.map((json) {
        final model = SectorModel.fromJson(json as Map<String, dynamic>);
        return model.toEntity();
      }).toList();
    } catch (e) {
      // API unavailable — use static sector list
      debugPrint('Sectors API unavailable, using fallback: $e');
      _sectors = _staticSectors();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Select a sector for the current request.
  void selectSector(SectorEntity sector) {
    _selectedSector = sector;
    notifyListeners();
  }

  void clearSelection() {
    _selectedSector = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Static fallback — matches the 9 sectors in the database.
  static List<SectorEntity> _staticSectors() {
    const names = [
      'ركاب', 'غاز', 'مياه', 'شحن صغير',
      'شاحنات', 'ونشات', 'آليات ثقيلة', 'شحن كبير', 'خاص',
    ];
    const descriptions = [
      'نقل الركاب بين المدن وداخلها',
      'نقل الغاز المنزلي والتجاري',
      'نقل وتوزيع المياه',
      'خدمات الشحن الصغير والبضائع',
      'نقل البضائع بالشاحنات',
      'خدمات الونش والإنقاذ',
      'تأجير الآليات الثقيلة',
      'نقل وشحن البضائع الكبيرة',
      'خدمات نقل خاصة',
    ];

    return List.generate(9, (i) {
      final id = i + 1;
      final sid = 'S-${id.toString().padLeft(2, '0')}';
      return SectorEntity(
        id: id,
        sectorId: sid,
        name: names[i],
        description: descriptions[i],
        iconPath: _staticIcon(sid),
        isActive: true,
        searchRadiusM: _staticRadius(id),
      );
    });
  }

  static double _staticRadius(int id) {
    return [5000, 10000, 5000, 15000, 20000, 20000, 25000, 30000, 5000][id - 1];
  }

  static String _staticIcon(String sid) {
    const map = {
      'S-01': RabtIcons.passenger,
      'S-02': RabtIcons.gas,
      'S-03': RabtIcons.water,
      'S-04': RabtIcons.cargo,
      'S-05': RabtIcons.trucks,
      'S-06': RabtIcons.wrecker,
      'S-07': RabtIcons.heavy,
      'S-08': RabtIcons.large,
      'S-09': RabtIcons.special,
    };
    return map[sid] ?? RabtIcons.passenger;
  }
}
