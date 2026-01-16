import 'dart:convert';

/// معالج النصوص المتقدم للغة العربية
/// يقوم بتنظيف النص المدخل قبل تحليل النوايا
class ArabicTextPreprocessor {
  // قوائم كلمات الحشو الشائعة (تم توسيعها)
  static final Map<String, List<String>> _stopWords = {
    'ar': [
      'لو', 'سمحت', 'ممكن', 'هل', 'ابغى', 'عايز', 'اريد', 'انا', 'انت', 'هو',
      'هي', 'هم', 'نحن', 'انتم', 'ان', 'في', 'من', 'الى', 'على', 'عن',
      'حتى', 'قد', 'سوف', 'كان', 'يكون', 'ما', 'لم', 'لا', 'إن', 'أن',
      'ب', 'ك', 'ل', 'و', 'ف', 'ثم', 'أو', 'أم', 'بل', 'لكن', 'حتى',
      'إذا', 'لأن', 'مهما', 'حيثما', 'كيفما', 'متى', 'أينما', 'أيا',
      'كل', 'بعض', 'أي', 'ذلك', 'هذا', 'تلك', 'هذه', 'هؤلاء',
      'أولئك', 'هنا', 'هناك', 'أين', 'متى', 'كيف', 'كم', 'أية',
      'أيها', 'أيتها', 'يا', 'أ', 'فإن', 'والذي', 'الذي', 'التي', 'ذين',
      'اللاتي', 'اللائي', 'اللواتي', 'ذلك', 'هذه', 'هذا', 'هؤلاء', 'هنا',
      'هناك', 'أين', 'متى', 'كيف', 'كم', 'أية', 'أيها', 'أيتها',
      'برجاء', 'من فضلك', 'رجاء', 'ماهو', 'ماهي', 'ماذا', 'هل يوجد',
      'عندك', 'لديك', 'عندي', 'لدي', 'بخصوص', 'عن', 'حول', 'برضو', 'كمان',
      'ازاى', 'ايه', 'ليه', 'مين', 'امتى', 'ايه', 'اللى', 'دى', 'ده',
      'دول', 'ديه', 'دوه', 'عشان', 'علشان', 'مش', 'ماشي', 'تمام', 'طيب',
      'يا ريت', 'بدي', 'عمر', 'تبقى', 'يعني', 'يا جماعة', 'يا جمعه',
      'و الله', 'والله', 'بس', 'خلاص', 'مثلا', 'يعني', 'مثل', 'مثلًا',
      'او', 'اوكي', 'ok', 'okay', 'plz', 'please', 'شكرا', 'شكراً',
      'مرحبا', 'مرحباً', 'السلام', 'عليكم', 'السلام عليكم', 'هلا', 'هلا والله'
    ],
  };

  // قائمة المرادفات الشائعة (تم توسيعها)
  static final Map<String, Map<String, List<String>>> _synonyms = {
    'ar': {
      'كم': ['كيف', 'ما مقدار', 'ما حجم', 'ما هو', 'عدد', 'عد', 'قد ايه', 'كام'],
      'كمية': ['مقدار', 'حجم', 'عدد', 'رقم', 'عد', 'قد ايه', 'كام'],
      'متبقي': ['باقي', 'متبقي', 'متبقى', 'المتبقي', 'اللي فاضل', 'فاضل'],
      'المخزون': ['الرصيد', 'المخزن', 'الكمية', 'الجرد', 'المتوفر', 'الموجود'],
      'منتج': ['سلعة', 'بضاعة', 'مادة', 'صنف', 'مستلزم', 'ايه', 'حاجة', 'شيء'],
      'عرض': ['اظهار', 'عطني', 'أعطني', 'ارني', 'أرني', 'ابعت', 'ارسل', 'وريني', 'ورينى'],
      'بيانات': ['معلومات', 'تفاصيل', 'مواصفات', 'خصائص', 'حاجات', 'أشياء'],
      'سعر': ['ثمن', 'تكلفة', 'قيمة', 'مبلغ', 'السعر', 'الثمن'],
      'ربح': ['مكسب', 'ربحية', 'عائد', 'منفعة', 'ربحه', 'مكسبه'],
      'جميع': ['كل', 'كامل', 'مختلف', 'كافة', 'أي', 'اى', 'اي', 'ايه'],
      'اخر': ['أحدث', 'جديد', 'متأخر', 'أخير', 'الاخير', 'اخر حاجة'],
      'عملاء': ['زبائن', 'زبون', 'عميل', 'العملاء', 'الزبائن', 'الزبون', 'زبائن'],
      'مبيعات': ['بيع', 'المبيعات', 'البايع', 'البيع', 'المبيع', 'بيع'],
      'فواتير': ['فاتورة', 'الفواتير', 'فاتوره', 'فايتورة', 'فايتوره'],
      'مخازن': ['مخزن', 'مستودع', 'المخازن', 'المستودعات', 'مستودعات', 'المخزن'],
      'صلاحيات': ['صلاحية', 'دور', 'ادوار', 'صلاحيه', 'صلاحيات', 'صلاحيه'],
      'مستخدمين': ['مستخدم', 'موظف', 'المستخدمين', 'الموظفين', 'موظفين', 'مستخدم'],
      'يوم': ['اليوم', 'هذا اليوم', 'الحالي', 'الان', 'الآن', 'دلوقتي', 'دلوقت'],
      'اسبوع': ['أسبوع', 'أسبوعي', 'اخر اسبوع', 'خلال اسبوع', 'اسبوع', 'الاسبوع'],
      'شهر': ['شهر', 'شهري', 'اخر شهر', 'خلال شهر', 'هذا الشهر', 'الشهر'],
      'سنة': ['سنة', 'سنوي', 'اخر سنة', 'خلال سنة', 'هذه السنة', 'السنة'],
    },
  };

