import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database_helper.dart';

class ProfessionalStatisticsScreen extends StatefulWidget {
  @override
  _ProfessionalStatisticsScreenState createState() => _ProfessionalStatisticsScreenState();
}

class _ProfessionalStatisticsScreenState extends State<ProfessionalStatisticsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // البيانات
  Map<String, dynamic> _dashboardStats = {};
  List<Map<String, dynamic>> _monthlySales = [];
  List<Map<String, dynamic>> _topCustomers = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _lowStockProducts = [];
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _supplierStats = [];

  // الحالة
  bool _isLoading = true;
  String _selectedPeriod = 'today'; // today, week, month, year
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAllStatistics();
  }
  Future<void> _loadAllStatistics() async {
    setState(() => _isLoading = true);

    try {
      // 📊 تحميل البيانات واحدة تلو الأخرى بدلاً من waitAll لسهولة التصحيح
      _dashboardStats = await _safeLoadDashboardStats();
      _monthlySales = await _safeLoadMonthlySales();
      _topCustomers = await _safeLoadTopCustomers();
      _topProducts = await _safeLoadTopProducts();
      _lowStockProducts = await _safeLoadLowStockProducts();
      _recentTransactions = await _safeLoadRecentTransactions();
      _supplierStats = await _safeLoadSupplierStats();

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ خطأ في تحميل الإحصائيات: $e');
      setState(() => _isLoading = false);
      _showError('❌ فشل في تحميل الإحصائيات: ${e.toString()}');
    }
  }

