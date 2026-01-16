import 'dart:convert';
import 'dart:async';

import '../database_helper.dart';

class SmartAssistant {
  // استخدم قاعدة البيانات الخاصة بك
  final DatabaseHelper dbHelper = DatabaseHelper();

  Future<String> answerQuestion(String question) async {
    try {
      // 1. تحليل السؤال
      QueryAnalysis analysis = await _analyzeQuestion(question);

      // 2. جمع البيانات من قاعدة البيانات
      dynamic data = await _fetchDataFromDB(analysis);

      // 3. توليد الرد
      String response = await _generateResponse(analysis, data);

      return response;
    } catch (e) {
      return 'عذرًا، حدث خطأ: ${e.toString()}';
    }
  }

  Future<QueryAnalysis> _analyzeQuestion(String question) async {
    question = question.toLowerCase();

    // تحليل النية
    QueryIntent intent = QueryIntent.general;

    // فحص الكلمات المفتاحية
    Map<String, QueryIntent> keywordMap = {
      // المنتجات
      'منتج': QueryIntent.products,
      'صنف': QueryIntent.products,
      'سلعة': QueryIntent.products,
      'بضاعة': QueryIntent.products,
      'باركود': QueryIntent.products,
      'كمية': QueryIntent.stock,
      'مخزون': QueryIntent.stock,
      'رصيد': QueryIntent.stock,

      // الفواتير
      'فاتورة': QueryIntent.invoices,
      'بيع': QueryIntent.sales,
      'شراء': QueryIntent.purchases,
      'مبيعات': QueryIntent.sales,
      'مشتريات': QueryIntent.purchases,
      'مرتجع': QueryIntent.returns,

      // العملاء
      'عميل': QueryIntent.customers,
      'زبون': QueryIntent.customers,
      'مديونية': QueryIntent.customers,
      'رصيد عميل': QueryIntent.customers,

      // الموردين
      'مورد': QueryIntent.suppliers,
      'مزود': QueryIntent.suppliers,

      // المستخدمين
      'مستخدم': QueryIntent.users,
      'موظف': QueryIntent.users,
      'صلاحية': QueryIntent.users,

      // التقارير
      'تقرير': QueryIntent.reports,
      'إحصائية': QueryIntent.reports,
      'إحصائيات': QueryIntent.reports,
      'بيان': QueryIntent.reports,
      'dashboard': QueryIntent.reports,

      // المالية
      'مالي': QueryIntent.financial,
      'دخل': QueryIntent.financial,
      'ربح': QueryIntent.financial,
      'خسارة': QueryIntent.financial,
      'صندوق': QueryIntent.financial,
    };

    // البحث عن الكلمة المفتاحية
    for (var entry in keywordMap.entries) {
      if (question.contains(entry.key)) {
        intent = entry.value;
        break;
      }
    }

    // استخراج الكيانات
    List<String> entities = _extractEntities(question);

    return QueryAnalysis(
      intent: intent,
      entities: entities,
      originalQuestion: question,
    );
  }

  List<String> _extractEntities(String question) {
    List<String> entities = [];

    // استخراج الأرقام
    RegExp numRegex = RegExp(r'\d+');
    entities.addAll(numRegex.allMatches(question).map((m) => m.group(0)!).toList());

    // استخراج التواريخ
    RegExp dateRegex = RegExp(r'\d{1,2}/\d{1,2}/\d{4}');
    entities.addAll(dateRegex.allMatches(question).map((m) => m.group(0)!).toList());

    return entities;
  }

