// screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';


class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'مرحباً بك في عالم إدارة المخزون الذكي',
      description: 'نظام متكامل لإدارة مخزونك بكل كفاءة واحترافية',
      animation: 'assets/animations/welcome.json',
      color: Color(0xFF4361EE),
      icon: Icons.store,
    ),
    OnboardingPage(
      title: 'تتبع المنتجات بذكاء',
      description: 'راقب حركة المنتجات من وإلى المخزون بكل دقة',
      animation: 'assets/animations/inventory.json',
      color: Color(0xFF3A0CA3),
      icon: Icons.inventory,
    ),
    OnboardingPage(
      title: 'تقارير وتحليلات متقدمة',
      description: 'احصل على تقارير شاملة تساعدك في اتخاذ القرارات',
      animation: 'assets/animations/analytics.json',
      color: Color(0xFF7209B7),
      icon: Icons.analytics,
    ),
    OnboardingPage(
      title: 'متابعة العملاء والموردين',
      description: 'إدارة متكاملة لعلاقاتك مع العملاء والموردين',
      animation: 'assets/animations/customers.json',
      color: Color(0xFFF72585),
      icon: Icons.people,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pages[_currentPage].color,
      body: Stack(
        children: [
          // خلفية متحركة
          AnimatedContainer(
            duration: Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _pages[_currentPage].color,
                  _pages[_currentPage].color.withOpacity(0.8),
                  Colors.black.withOpacity(0.1),
                ],
              ),
            ),
          ),

          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return OnboardingPageWidget(
                page: _pages[index],
                isActive: index == _currentPage,
              );
            },
          ),

          // مؤشر الصفحات
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                    (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentPage ? 30 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _currentPage ? Colors.white : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // أزرار التنقل
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // زر التخطي
                if (_currentPage < _pages.length - 1)
                  ElevatedButton(
                    onPressed: () {
                      _completeOnboarding();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Row(
                      children: [
                        Text('تخطي'),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ).animate().shake(delay: 2000.ms, hz: 2),

                // زر التالي/البدء
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _completeOnboarding();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _pages[_currentPage].color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    elevation: 10,
                    shadowColor: Colors.black.withOpacity(0.3),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _currentPage == _pages.length - 1 ? 'ابدأ الآن' : 'التالي',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        _currentPage == _pages.length - 1 ? Icons.rocket_launch : Icons.arrow_forward,
                        size: 20,
                      ),
                    ],
                  ),
                ).animate().scale(delay: 1000.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    // حفظ حالة الانتهاء من Onboarding
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    // الانتقال إلى شاشة تسجيل الدخول
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String animation;
  final Color color;
  final IconData icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.animation,
    required this.color,
    required this.icon,
  });
}

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;
  final bool isActive;

  const OnboardingPageWidget({
    required this.page,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // أنيميشن Lottie
          Container(
            width: 300,
            height: 300,
            child:Lottie.asset(
              page.animation,
              animate: isActive,
            )

          )
              .animate(target: isActive ? 1 : 0)
              .scale(duration: 500.ms),

          SizedBox(height: 40),

          // الأيقونة
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 40,
              color: Colors.white,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .rotate(duration: 1000.ms),

          SizedBox(height: 30),

          // العنوان
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              page.title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 200.ms, duration: 800.ms),

          SizedBox(height: 20),

          // الوصف
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              page.description,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 400.ms, duration: 800.ms),
        ],
      ),
    );
  }
}