// 🔧 دوال مساعدة لتحميل البيانات بشكل آمن
  Future<Map<String, dynamic>> _safeLoadDashboardStats() async {
    try {
      final stats = await _dbHelper.getDashboardStats();
      return stats is Map<String, dynamic> ? stats : {};
    } catch (e) {
      print('❌ خطأ في تحميل إحصائيات الداشبورد: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _safeLoadMonthlySales() async {
    try {
      final currentYear = DateTime.now().year;
      final sales = await _dbHelper.getMonthlySalesReport(currentYear);
      return _convertToListMap(sales);
    } catch (e) {
      print('❌ خطأ في تحميل المبيعات الشهرية: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _safeLoadTopCustomers() async {
    try {
      final customers = await _dbHelper.getCustomersReport();
      final list = _convertToListMap(customers);
      return list.take(5).toList();
    } catch (e) {
      print('❌ خطأ في تحميل العملاء: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _safeLoadTopProducts() async {
    try {
      final products = await _dbHelper.getTopSellingProducts(limit: 5, period: 'month');
      return _convertToListMap(products);
    } catch (e) {
      print('❌ خطأ في تحميل المنتجات: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _safeLoadLowStockProducts() async {
    try {
      final products = await _dbHelper.getLowStockProducts(threshold: 10);
      return _convertToListMap(products);
    } catch (e) {
      print('❌ خطأ في تحميل المنتجات منخفضة المخزون: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _safeLoadRecentTransactions() async {
    try {
      final transactions = await _dbHelper.getRecentTransactions();
      return _convertToListMap(transactions);
    } catch (e) {
      print('❌ خطأ في تحميل الحركات الأخيرة: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _safeLoadSupplierStats() async {
    try {
      final suppliers = await _dbHelper.getSuppliersReport();
      final list = _convertToListMap(suppliers);
      return list.take(5).toList();
    } catch (e) {
      print('❌ خطأ في تحميل الموردين: $e');
      return [];
    }
  }

// 🔄 دالة لتحويل البيانات إلى List<Map<String, dynamic>> بشكل آمن
  List<Map<String, dynamic>> _convertToListMap(dynamic data) {
    if (data == null) return [];

    if (data is List) {
      try {
        // تحقق من كل عنصر إذا كان Map
        return data.whereType<Map<String, dynamic>>().toList();
      } catch (e) {
        print('❌ خطأ في تحويل البيانات: $e');
        return [];
      }
    }

    return [];
  }
  Future<void> _refreshData() async {
    await _loadAllStatistics();
    _showSuccess('✅ تم تحديث البيانات');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.analytics, size: 24),
            SizedBox(width: 8),
            Text('لوحة التحكم والإحصائيات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.deepPurple[700],
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 22),
            onPressed: _refreshData,
            tooltip: 'تحديث البيانات',
          ),
          IconButton(
            icon: Icon(Icons.date_range, size: 22),
            onPressed: _showDatePicker,
            tooltip: 'اختيار التاريخ',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async => _loadAllStatistics(),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📊 بطاقات الإحصائيات السريعة
              _buildQuickStatsCards(),
              SizedBox(height: 16),

              // 📈 المبيعات والأرباح
              _buildSalesProfitSection(),
              SizedBox(height: 16),

              // 👥 العملاء والموردين
              Row(
                children: [
                  Expanded(child: _buildTopCustomersSection()),
                  SizedBox(width: 8),
                  Expanded(child: _buildTopSuppliersSection()),
                ],
              ),
              SizedBox(height: 16),

              // 📦 المنتجات والمخزون
              Row(
                children: [
                  Expanded(child: _buildTopProductsSection()),
                  SizedBox(width: 8),
                  Expanded(child: _buildLowStockSection()),
                ],
              ),
              SizedBox(height: 16),

              // 💼 الحركات الأخيرة
              _buildRecentTransactions(),
              SizedBox(height: 16),

              // 📊 المبيعات الشهرية
              // _buildMonthlySalesChart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsCards() {
    final stats = _dashboardStats;

    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.9,
      children: [
        _buildStatCard(
          'المنتجات',
          stats['total_products']?.toString() ?? '0',
          Icons.inventory_2,
          Colors.blue,
          Colors.blue[50]!,
        ),
        _buildStatCard(
          'العملاء',
          stats['total_customers']?.toString() ?? '0',
          Icons.group,
          Colors.green,
          Colors.green[50]!,
        ),
        _buildStatCard(
          'الموردين',
          stats['total_suppliers']?.toString() ?? '0',
          Icons.shopping_cart,
          Colors.orange,
          Colors.orange[50]!,
        ),
        _buildStatCard(
          'مبيعات اليوم',
          '${stats['today_sales']?.toStringAsFixed(0) ?? '0'}',
          Icons.trending_up,
          Colors.purple,
          Colors.purple[50]!,
        ),
        _buildStatCard(
          'منخفض المخزون',
          stats['low_stock_products']?.toString() ?? '0',
          Icons.warning,
          Colors.red,
          Colors.red[50]!,
        ),
        _buildStatCard(
          'الحركات',
          stats['today_transactions']?.toString() ?? '0',
          Icons.receipt,
          Colors.teal,
          Colors.teal[50]!,
        ),
        _buildStatCard(
          'المستودعات',
          '3', // يمكن جلبها من قاعدة البيانات
          Icons.store,
          Colors.indigo,
          Colors.indigo[50]!,
        ),
        _buildStatCard(
          'المبيعات الكلية',
          '${_calculateTotalSales()}',
          Icons.attach_money,
          Colors.amber,
          Colors.amber[50]!,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor, Color bgColor) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: iconColor),
            ),
            SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesProfitSection() {
    final monthlyTotal = _monthlySales.fold(0.0, (sum, item) => sum + (item['total_sales']?.toDouble() ?? 0));
    final todaySales = _dashboardStats['today_sales']?.toDouble() ?? 0;
    final avgDaily = monthlyTotal / DateTime.now().month;
    final growthRate = ((todaySales - avgDaily) / avgDaily * 100).clamp(-100, 100);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, size: 20, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'المبيعات والأرباح',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: growthRate >= 0 ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        growthRate >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: growthRate >= 0 ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 2),
                      Text(
                        '${growthRate.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: growthRate >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricCard('مبيعات اليوم', '${todaySales.toStringAsFixed(0)} ر.س', Colors.blue),
                _buildMetricCard('متوسط يومي', '${avgDaily.toStringAsFixed(0)} ر.س', Colors.green),
                _buildMetricCard('إجمالي الشهر', '${monthlyTotal.toStringAsFixed(0)} ر.س', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildTopCustomersSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, size: 18, color: Colors.green),
                SizedBox(width: 6),
                Text(
                  'أفضل العملاء',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Text(
                  '${_topCustomers.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 10),
            ..._topCustomers.asMap().entries.map((entry) {
              final index = entry.key;
              final customer = entry.value;
              final purchases = customer['total_purchases']?.toDouble() ?? 0;

              return Container(
                margin: EdgeInsets.only(bottom: 6),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer['name'] ?? 'غير معروف',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${customer['total_invoices'] ?? 0} فاتورة',
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${purchases.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[700]),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSuppliersSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart, size: 18, color: Colors.orange),
                SizedBox(width: 6),
                Text(
                  'أفضل الموردين',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Text(
                  '${_supplierStats.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 10),
            ..._supplierStats.map((supplier) {
              final purchases = supplier['total_purchases']?.toDouble() ?? 0;
              final balance = supplier['balance']?.toDouble() ?? 0;

              return Container(
                margin: EdgeInsets.only(bottom: 6),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            supplier['name'] ?? 'غير معروف',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${purchases.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: balance > 0 ? Colors.red[50] : Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'رصيد: ${balance.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: balance > 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Spacer(),
                        Text(
                          '${supplier['total_invoices'] ?? 0} فاتورة',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, size: 18, color: Colors.amber),
                SizedBox(width: 6),
                Text(
                  'أكثر المنتجات مبيعاً',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Text(
                  '${_topProducts.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 10),
            ..._topProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              final sold = product['total_sold'] ?? 0;
              final revenue = product['total_revenue']?.toDouble() ?? 0;

              return Container(
                margin: EdgeInsets.only(bottom: 6),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? 'غير معروف',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.shopping_bag, size: 10, color: Colors.grey),
                              SizedBox(width: 2),
                              Text(
                                'مبيع: $sold',
                                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${revenue.toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[700]),
                        ),
                        Text(
                          'ربح: ${product['profit']?.toStringAsFixed(0) ?? '0'}',
                          style: TextStyle(fontSize: 10, color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, size: 18, color: Colors.red),
                SizedBox(width: 6),
                Text(
                  'منخفض المخزون',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_lowStockProducts.length}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            ..._lowStockProducts.take(5).map((product) {
              final stock = product['total_stock'] ?? 0;
              final minLevel = product['min_stock_level'] ?? 0;
              final percentage = minLevel > 0 ? (stock / minLevel * 100) : 0;

              return Container(
                margin: EdgeInsets.only(bottom: 6),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? 'غير معروف',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'المتاح: $stock',
                                style: TextStyle(fontSize: 10, color: Colors.red[700]),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'الحد الأدنى: $minLevel',
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${percentage.toInt()}%',
                        style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, size: 18, color: Colors.blue),
                SizedBox(width: 6),
                Text(
                  'آخر الحركات',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Icon(Icons.chevron_left, size: 20, color: Colors.grey),
              ],
            ),
            SizedBox(height: 10),
            ..._recentTransactions.take(5).map((transaction) {
              final type = transaction['type'] ?? 'sale';
              final amount = transaction['total_amount']?.toDouble() ?? 0;
              final date = transaction['date'] != null
                  ? DateFormat('HH:mm').format(DateTime.parse(transaction['date']))
                  : '--:--';

              return Container(
                margin: EdgeInsets.only(bottom: 6),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: type == 'sale' ? Colors.green[100] : Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        type == 'sale' ? Icons.shopping_cart : Icons.inventory,
                        size: 16,
                        color: type == 'sale' ? Colors.green : Colors.blue,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction['product_name'] ?? 'غير معروف',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.person, size: 10, color: Colors.grey),
                              SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  transaction['customer_name'] ?? 'نقدي',
                                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$date',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          '${amount.toStringAsFixed(0)} ر.س',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: type == 'sale' ? Colors.green : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // Widget _buildMonthlySalesChart() {
  //   return Card(
  //     elevation: 1,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Padding(
  //       padding: EdgeInsets.all(12),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               Icon(Icons.bar_chart, size: 18, color: Colors.purple),
  //               SizedBox(width: 6),
  //               Text(
  //                 'المبيعات الشهرية',
  //                 style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
  //               ),
  //               Spacer(),
  //               Text(
  //                 '${DateTime.now().year}',
  //                 style: TextStyle(fontSize: 12, color: Colors.grey),
  //               ),
  //             ],
  //           ),
  //           SizedBox(height: 10),
  //           Container(
  //             height: 200,
  //             child: SfCartesianChart(
  //               margin: EdgeInsets.all(0),
  //               plotAreaBorderWidth: 0,
  //               primaryXAxis: CategoryAxis(
  //                 labelRotation: 0,
  //                 labelStyle: TextStyle(fontSize: 10),
  //                 majorGridLines: MajorGridLines(width: 0),
  //               ),
  //               primaryYAxis: NumericAxis(
  //                 labelStyle: TextStyle(fontSize: 10),
  //                 numberFormat: NumberFormat.compact(),
  //                 majorGridLines: MajorGridLines(width: 0.5, color: Colors.grey[200]!),
  //               ),
  //               series: <CartesianSeries>[
  //                 ColumnSeries<Map<String, dynamic>, String>(
  //                   dataSource: _monthlySales,
  //                   xValueMapper: (data, _) => _getMonthName(int.parse(data['month'])),
  //                   yValueMapper: (data, _) => data['total_sales']?.toDouble() ?? 0,
  //                   color: Colors.purple,
  //                   width: 0.6,
  //                   dataLabelSettings: DataLabelSettings(
  //                     isVisible: true,
  //                     labelAlignment: ChartDataLabelAlignment.top,
  //                     textStyle: TextStyle(fontSize: 9),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  String _getMonthName(int month) {
    final months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return months[month - 1].substring(0, 3); // أول 3 أحرف فقط
  }

  String _calculateTotalSales() {
    final total = _monthlySales.fold(0.0, (sum, item) => sum + (item['total_sales']?.toDouble() ?? 0));
    if (total >= 1000000) return '${(total / 1000000).toStringAsFixed(1)}M';
    if (total >= 1000) return '${(total / 1000).toStringAsFixed(1)}K';
    return total.toStringAsFixed(0);
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadAllStatistics();
    }
  }
}