  /// قائمة المترادفات الخاصة بالعملاء والمبيعات والمخزون
  static final Map<String, List<String>> _specialSynonyms = {
    'customer': ['عميل', 'زبون', 'عميلنا', 'زبائن', 'العملاء', 'الزبائن'],
    'sale': ['بيع', 'مبيع', 'مبيعات', 'بيع', 'المبيعات'],
    'invoice': ['فاتورة', 'فايتورة', 'فايتوره', 'فاتوره', 'الفواتير'],
    'warehouse': ['مخزن', 'مستودع', 'مخازن', 'مستودعات', 'المخزن', 'المستودع'],
    'user': ['مستخدم', 'موظف', 'المستخدمين', 'الموظفين'],
    'permission': ['صلاحية', 'دور', 'صلاحيات', 'ادوار'],
    'product': ['منتج', 'سلعة', 'بضاعة', 'صنف'],
    'stock': ['مخزون', 'رصيد', 'المخزون', 'الرصيد'],
  };

  /// تنظيف النص المدخل بالكامل
  static String preprocess(String text, {String language = 'ar'}) {
    String result = text;

    // 1. إزالة التشكيل والحركات
    result = _removeDiacritics(result);

    // 2. توحيد الحروف العربية
    result = _normalizeArabic(result);

    // 3. تحويل إلى أحرف صغيرة
    result = result.toLowerCase();

    // 4. إزالة علامات الترقيم والأرقام (في بعض الحالات)
    result = _removePunctuation(result);

    // 5. إزالة كلمات الحشو
    result = _removeStopWords(result, language);

    // 6. استبدال المرادفات العامة
    result = _replaceSynonyms(result, language);

    // 7. استبدال المرادفات الخاصة
    result = _replaceSpecialSynonyms(result);

    // 8. إزالة المسافات الزائدة
    result = _normalizeSpaces(result);

    return result.trim();
  }

  /// إزالة التشكيل والحركات
  static String _removeDiacritics(String text) {
    const Map<String, String> diacriticsMap = {
      'َ': '', 'ً': '', 'ُ': '', 'ٌ': '', 'ِ': '', 'ٍ': '', 'ْ': '', 'ّ': '',
      'ٰ': '', 'ٔ': '', 'ٕ': '', 'ٓ': '', 'ۖ': '', 'ۗ': '', 'ۘ': '', 'ۙ': '',
      'ۚ': '', 'ۛ': '', 'ۜ': '', '۟': '', '۠': '', 'ۡ': '', 'ۢ': '', 'ۣ': '',
      'ۤ': '', 'ۥ': '', 'ۦ': '', 'ۧ': '', 'ۨ': '', '۩': '', '۪': '', '۫': '',
      '۬': '', 'ۭ': '',
    };

    String result = text;
    diacriticsMap.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }

  /// توحيد الحروف العربية (أ، إ، آ → ا)
  static String _normalizeArabic(String text) {
    String result = text;

    // توحيد الهمزات
    result = result.replaceAll('أ', 'ا');
    result = result.replaceAll('إ', 'ا');
    result = result.replaceAll('آ', 'ا');
    result = result.replaceAll('ى', 'ي');
    result = result.replaceAll('ة', 'ه');
    result = result.replaceAll('ؤ', 'و');
    result = result.replaceAll('ئ', 'ي');

    // إزالة التكرار
    result = result.replaceAll('الله', 'الله');
    result = result.replaceAll('اللّه', 'الله');

    // إزالة التاء المربوطة في نهاية الكلمات
    result = result.replaceAll(RegExp(r'ه\b'), 'ه');

    return result;
  }

