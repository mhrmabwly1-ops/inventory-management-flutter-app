// lib/providers/app_provider.dart
import 'package:flutter/material.dart';
import 'package:untitled43/model/settings_model.dart';


class AppProvider with ChangeNotifier {
  AppSettings _settings = AppSettings();
  AppSettings get settings => _settings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _currentRoute = '/';
  String get currentRoute => _currentRoute;

  // تحميل الإعدادات
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      // محاكاة تحميل الإعدادات (في الواقع من SharedPreferences)
      await Future.delayed(Duration(milliseconds: 500));

      // مثال: إعدادات مسبقة
      final sampleSettings = {
        'language': 'ar',
        'theme': 'light',
        'currency': 'SAR',
        'showPrices': true,
        'showProfit': true,
        'enableTax': true,
        'enableDiscount': true,
        'dateFormat': 'dd/MM/yyyy',
        'decimalPlaces': 2,
        'notifications': true,
      };

      await _settings.loadFromMap(sampleSettings);
    } catch (e) {
      print('خطأ في تحميل الإعدادات: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // تحديث المسار الحالي
  void updateRoute(String route) {
    _currentRoute = route;
    notifyListeners();
  }

  // إعادة تعيين الإعدادات
  Future<void> resetSettings() async {
    await _settings.reset();
    notifyListeners();
  }
}