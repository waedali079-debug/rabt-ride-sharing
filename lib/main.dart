import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rabt/core/services/auth_service.dart';
import 'package:rabt/features/auth/presentation/phone_input_screen.dart';
import 'package:rabt/features/sectors/presentation/landing_hub_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize auth service (loads saved token)
  final authService = AuthService();
  await authService.init();
  
  runApp(RabtApp(authService: authService));
}

class RabtApp extends StatelessWidget {
  final AuthService authService;

  const RabtApp({Key? key, required this.authService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ربط - Rabt',
      debugShowCheckedModeBanner: false,
      theme: _buildRabtTheme(Brightness.light),
      darkTheme: _buildRabtTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: _buildHomeScreen(authService),
    );
  }

  ThemeData _buildRabtTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    final Color primary = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A);
    final Color bgPrimary = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFFFFFF);
    final Color bgSurface = isDark ? const Color(0xFF171717) : const Color(0xFFFFFFFF);
    final Color textPrimary = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0A0A0A);
    final Color textSecondary = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B);

    return ThemeData(
      brightness: brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: bgPrimary,
      cardColor: bgSurface,
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: textPrimary, height: 1.1),
        displayMedium: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: textPrimary, height: 1.125),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: textPrimary, height: 1.17),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: textPrimary, height: 1.22),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: textPrimary, height: 1.31),
        bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: textSecondary, height: 1.31),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white, height: 1.33),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: textSecondary.withOpacity(0.3), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: primary, width: 2)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w500),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bgSurface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildHomeScreen(AuthService authService) {
    if (!authService.isAuthenticated) {
      return const WelcomeScreen();
    }

    final role = authService.currentUser?['role'] ?? 'customer';

    if (role == 'driver') {
      return const DriverDashboardScreen();
    } else if (role == 'admin' || role == 'super_admin') {
      return const AdminPlaceholderScreen();
    } else {
      return const LandingHubScreen();
    }
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(24.0)),
                child: const Center(child: Text('ربط', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(height: 32),
              Text('مرحباً بك في ربط', style: Theme.of(context).textTheme.displayMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('المنصة الأولى التي تربطك بكل ما تحتاجه', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              const Spacer(flex: 3),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const PhoneInputScreen(),
                      ));
                    },
                    child: const Text('تسجيل الدخول'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const PhoneInputScreen(),
                      ));
                    },
                    child: const Text('إنشاء حساب جديد'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const LandingHubScreen(),
                  ));
                },
                child: Text('تصفح كزائر', style: TextStyle(color: Theme.of(context).primaryColor)),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class DriverDashboardScreen extends StatelessWidget {
  const DriverDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة السائق')),
      body: const Center(
        child: Text('قريباً: لوحة تحكم السائق'),
      ),
    );
  }
}

class AdminPlaceholderScreen extends StatelessWidget {
  const AdminPlaceholderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة تحكم المسؤول')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'SCR-401: قيد التطوير',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'لا يمكن للأدمن طلب رحلات من هنا.\nلوحة التحكم الإدارية قيد الإعداد.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