  /// إزالة علامات الترقيم
  static String _removePunctuation(String text) {
    final punctuation = RegExp(r'[.,،;؛:!?؟()\[\]{}"\`~_\-+=\*\\/|<>@#\$%^&]ّّّّ');
    return text.replaceAll(punctuation, ' ');
  }

  /// إزالة كلمات الحشو
  static String _removeStopWords(String text, String language) {
    final stopWords = _stopWords[language] ?? [];
    String result = text;

    for (final word in stopWords) {
      final pattern = RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false);
      result = result.replaceAll(pattern, ' ');
    }

    return result;
  }

  /// استبدال المرادفات العامة
  static String _replaceSynonyms(String text, String language) {
    final synonyms = _synonyms[language] ?? {};
    String result = text;

    synonyms.forEach((word, synonymsList) {
      for (final synonym in synonymsList) {
        final pattern = RegExp('\\b${RegExp.escape(synonym)}\\b', caseSensitive: false);
        if (pattern.hasMatch(result)) {
          result = result.replaceAll(pattern, word);
        }
      }
    });

    return result;
  }

  /// استبدال المرادفات الخاصة
  static String _replaceSpecialSynonyms(String text) {
    String result = text;

    _specialSynonyms.forEach((key, synonymsList) {
      for (final synonym in synonymsList) {
        final pattern = RegExp('\\b${RegExp.escape(synonym)}\\b', caseSensitive: false);
        if (pattern.hasMatch(result)) {
          // استبدال بالكلمة الإنجليزية الرئيسية لتسهيل التحليل لاحقاً
          result = result.replaceAll(pattern, key);
        }
      }
    });

    return result;
  }

  /// توحيد المسافات
  static String _normalizeSpaces(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// استخراج الأرقام من النص
  static List<int> extractNumbers(String text) {
    final matches = RegExp(r'\d+').allMatches(text);
    return matches.map((match) => int.tryParse(match.group(0) ?? '0') ?? 0).toList();
  }

  /// استخراج الكلمات الرئيسية (المحتوية على أكثر من حرفين)
  static List<String> extractKeywords(String text) {
    return text
        .split(' ')
        .where((word) => word.length > 2)
        .where((word) => !_isCommonWord(word))
        .toList();
  }

  /// التحقق إذا كانت الكلمة شائعة
  static bool _isCommonWord(String word) {
    const commonWords = ['من', 'في', 'على', 'عن', 'مع', 'الى', 'حتى', 'قد', 'ما', 'هو', 'هي', 'كان', 'يكون'];
    return commonWords.contains(word);
  }

  /// استخراج نوع الكيان من النص
  static String extractEntityType(String text) {
    if (text.contains('customer')) return 'customer';
    if (text.contains('sale')) return 'sale';
    if (text.contains('invoice')) return 'invoice';
    if (text.contains('warehouse')) return 'warehouse';
    if (text.contains('user')) return 'user';
    if (text.contains('permission')) return 'permission';
    if (text.contains('product')) return 'product';
    if (text.contains('stock')) return 'stock';
    return 'unknown';
  }
}

/// فئة مساعدة لاستخراج الكيانات من النص
class EntityExtractor {
  /// استخراج اسم المنتج من النص
  static String extractProductName(String text) {
    // قائمة الكلمات الدالة على المنتجات
    final productIndicators = [
      'منتج', 'سلعة', 'بضاعة', 'مادة', 'صنف', 'مستلزم', 'قطعة', 'وحدة',
      'بند', 'مشروع', 'خدمة', 'سلع', 'بضائع', 'مواد', 'أصناف', 'product'
    ];

    // قائمة الكلمات التي يجب إزالتها
    final wordsToRemove = [
      'كم', 'كمية', 'متبقي', 'المخزون', 'الرصيد', 'عرض', 'بيانات',
      'تفاصيل', 'سعر', 'ربح', 'ما', 'هو', 'هي', 'من', 'في', 'على',
      'لل', 'ال', 'كيف', 'ما مقدار', 'ما حجم', 'customer', 'sale',
      'invoice', 'warehouse', 'user', 'permission', 'stock'
    ];

    String processed = text;

    // إزالة المؤشرات والأرقام
    for (final indicator in productIndicators) {
      processed = processed.replaceAll(RegExp('\\b$indicator\\b'), '');
    }

    for (final word in wordsToRemove) {
      processed = processed.replaceAll(RegExp('\\b$word\\b'), '');
    }

    // البحث عن باركود (أرقام فقط)
    final barcodeMatch = RegExp(r'\b\d{8,14}\b').firstMatch(processed);
    if (barcodeMatch != null) {
      return barcodeMatch.group(0)!;
    }

    // البحث عن كود منتج
    final codeMatch = RegExp(r'[A-Za-z]{2,3}\d{3,6}').firstMatch(processed);
    if (codeMatch != null) {
      return codeMatch.group(0)!;
    }

    // استخراج ما تبقى كاسم المنتج (أول 3 كلمات)
    final words = processed.trim().split(' ');
    final filteredWords = words.where((w) => w.length > 1).take(3).toList();

    return filteredWords.join(' ').trim();
  }

