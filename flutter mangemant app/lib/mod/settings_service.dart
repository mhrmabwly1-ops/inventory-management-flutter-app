// services/settings_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';


import '../database_helper.dart';
import 'app_settings_model.dart';

class SettingsService with ChangeNotifier {
  final DatabaseHelper _dbHelper;
  Map<String, AppSettingsModel> _settings = {};
  Map<String, AppSettingsModel> _advancedSettings = {};
  Map<String, AppSettingsModel> _barcodeSettings = {};
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  final StreamController<Map<String, AppSettingsModel>> _settingsController =
  StreamController.broadcast();

  SettingsService(this._dbHelper);

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, AppSettingsModel> get settings => Map.unmodifiable(_settings);
  Map<String, AppSettingsModel> get advancedSettings => Map.unmodifiable(_advancedSettings);
  Map<String, AppSettingsModel> get barcodeSettings => Map.unmodifiable(_barcodeSettings);
  Stream<Map<String, AppSettingsModel>> get settingsStream => _settingsController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _loadAllSettings();
      _isInitialized = true;
      _error = null;
      _settingsController.add(_settings);
    } catch (e) {
      _error = 'فشل في تحميل الإعدادات: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAllSettings() async {
    try {
      final allSettings = await _dbHelper.getAllSettings();

      final Map<String, AppSettingsModel> settings = {};
      final Map<String, AppSettingsModel> advanced = {};
      final Map<String, AppSettingsModel> barcode = {};

      for (final row in allSettings) {
        try {
          final model = AppSettingsModel.fromMap(row);
          final category = model.category;

          if (category == 'advanced') {
            advanced[model.settingKey] = model;
          } else if (category == 'barcode') {
            barcode[model.settingKey] = model;
          } else {
            settings[model.settingKey] = model;
          }
        } catch (e) {
          debugPrint('خطأ في تحويل إعداد: $e');
        }
      }

      _settings = settings;
      _advancedSettings = advanced;
      _barcodeSettings = barcode;
    } catch (e) {
      debugPrint('خطأ في تحميل الإعدادات: $e');
      rethrow;
    }
  }

  AppSettingsModel? getSetting(String key) {
    return _settings[key] ?? _advancedSettings[key] ?? _barcodeSettings[key];
  }

  String getString(String key, {String defaultValue = ''}) {
    final setting = getSetting(key);
    if (setting == null) return defaultValue;

    final value = setting.typedValue;
    if (value is String) return value;
    return value.toString();
  }

  int getInt(String key, {int defaultValue = 0}) {
    final setting = getSetting(key);
    if (setting == null) return defaultValue;

    final value = setting.typedValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    final setting = getSetting(key);
    if (setting == null) return defaultValue;

    final value = setting.typedValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? defaultValue;
  }

  bool getBool(String key, {bool defaultValue = false}) {
    final setting = getSetting(key);
    if (setting == null) return defaultValue;

    final value = setting.typedValue;
    if (value is bool) return value;
    final str = value.toString().toLowerCase();
    return str == 'true' || str == '1';
  }

  Future<ValidationResult> setSetting(String key, dynamic value) async {
    final setting = getSetting(key);
    if (setting == null) {
      // إنشاء إعداد جديد
      return await _createNewSetting(key, value);
    }

    if (setting.isReadonly) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'هذا الإعداد للقراءة فقط',
      );
    }

    // التحقق من الصحة
    final validationResult = SettingValidator.validate(setting, value);
    if (!validationResult.isValid) {
      return validationResult;
    }

    // التحويل للنوع المناسب
    final String stringValue;
    if (value is bool) {
      stringValue = value ? '1' : '0';
    } else if (value is List<String>) {
      stringValue = jsonEncode(value);
    } else if (value is Map<String, dynamic>) {
      stringValue = jsonEncode(value);
    } else {
      stringValue = value.toString();
    }

    _isLoading = true;
    notifyListeners();

    try {
      // حفظ في قاعدة البيانات
      final result = await _dbHelper.setSetting(key, stringValue);

      if (result['success'] as bool) {
        // تحديث النموذج المحلي
        final updatedSetting = setting.copyWith(settingValue: stringValue);
        _updateSettingInMemory(updatedSetting);

        _error = null;
        notifyListeners();
        _settingsController.add(_settings);
        return ValidationResult(isValid: true);
      } else {
        return ValidationResult(
          isValid: false,
          errorMessage: result['error'] as String? ?? 'فشل في الحفظ',
        );
      }
    } catch (e) {
      _error = 'خطأ في تحديث الإعداد: $e';
      return ValidationResult(
        isValid: false,
        errorMessage: _error,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ValidationResult> _createNewSetting(String key, dynamic value) async {
    final stringValue = value.toString();

    try {
      final result = await _dbHelper.setSetting(key, stringValue);

      if (result['success'] as bool) {
        // تحميل الإعداد الجديد
        await _loadAllSettings();
        notifyListeners();
        _settingsController.add(_settings);
        return ValidationResult(isValid: true);
      } else {
        return ValidationResult(
          isValid: false,
          errorMessage: result['error'] as String? ?? 'فشل في إنشاء الإعداد',
        );
      }
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'خطأ في إنشاء الإعداد: $e',
      );
    }
  }

  void _updateSettingInMemory(AppSettingsModel setting) {
    final category = setting.category;

    if (category == 'advanced') {
      _advancedSettings[setting.settingKey] = setting;
    } else if (category == 'barcode') {
      _barcodeSettings[setting.settingKey] = setting;
    } else {
      _settings[setting.settingKey] = setting;
    }
  }

  Future<void> setAdvanced(String key, dynamic value) async {
    // البحث في الإعدادات المتقدمة أولاً
    var setting = _advancedSettings[key];
    if (setting == null) {
      // البحث في جميع الإعدادات
      setting = getSetting(key);
    }

    if (setting == null) {
      throw Exception('الإعداد المتقدم غير موجود: $key');
    }

    await setSetting(key, value);
  }

  Future<void> setBarcodeSettings(Map<String, dynamic> settings) async {
    for (final entry in settings.entries) {
      await setSetting(entry.key, entry.value);
    }

    // إعادة تحميل إعدادات الباركود
    final allSettings = await _dbHelper.getAllSettings();
    for (final row in allSettings) {
      final model = AppSettingsModel.fromMap(row);
      if (model.category == 'barcode') {
        _barcodeSettings[model.settingKey] = model;
      }
    }

    notifyListeners();
  }

  Future<void> reload() async {
    await _loadAllSettings();
    notifyListeners();
    _settingsController.add(_settings);
  }

  Future<Map<String, dynamic>> exportSettings({String? category}) async {
    try {
      return await _dbHelper.exportSettings(category: category);
    } catch (e) {
      throw Exception('فشل في تصدير الإعدادات: $e');
    }
  }

  Future<Map<String, dynamic>> importSettings(String jsonData, int userId) async {
    try {
      return await _dbHelper.importSettings(jsonData, userId);
    } catch (e) {
      throw Exception('فشل في استيراد الإعدادات: $e');
    }
  }

  Future<Map<String, dynamic>> resetSettingToDefault(String key) async {
    try {
      final result = await _dbHelper.resetSettingToDefault(key);
      if (result['success'] as bool) {
        await _loadAllSettings();
        notifyListeners();
        _settingsController.add(_settings);
      }
      return result;
    } catch (e) {
      return {'success': false, 'error': 'فشل في الاستعادة: $e'};
    }
  }

  Future<Map<String, dynamic>> resetAllSettings() async {
    try {
      final result = await _dbHelper.resetAllSettings();
      if (result['success'] as bool) {
        await _loadAllSettings();
        notifyListeners();
        _settingsController.add(_settings);
      }
      return result;
    } catch (e) {
      return {'success': false, 'error': 'فشل في استعادة جميع الإعدادات: $e'};
    }
  }

  List<AppSettingsModel> getSettingsByCategory(String category) {
    final allSettings = {..._settings, ..._advancedSettings, ..._barcodeSettings};
    return allSettings.values
        .where((setting) => setting.category == category)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  List<AppSettingsModel> getSettingsByCategoryAndGroup(String category, String groupName) {
    final allSettings = {..._settings, ..._advancedSettings, ..._barcodeSettings};
    return allSettings.values
        .where((setting) => setting.category == category && setting.groupName == groupName)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  @override
  void dispose() {
    _settingsController.close();
    super.dispose();
  }
}