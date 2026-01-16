// lib/models/settings_model.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';

class AppSettings extends ChangeNotifier {
  String _language = 'ar';
  String get language => _language;

  Future<void> setLanguage(String value) async {
    if (_language != value) {
      _language = value;
      notifyListeners();
      await _saveToStorage();
    }
  }

  String _theme = 'light';
  String get theme => _theme;

  Future<void> setTheme(String value) async {
    if (_theme != value) {
      _theme = value;
      notifyListeners();
      await _saveToStorage();
    }
  }

  String _currency = 'SAR';
  String get currency => _currency;

  Future<void> setCurrency(String value) async {
    if (_currency != value) {
      _currency = value;
      notifyListeners();
      await _saveToStorage();
    }
  }

  bool _showPrices = true;
  bool get showPrices => _showPrices;

  Future<void> setShowPrices(bool value) async {
    if (_showPrices != value) {
      _showPrices = value;
      notifyListeners();
      await _saveToStorage();
    }
  }

  bool _showProfit = true;
  bool get showProfit => _showProfit;

  Future<void> setShowProfit(bool value) async {
    if (_showProfit != value) {
      _showProfit = value;
      notifyListeners();
      await _saveToStorage();
    }
  }

  bool _enableTax = true;
  bool get enableTax => _enableTax;

  Future<void> setEnableTax(bool value) async {
    if (_enableTax != value) {
      _enableTax = value;
      notifyListeners();
      await _saveToStorage();
    }
  }

  bool _enableDiscount = true;
  bool get enableDiscount => _enableDiscount;

  Future<void> setEnableDiscount(bool value) async {
    if (_enableDiscount != value) {
      _enableDiscount = value;
      notifyListeners();
      await _saveToStorage();
    }
  }

  String _dateFormat = 'dd/MM/yyyy';
  String get dateFormat => _dateFormat;

  Future<void> setDateFormat(String value) async {
    if (_dateFormat != value) {
      _dateFormat = value;
      notifyListeners();
      await _saveToStorage();
    }
  }

  int _decimalPlaces = 2;
  int get decimalPlaces => _decimalPlaces;

  Future<void> setDecimalPlaces(int value) async {
    if (_decimalPlaces != value) {
      _decimalPlaces = value;
      notifyListeners();
      await _saveToStorage();
    }
  }

  bool _notifications = true;
  bool get notifications => _notifications;

  Future<void> setNotifications(bool value) async {
    if (_notifications != value) {
      _notifications = value;
      notifyListeners();
      await _saveToStorage();
    }
  }

  // تنسيق العملة
  String formatCurrency(double amount, {int? decimalPlaces}) {
    final decimals = decimalPlaces ?? _decimalPlaces;
    return '${amount.toStringAsFixed(decimals)} $_currency';
  }

  // تنسيق التاريخ
  String formatDate(DateTime date) {
    String formatted = _dateFormat;
    formatted = formatted.replaceAll('yyyy', date.year.toString());
    formatted = formatted.replaceAll('MM', date.month.toString().padLeft(2, '0'));
    formatted = formatted.replaceAll('dd', date.day.toString().padLeft(2, '0'));
    formatted = formatted.replaceAll('hh', date.hour.toString().padLeft(2, '0'));
    formatted = formatted.replaceAll('mm', date.minute.toString().padLeft(2, '0'));
    return formatted;
  }

  // تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'language': _language,
      'theme': _theme,
      'currency': _currency,
      'showPrices': _showPrices,
      'showProfit': _showProfit,
      'enableTax': _enableTax,
      'enableDiscount': _enableDiscount,
      'dateFormat': _dateFormat,
      'decimalPlaces': _decimalPlaces,
      'notifications': _notifications,
    };
  }

  // تحميل من Map
  Future<void> loadFromMap(Map<String, dynamic> map) async {
    _language = map['language'] ?? 'ar';
    _theme = map['theme'] ?? 'light';
    _currency = map['currency'] ?? 'SAR';
    _showPrices = map['showPrices'] ?? true;
    _showProfit = map['showProfit'] ?? true;
    _enableTax = map['enableTax'] ?? true;
    _enableDiscount = map['enableDiscount'] ?? true;
    _dateFormat = map['dateFormat'] ?? 'dd/MM/yyyy';
    _decimalPlaces = map['decimalPlaces'] ?? 2;
    _notifications = map['notifications'] ?? true;
    notifyListeners();
  }

  // حفظ في التخزين
  Future<void> _saveToStorage() async {
    try {
      final map = toMap();
      final json = jsonEncode(map);
      // في الواقع، هنا ستستخدم SharedPreferences
      print('تم حفظ الإعدادات: $json');
    } catch (e) {
      print('خطأ في حفظ الإعدادات: $e');
    }
  }

  // إعادة التعيين
  Future<void> reset() async {
    _language = 'ar';
    _theme = 'light';
    _currency = 'SAR';
    _showPrices = true;
    _showProfit = true;
    _enableTax = true;
    _enableDiscount = true;
    _dateFormat = 'dd/MM/yyyy';
    _decimalPlaces = 2;
    _notifications = true;
    notifyListeners();
    await _saveToStorage();
  }

  static AppSettings? fromMap(Map<String, dynamic> settingsMap) {}
}