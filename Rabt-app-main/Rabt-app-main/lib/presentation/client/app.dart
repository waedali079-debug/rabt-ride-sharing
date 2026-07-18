import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/rabt_theme.dart';
import '../../data/datasources/api_service.dart';
import '../../data/datasources/websocket_datasource.dart';
import '../shared/providers/trip_provider.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/sector_provider.dart';
import 'features/auth/welcome_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/home/sectors_hub_screen.dart';
import 'features/home/home_screen.dart';
import 'features/sectors/sector_request_screen.dart';
import 'features/trips/trip_searching_screen.dart';
import 'features/trips/trip_tracking_screen.dart';
import 'features/trips/trip_payment_screen.dart';
import 'features/trips/trip_history_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/settings_screen.dart';
import 'features/profile/notifications_screen.dart';

class RabtClientApp extends StatefulWidget {
  const RabtClientApp({super.key});

  @override
  State<RabtClientApp> createState() => _RabtClientAppState();
}

class _RabtClientAppState extends State<RabtClientApp> {
  late final ApiService _apiService;
  late final WebSocketDataSource _wsDataSource;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _wsDataSource = WebSocketDataSource();

    // Attempt to restore auth session on startup
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    // Will be handled by AuthProvider after first build
    // through the restoreSession method called in welcome_screen
  }

  @override
  void dispose() {
    _apiService.dispose();
    _wsDataSource.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(_apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => TripProvider(_apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => SectorProvider(_apiService),
        ),
        // WebSocket is not a ChangeNotifier but needs to be accessible
        // via the widget tree for screens that need real-time updates.
        Provider<WebSocketDataSource>.value(value: _wsDataSource),
      ],
      child: MaterialApp(
        title: 'Rabt - العميل',
        theme: RabtTheme.lightTheme(),
        darkTheme: RabtTheme.darkTheme(),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/sectors-hub': (context) => const SectorsHubScreen(),
          '/home': (context) => const HomeScreen(),
          '/sector-request': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return SectorRequestScreen(sectorId: args['sectorId'] as String);
          },
          '/trip-searching': (context) => const TripSearchingScreen(),
          '/trip-tracking': (context) => const TripTrackingScreen(),
          '/trip-payment': (context) => const TripPaymentScreen(),
          '/trip-history': (context) => const TripHistoryScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/notifications': (context) => const NotificationsScreen(),
        },
      ),
    );
  }
}
