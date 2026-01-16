import 'dart:math';

import '../database_helper.dart';
import 'intent_result.dart';
import 'text_preprocessor.dart';
import 'intent_recognizer.dart' as enhanced;
import 'dart:convert';
import 'package:http/http.dart' as http;

// استبدل تعريف _intentRecognizer في ChatController
class ChatController {
  final enhanced.AdvancedIntentRecognizer _intentRecognizer;
  final DatabaseHelper _dbHelper;
  final String? _openAIKey;  // إضافة متغير لمفتاح OpenAI
  final bool _hasOpenAISupport;  // للتحقق من دعم OpenAI


  ChatController({
    required DatabaseHelper dbHelper,
    required String intentsJson,
    String? openAIKey,  // إضافة معامل اختياري
  })  : _dbHelper = dbHelper,
        _intentRecognizer = enhanced.AdvancedIntentRecognizer(intentsJson: intentsJson),
        _openAIKey = openAIKey,
        _hasOpenAISupport = openAIKey != null && openAIKey.isNotEmpty {
    print(_hasOpenAISupport
        ? '✅ OpenAI Fallback متاح'
        : '⚠️ OpenAI Fallback غير متاح');
  }
  get product => null;


















  Future<IntentResult> _classifyIntent(String message) async {
    // أولاً: التصنيف المحلي
    final localResult = await _classifyLocally(message);

    print('🎯 النتيجة المحلية: ${localResult.intent} (${localResult.confidence})');

    // إذا كانت الثقة عالية (> 0.7)، استخدم النتيجة المحلية
    if (localResult.confidence > 0.7) {
      print('✅ استخدام التصنيف المحلي (ثقة عالية)');
      return localResult;
    }

    // إذا كانت الثقة متوسطة (0.4-0.7)، جرب OpenAI
    if (localResult.confidence >= 0.4 && localResult.confidence <= 0.7) {
      print('🔄 محاولة استخدام OpenAI كـ fallback...');
      try {
        final openAIResult = await _classifyWithOpenAI(message);
        // ✅ الآن openAIResult هو IntentResult
        print('✅ نتيجة OpenAI: ${openAIResult.intent} (${openAIResult.confidence})');
        return openAIResult;
      } catch (e) {
        print('❌ فشل OpenAI، استخدام النتيجة المحلية');
        return localResult;
      }
    }

    // إذا كانت الثقة منخفضة (< 0.4)، استخدم unknown
    print('🔄 الثقة منخفضة، استخدام unknown');
    return IntentResult(
      intent: 'unknown',
      confidence: 0.1,
      source: 'fallback',
      entity: 'unknown',
    );
  }
  Future<IntentResult> _classifyLocally(String message) async {
    // تنظيف وتوحيد النص
    final cleanedMessage = message.toLowerCase().trim();

    // قواعد تصنيف موسعة
    final Map<String, List<String>> intentPatterns = {
      'greeting': [
        'مرحبا', 'السلام عليكم', 'اهلا', 'صباح الخير', 'مساء الخير',
        'hello', 'hi', 'hey', 'مرحباً', 'اهلاً'
      ],
      'product_stock': [
        'المخزون', 'الكمية', 'البضاعة', 'المنتجات', 'السلع',
        'كم باقي', 'كم موجود', 'الرصيد', 'مخزون', 'كمية',
        'stock', 'inventory', 'كم تبقى', 'عدد'
      ],
      'sales_report': [
        'المبيعات', 'التقرير', 'الارباح', 'الخسائر', 'المردود',
        'تقارير', 'احصائيات', 'الاحصائيات', 'الايرادات',
        'sales', 'report', 'revenue', 'ربح', 'خسارة'
      ],
      'invoice_details': [
        'الفاتورة', 'الفواتير', 'فاتورة', 'رقم الفاتورة',
        'تفاصيل الفاتورة', 'بيانات الفاتورة', 'فاتورة رقم',
        'invoice', 'bill', 'فاتورة مبيعات'
      ],
      'user_management': [
        'المستخدمين', 'العملاء', 'الزبائن', 'العميل',
        'إدارة المستخدمين', 'بيانات العملاء', 'قائمة العملاء',
        'users', 'customers', 'clients', 'ادارة المستخدمين'
      ],
      'help': [
        'مساعدة', 'المساعدة', 'مساعده', 'مساعد', 'ماذا يمكنك',
        'help', 'what can you do', 'وظائفك', 'قدراتك'
      ],
      'goodbye': [
        'مع السلامة', 'الى اللقاء', 'وداعا', 'باي', 'سلام',
        'goodbye', 'bye', 'see you', 'الى اللقاء'
      ],
      'system_status': [
        'حالة النظام', 'الحالة', 'السيرفر', 'الخادم', 'الشبكة',
        'system', 'status', 'server', 'حالة التطبيق'
      ],
      'search_product': [
        'ابحث عن', 'بحث', 'أوجد', 'اعطني', 'عندك',
        'search', 'find', 'look for', 'هل لديك'
      ],
    };

    // حساب التطابق لكل نية
    Map<String, double> scores = {};

    for (final entry in intentPatterns.entries) {
      double score = 0.0;
      final patterns = entry.value;

      for (final pattern in patterns) {
        if (cleanedMessage.contains(pattern)) {
          score += 0.3; // زيادة عند وجود كلمة مطابقة
        }
      }

      // تحسين: تطابق جزئي أو متشابه
      for (final pattern in patterns) {
        if (_calculateSimilarity(cleanedMessage, pattern) > 0.6) {
          score += 0.2;
        }
      }

      scores[entry.key] = score;
    }

    // العثور على النية ذات الأعلى درجة
    String bestIntent = 'unknown';
    double bestScore = 0.0;

    scores.forEach((intent, score) {
      if (score > bestScore) {
        bestScore = score;
        bestIntent = intent;
      }
    });

    // إذا كانت الدرجة أقل من 0.3، نعتبرها غير معروفة
    if (bestScore < 0.3) {
      bestIntent = 'unknown';
      bestScore = 0.1;
    }

    // استخراج الكيانات البسيطة
    String entity = 'unknown';

    if (bestIntent == 'product_stock') {
      // محاولة استخراج اسم المنتج
      final productMatch = RegExp(r'(منتج|سلعة|بضاعة)\s+(\w+)').firstMatch(message);
      if (productMatch != null) {
        entity = productMatch.group(2)!;
      } else {
        // البحث عن أي كلمة بعد "كمية" أو "مخزون"
        final quantityMatch = RegExp(r'(كمية|مخزون)\s+(\w+)').firstMatch(message);
        if (quantityMatch != null) {
          entity = quantityMatch.group(2)!;
        }
      }
    } else if (bestIntent == 'invoice_details') {
      final invoiceMatch = RegExp(r'فاتورة\s+(\w+)').firstMatch(message);
      if (invoiceMatch != null) {
        entity = invoiceMatch.group(1)!;
      }
    }

    print('🎯 التصنيف المحلي: "$message" → $bestIntent (ثقة: $bestScore, كيان: $entity)');

    return IntentResult(
      intent: bestIntent,
      confidence: bestScore,
      source: 'local',
      entity: entity,
    );
  }

// دالة لحساب التشابه بين نصين
  double _calculateSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;

    // تشابه بسيط
    int matches = 0;
    for (int i = 0; i < min(a.length, b.length); i++) {
      if (a[i] == b[i]) matches++;
    }

