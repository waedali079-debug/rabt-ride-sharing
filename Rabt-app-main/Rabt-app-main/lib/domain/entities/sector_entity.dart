class SectorEntity {
  final int id;
  final String sectorId; // S-01, S-02, etc.
  final String name;
  final String description;
  final String iconPath;
  final bool isActive;
  final double searchRadiusM;

  SectorEntity({
    required this.id,
    required this.sectorId,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.isActive,
    required this.searchRadiusM,
  });

  SectorEntity copyWith({
    int? id,
    String? sectorId,
    String? name,
    String? description,
    String? iconPath,
    bool? isActive,
    double? searchRadiusM,
  }) {
    return SectorEntity(
      id: id ?? this.id,
      sectorId: sectorId ?? this.sectorId,
      name: name ?? this.name,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      isActive: isActive ?? this.isActive,
      searchRadiusM: searchRadiusM ?? this.searchRadiusM,
    );
  }

  static const Map<String, String> sectorNames = {
    'S-01': 'ركاب',
    'S-02': 'غاز',
    'S-03': 'مياه',
    'S-04': 'شحن صغير',
    'S-05': 'شاحنات',
    'S-06': 'ونشات',
    'S-07': 'آليات ثقيلة',
    'S-08': 'شحن كبير',
    'S-09': 'خدمات خاصة',
  };
}
