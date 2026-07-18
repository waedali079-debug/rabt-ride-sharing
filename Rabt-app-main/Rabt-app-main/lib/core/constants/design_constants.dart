class RabtDesignConstants {
  // الألوان الأساسية
  static const int primaryLight = 0xFF1E3A8A;
  static const int primaryDark = 0xFF60A5FA;
  static const int accessibleLight = 0xFF1E40AF;
  static const int accessibleDark = 0xFF93C5FD;
  static const int dangerLight = 0xFFDC2626;
  static const int dangerDark = 0xFFFCA5A5;
  static const int successLight = 0xFF059669;
  static const int successDark = 0xFF6EE7B7;
  static const int warningLight = 0xFFD97706;
  static const int warningDark = 0xFFFCD34D;
  static const int bgPrimaryLight = 0xFFFFFFFF;
  static const int bgPrimaryDark = 0xFF0A0A0A;
  static const int bgSurfaceLight = 0xFFFFFFFF;
  static const int bgSurfaceDark = 0xFF171717;
  static const int textPrimaryLight = 0xFF0A0A0A;
  static const int textPrimaryDark = 0xFFFAFAFA;
  static const int textSecondaryLight = 0xFF52525B;
  static const int textSecondaryDark = 0xFFA1A1AA;

  // ألوان القطاعات
  static const Map<String, int> sectorColors = {
    'S-01': 0xFF3B82F6, // ركاب
    'S-02': 0xFFF97316, // غاز
    'S-03': 0xFF06B6D4, // مياه
    'S-04': 0xFF8B5CF6, // شحن صغير
    'S-05': 0xFF10B981, // شاحنات
    'S-06': 0xFFEF4444, // ونشات
    'S-07': 0xFFF59E0B, // آليات
    'S-08': 0xFF6366F1, // شحن كبير
    'S-09': 0xFFEC4899, // خدمات خاصة
  };

  // المسافات
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 20.0;
  static const double spaceXl = 32.0;
  static const double space2xl = 52.0;
  static const double space3xl = 84.0;
  static const double space4xl = 136.0;

  // أحجام الأيقونات
  static const double iconStatus = 16.0;
  static const double iconInternal = 20.0;
  static const double iconNav = 24.0;
  static const double iconAction = 28.0;
  static const double iconWarning = 32.0;
  static const double iconSector = 48.0;

  // أحجام الأزرار
  static const double buttonHeightPrimary = 56.0;
  static const double buttonHeightSecondary = 48.0;
  static const double buttonHeightGhost = 40.0;
  static const double buttonHeightVoice = 72.0;
  static const double buttonFabSize = 64.0;
  static const double buttonIconRoundSize = 48.0;

  // أنصاف الأقطار
  static const double radiusCapsule = 28.0;
  static const double radiusMd = 12.0;
  static const double radiusSm = 8.0;
  static const double radiusRound = 24.0;
  static const double radiusFab = 32.0;
}
