import 'package:flutter/material.dart';

class AppColors {
  /* --------------------------------------------------------------------------
   * Material Color للون الأخضر الأساسي
   * -------------------------------------------------------------------------- */

  static const MaterialColor primarySwatch = MaterialColor(
    0xFF2E7D32,
    {
      50: Color(0xFFE8F5E9),
      100: Color(0xFFC8E6C9),
      200: Color(0xFFA5D6A7),
      300: Color(0xFF81C784),
      400: Color(0xFF66BB6A),
      500: Color(0xFF4CAF50),
      600: Color(0xFF43A047),
      700: Color(0xFF388E3C),
      800: Color(0xFF2E7D32),
      900: Color(0xFF1B5E20),
    },
  );

  /* --------------------------------------------------------------------------
   * ألوان الهوية (ثابتة)
   * -------------------------------------------------------------------------- */

  static const Color primary = Color(0xFF2E7D32); // أخضر الهوية (من Swatch 800)
  static const Color primaryLight = Color(0xFF66BB6A); // أخضر فاتح (من Swatch 400)
  static const Color primaryDark = Color(0xFF1B5E20); // أخضر غامق (من Swatch 900)

  static const Color purple = Color(0xFF6C63FF);
  static const Color orange = Color(0xFFFF9800);
  static const Color red = Color(0xFFF44336);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color deepPurple = Color(0xFF9C27B0);
  static const Color pink = Color(0xFFE91E63);
  static const Color brown = Color(0xFF795548);
  static const Color blueGrey = Color(0xFF607D8B);
  static const Color indigo = Color(0xFF3F51B5);

  /* --------------------------------------------------------------------------
   * ألوان متكيفة مع الثيم (Light / Dark)
   * -------------------------------------------------------------------------- */

  /// خلفية التطبيق العامة
  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F5F5);
  }

  /// خلفية الكروت
  static Color card(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
  }

  /// لون النص الأساسي
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF212121);
  }

  /// لون النص الثانوي
  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFB0B0B0)
        : const Color(0xFF666666);
  }

  /// لون الفواصل
  static Color divider(BuildContext context) {
    return Theme.of(context).dividerColor;
  }

  /* --------------------------------------------------------------------------
   * ألوان متقدمة مربوطة بـ ThemeData
   * -------------------------------------------------------------------------- */

  /// اللون الأساسي المتكيف (يستخدم في معظم الأماكن)
  static Color primaryAdaptive(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryLight // أخضر أفتح في الداكن
        : primary;
  }

  /// لون التمييز أو التركيز (للأزرار المهمة)
  static Color accent(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.deepPurple[300]!
        : deepPurple;
  }

  /// لون النجاح
  static Color success(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.green[300]!
        : Colors.green[700]!;
  }

  /// لون التحذير
  static Color warning(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.orange[300]!
        : orange;
  }

  /// لون الخطأ
  static Color error(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.red[300]!
        : red;
  }

  /// لون المعلومات
  static Color info(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.blue[300]!
        : Colors.blue[700]!;
  }
}