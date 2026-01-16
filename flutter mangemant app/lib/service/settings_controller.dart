// service/settings_controller.dart
import 'package:flutter/material.dart';
import '../database_helper.dart';

class SettingsController with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // حالة التحميل
  bool _isLoading = false;

  // الإعدادات العامة
  Map<String, dynamic> _settings = {};
  Map<String, dynamic> _advancedSettings = {};

  // صلاحيات المستخدم
  Map<String, bool> _userPermissions = {};

  // حالة الثيم واللغة
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('ar', 'SA');

  // Getters
  bool get isLoading => _isLoading;
  Map<String, dynamic> get settings => _settings;
  Map<String, dynamic> get advancedSettings => _advancedSettings;
  Map<String, bool> get userPermissions => _userPermissions;
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // تهيئة قاعدة البيانات
      await _dbHelper.initializeDatabase();

      // تحميل جميع الإعدادات
      await _loadAllSettings();

      // تحميل صلاحيات المستخدم (افتراضياً المستخدم رقم 1)
      await _loadUserPermissions(1);

      // تطبيق إعدادات الثيم واللغة
      _applyThemeSettings();
      _applyLanguageSettings();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _loadAllSettings() async {
    try {
      // جلب الإعدادات العامة
      final settingsList = await _dbHelper.getAllSettings();
      _settings = _convertListToMap(settingsList, 'setting_key', 'setting_value');

      // جلب الإعدادات المتقدمة
      final advancedList = await _dbHelper.getAllAdvancedSettings();
      _advancedSettings = _convertListToMap(advancedList, 'setting_key', 'setting_value');

    } catch (e) {
      // استخدام القيم الافتراضية في حالة الخطأ
      _setDefaultSettings();
      throw Exception('فشل في تحميل الإعدادات: $e');
    }
  }

  Map<String, dynamic> _convertListToMap(List<Map<String, dynamic>> list, String keyField, String valueField) {
    final Map<String, dynamic> result = {};
    for (var item in list) {
      if (item[keyField] != null) {
        result[item[keyField].toString()] = item[valueField];
      }
    }
    return result;
  }

  Future<void> _loadUserPermissions(int userId) async {
    try {
      final permissions = await _dbHelper.getUserPermissions(userId);
      _userPermissions.clear();

      for (var perm in permissions) {
        if (perm['permission_key'] != null) {
          _userPermissions[perm['permission_key'].toString()] = perm['granted'] == 1;
        }
      }
    } catch (e) {
      // صلاحيات افتراضية
      _setDefaultPermissions();
    }
  }

  void _setDefaultSettings() {
    _settings = {
      'company_name': 'نظام إدارة المخزون',
      'default_currency': 'ريال',
      'default_tax_rate': '15.0',
      'enable_notifications': 'true',
    };

    _advancedSettings = {
      'app_theme': 'فاتح',
      'app_language': 'العربية',
      'track_serial_numbers': 'false',
      'track_expiry_dates': 'false',
      'auto_print_invoice': 'false',
      'email_reports': 'false',
    };
  }

  void _setDefaultPermissions() {
    _userPermissions = {
      'view_dashboard': true,
      'manage_products': true,
      'manage_sales': true,
      'manage_purchases': true,
      'manage_customers': true,
      'manage_suppliers': true,
      'manage_reports': true,
      'manage_settings': true,
      'manage_users': true,
      'dangerous_operations': false, // للمسؤولين فقط
    };
  }

  Future<void> updateSetting(String key, dynamic value) async {
    try {
      // التحقق من الصلاحية
      if (!hasPermission('manage_settings')) {
        throw Exception('ليس لديك صلاحية لتعديل الإعدادات');
      }

      // حفظ في قاعدة البيانات
      await _dbHelper.updateSetting(key as int, value);

      // تحديث في الذاكرة
      _settings[key] = value.toString();

      notifyListeners();
    } catch (e) {
      throw Exception('فشل في تحديث الإعداد: $e');
    }
  }

  Future<void> updateAdvancedSetting(String key, dynamic value) async {
    try {
      // التحقق من الصلاحية
      if (!hasPermission('manage_settings')) {
        throw Exception('ليس لديك صلاحية لتعديل الإعدادات المتقدمة');
      }

      // حفظ في قاعدة البيانات
      await _dbHelper.updateAdvancedSetting(key, value);

      // تحديث في الذاكرة
      _advancedSettings[key] = value.toString();

      // إذا كان الإعداد متعلقاً بالمظهر أو اللغة
      if (key == 'app_theme') {
        _applyThemeSettings();
      } else if (key == 'app_language') {
        _applyLanguageSettings();
      }

      notifyListeners();
    } catch (e) {
      throw Exception('فشل في تحديث الإعداد المتقدم: $e');
    }
  }

  void _applyThemeSettings() {
    final theme = _advancedSettings['app_theme'] ?? 'فاتح';

    switch (theme) {
      case 'داكن':
        _themeMode = ThemeMode.dark;
        break;
      case 'تلقائي بالنظام':
        _themeMode = ThemeMode.system;
        break;
      default:
        _themeMode = ThemeMode.light;
    }
  }

  void _applyLanguageSettings() {
    final language = _advancedSettings['app_language'] ?? 'العربية';

    switch (language) {
      case 'English':
        _locale = const Locale('en', 'US');
        break;
      case 'Français':
        _locale = const Locale('fr', 'FR');
        break;
      case 'Español':
        _locale = const Locale('es', 'ES');
        break;
      default:
        _locale = const Locale('ar', 'SA');
    }
  }

  // دالة مساعدة للصلاحيات
  bool hasPermission(String permissionKey) {
    return _userPermissions[permissionKey] ?? false;
  }

  // دالة مساعدة للإعدادات
  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settings[key] ?? defaultValue;
  }

  dynamic getAdvancedSetting(String key, {dynamic defaultValue}) {
    return _advancedSettings[key] ?? defaultValue;
  }

  // دالة لقراءة الإعدادات من قاعدة البيانات مباشرة (للتحديث)
  Future<void> refreshSettings() async {
    await _loadAllSettings();
    notifyListeners();
  }

  // دالة للحفظ الجميع للإعدادات
  Future<void> saveAllSettings({
    required Map<String, dynamic> generalSettings,
    required Map<String, dynamic> advancedSettings,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // حفظ الإعدادات العامة
      for (var entry in generalSettings.entries) {
        await _dbHelper.updateSetting(entry.key as int, entry.value);
        _settings[entry.key] = entry.value.toString();
      }

      // حفظ الإعدادات المتقدمة
      for (var entry in advancedSettings.entries) {
        await _dbHelper.updateAdvancedSetting(entry.key, entry.value);
        _advancedSettings[entry.key] = entry.value.toString();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('فشل في حفظ الإعدادات: $e');
    }
  }
}