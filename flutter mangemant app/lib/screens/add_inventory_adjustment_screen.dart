import 'package:flutter/material.dart';
 // إضافة استيراد AppLocalizations
import '../database_helper.dart';
import '../l10n/app_localizations.dart';

class AddInventoryAdjustmentScreen extends StatefulWidget {
  @override
  _AddInventoryAdjustmentScreenState createState() => _AddInventoryAdjustmentScreenState();
}

class _AddInventoryAdjustmentScreenState extends State<AddInventoryAdjustmentScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _products = [];

  int? _selectedWarehouseId;
  String _adjustmentType = 'correction';
  String _reason = '';
  String _notes = '';

  final Map<String, String> _adjustmentTypes = {
    'increase': 'increase',
    'decrease': 'decrease',
    'correction': 'correction',
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final warehouses = await _dbHelper.getWarehouses();
      setState(() {
        _warehouses = warehouses;
        if (warehouses.isNotEmpty) _selectedWarehouseId = warehouses.first['id'];
      });
    } catch (e) {
      _showError('${AppLocalizations.of(context).translate('failed_to_load_data')}: $e');
    }
  }

  Future<void> _loadWarehouseProducts() async {
    if (_selectedWarehouseId == null) return;

    setState(() {
      _products = [];
      _items = [];
    });

    try {
      final products = await _dbHelper.getWarehouseStockForAdjustment(_selectedWarehouseId!);
      setState(() {
        _products = products;
      });
    } catch (e) {
      _showError('${AppLocalizations.of(context).translate('failed_to_load_warehouse_products')}: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _updateItemQuantity(int productId, int newQuantity) {
    setState(() {
      final index = _items.indexWhere((item) => item['product_id'] == productId);
      if (index != -1) {
        _items[index]['new_quantity'] = newQuantity;
        _items[index]['difference'] = newQuantity - (_items[index]['current_quantity'] as int);
      } else {
        final product = _products.firstWhere((p) => p['id'] == productId);
        _items.add({
          'product_id': productId,
          'product_name': product['name'],
          'current_quantity': product['current_quantity'] ?? 0,
          'new_quantity': newQuantity,
          'difference': newQuantity - (product['current_quantity'] ?? 0),
        });
      }
    });
  }

  void _removeItem(int productId) {
    setState(() {
      _items.removeWhere((item) => item['product_id'] == productId);
    });
  }

  Future<void> _submitAdjustment() async {
    final localizations = AppLocalizations.of(context);

    if (_selectedWarehouseId == null) {
      _showError(localizations.translate('please_select_warehouse'));
      return;
    }

    if (_reason.isEmpty) {
      _showError(localizations.translate('please_enter_adjustment_reason'));
      return;
    }

    if (_items.isEmpty) {
      _showError(localizations.translate('please_add_at_least_one_product'));
      return;
    }

    final adjustment = {
      'warehouse_id': _selectedWarehouseId,
      'adjustment_type': _adjustmentType,
      'reason': _reason,
      'notes': _notes,
      'adjustment_date': DateTime.now().toIso8601String(),
      'status': 'draft',
    };

    final items = _items.map((item) => ({
      'product_id': item['product_id'],
      'current_quantity': item['current_quantity'],
      'new_quantity': item['new_quantity'],
    })).toList();

    final result = await _dbHelper.createInventoryAdjustmentWithItems(adjustment, items);

    if (result['success']) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.translate('inventory_adjustment_created_successfully')} - ${localizations.translate('number')}: ${result['adjustment_number']}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showError(result['error']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('add_inventory_adjustment')),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _submitAdjustment,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Basic adjustment information
              _buildBasicInfo(localizations),
              SizedBox(height: 20),

              // Products list
              _buildProductsList(localizations),

              // Added products
              if (_items.isNotEmpty) ...[
                SizedBox(height: 20),
                _buildSelectedItems(localizations),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo(AppLocalizations localizations) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: _selectedWarehouseId,
              decoration: InputDecoration(
                labelText: localizations.translate('warehouse'),
                border: OutlineInputBorder(),
              ),
              items: _warehouses.map((warehouse) {
                return DropdownMenuItem<int>(
                  value: warehouse['id'],
                  child: Text(warehouse['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedWarehouseId = value;
                });
                _loadWarehouseProducts();
              },
              validator: (value) {
                if (value == null) return localizations.translate('please_select_warehouse');
                return null;
              },
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _adjustmentType,
              decoration: InputDecoration(
                labelText: localizations.translate('adjustment_type'),
                border: OutlineInputBorder(),
              ),
              items: _adjustmentTypes.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(localizations.translate(entry.value)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _adjustmentType = value!;
                });
              },
            ),
            SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                labelText: localizations.translate('adjustment_reason'),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _reason = value,
              validator: (value) {
                if (value == null || value.isEmpty) return localizations.translate('please_enter_adjustment_reason');
                return null;
              },
            ),
            SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                labelText: localizations.translate('notes'),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) => _notes = value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList(AppLocalizations localizations) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.translate('warehouse_products'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              _products.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      localizations.translate('no_products_in_selected_warehouse'),
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
                  : Expanded(
                child: ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final currentQty = product['current_quantity'] ?? 0;
                    final existingItem = _items.firstWhere(
                          (item) => item['product_id'] == product['id'],
                      orElse: () => {},
                    );

                    return ProductAdjustmentItem(
                      product: product,
                      currentQuantity: currentQty,
                      onQuantityChanged: (newQty) => _updateItemQuantity(product['id'], newQty),
                      onRemove: () => _removeItem(product['id']),
                      isSelected: existingItem.isNotEmpty,
                      localizations: localizations,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedItems(AppLocalizations localizations) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${localizations.translate('selected_products')} (${_items.length})',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ..._items.map((item) => ListTile(
              leading: CircleAvatar(
                backgroundColor: _getDifferenceColor(item['difference']),
                child: Text(
                  item['difference'] > 0 ? '+' : item['difference'] < 0 ? '-' : '=',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              title: Text(item['product_name']),
              subtitle: Text('${item['current_quantity']} → ${item['new_quantity']}'),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeItem(item['product_id']),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Color _getDifferenceColor(int difference) {
    if (difference > 0) return Colors.green;
    if (difference < 0) return Colors.red;
    return Colors.grey;
  }
}

class ProductAdjustmentItem extends StatefulWidget {
  final Map<String, dynamic> product;
  final int currentQuantity;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;
  final bool isSelected;
  final AppLocalizations localizations;

  const ProductAdjustmentItem({
    Key? key,
    required this.product,
    required this.currentQuantity,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.isSelected,
    required this.localizations,
  }) : super(key: key);

  @override
  _ProductAdjustmentItemState createState() => _ProductAdjustmentItemState();
}

class _ProductAdjustmentItemState extends State<ProductAdjustmentItem> {
  final TextEditingController _quantityController = TextEditingController();
  int _newQuantity = 0;

  @override
  void initState() {
    super.initState();
    _newQuantity = widget.currentQuantity;
    _quantityController.text = _newQuantity.toString();
  }

  @override
  Widget build(BuildContext context) {
    final difference = _newQuantity - widget.currentQuantity;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getDifferenceColor(difference),
          child: Text(
            widget.product['name'][0],
            style: TextStyle(color: Colors.white),
          ),
        ),
        title: Text(widget.product['name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.localizations.translate('current_quantity')}: ${widget.currentQuantity}'),
            if (widget.product['min_stock_level'] > 0)
              Text('${widget.localizations.translate('minimum_stock_level')}: ${widget.product['min_stock_level']}'),
          ],
        ),
        trailing: Container(
          width: 120,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: widget.localizations.translate('new'),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onChanged: (value) {
                    final qty = int.tryParse(value) ?? widget.currentQuantity;
                    setState(() {
                      _newQuantity = qty;
                    });
                    widget.onQuantityChanged(qty);
                  },
                ),
              ),
              if (widget.isSelected)
                IconButton(
                  icon: Icon(Icons.check_circle, color: Colors.green),
                  onPressed: widget.onRemove,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifferenceColor(int difference) {
    if (difference > 0) return Colors.green;
    if (difference < 0) return Colors.red;
    return Colors.blue;
  }
}