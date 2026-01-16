import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:untitled43/sales_screen.dart';
import 'package:untitled43/screens/permission_service.dart';
import 'package:untitled43/screens/profit_reports_screen.dart';
import 'package:untitled43/screens/reports_screen.dart';
import 'package:untitled43/screens/supplier_reports_screen.dart';
import 'package:untitled43/suppliers_screen.dart';
import 'package:untitled43/transactions_screen.dart';
import 'package:untitled43/warehouses_screen.dart';
import '../screens/sales_invoices_screen.dart';
import '../screens/purchase_invoices_screen.dart';
import '../screens/sales_returns_screen.dart';
import '../screens/purchase_returns_screen.dart';
import '../screens/inventory_adjustment_screen.dart';
import '../screens/stock_transfers_screen.dart';
import '../screens/receipt_vouchers_screen.dart';
import '../screens/payment_vouchers_screen.dart';
import '../screens/cash_ledger_screen.dart';
import '../screens/system_statistics_screen.dart';
import '../screens/users_management_screen.dart';
import '../screens/login_screen.dart';
import 'add_product_screen.dart';

import 'chat/chat_screen.dart';
import 'customers_screen.dart';
import 'database_helper.dart';
import 'service/settings_screen.dart';
// أضف استيراد شاشة الدردشة إذا كانت موجودة
// import '../screens/chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String username;
  final String role;

  DashboardScreen({required this.username, required this.role});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final PermissionService _permissionService = PermissionService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  int _selectedTab = 0;
  bool _isRefreshing = false;

  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // ✅ ألوان متكيفة مع الثيم
  late bool _isDarkMode;
  late Color _primaryColor;
  late Color _backgroundColor;
  late Color _cardColor;
  late Color _textPrimaryColor;
  late Color _textSecondaryColor;
  late Color _appBarColor;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    // تهيئة الألوان
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateThemeColors();
    });

    void testDatabase() async {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query('products');
      print('عدد المنتجات: ${result.length}');
      if (result.isNotEmpty) {
        print('اسم المنتج: ${result.first['name']}');
        print('الكمية: ${result.first['quantity']}');
        print('السعر: ${result.first['price']}');
      }
    }

    debugPrint('🎯 بدء تحميل لوحة التحكم للمستخدم: ${widget.username}');
    _initializePermissions();
    _loadDashboardData();
  }

  // ✅ دالة لتحديث الألوان حسب الثيم
  void _updateThemeColors() {
    if (!mounted) return;

    setState(() {
      _isDarkMode = Theme.of(context).brightness == Brightness.dark;
      _primaryColor = _isDarkMode ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);
      _appBarColor = _isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFF2E7D32);
      _backgroundColor = _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
      _cardColor = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
      _textPrimaryColor = _isDarkMode ? Colors.white : const Color(0xFF212121);
      _textSecondaryColor = _isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF666666);
    });
  }

  Future<void> _initializePermissions() async {
    try {
      _permissionService.setUserPermissions(widget.role);
      debugPrint('✅ تم تعيين صلاحيات المستخدم: ${_permissionService.roleName}');
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ خطأ في تعيين الصلاحيات: $e');
    }
  }

  // التحقق من صلاحية الـ Cache
  bool _isCacheValid() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  Future<void> _loadDashboardData({bool forceRefresh = false}) async {
    if (_isLoading) return;

    // استخدام الـ Cache إذا كانت البيانات صالحة
    if (!forceRefresh && _isCacheValid() && _stats.isNotEmpty) {
      debugPrint('📦 استخدام البيانات من الـ Cache');
      return;
    }

    try {
      setState(() => _isLoading = true);
      debugPrint('📊 جاري تحميل بيانات الداشبورد...');

      // استخدام دالة معدلة لتجنب أخطاء التحويل
      final stats = await _getDashboardStatsSafe();
      debugPrint('📈 بيانات الإحصائيات المستلمة: $stats');

      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
          _lastFetchTime = DateTime.now(); // تحديث وقت الـ Cache
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل بيانات الداشبورد: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('فشل في تحميل البيانات');
      }
    }
  }

  Future<Map<String, dynamic>> _getDashboardStatsSafe() async {
    try {
      final db = await _dbHelper.database;

      // حساب المبيعات والمشتريات
      final todaySales = await _getAmountSafe(db, 'sale_invoices');
      final todayPurchases = await _getAmountSafe(db, 'purchase_invoices');

      // حساب الربح اليومي (المبيعات - تكلفة البضاعة المباعة)
      final todayProfit = await _getTodayProfitSafe(db);

      // جمع البيانات بشكل آمن
      return {
        'total_products': await _getCountSafe(db, 'products'),
        'total_customers': await _getCountSafe(db, 'customers'),
        'total_suppliers': await _getCountSafe(db, 'suppliers'),
        'total_warehouses': await _getCountSafe(db, 'warehouses'),
        'today_sales': todaySales,
        'today_purchases': todayPurchases,
        'cash_balance': await _getCashBalanceSafe(db),
        'today_profit': todayProfit,
        'low_stock_products': await _getLowStockCountSafe(db),
        'today_transactions': await _getTodayTransactionsSafe(db),
        'pending_invoices': await _getPendingInvoicesCount(db),
        'monthly_sales': await _getMonthlySalesTotal(db),
      };
    } catch (e) {
      print('⚠️ خطأ في جمع الإحصائيات: $e');
      return {
        'total_products': 0,
        'total_customers': 0,
        'total_suppliers': 0,
        'total_warehouses': 0,
        'today_sales': 0.0,
        'today_purchases': 0.0,
        'cash_balance': 0.0,
        'today_profit': 0.0,
        'low_stock_products': 0,
        'today_transactions': 0,
        'pending_invoices': 0,
        'monthly_sales': 0.0,
      };
    }
  }

  Future<int> _getCountSafe(Database db, String table) async {
    try {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table WHERE is_active = 1');
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      print('⚠️ خطأ في حساب $table: $e');
      return 0;
    }
  }

  Future<double> _getAmountSafe(Database db, String table) async {
    try {
      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(total_amount), 0) as amount 
        FROM $table 
        WHERE status = "approved" AND date(created_at) = date("now")
      ''');
      final value = result.first['amount'];
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return 0.0;
    } catch (e) {
      print('⚠️ خطأ في حساب مبلغ $table: $e');
      return 0.0;
    }
  }

  Future<double> _getCashBalanceSafe(Database db) async {
    try {
      final result = await db.rawQuery('SELECT COALESCE(balance_after, 0) as balance FROM cash_ledger ORDER BY id DESC LIMIT 1');
      final value = result.first['balance'];
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return 0.0;
    } catch (e) {
      print('⚠️ خطأ في حساب رصيد الصندوق: $e');
      return 0.0;
    }
  }

  Future<int> _getLowStockCountSafe(Database db) async {
    try {
      final result = await db.rawQuery('''
        SELECT COUNT(DISTINCT p.id) as count 
        FROM products p 
        JOIN warehouse_stock ws ON p.id = ws.product_id 
        WHERE p.is_active = 1 AND p.min_stock_level > 0 
        AND ws.quantity <= p.min_stock_level
      ''');
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      print('⚠️ خطأ في حساب المنتجات منخفضة المخزون: $e');
      return 0;
    }
  }

  Future<int> _getTodayTransactionsSafe(Database db) async {
    try {
      final result = await db.rawQuery('''
        SELECT (
          SELECT COUNT(*) FROM sale_invoices WHERE date(created_at) = date("now")
        ) + (
          SELECT COUNT(*) FROM purchase_invoices WHERE date(created_at) = date("now")
        ) as count
      ''');
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      debugPrint('⚠️ خطأ في حساب المعاملات اليومية: $e');
      return 0;
    }
  }

  // ✨ دالة جديدة: حساب الربح اليومي من فواتير البيع
  Future<double> _getTodayProfitSafe(Database db) async {
    try {
      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(si.profit), 0) as total_profit
        FROM sale_items si
        JOIN sale_invoices s ON si.sale_invoice_id = s.id
        WHERE s.status = "approved" AND date(s.created_at) = date("now")
      ''');
      final value = result.first['total_profit'];
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return 0.0;
    } catch (e) {
      debugPrint('⚠️ خطأ في حساب الربح اليومي: $e');
      return 0.0;
    }
  }

  // ✨ دالة جديدة: عدد الفواتير المعلقة
  Future<int> _getPendingInvoicesCount(Database db) async {
    try {
      final result = await db.rawQuery('''
        SELECT (
          SELECT COUNT(*) FROM sale_invoices WHERE status IN ("draft", "pending")
        ) + (
          SELECT COUNT(*) FROM purchase_invoices WHERE status IN ("draft", "pending")
        ) as count
      ''');
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      debugPrint('⚠️ خطأ في حساب الفواتير المعلقة: $e');
      return 0;
    }
  }

  // ✨ دالة جديدة: إجمالي مبيعات الشهر الحالي
  Future<double> _getMonthlySalesTotal(Database db) async {
    try {
      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(total_amount), 0) as amount
        FROM sale_invoices
        WHERE status = "approved" 
        AND strftime('%Y-%m', created_at) = strftime('%Y-%m', 'now')
      ''');
      final value = result.first['amount'];
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return 0.0;
    } catch (e) {
      debugPrint('⚠️ خطأ في حساب مبيعات الشهر: $e');
      return 0.0;
    }
  }

  // ✨ دالة جديدة: تنسيق الأرقام بفواصل آلاف
  String _formatNumber(dynamic value, {int decimals = 0}) {
    if (value == null) return '0';
    final num number = value is num ? value : 0;
    if (decimals > 0) {
      return number.toStringAsFixed(decimals).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
      );
    }
    return number.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    await _loadDashboardData(forceRefresh: true);
    setState(() => _isRefreshing = false);
    _showSuccess('تم تحديث البيانات بنجاح');
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد تسجيل الخروج'),
          ],
        ),
        content: Text('هل أنت متأكد من تسجيل الخروج من النظام؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: _textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ تحديث الألوان عند كل إعادة بناء
    _updateThemeColors();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: _buildDashboardContent(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      drawer: _buildSideDrawer(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _appBarColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.menu, color: Colors.white),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.dashboard, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مرحباً، ${widget.username}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _permissionService.roleName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: _isRefreshing
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(Icons.refresh, color: Colors.white),
          onPressed: _refreshData,
          tooltip: 'تحديث البيانات',
        ),

      ],
    );
  }

  // ✅ بناء القائمة الجانبية
  Widget _buildSideDrawer() {
    return Drawer(
      backgroundColor: _cardColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // رأس القائمة الجانبية
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  _primaryColor,
                  _isDarkMode ? Color(0xFF4B0082) : Color(0xFF7E3BAF),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  widget.username,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _permissionService.roleName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // قسم الإدارة
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'الإدارة',
              style: TextStyle(
                color: _textSecondaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // زر إدارة المستخدمين
          if (_permissionService.canManageUsers)
            ListTile(
              leading: Icon(
                Icons.people,
                color: Colors.blue,
              ),
              title: Text(
                'إدارة المستخدمين',
                style: TextStyle(color: _textPrimaryColor),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => UsersManagementScreen()));
              },
            ),

          // قسم الإعدادات
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'الإعدادات',
              style: TextStyle(
                color: _textSecondaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // زر الإعدادات (تم تعديله ليفتح SettingsScreenWithProvider)
          ListTile(
            leading: Icon(
              Icons.settings,
              color: _primaryColor,
            ),
            title: Text(
              'الإعدادات',
              style: TextStyle(color: _textPrimaryColor),
            ),
            onTap: () {
              Navigator.pop(context);
              if (_permissionService.canAccessSystemSettings) {
                // استبدل بفتح SettingsScreenWithProvider
                Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreenWithProvider()));
              } else {
                _showError('لا تملك صلاحية الوصول للإعدادات');
              }
            },
          ),

          // قسم التواصل
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'التواصل',
              style: TextStyle(
                color: _textSecondaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // زر الدردشة (أضف استيراد ChatScreen أعلاه)
          ListTile(
            leading: Icon(
              Icons.chat,
              color: Colors.teal,
            ),
            title: Text(
              'الدردشة',
              style: TextStyle(color: _textPrimaryColor),
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen()));
            },
          ),

          // قسم المعلومات
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'المعلومات',
              style: TextStyle(
                color: _textSecondaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // زر الملف الشخصي
          ListTile(
            leading: Icon(
              Icons.person,
              color: Colors.blue,
            ),
            title: Text(
              'الملف الشخصي',
              style: TextStyle(color: _textPrimaryColor),
            ),
            onTap: () {
              Navigator.pop(context);
              _showUserProfile();
            },
          ),

          // زر معلومات المستخدم
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Colors.teal,
            ),
            title: Text(
              'معلومات المستخدم',
              style: TextStyle(color: _textPrimaryColor),
            ),
            onTap: () {
              Navigator.pop(context);
              _showDetailedUserInfo();
            },
          ),

          // زر الإحصائيات
          ListTile(
            leading: Icon(
              Icons.analytics,
              color: Colors.purple,
            ),
            title: Text(
              'إحصائيات النظام',
              style: TextStyle(color: _textPrimaryColor),
            ),
            onTap: () {
              Navigator.pop(context);
              if (_permissionService.canViewReports) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProfessionalStatisticsScreen()));
              } else {
                _showError('لا تملك صلاحية عرض الإحصائيات');
              }
            },
          ),

          Divider(color: _textSecondaryColor.withOpacity(0.3), height: 20),

          // قسم إضافي
          ListTile(
            leading: Icon(
              Icons.help_outline,
              color: _textSecondaryColor,
            ),
            title: Text(
              'المساعدة والدعم',
              style: TextStyle(color: _textPrimaryColor),
            ),
            onTap: () {
              Navigator.pop(context);
              _showHelpDialog();
            },
          ),

          // زر تسجيل الخروج
          Container(
            margin: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'تسجيل الخروج',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ دالة جديدة: عرض رسالة قريباً
  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.hourglass_top, color: Colors.amber),
            SizedBox(width: 10),
            Text('قريباً'),
          ],
        ),
        content: Text(
          'ميزة "$feature" قيد التطوير\nستتوفر في تحديثات لاحقة',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('حسناً'),
          ),
        ],
      ),
    );
  }

  // ✅ دالة جديدة: عرض معلومات مفصلة عن المستخدم
  void _showDetailedUserInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: _primaryColor),
            SizedBox(width: 10),
            Text('معلومات المستخدم'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('اسم المستخدم', widget.username),
              _buildInfoRow('الدور', _permissionService.roleName),
              _buildInfoRow('تاريخ الدخول', DateTime.now().toString().substring(0, 16)),
              Divider(),
              Text(
                'الصلاحيات الممنوحة:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _textPrimaryColor,
                ),
              ),
              SizedBox(height: 8),
              ..._buildPermissionsList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$title:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: _textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(color: _textPrimaryColor),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPermissionsList() {
    List<Widget> widgets = [];

    if (_permissionService.canManageProducts)
      widgets.add(_buildPermissionItem('إدارة المنتجات', true));
    if (_permissionService.canManageCustomers)
      widgets.add(_buildPermissionItem('إدارة العملاء', true));
    if (_permissionService.canManageSuppliers)
      widgets.add(_buildPermissionItem('إدارة الموردين', true));
    if (_permissionService.canManageWarehouses)
      widgets.add(_buildPermissionItem('إدارة المخازن', true));
    if (_permissionService.canManageUsers)
      widgets.add(_buildPermissionItem('إدارة المستخدمين', true));
    if (_permissionService.canCreateSaleInvoices)
      widgets.add(_buildPermissionItem('إنشاء فواتير البيع', true));
    if (_permissionService.canCreatePurchaseInvoices)
      widgets.add(_buildPermissionItem('إنشاء فواتير الشراء', true));
    if (_permissionService.canViewReports)
      widgets.add(_buildPermissionItem('عرض التقارير', true));
    if (_permissionService.canManageFinancial)
      widgets.add(_buildPermissionItem('إدارة الشؤون المالية', true));
    if (_permissionService.canAccessSystemSettings)
      widgets.add(_buildPermissionItem('الوصول للإعدادات', true));

    return widgets;
  }

  Widget _buildPermissionItem(String permission, bool hasPermission) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            hasPermission ? Icons.check_circle : Icons.remove_circle,
            color: hasPermission ? Colors.green : Colors.red,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            permission,
            style: TextStyle(
              fontSize: 12,
              color: hasPermission ? _textPrimaryColor : _textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help, color: Colors.blue),
            SizedBox(width: 10),
            Text('المساعدة والدعم'),
          ],
        ),
        content: Text(
          'للمساعدة والدعم الفني:\n\n'
              '• البريد الإلكتروني: support@company.com\n'
              '• الهاتف: 555-1234\n'
              '• ساعات العمل: 9:00 صباحاً - 5:00 مساءً\n\n'
              'للتأكد من أن النظام يعمل بشكل صحيح، يرجى تحديث البيانات بانتظام.',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _primaryColor),
            SizedBox(height: 20),
            Text('جاري تحميل البيانات...', style: TextStyle(color: _textSecondaryColor)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      backgroundColor: _primaryColor,
      color: Colors.white,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // البطاقات الإحصائية الرئيسية
            _buildMainStatsCards(),

            // بطاقات سريعة
            _buildQuickStatsCards(),

            // الخدمات حسب التبويب المختار
            _buildServicesSection(),

            SizedBox(height: 80), // مساحة للتبويب السفلي
          ],
        ),
      ),
    );
  }

  Widget _buildMainStatsCards() {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            _primaryColor,
            _isDarkMode ? Color(0xFF4B0082) : Color(0xFF7E3BAF),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // التاريخ واليوم مضغوط
          Container(
            margin: EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${now.day}/${now.month}/${now.year}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
                Text(
                  dayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // بطاقات أفقي صغيرة جداً
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSmallMainCard('المنتجات', '${_stats['total_products'] ?? 0}', Icons.inventory_2),
                SizedBox(width: 6),
                _buildSmallMainCard('العملاء', '${_stats['total_customers'] ?? 0}', Icons.people),
                SizedBox(width: 6),
                _buildSmallMainCard('الموردين', '${_stats['total_suppliers'] ?? 0}', Icons.local_shipping),
                SizedBox(width: 6),
                _buildSmallMainCard('المخازن', '${_stats['total_warehouses'] ?? 0}', Icons.warehouse),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMainCard(String title, String value, IconData icon) {
    return Container(
      width: 85,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCards() {
    final quickStats = <Widget>[
      // الصف الأول: مبيعات ومشتريات اليوم
      if (_permissionService.canCreateSaleInvoices)
        _buildQuickStatCard(
          'مبيعات اليوم',
          '${_formatNumber(_stats['today_sales'] ?? 0)} ر.س',
          Icons.trending_up,
          Colors.green,
        ),
      if (_permissionService.canCreatePurchaseInvoices)
        _buildQuickStatCard(
          'مشتريات اليوم',
          '${_formatNumber(_stats['today_purchases'] ?? 0)} ر.س',
          Icons.shopping_cart,
          Colors.blue,
        ),
      // الصف الثاني: رصيد الصندوق والربح
      if (_permissionService.canManageFinancial)
        _buildQuickStatCard(
          'رصيد الصندوق',
          '${_formatNumber(_stats['cash_balance'] ?? 0)} ر.س',
          Icons.account_balance_wallet,
          Colors.orange,
        ),
      if (_permissionService.canManageFinancial)
        _buildQuickStatCard(
          'ربح اليوم',
          '${_formatNumber(_stats['today_profit'] ?? 0)} ر.س',
          Icons.monetization_on,
          _primaryColor,
          isProfit: true,
        ),
      // الصف الثالث: المخزون والفواتير المعلقة
      if (_permissionService.canManageInventory)
        _buildQuickStatCard(
          'منخفض المخزون',
          '${_stats['low_stock_products'] ?? 0}',
          Icons.warning_amber,
          Colors.red,
          showAlert: (_stats['low_stock_products'] ?? 0) > 0,
        ),
      if (_permissionService.canViewDashboard)
        _buildQuickStatCard(
          'فواتير معلقة',
          '${_stats['pending_invoices'] ?? 0}',
          Icons.pending_actions,
          Colors.amber[700]!,
          showAlert: (_stats['pending_invoices'] ?? 0) > 0,
        ),
      // الصف الرابع: مبيعات الشهر
      if (_permissionService.canViewReports)
        _buildQuickStatCard(
          'مبيعات الشهر',
          '${_formatNumber(_stats['monthly_sales'] ?? 0)} ر.س',
          Icons.calendar_month,
          Colors.teal,
        ),
    ];

    if (quickStats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإحصائيات اليومية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimaryColor,
                ),
              ),
              // إظهار آخر تحديث
              if (_lastFetchTime != null)
                Text(
                  'آخر تحديث: ${_lastFetchTime!.hour}:${_lastFetchTime!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: _textSecondaryColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // استخدام Wrap لتفادي الـ overflow
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: quickStats,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(
      String title,
      String value,
      IconData icon,
      Color color, {
        bool isProfit = false,
        bool showAlert = false,
      }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: MediaQuery.of(context).size.width / 2 - 24,
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isProfit ? color.withOpacity(0.05) : _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isProfit
            ? Border.all(color: color.withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: showAlert
                ? color.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: showAlert ? 8 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // أيقونة مع مؤشر تنبيه
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  // نقطة تنبيه
                  if (showAlert)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: _cardColor, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isProfit ? color : _textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        color: _textSecondaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    final services = _getServicesByTab();

    if (services.isEmpty) {
      return Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.lock_outline, size: 48, color: _textSecondaryColor),
            SizedBox(height: 16),
            Text(
              'لا توجد خدمات متاحة',
              style: TextStyle(fontSize: 16, color: _textPrimaryColor, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'لا تمتلك صلاحيات للوصول إلى خدمات هذا القسم',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _textSecondaryColor),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getTabTitle(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimaryColor,
            ),
          ),
          SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) => services[index],
          ),
        ],
      ),
    );
  }

  List<Widget> _getServicesByTab() {
    switch (_selectedTab) {
      case 0: // المنتجات والمخزون
        return [
          if (_permissionService.canManageProducts)
            _buildServiceButton('المنتجات', Icons.inventory_2, Colors.blue, InventoryAdjustmentScreen()),
          if (_permissionService.canManageProducts)
            _buildServiceButton('إضافة منتج', Icons.add_circle, Colors.green, AddProductScreen()),
          if (_permissionService.canManageWarehouses)
            _buildServiceButton('المخازن', Icons.warehouse, Colors.orange, WarehousesScreen()),
          if (_permissionService.canManageInventory)
            _buildServiceButton('جرد المخزون', Icons.inventory, Colors.purple, InventoryAdjustmentScreen()),
          if (_permissionService.canManageInventory)
            _buildServiceButton('تحويل المخزون', Icons.compare_arrows, Colors.teal, StockTransfersScreen()),
        ];

      case 1: // المبيعات والعملاء
        return [
          if (_permissionService.canCreateSaleInvoices)
            _buildServiceButton('فواتير البيع', Icons.receipt_long, Colors.green, SalesInvoicesScreen()),
          if (_permissionService.canCreateSaleInvoices)
            _buildServiceButton('مرتجعات البيع', Icons.undo, Colors.orange, SalesReturnsScreen()),
          if (_permissionService.canManageCustomers)
            _buildServiceButton('العملاء', Icons.people, Colors.blue, CustomersScreen()),
        ];

      case 2: // المشتريات والموردين
        return [
          if (_permissionService.canCreatePurchaseInvoices)
            _buildServiceButton('فواتير الشراء', Icons.shopping_cart, Colors.purple, PurchaseInvoicesScreen()),
          if (_permissionService.canCreatePurchaseInvoices)
            _buildServiceButton('مرتجعات الشراء', Icons.reply, Colors.red, PurchaseReturnsScreen()),
          if (_permissionService.canManageSuppliers)
            _buildServiceButton('الموردين', Icons.local_shipping, Colors.amber, SuppliersScreen()),
        ];

      case 3: // الشؤون المالية
        return [
          if (_permissionService.canManageFinancial)
            _buildServiceButton('سندات القبض', Icons.payments, Colors.green, ReceiptVouchersScreen()),
          if (_permissionService.canManageFinancial)
            _buildServiceButton('سندات الصرف', Icons.money_off, Colors.red, PaymentVouchersScreen()),
          if (_permissionService.canManageFinancial)
            _buildServiceButton('سجل الصندوق', Icons.account_balance_wallet, Colors.blue, CashLedgerScreen()),
        ];

      case 4: // التقارير والإحصائيات والإعدادات
        return [
          if (_permissionService.canViewReports)
            _buildServiceButton('التقارير', Icons.analytics, Colors.purple, ComprehensiveReportsScreen()),
          if (_permissionService.canViewReports)
            _buildServiceButton('إحصائيات', Icons.show_chart, Colors.blue, ProfessionalStatisticsScreen()),
          if (_permissionService.canViewReports)
            _buildServiceButton('تقارير الأرباح', Icons.trending_up, Colors.green, ProfitReportsScreen()),
          if (_permissionService.canViewReports)
            _buildServiceButton('تقارير الموردين', Icons.local_shipping, Colors.orange, SupplierReportsScreen()),
          if (_permissionService.canViewReports)
            _buildServiceButton('تقارير المعاملات', Icons.receipt_long, Colors.teal, TransactionsScreen()),
          if (_permissionService.canViewReports)
            _buildServiceButton('شاشة الكاشير', Icons.point_of_sale, Colors.indigo, SalesScreen()),
          if (_permissionService.canAccessSystemSettings)
            _buildServiceButton('الإعدادات', Icons.settings, Colors.grey[700]!, SettingsScreenWithProvider()),
        ];

      default:
        return [];
    }
  }

  String _getTabTitle() {
    switch (_selectedTab) {
      case 0: return 'المنتجات والمخزون';
      case 1: return 'المبيعات والعملاء';
      case 2: return 'المشتريات والموردين';
      case 3: return 'الشؤون المالية';
      case 4: return 'التقارير والإحصائيات';
      default: return 'الخدمات';
    }
  }

  Widget _buildServiceButton(String title, IconData icon, Color color, Widget screen) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _textPrimaryColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildNavItem('منتجات', Icons.inventory_2, 0),
            _buildNavItem('مبيعات', Icons.sell, 1),
            _buildNavItem('مشتريات', Icons.shopping_cart, 2),
            _buildNavItem('مالية', Icons.monetization_on, 3),
            _buildNavItem('تقارير', Icons.analytics, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String title, IconData icon, int index) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedTab = index),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? _primaryColor : _textSecondaryColor,
                ),
                SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? _primaryColor : _textSecondaryColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return Colors.red;
      case 'manager': return Colors.orange;
      case 'warehouse': return Colors.blue;
      case 'cashier': return Colors.green;
      case 'viewer': return Colors.grey[600]!;
      default: return _primaryColor;
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'الإثنين';
      case 2: return 'الثلاثاء';
      case 3: return 'الأربعاء';
      case 4: return 'الخميس';
      case 5: return 'الجمعة';
      case 6: return 'السبت';
      case 7: return 'الأحد';
      default: return '';
    }
  }

  void _showUserProfile() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: _textSecondaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(Icons.person, size: 30, color: _primaryColor),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.username,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimaryColor),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _permissionService.roleName,
                        style: TextStyle(color: _textSecondaryColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Text('الصلاحيات المتاحة:', style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimaryColor)),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildPermissionChips(),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('إغلاق', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPermissionChips() {
    final chips = <Widget>[];

    if (_permissionService.canManageProducts)
      chips.add(_buildPermissionChip('إدارة المنتجات', Colors.blue));
    if (_permissionService.canManageCustomers)
      chips.add(_buildPermissionChip('إدارة العملاء', Colors.green));
    if (_permissionService.canManageSuppliers)
      chips.add(_buildPermissionChip('إدارة الموردين', Colors.orange));
    if (_permissionService.canManageWarehouses)
      chips.add(_buildPermissionChip('إدارة المخازن', Colors.purple));
    if (_permissionService.canManageUsers)
      chips.add(_buildPermissionChip('إدارة المستخدمين', Colors.red));
    if (_permissionService.canViewReports)
      chips.add(_buildPermissionChip('عرض التقارير', Colors.teal));

    return chips;
  }

  Widget _buildPermissionChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

