import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/sector_model.dart';

class SectorService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Sector>> fetchSectors() async {
    try {
      final response = await _client
          .from('rabt_sectors')
          .select()
          .order('code', ascending: true);

      if (response.isEmpty) {
        throw Exception('No sectors found');
      }

      return response.map<Sector>((data) => Sector.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to load sectors: $e');
    }
  }
}