    return matches / max(a.length, b.length);
  }
  // أضف هذه الدالة الجديدة للاستعلام من OpenAI
  Future<IntentResult> _classifyWithOpenAI(String message) async {
    try {
      final apiKey = _openAIKey;

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('مفتاح OpenAI غير مضبوط');
      }

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'أنت مساعد لتصنيف النوايا. صنف النص إلى: greeting, product_stock, sales_report, invoice_details, user_management, help, goodbye, unknown. أعد الإجابة بصيغة: النية|الثقة|الكيان'
            },
            {'role': 'user', 'content': message},
          ],
          'temperature': 0.3,
          'max_tokens': 50,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'].trim();

        final parts = content.split('|');
        if (parts.length >= 3) {
          // ✅ الآن ترجع IntentResult وليس Map
          return IntentResult(
            intent: parts[0],
            confidence: double.tryParse(parts[1]) ?? 0.5,
            source: 'openai',
            entity: parts[2],
          );
        } else {
          // إذا كان الرد غير متوقع، ارجع unknown
          return IntentResult(
            intent: 'unknown',
            confidence: 0.1,
            source: 'openai',
            entity: 'unknown',
          );
        }
      } else if (response.statusCode == 401) {
        print('❌ خطأ 401: مفتاح OpenAI غير صالح');
        throw Exception('مفتاح OpenAI غير صالح (401)');
      } else {
        print('❌ خطأ من OpenAI: ${response.statusCode}');
        throw Exception('فشل في الاتصال بـ OpenAI: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ استثناء في OpenAI: $e');
      rethrow;
    }
  }
  // أضف دالة مساعدة لدمج النتائج
  Future<Map<String, dynamic>> _mergeIntentResults(
      Map<String, dynamic> localIntent,
      Map<String, dynamic>? openAIIntent,
      ) async {
    // إذا كانت النية المحلية مع ثقة عالية، استخدمها
    if (localIntent['confidence'] >= 0.5) {
      return localIntent;
    }

    // إذا كان OpenAI متاحاً وناجحاً، استخدمه
    if (openAIIntent != null && openAIIntent['success'] == true) {
      final openAITag = openAIIntent['intent'];
      final openAIEntities = openAIIntent['entities'];

      return {
        'tag': openAITag,
        'confidence': 0.7,  // ثقة متوسطة لـ OpenAI
        'params': openAIEntities,
        'source': 'openai',
        'query_type': localIntent['query_type'] ?? 'general',
      };
    }

    // إذا فشل كلاهما
    return localIntent;
  }



  // تحديث دالة _handleProductStock لدعم أنواع الاستعلام المختلفة
  Future<Map<String, dynamic>> _handleProductStock(
      Map<String, dynamic> params,
      String queryType
      ) async {
    final identifier = params['product_identifier']?.toString();
    final isSpecific = params['is_specific'] ?? true;

    if (identifier == null || identifier.isEmpty || !isSpecific) {
      return _handleGeneralStockQuery(params, queryType);
    }

    // ... الكود الحالي مع تحسينات ...

    // إضافة تحسينات للردود
    final response = await _generateStockResponse(product, queryType);

    return {
      'success': true,
      'response': response,
      'response_type': 'text',
      'data': product,
      'query_type': queryType,
    };
  }

  // دالة جديدة: معالجة استعلامات المخزون العامة
  Future<Map<String, dynamic>> _handleGeneralStockQuery(
      Map<String, dynamic> params,
      String queryType
      ) async {
    try {
      final products = await _dbHelper.getProductsForChat(limit: 20);

      if (products.isEmpty) {
        return {
          'success': true,
          'response': '📦 **لا توجد منتجات مسجلة في النظام.**',
          'response_type': 'text',
          'data': [],
        };
      }

      // تحليل المخزون العام
      int totalQuantity = 0;
      int lowStockCount = 0;
      int outOfStockCount = 0;
      double totalValue = 0.0;

      for (final product in products) {
        final quantity = product['quantity'] as int? ?? 0;
        final price = product['price'] as num? ?? 0.0;
        final minLevel = product['min_quantity'] as int? ?? 10;

        totalQuantity += quantity;
        totalValue += quantity * price.toDouble();

        if (quantity <= 0) {
          outOfStockCount++;
        } else if (quantity <= minLevel) {
          lowStockCount++;
        }
      }

      // توليد رد بناءً على نوع الاستعلام
      String response = '';

      switch (queryType) {
        case 'quantity':
          response = '''
📊 **تحليل كميات المخزون العام:**

• **إجمالي المنتجات:** ${products.length} منتج
• **إجمالي الكمية:** $totalQuantity وحدة
• **القيمة الإجمالية:** ${totalValue.toStringAsFixed(2)} ريال
• **المنتجات المنخفضة:** $lowStockCount منتج
• **المنتجات النافذة:** $outOfStockCount منتج

💡 **توصية:** ${lowStockCount > 0 ? 'يوجد منتجات تحتاج لإعادة تخزين.' : 'المخزون العام في حالة جيدة.'}
''';
          break;

        default:
          response = '''
🏪 **نظرة عامة على المخزون:**

📈 **الإحصائيات:**
• عدد المنتجات: ${products.length}
• إجمالي الوحدات: $totalQuantity
• القيمة الإجمالية: ${totalValue.toStringAsFixed(2)} ريال

⚠️ **الإنذارات:**
• المنتجات المنخفضة: $lowStockCount
• المنتجات النافذة: $outOfStockCount

📋 **للمزيد من التفاصيل، يمكنك سؤال:**
• "ما هي المنتجات المنخفضة؟"
• "عرض المنتجات النافذة"
• أو استفسر عن منتج معين
''';
      }

      return {
        'success': true,
        'response': response,
        'response_type': 'text',
        'data': {
          'total_products': products.length,
          'total_quantity': totalQuantity,
          'total_value': totalValue,
          'low_stock_count': lowStockCount,
          'out_of_stock_count': outOfStockCount,
        },
        'query_type': queryType,
      };
    } catch (e) {
      return _handleError(e, 'general_stock_query');
    }
  }

  // دالة جديدة: توليد ردود المخزون المتنوعة
  Future<String> _generateStockResponse(
      Map<String, dynamic> product,
      String queryType
      ) async {
    final name = product['name'] ?? 'غير معروف';
    final quantity = product['current_quantity'] as int? ?? 0;
    final minLevel = product['min_stock_level'] as int? ?? 10;
    final unit = product['unit'] ?? 'قطعة';

    // قوالب ردود متنوعة
    final List<Map<String, String>> responseTemplates = [
      {
        'template': '''
📦 **مخزون المنتج: {name}**

🔢 **الكمية المتاحة:** {quantity} {unit}
📊 **الحد الأدنى المطلوب:** {minLevel} {unit}
🏷️ **حالة المخزون:** {status}

{advice}
''',
        'condition': 'quantity <= minLevel'
      },
      {
        'template': '''
🛒 **تقرير المخزون**

**المنتج:** {name}
**المتوفر حالياً:** {quantity} {unit}
**المستوى المطلوب:** {minLevel} {unit}
**التقييم:** {status}

{advice}
''',
        'condition': 'quantity > 0 && quantity <= minLevel * 2'
      },
      {
        'template': '''
✅ **مخزون آمن**

**{name}**
• الكمية: {quantity} {unit}
• الحد الأدنى: {minLevel} {unit}
• الحالة: {status}

{advice}
''',
        'condition': 'quantity > minLevel * 2'
      }
    ];

    // تحديد الحالة
    String status;
    String advice;

    if (quantity <= 0) {
      status = '🟥 نفذ تماماً';
      advice = '⚠️ **مطلوب:** يحتاج لإعادة طلب فورية!';
    } else if (quantity <= minLevel) {
      status = '🟧 منخفض جداً';
      advice = '⚠️ **تحذير:** أقل من الحد الأدنى، يوصى بإعادة التخزين فوراً.';
    } else if (quantity <= minLevel * 2) {
      status = '🟨 مقبول';
      advice = 'ℹ️ **ملاحظة:** المخزون في مستوى مقبول لكن يحتاج للمراقبة.';
    } else {
      status = '🟩 ممتاز';
      advice = '✅ **جيد:** المخزون في مستوى آمن ولا يحتاج إجراء عاجل.';
    }

    // اختيار القالب المناسب
    Map<String, String> selectedTemplate = responseTemplates.first;

    if (quantity <= 0) {
      selectedTemplate = responseTemplates[0];
    } else if (quantity <= minLevel * 2) {
      selectedTemplate = responseTemplates[1];
    } else {
      selectedTemplate = responseTemplates[2];
    }

    // تعبئة القالب
    return selectedTemplate['template']!
        .replaceAll('{name}', name)
        .replaceAll('{quantity}', quantity.toString())
        .replaceAll('{minLevel}', minLevel.toString())
        .replaceAll('{unit}', unit)
        .replaceAll('{status}', status)
        .replaceAll('{advice}', advice);
  }

  // دالة جديدة: معالجة الأخطاء المحسنة
  Map<String, dynamic> _handleError(dynamic error, String context) {
    print('❌ خطأ في $context: $error');

    final errorResponses = [
      '''
🔄 **حدث خطأ غير متوقع**

عذراً، واجهت مشكلة فنية أثناء معالجة طلبك.
يرجى المحاولة مرة أخرى أو الاتصال بالدعم الفني.

🔧 **التفاصيل:** ${error.toString().substring(0, 100)}
''',
      '''
⚠️ **تعذر الإكمال**

حدث خطأ في النظام. يمكنك:
1. المحاولة مرة أخرى
2. استخدام أمر مختلف
3. التحقق من اتصال قاعدة البيانات

💡 **السياق:** $context
''',
      '''
🔧 **مشكلة فنية**

عذراً، تعذر معالجة طلبك حاليًا.
سيتم إصلاح المشكلة قريبًا.

📋 **الخطأ:** ${error.toString().split('\n').first}
'''
    ];

    final randomIndex = DateTime.now().millisecondsSinceEpoch % errorResponses.length;

    return {
      'success': false,
      'response': errorResponses[randomIndex],
      'response_type': 'text',
      'error': error.toString(),
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // دالة جديدة: معالجة الاستعلامات غير المعروفة

  /// معالجة سؤال المستخدم
  // قم بتعديل دالة processQuery الرئيسية
  Future<Map<String, dynamic>> processQuery(String userInput) async {
    try {
      // 1. التعرف على النية محلياً
      final localIntent = _intentRecognizer.recognizeIntent(userInput);

      // 2. إذا كانت الثقة منخفضة وكان OpenAI متاحاً، استخدمه كـ fallback
      Map<String, dynamic>? openAIIntent;
      if (localIntent['confidence'] < 0.4 && _hasOpenAISupport) {
        try {
          print('🔄 استخدام OpenAI كـ fallback...');
          openAIIntent = (await _classifyWithOpenAI(userInput)).toMap();
        } catch (e) {
          print('⚠️ فشل OpenAI fallback: $e');
        }
      }

      // 3. دمج النتائج
      final finalIntent = await _mergeIntentResults(localIntent, openAIIntent);
      final tag = finalIntent['tag'];
      final confidence = finalIntent['confidence'];
      final params = finalIntent['params'];
      final source = finalIntent['source'] ?? 'local';
      final entityType = params['entity_type'] ?? 'unknown';

      print('✅ النية النهائية: $tag (الثقة: $confidence, المصدر: $source, الكيان: $entityType)');

      // إذا كانت الثقة منخفضة جداً حتى بعد fallback
      if (confidence < 0.3 && tag != 'help') {
        return {
          'success': false,
          'response': 'لم أفهم سؤالك بوضوح. يمكنك إعادة صياغته أو كتابة "مساعدة" لرؤية الأوامر المتاحة.',
          'response_type': 'text',
          'confidence': confidence,
          'source': source,
        };
      }

      // 4. استدعاء الدالة المناسبة بناءً على النية
      final result = await _callIntentFunction(tag, params, entityType);
      result['source'] = source;  // إضافة معلومات المصدر

      return result;

    } catch (e) {
      return {
        'success': false,
        'response': 'حدث خطأ أثناء معالجة طلبك: ${e.toString()}',
        'response_type': 'text',
        'error': e.toString(),
        'source': 'error',
      };
    }
  }

  // دالة مساعدة لاستدعاء الدوال بناءً على النية
  Future<Map<String, dynamic>> _callIntentFunction(
      String tag,
      Map<String, dynamic> params,
      String entityType
      ) async {
    switch (tag) {
      case 'product_stock':
        return await _handleProductStock(params, 'stock');
      case 'product_details':
        return await _handleProductDetails(params);
      case 'product_profit':
        return await _handleProductProfit(params);
      case 'low_stock_products':
        return await _handleLowStockProducts();
      case 'out_of_stock_products':
        return await _handleOutOfStockProducts();
      case 'all_products':
        return await _handleAllProducts();
      case 'supplier_details':
        return await _handleSupplierDetails(params);
      case 'all_suppliers':
        return await _handleAllSuppliers();
      case 'customer_details':
        return await _handleCustomerDetails(params);
      case 'customer_list':
        return await _handleAllCustomers();
      case 'new_customer':
        return await _handleNewCustomer(params);
      case 'warehouse_stock':
        return await _handleWarehouseStock(params);
      case 'all_warehouses':
        return await _handleAllWarehouses();
      case 'sales_report':
        return await _handleSalesReport(params);
      case 'latest_sales':
        return await _handleLatestSales(params);
      case 'invoice_details':
        return await _handleInvoiceDetails(params);
      case 'financial_summary':
        return await _handleFinancialSummary(params);
      case 'recent_operations':
        return await _handleRecentOperations(params);
      case 'system_info':
        return await _handleSystemInfo();
      case 'system_alerts':
        return await _handleSystemAlerts();
      case 'user_permissions':
        return await _handleUserPermissions(params);
      case 'help':
        return await _handleHelp();
      case 'unknown':
      default:
        return {
          'success': false,
          'response': 'عذراً، لا أستطيع معالجة هذا السؤال حالياً. يمكنك استخدام "مساعدة" لمعرفة ما يمكنني فعله.',
          'response_type': 'text',
          'confidence': 0.0,
        };
    }
  }

  /// === دالات جديدة للمعالجة ===

  /// معالجة تقرير المبيعات
  Future<Map<String, dynamic>> _handleSalesReport(Map<String, dynamic> params) async {
    try {
      final period = params['period'] ?? 'today';
      final salesData = await _dbHelper.getSalesReport(period);

      if (salesData.isEmpty) {
        return {
          'success': true,
          'response': '💰 **لا توجد مبيعات مسجلة للفترة المحددة.**',
          'response_type': 'text',
          'data': salesData,
        };
      }

      final totalSales = salesData['total_sales'] ?? 0.0;
      final totalProfit = salesData['total_profit'] ?? 0.0;
      final invoiceCount = salesData['invoice_count'] ?? 0;
      final periodStr = _translatePeriod(period);

      final response = '''
💰 **تقرير المبيعات ($periodStr)**

📈 **الإحصائيات:**
• عدد الفواتير: $invoiceCount
• إجمالي المبيعات: ${totalSales.toStringAsFixed(2)} ريال
• إجمالي الأرباح: ${totalProfit.toStringAsFixed(2)} ريال
• متوسط الفاتورة: ${invoiceCount > 0 ? (totalSales / invoiceCount).toStringAsFixed(2) : 0.0} ريال

📊 **التحليل:**
${totalSales > 0 ? '✅ **الأداء جيد**' : 'ℹ️ **لا توجد مبيعات**'}

💡 **التوصيات:**
${totalSales > 0 ? '• الحفاظ على مستوى المبيعات' : '• العمل على زيادة المبيعات'}
''';

      return {
        'success': true,
        'response': response,
        'response_type': 'text',
        'data': salesData,
      };
    } catch (e) {
      return _handleError(e, 'sales_report');
    }
  }

  /// معالجة أحدث المبيعات
  Future<Map<String, dynamic>> _handleLatestSales(Map<String, dynamic> params) async {
    try {
      final limit = params['limit'] ?? 10;
      final sales = await _dbHelper.getLatestSales(limit);

      if (sales.isEmpty) {
        return {
          'success': true,
          'response': '💰 **لا توجد مبيعات حديثة.**',
          'response_type': 'text',
          'data': sales,
        };
      }

      String response = '🔄 **آخر المبيعات:**\n\n';
      double totalAmount = 0.0;

      for (int i = 0; i < sales.length && i < limit; i++) {
        final sale = sales[i];
        final customer = sale['customer_name'] ?? 'عميل نقدي';
        final amount = sale['total_amount'] ?? 0.0;
        final date = sale['invoice_date'] ?? 'غير معروف';
        final invoiceNo = sale['invoice_number'] ?? 'غير معروف';

        totalAmount += amount;

        response += '${i + 1}. **فاتورة #$invoiceNo**\n';
        response += '   👤 العميل: $customer\n';
        response += '   💰 المبلغ: ${amount.toStringAsFixed(2)} ريال\n';
        response += '   📅 التاريخ: $date\n\n';
      }

      response += '💰 **الإجمالي:** ${totalAmount.toStringAsFixed(2)} ريال';

      return {
        'success': true,
        'response': response,
        'response_type': 'text',
        'data': sales,
      };
    } catch (e) {
      return _handleError(e, 'latest_sales');
    }
  }

  /// معالجة تفاصيل الفاتورة
  Future<Map<String, dynamic>> _handleInvoiceDetails(Map<String, dynamic> params) async {
    final invoiceNumber = params['invoice_number']?.toString();

    if (invoiceNumber == null || invoiceNumber.isEmpty) {
      return {
        'success': false,
        'response': 'يرجى تحديد رقم الفاتورة.',
        'response_type': 'text',
      };
    }

    try {
      final invoice = await _dbHelper.getInvoiceDetails(invoiceNumber);

      if (invoice == null) {
        return {
          'success': false,
          'response': 'لم أجد فاتورة برقم "$invoiceNumber".',
          'response_type': 'text',
        };
      }

      final invoiceNo = invoice['invoice_number'] ?? 'غير معروف';
      final customer = invoice['customer_name'] ?? 'عميل نقدي';
      final totalAmount = invoice['total_amount'] ?? 0.0;
      final paidAmount = invoice['paid_amount'] ?? 0.0;
      final remainingAmount = invoice['remaining_amount'] ?? 0.0;
      final date = invoice['invoice_date'] ?? 'غير معروف';
      final status = invoice['status'] ?? 'غير معروف';
      final items = invoice['items'] as List? ?? [];

      String response = '''
🧾 **تفاصيل الفاتورة: #$invoiceNo**

👤 **العميل:** $customer
📅 **التاريخ:** $date
💰 **الإجمالي:** ${totalAmount.toStringAsFixed(2)} ريال
💳 **المدفوع:** ${paidAmount.toStringAsFixed(2)} ريال
📊 **المتبقي:** ${remainingAmount.toStringAsFixed(2)} ريال
🏷️ **الحالة:** ${_translateInvoiceStatus(status)}

🛒 **المنتجات:**
''';

      if (items.isNotEmpty) {
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          final productName = item['product_name'] ?? 'غير معروف';
          final quantity = item['quantity'] ?? 0;
          final price = item['unit_price'] ?? 0.0;
          final total = item['total_price'] ?? 0.0;

          response += '${i + 1}. **$productName**\n';
          response += '   🔢 الكمية: $quantity\n';
          response += '   💰 السعر: ${price.toStringAsFixed(2)} ريال\n';
          response += '   💵 الإجمالي: ${total.toStringAsFixed(2)} ريال\n\n';
        }
      } else {
        response += '• لا توجد منتجات مسجلة\n';
      }

      return {
        'success': true,
        'response': response,
        'response_type': 'text',
        'data': invoice,
      };
    } catch (e) {
      return _handleError(e, 'invoice_details');
    }
  }

  /// معالجة إضافة عميل جديد
  Future<Map<String, dynamic>> _handleNewCustomer(Map<String, dynamic> params) async {
    // في نظام حقيقي، هنا ستكون استمارة إضافة عميل جديد
    // لكننا سنقدم معلومات مساعدة للمستخدم
    return {
      'success': true,
      'response': '''
👤 **إضافة عميل جديد**

لإضافة عميل جديد، يرجى اتباع الخطوات التالية:

1. انتقل إلى قسم **العملاء**
2. اضغط على زر **"إضافة عميل جديد"**
3. املأ البيانات المطلوبة:
   - اسم العميل
   - رقم الهاتف
   - البريد الإلكتروني (اختياري)
   - العنوان (اختياري)
   - الحد الائتماني (اختياري)

💡 **ملاحظات:**
• يمكن للعميل الشراء نقداً أو بالآجل
• يمكن تتبع مدفوعات العميل من خلال حسابه
• يمكن إضافة ملاحظات خاصة لكل عميل

📞 **للاستفسار:** يمكنك التواصل مع الدعم الفني
''',
      'response_type': 'text',
      'data': null,
    };
  }

  /// معالجة صلاحيات المستخدم
  Future<Map<String, dynamic>> _handleUserPermissions(Map<String, dynamic> params) async {
    final userName = params['user_name']?.toString();

    if (userName == null || userName.isEmpty) {
      // عرض جميع المستخدمين
      try {
        final users = await _dbHelper.getUsersForChat();

        if (users.isEmpty) {
          return {
            'success': true,
            'response': '👤 **لا توجد مستخدمين مسجلين في النظام.**',
            'response_type': 'text',
            'data': [],
          };
        }

        String response = '👤 **المستخدمين والصلاحيات:**\n\n';

        for (int i = 0; i < users.length && i < 10; i++) {
          final user = users[i];
          final name = user['name'] ?? 'غير معروف';
          final role = user['role'] ?? 'user';
          final status = user['is_active'] == 1 ? '✅ نشط' : '❌ غير نشط';
          final lastLogin = user['last_login'] ?? 'لم يسجل دخول';

          response += '${i + 1}. **$name**\n';
          response += '   👤 الدور: ${_translateUserRole(role)}\n';
          response += '   🏷️ الحالة: $status\n';
          response += '   🕒 آخر دخول: $lastLogin\n\n';
        }

        if (users.length > 10) {
          response += '... و ${users.length - 10} مستخدم آخر\n';
        }

        return {
          'success': true,
          'response': response,
          'response_type': 'text',
          'data': users,
        };
      } catch (e) {
        return _handleError(e, 'user_permissions_list');
      }
    } else {
      // عرض بيانات مستخدم محدد
      try {
        final user = await _dbHelper.getUserForChat(userName);

        if (user == null) {
          return {
            'success': false,
            'response': 'لم أجد مستخدمًا مطابقاً لـ "$userName".',
            'response_type': 'text',
          };
        }

        final name = user['name'] ?? 'غير معروف';
        final email = user['email'] ?? 'غير متوفر';
        final phone = user['phone'] ?? 'غير متوفر';
        final role = user['role'] ?? 'user';
        final status = user['is_active'] == 1 ? '✅ نشط' : '❌ غير نشط';
        final lastLogin = user['last_login'] ?? 'لم يسجل دخول';
        final createdAt = user['created_at'] ?? 'غير معروف';

        final response = '''
👤 **تفاصيل المستخدم: $name**

📧 **البريد:** $email
📞 **الهاتف:** $phone
👤 **الدور:** ${_translateUserRole(role)}
🏷️ **الحالة:** $status
🕒 **آخر دخول:** $lastLogin
📅 **تاريخ التسجيل:** $createdAt

🔐 **الصلاحيات المتاحة:**
${_getPermissionsForRole(role)}
''';

        return {
          'success': true,
          'response': response,
          'response_type': 'text',
          'data': user,
        };
      } catch (e) {
        return _handleError(e, 'user_permissions_details');
      }
    }
  }

  /// دوال مساعدة إضافية
  String _translateInvoiceStatus(String status) {
    switch (status) {
      case 'draft': return '📝 مسودة';
      case 'pending': return '⏳ قيد الانتظار';
      case 'approved': return '✅ معتمدة';
      case 'paid': return '💰 مدفوعة';
      case 'cancelled': return '❌ ملغاة';
      default: return status;
    }
  }

  String _translateUserRole(String role) {
    switch (role) {
      case 'admin': return '👑 مدير النظام';
      case 'supervisor': return '👨‍💼 مشرف';
      case 'sales': return '💰 مندوب مبيعات';
      case 'warehouse': return '📦 مسؤول مخازن';
      case 'accountant': return '🧮 محاسب';
      default: return '👤 مستخدم';
    }
  }

  String _getPermissionsForRole(String role) {
    switch (role) {
      case 'admin':
        return '• جميع الصلاحيات\n• إدارة النظام بالكامل\n• إضافة/حذف المستخدمين\n• الوصول لجميع البيانات';
      case 'supervisor':
        return '• مشاهدة التقارير\n• إدارة المبيعات والمشتريات\n• إدارة المخزون\n• إدارة العملاء والموردين';
      case 'sales':
        return '• إضافة المبيعات\n• إدارة العملاء\n• مشاهدة المخزون\n• طباعة الفواتير';
      case 'warehouse':
        return '• إدارة المخزون\n• إضافة المشتريات\n• إدارة المخازن\n• جرد المنتجات';
      case 'accountant':
        return '• الوصول للبيانات المالية\n• إدارة الدفعات\n• التقارير المالية\n• المصاريف والإيرادات';
      default:
        return '• صلاحيات محدودة\n• مشاهدة البيانات العامة';
    }
  }

  // باقي الدوال الموجودة سابقاً تبقى كما هي مع إضافة تحسينات طفيفة

  Future<Map<String, dynamic>> _handleProductDetails(Map<String, dynamic> params) async {
    final identifier = params['product_identifier']?.toString();

    if (identifier == null || identifier.isEmpty) {
      return {
        'success': false,
        'response': 'يرجى تحديد اسم المنتج أو الباركود.',
        'response_type': 'text',
      };
    }

    try {
      final product = await _dbHelper.getProductForChat(identifier);

      if (product == null) {
        return {
          'success': false,
          'response': 'لم أجد منتجاً مطابقاً لـ "$identifier".',
          'response_type': 'text',
        };
      }

      final name = product['name'] ?? 'غير معروف';
      final barcode = product['barcode'] ?? 'غير متوفر';
      final category = product['category_name'] ?? 'غير مصنف';
      final supplier = product['supplier_name'] ?? 'غير معروف';
      final quantity = product['current_quantity'] ?? 0;
      final purchasePrice = product['purchase_price'] ?? 0.0;
      final costPrice = product['cost_price'] ?? 0.0;
      final sellPrice = product['sell_price'] ?? 0.0;
      final minLevel = product['min_stock_level'] ?? 10;
      final unit = product['unit'] ?? 'قطعة';

      final profitPerUnit = sellPrice - costPrice;
      final profitPercentage = costPrice > 0 ? (profitPerUnit / costPrice * 100) : 0;
      final totalProfitPotential = profitPerUnit * quantity;

      final response = '''
📋 **تفاصيل المنتج: $name**

🏷️ **الباركود:** $barcode
📂 **الفئة:** $category
🏭 **المورد:** $supplier
📦 **الكمية المتاحة:** $quantity $unit
📊 **الحد الأدنى:** $minLevel $unit

💰 **التكلفة:** ${costPrice.toStringAsFixed(2)} ريال
💵 **سعر الشراء:** ${purchasePrice.toStringAsFixed(2)} ريال
🏪 **سعر البيع:** ${sellPrice.toStringAsFixed(2)} ريال
📈 **ربح الوحدة:** ${profitPerUnit.toStringAsFixed(2)} ريال
📊 **نسبة الربح:** ${profitPercentage.toStringAsFixed(2)}%
💰 **إجمالي الربح المحتمل:** ${totalProfitPotential.toStringAsFixed(2)} ريال
''';

      return {
        'success': true,
        'response': response,
        'response_type': 'text',
        'data': product,
      };
    } catch (e) {
      return _handleError(e, 'product_details');
    }
  }

  Future<Map<String, dynamic>> _handleProductProfit(Map<String, dynamic> params) async {
    final identifier = params['product_identifier']?.toString();

    if (identifier == null || identifier.isEmpty) {
      return {
        'success': false,
        'response': 'يرجى تحديد اسم المنتج أو الباركود.',
        'response_type': 'text',
      };
    }

    try {
      final product = await _dbHelper.getProductForChat(identifier);

      if (product == null) {
        return {
          'success': false,
          'response': 'لم أجد منتجاً مطابقاً لـ "$identifier".',
          'response_type': 'text',
        };
      }

      final name = product['name'] ?? 'غير معروف';
      final costPrice = product['cost_price'] ?? 0.0;
      final sellPrice = product['sell_price'] ?? 0.0;
      final quantity = product['current_quantity'] ?? 0;

      final profitPerUnit = sellPrice - costPrice;
      final profitPercentage = costPrice > 0 ? (profitPerUnit / costPrice * 100) : 0;
      final totalProfitPotential = profitPerUnit * quantity;

      final response = '''
💰 **تحليل ربحية المنتج: $name**

💵 **سعر التكلفة:** ${costPrice.toStringAsFixed(2)} ريال
🏪 **سعر البيع:** ${sellPrice.toStringAsFixed(2)} ريال
📈 **ربح الوحدة:** ${profitPerUnit.toStringAsFixed(2)} ريال
📊 **نسبة الربح:** ${profitPercentage.toStringAsFixed(2)}%
📦 **الكمية المتاحة:** $quantity وحدة
💰 **إجمالي الربح المحتمل:** ${totalProfitPotential.toStringAsFixed(2)} ريال

${profitPercentage > 30 ? '✅ **مربح جداً**' : profitPercentage > 15 ? '🟡 **مربح بشكل معقول**' : '🟠 **هامش ربح منخفض**'}
''';

      return {
        'success': true,
        'response': response,
        'response_type': 'text',
        'data': product,
      };
    } catch (e) {
      return _handleError(e, 'product_profit');
    }
  }

  Future<Map<String, dynamic>> _handleLowStockProducts() async {
    try {
      final products = await _dbHelper.getLowStockProductsForChat();

      if (products.isEmpty) {
        return {
          'success': true,
          'response': '✅ **لا توجد منتجات منخفضة المخزون حالياً.**\nجميع المنتجات في المستوى الآمن.',
          'response_type': 'text',
          'data': [],
        };
      }

      String response = '⚠️ **المنتجات المنخفضة المخزون:**\n\n';

      for (int i = 0; i < products.length && i < 15; i++) {
        final product = products[i];
        final name = product['name'] ?? 'غير معروف';
        final quantity = product['current_quantity'] ?? 0;
        final minLevel = product['min_stock_level'] ?? 10;
        final percentage = product['stock_percentage'] ?? 0.0;
        final barcode = product['barcode'] ?? 'بدون باركود';

        response += '${i + 1}. **$name**\n';
        response += '   📍 الباركود: $barcode\n';
        response += '   📦 المتاح: $quantity / $minLevel وحدة\n';
        response += '   📊 النسبة: ${percentage.toStringAsFixed(1)}%\n\n';
      }

      if (products.length > 15) {
        response += '\n... و ${products.length - 15} منتج آخر';
      }

      return {
        'success': true,
        'response': response,
        'response_type': 'text',
        'data': products,
      };
    } catch (e) {
      return _handleError(e, 'low_stock_products');
    }
  }

  Future<Map<String, dynamic>> _handleOutOfStockProducts() async {
    try {
      final products = await _dbHelper.getOutOfStockProductsForChat();

      if (products.isEmpty) {
        return {
          'success': true,
          'response': '✅ **لا توجد منتجات نافذة من المخزون حالياً.**',
          'response_type': 'text',
          'data': [],
        };
      }

      String response = '🟥 **المنتجات النافذة من المخزون:**\n\n';

      for (int i = 0; i < products.length && i < 15; i++) {
        final product = products[i];
        final name = product['name'] ?? 'غير معروف';
        final barcode = product['barcode'] ?? 'بدون باركود';
        final category = product['category_name'] ?? 'غير مصنف';

        response += '${i + 1}. **$name**\n';
        response += '   📍 الباركود: $barcode\n';
        response += '   📂 الفئة: $category\n\n';
      }

      if (products.length > 15) {
        response += '\n... و ${products.length - 15} منتج آخر';
      }

      return {
        'success': true,
        'response': response,
        'response_type': 'text',
        'data': products,
      };
    } catch (e) {
      return _handleError(e, 'out_of_stock_products');
    }
  }

  Future<Map<String, dynamic>> _handleAllProducts() async {
    try {
      final products = await _dbHelper.getProductsForChat();

      if (products.isEmpty) {
        return {
          'success': true,
          'response': '📦 **لا توجد منتجات مسجلة في النظام.**',
          'response_type': 'text',
          'data': [],
        };
      }

      String response = '📦 **جميع المنتجات:**\n\n';
      int totalQuantity = 0;
      double totalValue = 0.0;

      for (int i = 0; i < products.length && i < 10; i++) {
        final product = products[i];
        final name = product['name'] ?? 'غير معروف';
        final barcode = product['barcode'] ?? 'بدون باركود';
        final quantity = product['quantity'] as int? ?? 0; // ✅ تأكيد النوع
        final price = product['price'] as num? ?? 0.0; // ✅ تأكيد النوع

        totalQuantity += quantity;
        totalValue += quantity * price.toDouble(); // ✅ تحويل price إلى double

        response += '${i + 1}. **$name**\n';
        response += '   📍 الباركود: $barcode\n';
        response += '   📦 الكمية: $quantity وحدة\n';
        response += '   💰 السعر: ${price.toStringAsFixed(2)} ريال\n\n';
      }

      if (products.length > 10) {
        response += '... و ${products.length - 10} منتج آخر\n\n';
      }

      response += '📊 **الإجماليات:**\n';
      response += '• عدد المنتجات: ${products.length}\n';
      response += '• إجمالي الكمية: $totalQuantity وحدة\n';
      response += '• إجمالي القيمة: ${totalValue.toStringAsFixed(2)} ريال';

      return {
        'success': true,
        'response': response,
        'response_type': 'text',
        'data': products,
      };
    } catch (e) {
      return _handleError(e, 'all_products');
    }
  }
  /// === معالجة الموردين ===

  Future<Map<String, dynamic>> _handleSupplierDetails(Map<String, dynamic> params) async {
    final supplierName = params['supplier_name']?.toString();

    if (supplierName == null || supplierName.isEmpty) {
      return {
        'success': false,
        'response': 'يرجى تحديد اسم المورد.',
        'response_type': 'text',
      };
    }

    try {
      final supplier = await _dbHelper.getSupplierForChat(supplierName);

      if (supplier == null) {
        return {
          'success': false,
          'response': 'لم أجد مورداً مطابقاً لـ "$supplierName".',
          'response_type': 'text',
        };
      }

      final name = supplier['name'] ?? 'غير معروف';
      final phone = supplier['phone'] ?? 'غير متوفر';
      final email = supplier['email'] ?? 'غير متوفر';
      final balance = supplier['balance'] ?? 0.0;
      final productCount = supplier['product_count'] ?? 0;
      final totalInvestment = supplier['total_investment'] ?? 0.0;
      final purchases = supplier['purchases'] as List? ?? [];

      String response = '''
🏭 **تفاصيل المورد: $name**

📞 **الهاتف:** $phone
📧 **البريد:** $email
💰 **الرصيد:** ${balance.toStringAsFixed(2)} ريال
📦 **عدد المنتجات:** $productCount منتج
💼 **إجمالي الاستثمار:** ${totalInvestment.toStringAsFixed(2)} ريال
📋 **عدد المشتريات:** ${purchases.length} عملية

${balance < 0 ? '⚠️ **المورد مدين** (مطلوب منه ${balance.abs().toStringAsFixed(2)} ريال)' : balance > 0 ? '✅ **المورد دائن** (له ${balance.toStringAsFixed(2)} ريال)' : '🟢 **الحساب متوازن**'}
''';

      if (purchases.isNotEmpty) {
        response += '\n🛒 **آخر المشتريات:**\n';
        for (int i = 0; i < purchases.length && i < 3; i++) {
          final purchase = purchases[i];
          final invoiceNo = purchase['invoice_number'] ?? 'غير معروف';
          final amount = purchase['total_amount'] ?? 0.0;
          final date = purchase['invoice_date'] ?? 'غير معروف';

          response += '• $invoiceNo - ${amount.toStringAsFixed(2)} ريال ($date)\n';
        }
      }

      return {
        'success': true,
        'response': response,
        'response_type': 'text',
        'data': supplier,
      };
    } catch (e) {
      return _handleError(e, 'supplier_details');
    }
  }

  Future<Map<String, dynamic>> _handleAllSuppliers() async {
    try {
      final suppliers = await _dbHelper.getSuppliersForChat();

      if (suppliers.isEmpty) {
        return {
          'success': true,
          'response': '🏭 **لا توجد موردين مسجلين في النظام.**',
          'response_type': 'text',
          'data': [],
        };
      }

      String response = '🏭 **جميع الموردين:**\n\n';
      double totalBalance = 0.0;
      int totalProducts = 0;

      for (int i = 0; i < suppliers.length && i < 10; i++) {
        final supplier = suppliers[i];
        final name = supplier['name'] ?? 'غير معروف';
        final phone = supplier['phone'] ?? 'غير متوفر';
        final balance = supplier['balance'] as num? ?? 0.0; // ✅ تأكيد النوع
        final productCount = supplier['product_count'] as int? ?? 0; // ✅ تأكيد النوع

        totalBalance += balance.toDouble();
        totalProducts += productCount; // ✅ الآن productCount هو int

        response += '${i + 1}. **$name**\n';
        response += '   📞 الهاتف: $phone\n';
        response += '   💰 الرصيد: ${balance.toStringAsFixed(2)} ريال\n';
        response += '   📦 المنتجات: $productCount منتج\n\n';
      }

      if (suppliers.length > 10) {
        response += '... و ${suppliers.length - 10} مورد آخر\n\n';
      }

      response += '📊 **الإجماليات:**\n';
      response += '• عدد الموردين: ${suppliers.length}\n';
      response += '• إجمالي المنتجات: $totalProducts منتج\n';
      response += '• إجمالي الأرصدة: ${totalBalance.toStringAsFixed(2)} ريال';

      return {
        'success': true,
        'response': response,
        'response_type': 'text',
        'data': suppliers,
      };
    } catch (e) {
      return _handleError(e, 'all_suppliers');
    }
  }
  Future<Map<String, dynamic>> _handleCustomerDetails(Map<String, dynamic> params) async {
    final customerName = params['customer_name']?.toString();

    if (customerName == null || customerName.isEmpty) {
      return {
        'success': false,
        'response': 'يرجى تحديد اسم العميل.',
        'response_type': 'text',
      };
    }

    try {
      final customer = await _dbHelper.getCustomerForChat(customerName);

      if (customer == null) {
        return {
          'success': false,
          'response': 'لم أجد عميلاً مطابقاً لـ "$customerName".',
          'response_type': 'text',
        };
      }

      final name = customer['name'] ?? 'غير معروف';
      final phone = customer['phone'] ?? 'غير متوفر';
      final balance = customer['balance'] ?? 0.0;
      final invoiceCount = customer['invoice_count'] ?? 0;
      final totalSpent = customer['total_spent'] ?? 0.0;
      final totalPaid = customer['total_paid'] ?? 0.0;
      final totalRemaining = (customer['total_remaining'] as double?) ?? (totalSpent - totalPaid);
      final invoices = customer['invoices'] as List? ?? [];

      String response = '''
👤 **تفاصيل العميل: $name**

📞 **الهاتف:** $phone
💰 **الرصيد الحالي:** ${balance.toStringAsFixed(2)} ريال
🧾 **عدد الفواتير:** $invoiceCount فاتورة
💵 **إجمالي المشتريات:** ${totalSpent.toStringAsFixed(2)} ريال
💳 **إجمالي المدفوع:** ${totalPaid.toStringAsFixed(2)} ريال
📊 **المتبقي:** ${totalRemaining.toStringAsFixed(2)} ريال

${balance > 0 ? '⚠️ **العميل مدين** (مدين بـ ${balance.toStringAsFixed(2)} ريال)' : balance < 0 ? '✅ **العميل دائن** (له ${balance.abs().toStringAsFixed(2)} ريال)' : '🟢 **الحساب متوازن**'}
''';

      if (invoices.isNotEmpty) {
        response += '\n🧾 **آخر الفواتير:**\n';
        for (int i = 0; i < invoices.length && i < 3; i++) {
          final invoice = invoices[i];
          final invoiceNo = invoice['invoice_number'] ?? 'غير معروف';
          final amount = invoice['total_amount'] ?? 0.0;
          final date = invoice['invoice_date'] ?? 'غير معروف';

          response += '• $invoiceNo - ${amount.toStringAsFixed(2)} ريال ($date)\n';
        }
      }

      return {
        'success': true,
        'response': response,
        'response_type': 'text',
        'data': customer,
      };
    } catch (e) {
      return _handleError(e, 'customer_details');
    }
  }

  Future<Map<String, dynamic>> _handleAllCustomers() async {
    try {
      final customers = await _dbHelper.getCustomersForChat();

      if (customers.isEmpty) {
        return {
          'success': true,
          'response': '👤 **لا توجد عملاء مسجلين في النظام.**',
          'response_type': 'text',
          'data': [],
        };
      }

      String response = '👤 **جميع العملاء:**\n\n';
      double totalBalance = 0.0;
      double totalSpent = 0.0;

      for (int i = 0; i < customers.length && i < 10; i++) {
        final customer = customers[i];
        final name = customer['name'] ?? 'غير معروف';
        final phone = customer['phone'] ?? 'غير متوفر';
        final balance = customer['balance'] ?? 0.0;
        final invoiceCount = customer['invoice_count'] ?? 0;
        final lastPurchase = customer['last_purchase_date'] ?? 'لا يوجد';

        totalBalance += balance;

        response += '${i + 1}. **$name**\n';
        response += '   📞 الهاتف: $phone\n';
        response += '   💰 الرصيد: ${balance.toStringAsFixed(2)} ريال\n';
        response += '   🧾 الفواتير: $invoiceCount فاتورة\n';
        response += '   🕒 آخر شراء: $lastPurchase\n\n';
      }

      if (customers.length > 10) {
        response += '... و ${customers.length - 10} عميل آخر\n\n';
      }

      response += '📊 **الإجماليات:**\n';
      response += '• عدد العملاء: ${customers.length}\n';
      response += '• إجمالي الأرصدة: ${totalBalance.toStringAsFixed(2)} ريال';

      return {
        'success': true,
        'response': response,
        'response_type': 'text',
        'data': customers,
      };
    } catch (e) {
      return _handleError(e, 'all_customers');
    }
  }

  /// === معالجة المخازن ===

  Future<Map<String, dynamic>> _handleWarehouseStock(Map<String, dynamic> params) async {
    final warehouseName = params['warehouse_name']?.toString();

    if (warehouseName == null || warehouseName.isEmpty) {
      return {
        'success': false,
        'response': 'يرجى تحديد اسم المخزن.',
        'response_type': 'text',
      };
    }

    try {
      // الحصول على جميع المخازن أولاً
      final warehouses = await _dbHelper.getWarehousesForChat();

      // البحث عن المخزن المناسب
      int? warehouseId;
      String? actualWarehouseName;

      for (final warehouse in warehouses) {
        final name = warehouse['name']?.toString().toLowerCase() ?? '';
        if (name.contains(warehouseName.toLowerCase()) ||
            warehouseName.toLowerCase().contains(name)) {
          warehouseId = warehouse['id'] as int;
          actualWarehouseName = warehouse['name']?.toString();
          break;
        }
      }

      if (warehouseId == null) {
        return {
          'success': false,
          'response': 'لم أجد مخزناً مطابقاً لـ "$warehouseName".',
          'response_type': 'text',
        };
      }

      final warehouseData = await _dbHelper.getWarehouseStockForChat(warehouseId);

      if (warehouseData.isEmpty) {
        return {
          'success': true,
          'response': '🏭 **المخزن "$actualWarehouseName" فارغ حالياً.**',
          'response_type': 'text',
          'data': warehouseData,
        };
      }

      final productCount = warehouseData['product_count'] ?? 0;
      final totalQuantity = warehouseData['total_quantity'] ?? 0;
      final totalValue = warehouseData['total_value'] ?? 0.0;
      final products = warehouseData['products'] as List? ?? [];

      String response = '''
🏭 **مخزون المخزن: $actualWarehouseName**

📊 **الإحصائيات:**
• عدد المنتجات: $productCount منتج
• إجمالي الكمية: $totalQuantity وحدة
• إجمالي القيمة: ${totalValue.toStringAsFixed(2)} ريال

📦 **المنتجات الرئيسية:**
''';

      for (int i = 0; i < products.length && i < 10; i++) {
        final product = products[i];
        final name = product['name'] ?? 'غير معروف';
        final quantity = product['current_quantity'] ?? 0;
        final price = product['sell_price'] ?? 0.0;
        final profit = product['profit_per_unit'] ?? 0.0;

        response += '${i + 1}. **$name**\n';
        response += '   📦 الكمية: $quantity وحدة\n';
        response += '   💰 السعر: ${price.toStringAsFixed(2)} ريال\n';
        response += '   📈 الربح/وحدة: ${profit.toStringAsFixed(2)} ريال\n\n';
      }

      if (products.length > 10) {
        response += '\n... و ${products.length - 10} منتج آخر';
      }

      return {
        'success': true,
        'response': response,
        'response_type': 'text',
        'data': warehouseData,
      };
    } catch (e) {
      return _handleError(e, 'warehouse_stock');
    }
  }

  Future<Map<String, dynamic>> _handleAllWarehouses() async {
    try {
      final warehouses = await _dbHelper.getWarehousesForChat();

      if (warehouses.isEmpty) {
        return {
          'success': true,
          'response': '🏭 **لا توجد مخازن مسجلة في النظام.**',
          'response_type': 'text',
          'data': [],
        };
      }

      String response = '🏭 **جميع المخازن:**\n\n';
      int totalProducts = 0;
      int totalQuantity = 0;
      double totalValue = 0.0;

      for (int i = 0; i < warehouses.length && i < 10; i++) {
        final warehouse = warehouses[i];
        final name = warehouse['name'] ?? 'غير معروف';
        final address = warehouse['address'] ?? 'غير محدد';
        final productCount = warehouse['product_count'] as int? ?? 0; // ✅ تأكيد النوع
        final quantity = warehouse['total_quantity'] as int? ?? 0; // ✅ تأكيد النوع
        final value = warehouse['total_value'] as num? ?? 0.0; // ✅ تأكيد النوع

        totalProducts += productCount; // ✅ الآن productCount هو int
        totalQuantity += quantity; // ✅ الآن quantity هو int
        totalValue += value.toDouble();

        response += '${i + 1}. **$name**\n';
        response += '   📍 الموقع: $address\n';
        response += '   📦 المنتجات: $productCount منتج\n';
        response += '   🔢 الكمية: $quantity وحدة\n';
        response += '   💰 القيمة: ${value.toStringAsFixed(2)} ريال\n\n';
      }

      if (warehouses.length > 10) {
        response += '... و ${warehouses.length - 10} مخزن آخر\n\n';
      }

      response += '📊 **الإجماليات:**\n';
      response += '• عدد المخازن: ${warehouses.length}\n';
      response += '• إجمالي المنتجات: $totalProducts منتج\n';
      response += '• إجمالي الكمية: $totalQuantity وحدة\n';
      response += '• إجمالي القيمة: ${totalValue.toStringAsFixed(2)} ريال';

      return {
        'success': true,
        'response': response,
        'response_type': 'text',
        'data': warehouses,
      };
    } catch (e) {
      return _handleError(e, 'all_warehouses');
    }
  }
  Future<Map<String, dynamic>> _handleFinancialSummary(Map<String, dynamic> params) async {
    final period = params['period']?.toString() ?? 'today';

    try {
      final summary = await _dbHelper.getFinancialSummaryForChat(period);

      if (summary.isEmpty) {
        return {
          'success': true,
          'response': '💰 **لا توجد بيانات مالية متاحة للفترة المحددة.**',
          'response_type': 'text',
          'data': summary,
        };
      }

      final periodStr = _translatePeriod(period);
      final totalSales = summary['total_sales'] ?? 0.0;
      final totalPurchases = summary['total_purchases'] ?? 0.0;
      final totalProfit = summary['total_profit'] ?? 0.0;
      final totalDebts = summary['total_debts'] ?? 0.0;
      final netIncome = summary['net_income'] ?? 0.0;

      final profitMargin = totalSales > 0 ? (totalProfit / totalSales * 100) : 0;
      final purchaseRatio = totalSales > 0 ? (totalPurchases / totalSales * 100) : 0;
      final debtRatio = totalSales > 0 ? (totalDebts / totalSales * 100) : 0;

      String response = '''
💰 **الملخص المالي ($periodStr)**

📈 **الإيرادات:**
• إجمالي المبيعات: ${totalSales.toStringAsFixed(2)} ريال
• إجمالي الأرباح: ${totalProfit.toStringAsFixed(2)} ريال
• صافي الدخل: ${netIncome.toStringAsFixed(2)} ريال

📉 **التكاليف:**
• إجمالي المشتريات: ${totalPurchases.toStringAsFixed(2)} ريال
• إجمالي الديون: ${totalDebts.toStringAsFixed(2)} ريال

📊 **المؤشرات:**
• هامش الربح: ${profitMargin.toStringAsFixed(2)}%
• نسبة المشتريات: ${purchaseRatio.toStringAsFixed(2)}%
• نسبة الديون: ${debtRatio.toStringAsFixed(2)}%

${profitMargin > 20 ? '✅ **أداء مالي ممتاز**' : profitMargin > 10 ? '🟡 **أداء مالي جيد**' : '🟠 **أداء مالي بحاجة لتحسين**'}
''';

      return {
        'success': true,
        'response': response,
        'response_type': 'text',
        'data': summary,
      };
    } catch (e) {
      return _handleError(e, 'financial_summary');
    }
  }

  /// ترجمة الفترة الزمنية
  String _translatePeriod(String period) {
    switch (period) {
      case 'today': return 'اليوم';
      case 'week': return 'الأسبوع';
      case 'month': return 'الشهر';
      case 'year': return 'السنة';
      default: return 'اليوم';
    }
  }

  /// === العمليات الأخيرة ===

  Future<Map<String, dynamic>> _handleRecentOperations(Map<String, dynamic> params) async {
    final limit = params['limit'] ?? 10;

    try {
      final operations = await _dbHelper.getRecentOperationsForChat(limit);

      if (operations.isEmpty) {
        return {
          'success': true,
          'response': '🔄 **لا توجد عمليات حديثة.**',
          'response_type': 'text',
          'data': [],
        };
      }

      String response = '🔄 **آخر العمليات:**\n\n';
      double totalAmount = 0.0;

      for (int i = 0; i < operations.length && i < limit; i++) {
        final operation = operations[i];
        final type = operation['type'] ?? 'غير معروف';
        final description = operation['description'] ?? 'عملية غير معروفة';
        final amount = operation['amount'] ?? 0.0;
        final date = operation['date'] ?? 'غير معروف';

        totalAmount += amount;

        final typeEmoji = _getOperationEmoji(type);

        response += '${i + 1}. $typeEmoji **$description**\n';
        response += '   💰 المبلغ: ${amount.toStringAsFixed(2)} ريال\n';
        response += '   🕒 التاريخ: $date\n\n';
      }

      response += '📊 **الإجمالي:** ${totalAmount.toStringAsFixed(2)} ريال';

      return {
        'success': true,
        'response': response,
        'response_type': 'text',
        'data': operations,
      };
    } catch (e) {
      return _handleError(e, 'recent_operations');
    }
  }

  /// الحصول على إيموجي حسب نوع العملية
  String _getOperationEmoji(String type) {
    switch (type) {
      case 'sale': return '💰';
      case 'purchase': return '🛒';
      case 'receipt': return '💳';
      case 'payment': return '💸';
      default: return '📄';
    }
  }

  /// === معلومات النظام ===

  Future<Map<String, dynamic>> _handleSystemInfo() async {
    try {
      final systemInfo = await _dbHelper.getAdvancedSystemInfo();

      if (systemInfo.isEmpty) {
        return {
          'success': true,
          'response': '🖥️ **لا توجد معلومات متاحة عن النظام.**',
          'response_type': 'text',
          'data': systemInfo,
        };
      }

      final users = systemInfo['users'] as Map<String, dynamic>? ?? {};
      final products = systemInfo['products'] as Map<String, dynamic>? ?? {};
      final warehouses = systemInfo['warehouses'] as Map<String, dynamic>? ?? {};
      final financial = systemInfo['financial'] as Map<String, dynamic>? ?? {};
      final today = systemInfo['today'] as Map<String, dynamic>? ?? {};

      String response = '''
🖥️ **نظرة عامة على النظام**

👥 **المستخدمون:**
• إجمالي المستخدمين: ${users['total_users'] ?? 0}
• المستخدمون النشطون: ${users['active_users'] ?? 0}
• المسؤولون: ${users['admins'] ?? 0}

📦 **المنتجات:**
• إجمالي المنتجات: ${products['total_products'] ?? 0}
• القيمة الإجمالية: ${(products['total_stock_value'] as double? ?? 0).toStringAsFixed(2)} ريال
• المنتجات النافذة: ${products['out_of_stock'] ?? 0}
• المنتجات المنخفضة: ${products['low_stock'] ?? 0}

🏭 **المخازن:**
• عدد المخازن: ${warehouses['total_warehouses'] ?? 0}
• المخازن النشطة: ${warehouses['active_warehouses'] ?? 0}

💰 **المالية:**
• إجمالي المبيعات: ${(financial['total_sales'] as double? ?? 0).toStringAsFixed(2)} ريال
• إجمالي المشتريات: ${(financial['total_purchases'] as double? ?? 0).toStringAsFixed(2)} ريال
• الرصيد النقدي: ${(financial['current_cash_balance'] as double? ?? 0).toStringAsFixed(2)} ريال

📅 **اليوم:**
• فواتير البيع: ${today['today_sales_count'] ?? 0}
• مبيعات اليوم: ${(today['today_sales_amount'] as double? ?? 0).toStringAsFixed(2)} ريال
• الأنشطة: ${today['today_activities'] ?? 0}
''';

      return {
        'success': true,
        'response': response,
        'response_type': 'text',
        'data': systemInfo,
      };
    } catch (e) {
      return _handleError(e, 'system_info');
    }
  }

  /// === التنبيهات ===

  Future<Map<String, dynamic>> _handleSystemAlerts() async {
    try {
      final alerts = await _dbHelper.getSystemAlertsSummary();

      if (alerts.isEmpty) {
        return {
          'success': true,
          'response': '✅ **لا توجد تنبيهات حالياً.**\nكل شيء يعمل بشكل طبيعي.',
          'response_type': 'text',
          'data': alerts,
        };
      }

      String response = '⚠️ **ملخص التنبيهات:**\n\n';
      int totalAlerts = 0;
      int unreadAlerts = 0;

      for (final alert in alerts) {
        final type = alert['alert_type'] ?? 'غير معروف';
        final priority = alert['priority'] ?? 'medium';
        final count = alert['count'] as int? ?? 0; // ✅ تأكيد النوع
        final unread = alert['unread_count'] as int? ?? 0; // ✅ تأكيد النوع

        totalAlerts += count; // ✅ الآن count هو int
        unreadAlerts += unread; // ✅ الآن unread هو int

        final priorityEmoji = _getPriorityEmoji(priority);
        final typeStr = _translateAlertType(type);

        response += '$priorityEmoji **$typeStr:**\n';
        response += '   🔢 العدد: $count تنبيه\n';
        response += '   📌 غير المقروء: $unread\n\n';
      }

      response += '📊 **الإجمالي:** $totalAlerts تنبيه ($unreadAlerts غير مقروء)';

      return {
        'success': true,
        'response': response,
        'response_type': 'text',
        'data': alerts,
      };
    } catch (e) {
      return _handleError(e, 'system_alerts');
    }
  }
  /// الحصول على إيموجي حسب الأولوية
  String _getPriorityEmoji(String priority) {
    switch (priority) {
      case 'critical': return '🟥';
      case 'high': return '🟧';
      case 'medium': return '🟨';
      case 'low': return '🟩';
      default: return '⚪';
    }
  }

  /// ترجمة نوع التنبيه
  String _translateAlertType(String type) {
    switch (type) {
      case 'low_stock': return 'مخزون منخفض';
      case 'expiry': return 'انتهاء صلاحية';
      case 'payment_due': return 'مدفوعات مستحقة';
      case 'system': return 'نظام';
      default: return type;
    }
  }

  /// === المساعدة ===

  Future<Map<String, dynamic>> _handleHelp() async {
    String response = '''
🤖 **مرحباً بك في مساعد المخزون الذكي!**

أنا هنا لمساعدتك في استعلامات وإدارة نظام المخزون. يمكنك سؤالي عن:

📦 **المنتجات والمخزون:**
• "كم كمية منتج [اسم المنتج]؟" - للتحقق من المخزون
• "عرض تفاصيل المنتج [اسم/باركود]" - لعرض بيانات المنتج
• "ما هي المنتجات المنخفضة؟" - للمنتجات قاربت على النفاد
• "عرض المنتجات النافذة" - للمنتجات المنتهية
• "عرض جميع المنتجات" - لقائمة المنتجات
• "ربح المنتج [اسم المنتج]" - لتحليل الربحية

💰 **المالية والمبيعات:**
• "عرض المبيعات اليوم/الأسبوع/الشهر" - لتقرير المبيعات
• "آخر المبيعات" - لأحدث عمليات البيع
• "إجمالي المبيعات اليوم/الأسبوع/الشهر" - للملخص المالي
• "الأرباح" - للتقرير المالي
• "آخر 10 عمليات" - للحركات الحديثة

👥 **العملاء:**
• "عرض بيانات العميل [اسم العميل]" - لمعلومات العميل
• "عرض جميع العملاء" - لقائمة العملاء
• "اضافة عميل جديد" - لإضافة عميل جديد
• "عرض فاتورة [رقم الفاتورة]" - لتفاصيل الفاتورة

🏭 **الموردين والمخازن:**
• "عرض بيانات المورد [اسم المورد]" - لمعلومات المورد
• "عرض جميع الموردين" - لقائمة الموردين
• "مخزون المخزن [اسم المخزن]" - لعرض مخزون مخزن معين
• "عرض جميع المخازن" - لقائمة المخازن

👤 **المستخدمين والصلاحيات:**
• "عرض صلاحيات المستخدم [اسم المستخدم]" - لعرض صلاحيات مستخدم
• "عرض جميع المستخدمين" - لقائمة المستخدمين

🖥️ **النظام:**
• "معلومات النظام" - لنظرة عامة على النظام
• "عرض التنبيهات" - لملخص التنبيهات

💡 **نصائح:**
• يمكنك استخدام أسماء المنتجات أو الباركود
• الأسئلة باللغة العربية أو العامية
• النظام يعمل 100% بدون إنترنت
• OpenAI متاح كنسخة احتياطية إذا لزم الأمر

💬 **أمثلة:**
• "كم كمية التفاح؟"
• "عرض تفاصيل المنتج 123456789"
• "ما هي المنتجات المنخفضة؟"
• "عرض المبيعات اليوم"
• "آخر 15 عملية بيع"
• "عرض بيانات العميل محمد"
• "مخزون المخزن الرئيسي"
• "عرض جميع العملاء"
• "عرض صلاحيات المستخدم أحمد"
''';

    return {
      'success': true,
      'response': response,
      'response_type': 'text',
      'data': null,
    };
  }
}

// في intent_result.dart
class IntentResult {
  final String intent;
  final double confidence;
  final String source;
  final String entity;

  IntentResult({
    required this.intent,
    required this.confidence,
    required this.source,
    this.entity = 'unknown',
  });

  // تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'intent': intent,
      'confidence': confidence,
      'source': source,
      'entity': entity,
    };
  }

  // إنشاء من Map
  factory IntentResult.fromMap(Map<String, dynamic> map) {
    return IntentResult(
      intent: map['intent'] ?? 'unknown',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      source: map['source'] ?? 'unknown',
      entity: map['entity'] ?? 'unknown',
    );
  }
}
