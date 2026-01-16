// theme_manager.dart
import 'package:flutter/material.dart';

/// متغير عام للتحكم بالثيم
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

/// تحويل النص إلى ThemeMode
ThemeMode mapStringToThemeMode(String themeString) {
  switch (themeString) {
    case 'فاتح':
      return ThemeMode.light;
    case 'داكن':
      return ThemeMode.dark;
    case 'تلقائي بالنظام':
    default:
      return ThemeMode.system;
  }
}

/// تحويل ThemeMode إلى نص
String themeModeToString(ThemeMode themeMode) {
  switch (themeMode) {
    case ThemeMode.light:
      return 'فاتح';
    case ThemeMode.dark:
      return 'داكن';
    case ThemeMode.system:
    default:
      return 'تلقائي بالنظام';
  }
}