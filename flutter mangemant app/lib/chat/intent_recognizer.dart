import 'dart:convert';
import 'text_preprocessor.dart';

/// نظام متقدم للتعرف على النوايا باستخدام نظام الترجيح
class AdvancedIntentRecognizer {
  final Map<String, dynamic> _intents;
  final Map<String, double> _intentScores = {};
  final Map<String, String> _entityMap = {};

  AdvancedIntentRecognizer({required String intentsJson})
      : _intents = jsonDecode(intentsJson) {
    _initializeIntentScores();
    _initializeEntityMap();
  }

  /// تهيئة درجات النوايا بناءً على الأهمية
  void _initializeIntentScores() {
    final priorityIntents = [
      'product_stock', 'low_stock_products', 'out_of_stock_products',
      'sales_report', 'financial_summary', 'new_customer'
    ];

    for (final intent in _intents['intents']) {
      final tag = intent['tag'];
      _intentScores[tag] = priorityIntents.contains(tag) ? 1.0 : 0.8;
    }
  }

  /// تهيئة خريطة الكيانات
  void _initializeEntityMap() {
    _entityMap['customer'] = 'customer';
    _entityMap['sale'] = 'sale';
    _entityMap['invoice'] = 'invoice';
    _entityMap['warehouse'] = 'warehouse';
    _entityMap['user'] = 'user';
    _entityMap['permission'] = 'permission';
    _entityMap['product'] = 'product';
    _entityMap['stock'] = 'stock';
  }

  /// التعرف على النية مع نظام ترجيح متقدم
  Map<String, dynamic> recognizeIntent(String userInput) {
    // 1. المعالجة المسبقة للنص
    final processedInput = ArabicTextPreprocessor.preprocess(userInput);

    // 2. استخراج الكلمات المفتاحية
    final keywords = ArabicTextPreprocessor.extractKeywords(processedInput);

    // 3. تحديد نوع الاستعلام
    final queryType = EntityExtractor.detectQueryType(processedInput);
    final isSpecificProduct = EntityExtractor.isSpecificProductQuery(processedInput);
    final timePeriod = EntityExtractor.extractTimePeriod(processedInput);

    String bestMatchTag = 'unknown';
    double bestConfidence = 0.0;
    Map<String, dynamic> bestParams = {};
    List<String> matchedKeywords = [];
    String entityType = 'unknown';

    // 4. البحث عن نية متطابقة مع نظام الترجيح
    for (final intent in _intents['intents']) {
      final tag = intent['tag'];
      final patterns = (intent['patterns'] as List).cast<String>();

      double intentScore = _intentScores[tag] ?? 0.5;
      double patternScore = 0.0;
      List<String> currentMatchedKeywords = [];
      String currentEntityType = '';

      // حساب درجة المطابقة لكل نمط
      for (final pattern in patterns) {
        final processedPattern = ArabicTextPreprocessor.preprocess(pattern);
        final score = _calculatePatternScore(
            processedInput,
            processedPattern,
            keywords,
            queryType,
            isSpecificProduct
        );

        if (score > patternScore) {
          patternScore = score;
          currentMatchedKeywords = _getMatchingKeywords(
              processedInput,
              processedPattern,
              keywords
          );
          currentEntityType = _detectEntityTypeFromIntent(tag);
        }
      }

      // احتساب الدرجة النهائية
      final finalScore = (patternScore * 0.7) + (intentScore * 0.3);

      if (finalScore > bestConfidence) {
        bestConfidence = finalScore;
        bestMatchTag = tag;
        matchedKeywords = currentMatchedKeywords;
        entityType = currentEntityType;

        // استخراج المعاملات فقط إذا كانت الثقة عالية
        if (finalScore >= 0.4) {
          bestParams = _extractParameters(intent, processedInput, matchedKeywords, entityType);
          bestParams['query_type'] = queryType;
          bestParams['is_specific_product'] = isSpecificProduct;
          bestParams['time_period'] = timePeriod;
          bestParams['entity_type'] = entityType;
        }
      }
    }

    // 5. معالجة الحالات الخاصة
    if (bestConfidence < 0.3) {
      final lowConfidenceResult = _handleLowConfidence(processedInput, keywords, queryType);
      bestMatchTag = lowConfidenceResult['tag'];
      bestConfidence = 0.3;
      entityType = lowConfidenceResult['entity_type'];
    }

    // 6. تحسين الثقة بناءً على الكلمات المفتاحية
    if (matchedKeywords.length >= 2) {
      bestConfidence = (bestConfidence * 0.8) + (0.2 * (matchedKeywords.length / 3.0));
      bestConfidence = bestConfidence.clamp(0.0, 1.0);
    }

    // 7. استخراج الكيان إذا كان مطلوباً
    if (entityType != 'unknown' && bestParams['extracted_entity'] == null) {
      final entity = _extractEntity(processedInput, entityType);
      if (entity.isNotEmpty) {
        bestParams['extracted_entity'] = entity;
      }
    }

    return {
      'tag': bestMatchTag,
      'confidence': bestConfidence,
      'params': bestParams,
      'keywords': matchedKeywords,
      'query_type': queryType,
      'entity_type': entityType,
      'original_input': userInput,
      'processed_input': processedInput,
      'response_type': _getResponseType(bestMatchTag),
      'requires_db_query': _requiresDBQuery(bestMatchTag),
    };
  }

