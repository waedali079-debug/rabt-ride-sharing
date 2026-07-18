class ApiConfig {
  // غيّر هذا الرابط إلى رابط الخادم الفعلي
  static const String baseUrl = 'http://localhost:8080';
  static const String apiPrefix = '/api/v1';

  // Auth endpoints
  static const String register = '$apiPrefix/auth/register';
  static const String login = '$apiPrefix/auth/login';

  // Profile endpoints
  static const String profile = '$apiPrefix/profile';

  // Trips endpoints
  static const String trips = '$apiPrefix/trips';
  static String tripById(String id) => '$trips/$id';
  static String tripAccept(String id) => '$trips/$id/accept';
  static String tripComplete(String id) => '$trips/$id/complete';
  static String tripCancel(String id) => '$trips/$id/cancel';
  static String tripRate(String id) => '$trips/$id/rate';

  // Sectors endpoints
  static const String sectors = '$apiPrefix/sectors';
  static const String sectorStats = '$apiPrefix/sectors/stats';

  // Notifications
  static const String notifications = '$apiPrefix/notifications';
  static String notificationRead(String id) => '$notifications/$id/read';
  static const String notificationReadAll = '$notifications/read-all';
  static const String notificationUnreadCount = '$notifications/unread-count';

  // Customer Wallet (Rabt Cash)
  static const String rabtaCash = '$apiPrefix/rabta-cash';
  static const String rabtaCashRedeem = '$apiPrefix/rabta-cash/redeem';
  static const String rabtaCashPaymentMethods = '$apiPrefix/rabta-cash/payment-methods';
  static String rabtaCashDeleteMethod(String id) => '$rabtaCash/payment-methods/$id';
  static const String rabtaCashTransactions = '$apiPrefix/rabta-cash/transactions';

  // Driver Wallet
  static const String wallet = '$apiPrefix/wallet';
  static const String walletTopUp = '$apiPrefix/wallet/top-up';
  static const String walletTransactions = '$apiPrefix/wallet/transactions';

  // Navigation endpoints
  static const String navigationLocation = '$apiPrefix/navigation/location';
  static const String navigationStatus = '$apiPrefix/navigation/status';
  static const String navigationStream = '$apiPrefix/navigation/stream';
  static const String locationShare = '$apiPrefix/location/share';

  // Disputes
  static const String disputes = '$apiPrefix/disputes';

  // AI Assistant
  static const String aiChat = '$apiPrefix/ai/chat';

  // Rabt Tree
  static const String rabtTree = '$apiPrefix/rabt-tree';

  // WebSocket
  static const String wsUrl = 'ws://localhost:8080/api/v1/ws';
}
