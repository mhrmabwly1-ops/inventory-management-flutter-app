import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:untitled43/screens/Onboarding.dart';
import 'package:untitled43/widgets/theme_manager.dart';
import 'color.dart';
import 'l10n/app_localizations.dart';
import 'screens/login_screen.dart';
import 'service/settings_service.dart';
 // استيراد شاشات التعريف الجديدة

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsService()..loadSettings(),
        ),
        // 🔹 أي Services ثانية تضيفها هنا مستقبلاً
      ],
      child: const InventoryApp(),
    ),
  );
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, _) {
        return MaterialApp(
          title: 'نظام إدارة المخزون المتكامل',
          debugShowCheckedModeBanner: false,
          themeMode: currentTheme,

          // 🔹 إضافة دعم الترجمة
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('ar', ''), // العربية
            Locale('en', ''), // الإنجليزية
          ],
          locale: Locale('ar'), // اللغة الافتراضية

          // 🌞 الوضع الفاتح
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: AppColors.primarySwatch,
            primaryColor: AppColors.primary,
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: AppColors.primarySwatch,
              accentColor: AppColors.deepPurple,
              cardColor: Colors.white,
              backgroundColor: const Color(0xFFF5F5F5),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            cardColor: Colors.white,
            dividerColor: Colors.grey[300],
            fontFamily: 'Cairo',
            // إضافة أنيميشن جديدة للوضع الفاتح
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),

          // 🌙 الوضع الداكن
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: AppColors.primarySwatch,
            primaryColor: AppColors.primaryLight,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryLight,
              secondary: AppColors.deepPurple,
              surface: Color(0xFF1E1E1E),
              background: Color(0xFF121212),
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            dividerColor: Colors.grey,
            fontFamily: 'Cairo',
            // إضافة أنيميشن جديدة للوضع الداكن
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),

          // 🚀 توجيه المستخدم إلى الشاشة المناسبة
          home: FutureBuilder<bool>(
            future: _checkFirstLaunch(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // عرض شاشة Splash أثناء الانتظار
                return SplashScreen();
              } else {
                final bool isFirstLaunch = snapshot.data ?? true;
                if (isFirstLaunch) {
                  return OnboardingScreen();
                } else {
                  return LoginScreen();
                }
              }
            },
          ),
        );
      },
    );
  }

  // 🔍 دالة للتحقق مما إذا كانت هذه أول مرة لتشغيل التطبيق
  Future<bool> _checkFirstLaunch() async {
    // يمكن استخدام SharedPreferences هنا لتخزين الحالة
    await Future.delayed(Duration(seconds: 2)); // تأخير محاكاة للتحقق

    // هنا يمكنك التحقق من SharedPreferences
    // bool hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    // return !hasSeenOnboarding;

    return true; // مؤقتاً، نرجع true حتى تظهر شاشات Onboarding
  }
}

// 🎬 شاشة Splash مع أنيميشن مذهلة
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Color(0xFF121212)
          : Color(0xFF0A2463),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔥 أيقونة التطبيق مع تأثير ثلاثي الأبعاد
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.deepPurple,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.inventory_2,
                size: 80,
                color: Colors.white,
              ),
            )
                .animate()
                .scale(duration: 1500.ms, curve: Curves.elasticOut)
                .shake(hz: 2, duration: 1000.ms),

            SizedBox(height: 30),

            // 📱 اسم التطبيق مع أنيميشن
            Column(
              children: [
                Text(
                  'نظام إدارة المخزون',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 1000.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

                Text(
                  'الإصدار الاحترافي',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Cairo',
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 1000.ms),
              ],
            ),

            SizedBox(height: 50),

            // 🔄 مؤشر تحميل متحرك
            Container(
              width: 200,
              height: 4,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                minHeight: 4,
              ),
            )
                .animate()
                .scaleX(delay: 1500.ms, duration: 2000.ms, begin: 0, end: 1),

            SizedBox(height: 20),

            // ⚡ رسالة تحميل
            Text(
              'جاري تحميل النظام...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontFamily: 'Cairo',
              ),
            )
                .animate()
                .fadeIn(delay: 2000.ms, duration: 500.ms)
                .blur(begin: Offset(10, 0), end: Offset(0, 0)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}