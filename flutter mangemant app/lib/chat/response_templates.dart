/// قوالب الردود المتنوعة والمحسنة
class EnhancedResponseTemplates {
  /// قوالب ردود المنتجات
  static final List<String> productStockTemplates = [
    '''
📦 **مخزون المنتج: {name}**

🔢 **الكمية المتاحة:** {quantity} {unit}
📊 **الحد الأدنى المطلوب:** {minLevel} {unit}
🏷️ **حالة المخزون:** {status}

{advice}
''',
    '''
🛒 **تقرير المخزون**

**المنتج:** {name}
**المتوفر حالياً:** {quantity} {unit}
**المستوى المطلوب:** {minLevel} {unit}
**التقييم:** {status}

{advice}
''',
    '''
✅ **مخزون آمن**

**{name}**
• الكمية: {quantity} {unit}
• الحد الأدنى: {minLevel} {unit}
• الحالة: {status}

{advice}
''',
    '''
📊 **تحليل المخزون**

اسم المنتج: {name}
الكمية الحالية: {quantity} {unit}
الحد الأدنى: {minLevel} {unit}
التقييم: {status}

{advice}
'''
  ];

  /// قوالب ردود المنتجات المنخفضة
  static final List<String> lowStockTemplates = [
    '''
⚠️ **المنتجات المنخفضة المخزون:**

{products_list}

📈 **إجمالي المنتجات المنخفضة:** {count} منتج
💡 **التوصية:** يوصى بإعادة تخزين هذه المنتجات قريباً.
''',
    '''
🔻 **قائمة المنتجات التي تحتاج لإعادة تخزين:**

{products_list}

📊 **العدد:** {count} منتج تحت الحد الأدنى
🚨 **الأولوية:** {priority_count} منتج يحتاج إجراء عاجل
''',
    '''
📉 **منتجات قاربت على النفاد:**

{products_list}

🔢 **المجموع:** {count} منتج
⏰ **مستوى الخطورة:** {risk_level}
'''
  ];

  /// توليد رد بناءً على السياق
  static String generateResponse(
      String templateType,
      Map<String, dynamic> data,
      String context
      ) {
    final templates = _getTemplatesByType(templateType);
    final selectedTemplate = _selectTemplate(templates, context);

    return _fillTemplate(selectedTemplate, data);
  }

  /// الحصول على القوالب حسب النوع
  static List<String> _getTemplatesByType(String type) {
    switch (type) {
      case 'product_stock':
        return productStockTemplates;
      case 'low_stock':
        return lowStockTemplates;
      default:
        return ['''📝 **الرد:** {message}'''];
    }
  }

  /// اختيار القالب المناسب بناءً على السياق
  static String _selectTemplate(List<String> templates, String context) {
    if (templates.isEmpty) return '⚠️ **لا يوجد قالب متاح**';

    // اختيار عشوائي مع مراعاة السياق
    final hash = context.hashCode.abs();
    final index = hash % templates.length;

    return templates[index];
  }

  /// تعبئة القالب بالبيانات
  static String _fillTemplate(String template, Map<String, dynamic> data) {
    String result = template;

    data.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });

    return result;
  }

  /// نصائح بناءً على حالة المخزون
  static Map<String, String> stockAdvice = {
    'critical': '🚨 **حرج:** يحتاج لإعادة طلب فورية!',
    'low': '⚠️ **منخفض:** يوصى بإعادة التخزين خلال 48 ساعة.',
    'medium': '🟡 **متوسط:** المخزون في مستوى مقبول، مراقبة مستمرة مطلوبة.',
    'good': '✅ **جيد:** المخزون في مستوى آمن، متابعة روتينية كافية.',
    'excellent': '🏆 **ممتاز:** المخزون في أفضل مستوى، لا يحتاج إجراء.'
  };

  /// تحديد مستوى الخطورة
  static String determineRiskLevel(int quantity, int minLevel) {
    if (quantity <= 0) return 'critical';
    if (quantity <= minLevel) return 'low';
    if (quantity <= minLevel * 2) return 'medium';
    if (quantity <= minLevel * 3) return 'good';
    return 'excellent';
  }
}