  /// حساب درجة المطابقة بين النص والنمط
  double _calculatePatternScore(
      String input,
      String pattern,
      List<String> keywords,
      String queryType,
      bool isSpecificProduct
      ) {
    if (input.isEmpty || pattern.isEmpty) return 0.0;

    double score = 0.0;

    // 1. المطابقة التامة (أعلى درجة)
    if (input == pattern) {
      return 1.0;
    }

    // 2. النمط موجود كجزء من النص
    if (input.contains(pattern) && pattern.length > 3) {
      score = 0.9;
    }

    // 3. مطابقة الكلمات المفتاحية
    final patternWords = pattern.split(' ');
    final inputWords = input.split(' ');

    int exactMatches = 0;
    int partialMatches = 0;

    for (final patternWord in patternWords) {
      if (patternWord.length < 2) continue;

      if (inputWords.contains(patternWord)) {
        exactMatches++;
      } else if (input.contains(patternWord)) {
        partialMatches++;
      }
    }

    // حساب نسبة المطابقة
    final exactMatchRatio = patternWords.isNotEmpty
        ? exactMatches / patternWords.length
        : 0.0;

    final partialMatchRatio = patternWords.isNotEmpty
        ? partialMatches / patternWords.length
        : 0.0;

    // 4. احتساب النتيجة النهائية
    final keywordScore = (exactMatchRatio * 0.6) + (partialMatchRatio * 0.4);

    if (score == 0.0) {
      score = keywordScore;
    } else {
      score = (score * 0.7) + (keywordScore * 0.3);
    }

    // 5. تحسين الدرجة بناءً على نوع الاستعلام
    if (queryType == 'quantity' && pattern.contains('كم')) {
      score *= 1.2;
    }

    if (isSpecificProduct && pattern.contains('منتج')) {
      score *= 1.1;
    }

    // 6. تحسين الدرجة بناءً على وجود كلمات مفتاحية مهمة
    final importantKeywords = ['customer', 'sale', 'invoice', 'warehouse', 'product'];
    for (final keyword in importantKeywords) {
      if (input.contains(keyword) && pattern.contains(keyword)) {
        score *= 1.15;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  /// الحصول على الكلمات المفتاحية المتطابقة
  List<String> _getMatchingKeywords(
      String input,
      String pattern,
      List<String> keywords
      ) {
    final patternWords = pattern.split(' ');
    return keywords.where((keyword) {
      return patternWords.any((patternWord) {
        return keyword.contains(patternWord) || patternWord.contains(keyword);
      });
    }).toList();
  }

  /// تحديد نوع الكيان من النية
  String _detectEntityTypeFromIntent(String tag) {
    switch (tag) {
      case 'product_stock':
      case 'product_details':
      case 'product_profit':
        return 'product';
      case 'customer_details':
      case 'customer_list':
      case 'new_customer':
        return 'customer';
      case 'sales_report':
      case 'latest_sales':
        return 'sale';
      case 'invoice_details':
        return 'invoice';
      case 'warehouse_stock':
        return 'warehouse';
      case 'user_permissions':
        return 'user';
      default:
        return 'unknown';
    }
  }

  /// معالجة الحالات ذات الثقة المنخفضة
  Map<String, dynamic> _handleLowConfidence(String input, List<String> keywords, String queryType) {
    // التحقق من وجود كلمات مفتاحية تشير إلى عملاء
    final customerKeywords = ['عميل', 'زبون', 'customer'];
    final hasCustomerKeyword = keywords.any((keyword) =>
        customerKeywords.any((customer) => keyword.contains(customer)));

    if (hasCustomerKeyword) {
      if (input.contains('جديد') || input.contains('اضافة') || input.contains('تسجيل')) {
        return {'tag': 'new_customer', 'entity_type': 'customer'};
      } else if (input.contains('جميع') || input.contains('كل') || input.contains('all')) {
        return {'tag': 'customer_list', 'entity_type': 'customer'};
      } else {
        return {'tag': 'customer_details', 'entity_type': 'customer'};
      }
    }

    // التحقق من وجود كلمات مفتاحية تشير إلى مبيعات
    final salesKeywords = ['بيع', 'مبيعات', 'sale'];
    final hasSalesKeyword = keywords.any((keyword) =>
        salesKeywords.any((sale) => keyword.contains(sale)));

    if (hasSalesKeyword) {
      if (input.contains('اخر') || input.contains('احدث') || input.contains('latest')) {
        return {'tag': 'latest_sales', 'entity_type': 'sale'};
      } else {
        return {'tag': 'sales_report', 'entity_type': 'sale'};
      }
    }

    // التحقق من وجود كلمات مفتاحية تشير إلى منتجات
    final productKeywords = ['منتج', 'سلعة', 'بضاعة', 'product'];
    final hasProductKeyword = keywords.any((keyword) =>
        productKeywords.any((product) => keyword.contains(product)));

    if (hasProductKeyword) {
      if (input.contains('كم') || input.contains('كمية')) {
        return {'tag': 'product_stock', 'entity_type': 'product'};
      } else if (input.contains('تفاصيل') || input.contains('بيانات')) {
        return {'tag': 'product_details', 'entity_type': 'product'};
      } else if (input.contains('ربح') || input.contains('مكسب')) {
        return {'tag': 'product_profit', 'entity_type': 'product'};
      }
    }

    // التحقق من وجود كلمات مفتاحية تشير إلى مخزون
    if (keywords.any((k) => k.contains('مخزون') || k.contains('رصيد') || k.contains('stock'))) {
      return {'tag': 'low_stock_products', 'entity_type': 'stock'};
    }

    return {'tag': 'help', 'entity_type': 'unknown'};
  }

  /// استخراج المعاملات المتقدمة
  Map<String, dynamic> _extractParameters(
      Map<String, dynamic> intent,
      String input,
      List<String> matchedKeywords,
      String entityType
      ) {
    final params = <String, dynamic>{};
    final tag = intent['tag'];

    switch (tag) {
      case 'product_stock':
      case 'product_details':
      case 'product_profit':
        params['product_identifier'] = EntityExtractor.extractProductName(input);
        params['extraction_method'] = 'entity_extractor';
        params['entity_type'] = 'product';

        // استخراج الأرقام إن وجدت
        final numbers = ArabicTextPreprocessor.extractNumbers(input);
        if (numbers.isNotEmpty) {
          params['extracted_numbers'] = numbers;
        }

        // تحديد ما إذا كان المنتج محدداً
        params['is_specific'] = EntityExtractor.isSpecificProductQuery(input);
        break;

      case 'customer_details':
        params['customer_name'] = EntityExtractor.extractCustomerName(input);
        params['entity_type'] = 'customer';
        break;

      case 'supplier_details':
        params['supplier_name'] = EntityExtractor.extractSupplierName(input);
        params['entity_type'] = 'supplier';
        break;

      case 'warehouse_stock':
        params['warehouse_name'] = _extractWarehouseName(input);
        params['entity_type'] = 'warehouse';
        break;

      case 'invoice_details':
        params['invoice_number'] = _extractInvoiceNumber(input);
        params['invoice_type'] = _extractInvoiceType(input);
        params['entity_type'] = 'invoice';
        break;

      case 'sales_report':
      case 'financial_summary':
        params['period'] = EntityExtractor.extractTimePeriod(input);
        params['date_range'] = _extractDateRange(input);
        params['entity_type'] = 'sale';
        break;

      case 'recent_operations':
        params['limit'] = _extractLimit(input);
        params['operation_type'] = _extractOperationType(input);
        break;

      case 'user_permissions':
        params['user_name'] = _extractUserName(input);
        params['permission_level'] = _extractPermissionLevel(input);
        params['entity_type'] = 'user';
        break;
    }

    // إضافة الكلمات المفتاحية المتطابقة
    if (matchedKeywords.isNotEmpty) {
      params['matched_keywords'] = matchedKeywords;
    }

    // إضافة نوع الكيان
    if (entityType != 'unknown') {
      params['entity_type'] = entityType;
    }

    return params;
  }

  /// استخراج اسم المخزن
  String _extractWarehouseName(String input) {
    if (input.contains('رئيسي') || input.contains('الرئيسي') || input.contains('main')) {
      return 'المخزن الرئيسي';
    }

    if (input.contains('فرع') || input.contains('branch')) {
      return 'مخزن الفرع';
    }

    final warehouseIndicators = ['مخزن', 'مستودع', 'فرع', 'محل', 'مكان', 'warehouse'];
    String processed = input;

    for (final indicator in warehouseIndicators) {
      processed = processed.replaceAll(RegExp('\\b$indicator\\b'), '');
    }

    return processed.trim().isNotEmpty ? processed.trim() : 'المخزن الرئيسي';
  }

  /// استخراج رقم الفاتورة
  String _extractInvoiceNumber(String input) {
    final numberMatch = RegExp(r'(?:فاتورة|invoice)\s*(\d+)').firstMatch(input.toLowerCase());
    if (numberMatch != null) {
      return numberMatch.group(1)!;
    }

    final directNumber = RegExp(r'\b\d{4,8}\b').firstMatch(input);
    if (directNumber != null) {
      return directNumber.group(0)!;
    }

    return '';
  }

  /// استخراج نوع الفاتورة
  String _extractInvoiceType(String input) {
    if (input.contains('بيع') || input.contains('sale')) {
      return 'sale';
    } else if (input.contains('شراء') || input.contains('purchase')) {
      return 'purchase';
    }
    return 'sale';
  }

  /// استخراج نطاق التاريخ
  Map<String, dynamic>? _extractDateRange(String input) {
    // يمكن توسيع هذا لاستخراج تواريخ محددة
    return null;
  }

  /// استخراج الحد الأقصى
  int _extractLimit(String input) {
    final numbers = ArabicTextPreprocessor.extractNumbers(input);
    if (numbers.isNotEmpty) {
      final num = numbers.first;
      if (num > 0 && num <= 50) return num;
    }

    // البحث عن كلمات دالة على الأعداد
    final wordNumbers = {
      'خمسة': 5, 'عشرة': 10, 'خمسة عشر': 15, 'عشرين': 20,
      'خمس وعشرين': 25, 'ثلاثين': 30, 'اربعين': 40, 'خمسين': 50
    };

    for (final entry in wordNumbers.entries) {
      if (input.contains(entry.key)) {
        return entry.value;
      }
    }

    return 10;
  }

  /// استخراج نوع العملية
  String _extractOperationType(String input) {
    if (input.contains('بيع') || input.contains('مبيعات')) return 'sale';
    if (input.contains('شراء') || input.contains('مشتريات')) return 'purchase';
    if (input.contains('دفع') || input.contains('صرف')) return 'payment';
    if (input.contains('قبض') || input.contains('تحصيل')) return 'receipt';
    return 'all';
  }

  /// استخراج اسم المستخدم
  String _extractUserName(String input) {
    final userIndicators = ['مستخدم', 'موظف', 'user'];
    String processed = input;

    for (final indicator in userIndicators) {
      processed = processed.replaceAll(RegExp('\\b$indicator\\b'), '');
    }

    final commonWords = ['عرض', 'بيانات', 'تفاصيل', 'صلاحيات', 'دور'];
    for (final word in commonWords) {
      processed = processed.replaceAll(RegExp('\\b$word\\b'), '');
    }

    return processed.trim();
  }

  /// استخراج مستوى الصلاحية
  String _extractPermissionLevel(String input) {
    if (input.contains('مدير') || input.contains('admin')) {
      return 'admin';
    } else if (input.contains('مشرف') || input.contains('supervisor')) {
      return 'supervisor';
    } else if (input.contains('موظف') || input.contains('employee')) {
      return 'employee';
    }
    return 'user';
  }

  /// استخراج الكيان من النص
  String _extractEntity(String input, String entityType) {
    switch (entityType) {
      case 'customer':
        return EntityExtractor.extractCustomerName(input);
      case 'product':
        return EntityExtractor.extractProductName(input);
      case 'supplier':
        return EntityExtractor.extractSupplierName(input);
      case 'warehouse':
        return _extractWarehouseName(input);
      case 'user':
        return _extractUserName(input);
      default:
        return '';
    }
  }

  /// الحصول على نوع الاستجابة
  String _getResponseType(String tag) {
    const textResponses = ['help', 'unknown', 'greeting'];
    const dbQueryResponses = [
      'product_stock', 'product_details', 'product_profit',
      'customer_details', 'customer_list', 'sales_report',
      'invoice_details', 'warehouse_stock', 'user_permissions',
      'new_customer', 'latest_sales', 'financial_summary'
    ];

    if (textResponses.contains(tag)) return 'text';
    if (dbQueryResponses.contains(tag)) return 'database_query';
    return 'text';
  }

  /// تحديد ما إذا كان يحتاج إلى استعلام قاعدة بيانات
  bool _requiresDBQuery(String tag) {
    const dbQueryTags = [
      'product_stock', 'product_details', 'product_profit',
      'customer_details', 'customer_list', 'sales_report',
      'invoice_details', 'warehouse_stock', 'user_permissions',
      'latest_sales', 'financial_summary'
    ];
    return dbQueryTags.contains(tag);
  }

  /// الحصول على جميع النوايا المتاحة
  List<String> getAvailableIntents() {
    return _intents['intents'].map<String>((i) => i['tag'] as String).toList();
  }

  /// إضافة نية جديدة ديناميكياً (للتوسع المستقبلي)
  void addIntent(Map<String, dynamic> intent) {
    _intents['intents'].add(intent);
    _intentScores[intent['tag']] = 0.8;
  }
}