  Future<dynamic> _fetchDataFromDB(QueryAnalysis analysis) async {
    switch (analysis.intent) {
      case QueryIntent.products:
        return await _fetchProductsData(analysis.entities);
      case QueryIntent.stock:
        return await _fetchStockData(analysis.entities);
      case QueryIntent.invoices:
        return await _fetchInvoicesData(analysis.entities);
      case QueryIntent.sales:
        return await _fetchSalesData(analysis.entities);
      case QueryIntent.purchases:
        return await _fetchPurchasesData(analysis.entities);
      case QueryIntent.customers:
        return await _fetchCustomersData(analysis.entities);
      case QueryIntent.suppliers:
        return await _fetchSuppliersData(analysis.entities);
      case QueryIntent.users:
        return await _fetchUsersData(analysis.entities);
      case QueryIntent.reports:
        return await _fetchReportsData(analysis.entities);
      case QueryIntent.financial:
        return await _fetchFinancialData(analysis.entities);
      case QueryIntent.returns:
        return await _fetchReturnsData(analysis.entities);
      default:
        return await _fetchGeneralData(analysis.entities);
    }
  }

  // ============ الدوال الناقصة ============

  Future<Map<String, dynamic>> _fetchSalesData(List<String> entities) async {
    final db = await dbHelper.database;

    // المبيعات اليوم
    var todaySales = await db.rawQuery('''
      SELECT COUNT(*) as count, SUM(total_amount) as total, 
             SUM(paid_amount) as paid, SUM(remaining_amount) as remaining
      FROM sale_invoices 
      WHERE DATE(invoice_date) = DATE('now') AND status = 'approved'
    ''');

    // المبيعات هذا الشهر
    var monthSales = await db.rawQuery('''
      SELECT COUNT(*) as count, SUM(total_amount) as total
      FROM sale_invoices 
      WHERE strftime('%Y-%m', invoice_date) = strftime('%Y-%m', 'now') 
      AND status = 'approved'
    ''');

    // أفضل المنتجات مبيعاً
    var topProducts = await db.rawQuery('''
      SELECT p.name, SUM(si.quantity) as sold_quantity
      FROM sale_items si
      JOIN products p ON si.product_id = p.id
      JOIN sale_invoices s ON si.sale_invoice_id = s.id
      WHERE s.status = 'approved'
      GROUP BY p.id
      ORDER BY sold_quantity DESC
      LIMIT 5
    ''');

    return {
      'type': 'sales_report',
      'today': {
        'count': todaySales.first['count'] ?? 0,
        'total': todaySales.first['total'] ?? 0.0,
        'paid': todaySales.first['paid'] ?? 0.0,
        'remaining': todaySales.first['remaining'] ?? 0.0,
      },
      'month': {
        'count': monthSales.first['count'] ?? 0,
        'total': monthSales.first['total'] ?? 0.0,
      },
      'top_products': topProducts,
    };
  }

  Future<Map<String, dynamic>> _fetchPurchasesData(List<String> entities) async {
    final db = await dbHelper.database;

    // المشتريات اليوم
    var todayPurchases = await db.rawQuery('''
      SELECT COUNT(*) as count, SUM(total_amount) as total
      FROM purchase_invoices 
      WHERE DATE(invoice_date) = DATE('now') AND status = 'approved'
    ''');

    // الموردين الأكثر تعاملاً
    var topSuppliers = await db.rawQuery('''
      SELECT s.name, COUNT(pi.id) as invoice_count, SUM(pi.total_amount) as total_amount
      FROM purchase_invoices pi
      JOIN suppliers s ON pi.supplier_id = s.id
      WHERE pi.status = 'approved'
      GROUP BY s.id
      ORDER BY total_amount DESC
      LIMIT 5
    ''');

    return {
      'type': 'purchases_report',
      'today': {
        'count': todayPurchases.first['count'] ?? 0,
        'total': todayPurchases.first['total'] ?? 0.0,
      },
      'top_suppliers': topSuppliers,
    };
  }

  Future<Map<String, dynamic>> _fetchSuppliersData(List<String> entities) async {
    List<Map<String, dynamic>> suppliers = await dbHelper.getSuppliers();

    // الموردين ذوي الرصيد العالي
    List<Map<String, dynamic>> highBalanceSuppliers = suppliers.where((s) {
      double balance = s['balance'] ?? 0.0;
      return balance > 0;
    }).toList();

    return {
      'type': 'suppliers_report',
      'total_suppliers': suppliers.length,
      'total_balance': suppliers.fold(0.0, (sum, s) => sum + (s['balance'] ?? 0.0)),
      'high_balance_count': highBalanceSuppliers.length,
      'high_balance_suppliers': highBalanceSuppliers.take(5).toList(),
    };
  }