  /// استخراج اسم العميل من النص
  static String extractCustomerName(String text) {
    final customerIndicators = ['عميل', 'زبون', 'customer'];
    final wordsToRemove = ['عرض', 'بيانات', 'تفاصيل', 'سجل', 'تسجيل', 'جديد', 'اضافة'];

    String processed = text;

    for (final indicator in customerIndicators) {
      processed = processed.replaceAll(RegExp('\\b$indicator\\b'), '');
    }

    for (final word in wordsToRemove) {
      processed = processed.replaceAll(RegExp('\\b$word\\b'), '');
    }

    final words = processed.trim().split(' ');
    final filteredWords = words.where((w) => w.length > 1).take(2).toList();

    return filteredWords.join(' ').trim();
  }

  /// استخراج اسم المورد من النص
  static String extractSupplierName(String text) {
    final supplierIndicators = ['مورد', 'مزود', 'supplier'];
    final wordsToRemove = ['عرض', 'بيانات', 'تفاصيل', 'سجل'];

    String processed = text;

    for (final indicator in supplierIndicators) {
      processed = processed.replaceAll(RegExp('\\b$indicator\\b'), '');
    }

    for (final word in wordsToRemove) {
      processed = processed.replaceAll(RegExp('\\b$word\\b'), '');
    }

    final words = processed.trim().split(' ');
    final filteredWords = words.where((w) => w.length > 1).take(2).toList();

    return filteredWords.join(' ').trim();
  }

  /// تمييز نوع الاستعلام
  static String detectQueryType(String text) {
    if (text.contains('كم') && (text.contains('كمية') || text.contains('عدد'))) {
      return 'quantity';
    } else if (text.contains('سعر') || text.contains('ثمن')) {
      return 'price';
    } else if (text.contains('ربح') || text.contains('مكسب')) {
      return 'profit';
    } else if (text.contains('بيانات') || text.contains('تفاصيل')) {
      return 'details';
    } else if (text.contains('مخزون') || text.contains('رصيد') || text.contains('stock')) {
      return 'stock';
    } else if (text.contains('جديد') || text.contains('اضافة') || text.contains('تسجيل')) {
      return 'new';
    } else if (text.contains('اخر') || text.contains('احدث') || text.contains('آخر')) {
      return 'latest';
    } else if (text.contains('جميع') || text.contains('كل') || text.contains('all')) {
      return 'all';
    }
    return 'general';
  }

  /// تحديد ما إذا كان السؤال عن منتج معين
  static bool isSpecificProductQuery(String text) {
    final genericPatterns = [
      'جميع المنتجات',
      'كل المنتجات',
      'المنتجات',
      'المخزون',
      'الرصيد',
      'all product',
      'products'
    ];

    for (final pattern in genericPatterns) {
      if (text.contains(pattern)) {
        return false;
      }
    }

    // إذا كان النص يحتوي على كلمات دالة على منتج محدد
    final specificIndicators = ['منتج', 'سلعة', 'بضاعة', 'مادة', 'صنف', 'product'];
    for (final indicator in specificIndicators) {
      if (text.contains(indicator)) {
        return true;
      }
    }

    return false;
  }

  /// استخراج الفترة الزمنية
  static String extractTimePeriod(String text) {
    if (text.contains('اليوم') || text.contains('day') || text.contains('الحالي')) {
      return 'today';
    } else if (text.contains('أسبوع') || text.contains('اسبوع') || text.contains('week')) {
      return 'week';
    } else if (text.contains('شهر') || text.contains('month')) {
      return 'month';
    } else if (text.contains('سنة') || text.contains('year')) {
      return 'year';
    }
    return 'all';
  }
}