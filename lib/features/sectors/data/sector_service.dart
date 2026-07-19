import 'package:rabt/core/services/api_client.dart';
import '../domain/sector_model.dart';

class SectorService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Sector>> fetchSectors() async {
    try {
      final response = await _apiClient.get('/v1/sectors');

      if (response.statusCode == 200 && response.data is List) {
        return response.data.map<Sector>((data) => Sector.fromMap(data)).toList();
      }
      throw Exception('No sectors found');
    } catch (e) {
      throw Exception('Failed to load sectors: $e');
    }
  }
}
