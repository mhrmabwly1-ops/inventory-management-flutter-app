import 'package:flutter/foundation.dart';
import '../database_helper.dart';

class SettingsService extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Map<String, dynamic> _settings = {};
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic> get settings => _settings;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSettings() async {
    try {
      _settings = await _dbHelper.getSystemSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ خطأ في جلب الإعدادات: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    if (_isInitialized || _isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await loadSettings();
      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    _isInitialized = false;
    await initialize();
  }

  String getString(String key, {String defaultValue = ''}) {
    return _settings[key]?.toString() ?? defaultValue;
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    final value = _settings[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  bool getBool(String key, {bool defaultValue = false}) {
    final value = _settings[key];
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true';
    return defaultValue;
  }

  Future<Map<String, dynamic>> setSetting(String key, dynamic value) async {
    try {
      await _dbHelper.setSystemSetting(key, value);
      _settings[key] = value;
      notifyListeners();
      return {'success': true, 'isValid': true};
    } catch (e) {
      return {
        'success': false,
        'isValid': false,
        'error': e.toString(),
        'errorMessage': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> resetAllSettings() async {
    try {
      await _dbHelper.resetSystemSettings();
      await loadSettings();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> clearAllData() async {
    try {
      await _dbHelper.clearAllData();
      _settings.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ خطأ في مسح البيانات: $e');
      rethrow;
    }
  }
}