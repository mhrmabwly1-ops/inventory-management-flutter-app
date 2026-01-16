// user_permissions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../color.dart';
import '../database_helper.dart';

class UserPermissionsScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const UserPermissionsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserPermissionsScreen> createState() => _UserPermissionsScreenState();
}

class _UserPermissionsScreenState extends State<UserPermissionsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, bool> _permissions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() => _isLoading = true);
    try {
      final permissions = await _dbHelper.getUserPermissions(widget.userId);
      _permissions.clear();

      for (var permission in permissions) {
        _permissions[permission['permission_key']] =
            permission['granted'] == 1;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل الصلاحيات: $e')),
      );
    }
  }

  Future<void> _updatePermission(String key, bool value) async {
    try {
      await _dbHelper.updateUserPermission(widget.userId, key, value);
      setState(() {
        _permissions[key] = value;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحديث الصلاحية: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('صلاحيات المستخدم: ${widget.userName}'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إدارة المنتجات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ..._buildPermissionSwitches([
                    'products_view',
                    'products_add',
                    'products_edit',
                    'products_delete',
                  ]),
                ],
              ),
            ),
          ),
          // يمكن إضافة المزيد من المجموعات هنا
        ],
      ),
    );
  }

  List<Widget> _buildPermissionSwitches(List<String> keys) {
    return keys.map((key) {
      return SwitchListTile(
        title: Text(_getPermissionName(key)),
        value: _permissions[key] ?? false,
        onChanged: (value) => _updatePermission(key, value),
      );
    }).toList();
  }

  String _getPermissionName(String key) {
    final names = {
      'products_view': 'عرض المنتجات',
      'products_add': 'إضافة منتج',
      'products_edit': 'تعديل منتج',
      'products_delete': 'حذف منتج',
      // إضافة المزيد من الصلاحيات
    };
    return names[key] ?? key;
  }
}