  Future<Map<String, dynamic>> _fetchUsersData(List<String> entities) async {
    final db = await dbHelper.database;

    // المستخدمين النشطين
    var activeUsers = await db.rawQuery('''
      SELECT COUNT(*) as count FROM users WHERE is_active = 1
    ''');

    // توزيع المستخدمين حسب الدور
    var usersByRole = await db.rawQuery('''
      SELECT role, COUNT(*) as count
      FROM users 
      WHERE is_active = 1
      GROUP BY role
    ''');

    return {
      'type': 'users_report',
      'total_active': activeUsers.first['count'] ?? 0,
      'by_role': usersByRole,
    };
  }

  Future<Map<String, dynamic>> _fetchReportsData(List<String> entities) async {
    // استخدام دالة getDashboardStats الموجودة في DatabaseHelper
    return await dbHelper.getDashboardStats();
  }

  Future<Map<String, dynamic>> _fetchFinancialData(List<String> entities) async {
    final db = await dbHelper.database;

    // رصيد الصندوق الحالي
    var cashBalance = await db.rawQuery('''
      SELECT balance_after FROM cash_ledger ORDER BY id DESC LIMIT 1
    ''');

    // الحركات المالية اليوم
    var todayTransactions = await db.rawQuery('''
      SELECT transaction_type, SUM(amount) as total
      FROM cash_ledger 
      WHERE DATE(transaction_date) = DATE('now')
      GROUP BY transaction_type
    ''');

    // الأرباح الشهرية
    var monthlyProfit = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', s.invoice_date) as month,
        SUM(si.quantity * (si.unit_price - si.cost_price)) as profit
      FROM sale_items si
      JOIN sale_invoices s ON si.sale_invoice_id = s.id
      WHERE s.status = 'approved'
      GROUP BY strftime('%Y-%m', s.invoice_date)
      ORDER BY month DESC
      LIMIT 6
    ''');

    return {
      'type': 'financial_report',
      'cash_balance': cashBalance.isNotEmpty ? cashBalance.first['balance_after'] ?? 0.0 : 0.0,
      'today_transactions': todayTransactions,
      'monthly_profit': monthlyProfit,
    };
  }

  Future<Map<String, dynamic>> _fetchReturnsData(List<String> entities) async {
    final db = await dbHelper.database;

    // مرتجعات المبيعات
    var salesReturns = await db.rawQuery('''
      SELECT COUNT(*) as count, SUM(total_amount) as total
      FROM sale_returns 
      WHERE status = 'approved'
      AND DATE(return_date) = DATE('now')
    ''');

    // مرتجعات المشتريات
    var purchaseReturns = await db.rawQuery('''
      SELECT COUNT(*) as count, SUM(total_amount) as total
      FROM purchase_returns 
      WHERE status = 'approved'
      AND DATE(return_date) = DATE('now')
    ''');

    return {
      'type': 'returns_report',
      'sales_returns': {
        'count': salesReturns.first['count'] ?? 0,
        'total': salesReturns.first['total'] ?? 0.0,
      },
      'purchase_returns': {
        'count': purchaseReturns.first['count'] ?? 0,
        'total': purchaseReturns.first['total'] ?? 0.0,
      },
    };
  }

  Future<Map<String, dynamic>> _fetchGeneralData(List<String> entities) async {
    // إحصائيات عامة
    var stats = await dbHelper.getDashboardStats();

    return {
      'type': 'general_stats',
      'stats': stats,
    };
  }

  // ============ الدوال الموجودة سابقاً ============

  Future<Map<String, dynamic>> _fetchProductsData(List<String> entities) async {
    // البحث عن المنتجات
    List<Map<String, dynamic>> products = await dbHelper.getProducts();

    // إذا كان هناك كيان رقمي، افترض أنه ID أو باركود
    for (String entity in entities) {
      if (int.tryParse(entity) != null) {
        // البحث بالباركود أو ID
        var product = await dbHelper.getProductByBarcode(entity);
        if (product != null) {
          return {
            'type': 'product',
            'data': product,
            'total': 1,
          };
        }
      }
    }

    // البحث بالاسم
    if (entities.any((e) => e.length > 2)) {
      String searchTerm = entities.firstWhere(
            (e) => e.length > 2,
        orElse: () => '',
      );

      if (searchTerm.isNotEmpty) {
        products = products.where((p) {
          String name = (p['name'] ?? '').toString().toLowerCase();
          return name.contains(searchTerm.toLowerCase());
        }).toList();
      }
    }

    return {
      'type': 'products_list',
      'data': products,
      'total': products.length,
      'low_stock': products.where((p) =>
      (p['current_quantity'] ?? 0) <= (p['min_stock_level'] ?? 0)
      ).length,
    };
  }

  Future<Map<String, dynamic>> _fetchStockData(List<String> entities) async {
    List<Map<String, dynamic>> products = await dbHelper.getProducts();

    int totalQuantity = products.fold<int>(0,
            (sum, p) => sum + dbHelper.safeParseInt(p['current_quantity'])
    );

    double totalValue = products.fold<double>(0.0,
            (sum, p) {
          int qty = dbHelper.safeParseInt(p['current_quantity']);
          double cost = dbHelper.safeParseDouble(p['cost_price']);
          return sum + (qty * cost);
        }
    );

    List<Map<String, dynamic>> lowStock = products.where((p) {
      int current = dbHelper.safeParseInt(p['current_quantity']);
      int min = dbHelper.safeParseInt(p['min_stock_level']);
      return current <= min;
    }).toList();

    return {
      'type': 'stock_report',
      'total_products': products.length,
      'total_quantity': totalQuantity,
      'total_value': totalValue,
      'low_stock_count': lowStock.length,
      'low_stock_items': lowStock.take(5).toList(),
    };
  }
  Future<Map<String, dynamic>> _fetchInvoicesData(List<String> entities) async {
    final db = await dbHelper.database;

    // فواتير اليوم
    var todaySales = await db.rawQuery('''
      SELECT COUNT(*) as count, SUM(total_amount) as total
      FROM sale_invoices 
      WHERE DATE(invoice_date) = DATE('now') AND status = 'approved'
    ''');

    // فواتير البارحة
    var yesterdaySales = await db.rawQuery('''
      SELECT COUNT(*) as count, SUM(total_amount) as total
      FROM sale_invoices 
      WHERE DATE(invoice_date) = DATE('now', '-1 day') AND status = 'approved'
    ''');

    // فواتير معلقة
    var pendingInvoices = await db.rawQuery('''
      SELECT COUNT(*) as count, SUM(total_amount) as total
      FROM sale_invoices 
      WHERE status = 'draft' OR status = 'pending'
    ''');

    return {
      'type': 'invoices_summary',
      'today': {
        'count': todaySales.first['count'] ?? 0,
        'total': todaySales.first['total'] ?? 0.0,
      },
      'yesterday': {
        'count': yesterdaySales.first['count'] ?? 0,
        'total': yesterdaySales.first['total'] ?? 0.0,
      },
      'pending': {
        'count': pendingInvoices.first['count'] ?? 0,
        'total': pendingInvoices.first['total'] ?? 0.0,
      },
    };
  }

  Future<Map<String, dynamic>> _fetchCustomersData(List<String> entities) async {
    List<Map<String, dynamic>> customers = await dbHelper.getCustomers();

    // العملاء المتأخرين
    List<Map<String, dynamic>> lateCustomers = customers.where((c) {
      double balance = c['balance'] ?? 0.0;
      double creditLimit = c['credit_limit'] ?? 0.0;
      return balance > creditLimit;
    }).toList();

    // العملاء النشطين
    List<Map<String, dynamic>> activeCustomers = customers.where((c) {
      return (c['balance'] ?? 0.0) > 0;
    }).toList();

    return {
      'type': 'customers_report',
      'total_customers': customers.length,
      'total_balance': customers.fold(0.0, (sum, c) => sum + (c['balance'] ?? 0.0)),
      'late_customers_count': lateCustomers.length,
      'late_customers': lateCustomers.take(5).toList(),
      'active_customers_count': activeCustomers.length,
    };
  }

  // ============ دوال توليد الردود ============

  Future<String> _generateResponse(QueryAnalysis analysis, dynamic data) async {
    switch (analysis.intent) {
      case QueryIntent.products:
        return _generateProductsResponse(data);
      case QueryIntent.stock:
        return _generateStockResponse(data);
      case QueryIntent.invoices:
        return _generateInvoicesResponse(data);
      case QueryIntent.sales:
        return _generateSalesResponse(data);
      case QueryIntent.purchases:
        return _generatePurchasesResponse(data);
      case QueryIntent.customers:
        return _generateCustomersResponse(data);
      case QueryIntent.suppliers:
        return _generateSuppliersResponse(data);
      case QueryIntent.users:
        return _generateUsersResponse(data);
      case QueryIntent.reports:
        return _generateReportsResponse(data);
      case QueryIntent.financial:
        return _generateFinancialResponse(data);
      case QueryIntent.returns:
        return _generateReturnsResponse(data);
      default:
        return _generateGeneralResponse(analysis, data);
    }
  }

  String _generateProductsResponse(dynamic data) {
    if (data['type'] == 'product') {
      var product = data['data'];
      return '''
📦 **معلومات المنتج:**

**الاسم:** ${product['name']}
**الباركود:** ${product['barcode'] ?? 'غير محدد'}
**الفئة:** ${product['category_name'] ?? 'غير مصنف'}
**المورد:** ${product['supplier_name'] ?? 'غير محدد'}
**الوحدة:** ${product['unit']}

**الأسعار:**
- سعر الشراء: ${product['purchase_price'] ?? 0} ريال
- سعر البيع: ${product['sell_price'] ?? 0} ريال
- سعر التكلفة: ${product['cost_price'] ?? 0} ريال

**المخزون:**
- الكمية الحالية: ${product['current_quantity'] ?? 0}
- الحد الأدنى: ${product['min_stock_level'] ?? 0}
- الكمية الأولية: ${product['initial_quantity'] ?? 0}

**الحالة:** ${(product['is_active'] ?? 0) == 1 ? '✅ نشط' : '❌ غير نشط'}
''';
    } else {
      return '''
📦 **المنتجات:**

إجمالي المنتجات: **${data['total']}** منتج
المنتجات قليلة المخزون: **${data['low_stock']}** منتج

${data['total'] > 0 ? 'جرب أن تسأل عن منتج محدد بالاسم أو الباركود' : 'لا توجد منتجات مسجلة'}
''';
    }
  }

  String _generateStockResponse(dynamic data) {
    String lowStockItems = '';
    if (data['low_stock_count'] > 0) {
      lowStockItems = '\n**أهم 5 منتجات قليلة المخزون:**\n';
      for (var product in data['low_stock_items']) {
        lowStockItems += '• ${product['name']} (${product['current_quantity']}/${product['min_stock_level']})\n';
      }
    }

    return '''
📊 **تقرير المخزون:**

**الإجماليات:**
- عدد المنتجات: ${data['total_products']}
- الكمية الكلية: ${data['total_quantity']}
- القيمة الإجمالية: ${data['total_value'].toStringAsFixed(2)} ريال

**المنتجات قليلة المخزون:**
${data['low_stock_count']} منتج يحتاج لإعادة طلب
${lowStockItems}
''';
  }

  String _generateInvoicesResponse(dynamic data) {
    return '''
🧾 **ملخص الفواتير:**

**اليوم:** 
- عدد الفواتير: ${data['today']['count']}
- إجمالي المبيعات: ${data['today']['total'].toStringAsFixed(2)} ريال

**الأمس:**
- عدد الفواتير: ${data['yesterday']['count']}
- إجمالي المبيعات: ${data['yesterday']['total'].toStringAsFixed(2)} ريال

**الفواتير المعلقة:**
- عدد الفواتير: ${data['pending']['count']}
- القيمة الإجمالية: ${data['pending']['total'].toStringAsFixed(2)} ريال
''';
  }

  String _generateSalesResponse(dynamic data) {
    String topProducts = '';
    for (var product in data['top_products']) {
      topProducts += '• ${product['name']}: ${product['sold_quantity']} قطعة\n';
    }

    return '''
💰 **تقرير المبيعات:**

**اليوم:**
- عدد الفواتير: ${data['today']['count']}
- الإجمالي: ${data['today']['total'].toStringAsFixed(2)} ريال
- المدفوع: ${data['today']['paid'].toStringAsFixed(2)} ريال
- المتبقي: ${data['today']['remaining'].toStringAsFixed(2)} ريال

**هذا الشهر:**
- عدد الفواتير: ${data['month']['count']}
- الإجمالي: ${data['month']['total'].toStringAsFixed(2)} ريال

**أفضل المنتجات مبيعاً:**
${topProducts.isNotEmpty ? topProducts : 'لا توجد بيانات'}
''';
  }

  String _generatePurchasesResponse(dynamic data) {
    String topSuppliers = '';
    for (var supplier in data['top_suppliers']) {
      topSuppliers += '• ${supplier['name']}: ${supplier['total_amount'].toStringAsFixed(2)} ريال\n';
    }

    return '''
🛒 **تقرير المشتريات:**

**اليوم:**
- عدد فواتير الشراء: ${data['today']['count']}
- إجمالي المشتريات: ${data['today']['total'].toStringAsFixed(2)} ريال

**الموردين الأكثر تعاملاً:**
${topSuppliers.isNotEmpty ? topSuppliers : 'لا توجد بيانات'}
''';
  }

  String _generateCustomersResponse(dynamic data) {
    String lateCustomers = '';
    if (data['late_customers_count'] > 0) {
      lateCustomers = '\n**أهم 5 عملاء متأخرين:**\n';
      for (var customer in data['late_customers']) {
        lateCustomers += '• ${customer['name']}: ${customer['balance'].toStringAsFixed(2)} ريال\n';
      }
    }

    return '''
👥 **تقرير العملاء:**

**الإجماليات:**
- عدد العملاء: ${data['total_customers']}
- إجمالي المديونيات: ${data['total_balance'].toStringAsFixed(2)} ريال
- العملاء المتأخرين: ${data['late_customers_count']}
- العملاء النشطين: ${data['active_customers_count']}
${lateCustomers}
''';
  }

  String _generateSuppliersResponse(dynamic data) {
    String highBalanceSuppliers = '';
    if (data['high_balance_count'] > 0) {
      highBalanceSuppliers = '\n**الموردين ذوي الرصيد العالي:**\n';
      for (var supplier in data['high_balance_suppliers']) {
        highBalanceSuppliers += '• ${supplier['name']}: ${supplier['balance'].toStringAsFixed(2)} ريال\n';
      }
    }

    return '''
🏢 **تقرير الموردين:**

**الإجماليات:**
- عدد الموردين: ${data['total_suppliers']}
- إجمالي الرصيد: ${data['total_balance'].toStringAsFixed(2)} ريال
- الموردين ذوي الرصيد: ${data['high_balance_count']}
${highBalanceSuppliers}
''';
  }

  String _generateUsersResponse(dynamic data) {
    String roles = '';
    for (var role in data['by_role']) {
      roles += '• ${role['role']}: ${role['count']} مستخدم\n';
    }

    return '''
👤 **تقرير المستخدمين:**

**المستخدمين النشطين:** ${data['total_active']}

**التوزيع حسب الدور:**
${roles.isNotEmpty ? roles : 'لا توجد بيانات'}
''';
  }

  String _generateReportsResponse(dynamic data) {
    return '''
📈 **تقرير إحصائي شامل:**

**المخزون:**
- المنتجات: ${data['total_products']}
- المخازن: ${data['total_warehouses']}
- منتجات قليلة المخزون: ${data['low_stock_products']}

**المبيعات اليوم:**
- المبيعات: ${data['today_sales'].toStringAsFixed(2)} ريال
- المشتريات: ${data['today_purchases'].toStringAsFixed(2)} ريال
- الأرباح: ${data['today_profit'].toStringAsFixed(2)} ريال

**العملاء والموردين:**
- العملاء: ${data['total_customers']}
- الموردين: ${data['total_suppliers']}
- تنبيهات غير مقروءة: ${data['total_alerts']}

**الصندوق:**
- الرصيد النقدي: ${data['cash_balance'].toStringAsFixed(2)} ريال
- المعاملات اليوم: ${data['today_transactions']}
- الفواتير المعلقة: ${data['pending_invoices']}
''';
  }

  String _generateFinancialResponse(dynamic data) {
    String todayTransactions = '';
    for (var transaction in data['today_transactions']) {
      todayTransactions += '• ${transaction['transaction_type']}: ${transaction['total'].toStringAsFixed(2)} ريال\n';
    }

    String monthlyProfit = '';
    for (var month in data['monthly_profit']) {
      monthlyProfit += '• ${month['month']}: ${month['profit'].toStringAsFixed(2)} ريال\n';
    }

    return '''
💰 **تقرير مالي:**

**رصيد الصندوق:** ${data['cash_balance'].toStringAsFixed(2)} ريال

**الحركات اليوم:**
${todayTransactions.isNotEmpty ? todayTransactions : 'لا توجد حركات اليوم'}

**الأرباح الشهرية:**
${monthlyProfit.isNotEmpty ? monthlyProfit : 'لا توجد بيانات'}
''';
  }

  String _generateReturnsResponse(dynamic data) {
    return '''
🔄 **تقرير المرتجعات:**

**مرتجعات المبيعات:**
- عدد المرتجعات: ${data['sales_returns']['count']}
- القيمة الإجمالية: ${data['sales_returns']['total'].toStringAsFixed(2)} ريال

**مرتجعات المشتريات:**
- عدد المرتجعات: ${data['purchase_returns']['count']}
- القيمة الإجمالية: ${data['purchase_returns']['total'].toStringAsFixed(2)} ريال
''';
  }

  String _generateGeneralResponse(QueryAnalysis analysis, dynamic data) {
    return '''
🤖 **مساعد المخازن الذكي**

لقد استلمت سؤالك: "${analysis.originalQuestion}"

أستطيع مساعدتك في:

📦 **المنتجات والمخزون**
• البحث عن منتج بالاسم أو الباركود
• عرض المخزون الحالي
• المنتجات قليلة المخزون

🧾 **الفواتير والمعاملات**
• مبيعات اليوم والشهر
• فواتير الشراء والمشتريات
• المرتجعات والمدفوعات

👥 **العملاء والموردين**
• بيانات العملاء والمديونيات
• معلومات الموردين والرصيد

👤 **المستخدمين والصلاحيات**
• بيانات الموظفين
• الصلاحيات والأدوار

📊 **التقارير والإحصائيات**
• تقارير الأداء
• الإحصائيات المالية
• التنبيهات والإشعارات

💡 **جرب أن تسأل:**
• "ما هي المنتجات قليلة المخزون؟"
• "كم بلغت مبيعات اليوم؟"
• "من العملاء المتأخرين في السداد؟"
• "أعطني تقرير المخزون"
• "كم عدد المنتجات في النظام؟"
''';
  }
}

// الأنواع
enum QueryIntent {
  products,
  stock,
  invoices,
  sales,
  purchases,
  customers,
  suppliers,
  users,
  reports,
  financial,
  returns,
  general
}

class QueryAnalysis {
  final QueryIntent intent;
  final List<String> entities;
  final String originalQuestion;

  QueryAnalysis({
    required this.intent,
    required this.entities,
    required this.originalQuestion,
  });
}