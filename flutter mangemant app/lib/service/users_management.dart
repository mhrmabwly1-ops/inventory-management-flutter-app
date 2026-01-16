// users_management.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled43/service/ser_permissions_screen.dart';

import '../color.dart';
import '../database_helper.dart';



class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  // مرشحات البحث
  final TextEditingController _searchController = TextEditingController();
  String _filterRole = 'الكل';
  String _filterStatus = 'الكل';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      _users = await _dbHelper.getUsers();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل المستخدمين: $e')),
      );
    }
  }

  Future<void> _deleteUser(int userId, String username) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المستخدم "$username"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _dbHelper.deleteUser(userId);
                Navigator.pop(context);
                await _loadUsers();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف المستخدم بنجاح')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ في حذف المستخدم: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => _UserEditDialog(
        onUserAdded: () => _loadUsers(),
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => _UserEditDialog(
        user: user,
        onUserUpdated: () => _loadUsers(),
      ),
    );
  }

  void _showUserPermissionsDialog(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserPermissionsScreen(
          userId: user['id'],
          userName: user['name'],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredUsers() {
    List<Map<String, dynamic>> filtered = List.from(_users);

    // تصفية حسب البحث
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((user) {
        final name = user['name'].toString().toLowerCase();
        final username = user['username'].toString().toLowerCase();
        final search = _searchController.text.toLowerCase();
        return name.contains(search) || username.contains(search);
      }).toList();
    }

    // تصفية حسب الدور
    if (_filterRole != 'الكل') {
      filtered = filtered.where((user) => user['role'] == _filterRole).toList();
    }

    // تصفية حسب الحالة
    if (_filterStatus != 'الكل') {
      final isActive = _filterStatus == 'نشط';
      filtered = filtered.where((user) => user['is_active'] == (isActive ? 1 : 0)).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _getFilteredUsers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddUserDialog,
            tooltip: 'إضافة مستخدم جديد',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'تحديث القائمة',
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث والتصفية
          Card(
            margin: const EdgeInsets.all(8),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'بحث عن مستخدم',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filterRole,
                          decoration: const InputDecoration(
                            labelText: 'الدور',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'الكل', child: Text('الكل')),
                            DropdownMenuItem(value: 'admin', child: Text('مدير')),
                            DropdownMenuItem(value: 'manager', child: Text('مدير مخزن')),
                            DropdownMenuItem(value: 'warehouse', child: Text('مخازن')),
                            DropdownMenuItem(value: 'cashier', child: Text('كاشير')),
                            DropdownMenuItem(value: 'viewer', child: Text('مشاهد')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterRole = value!;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filterStatus,
                          decoration: const InputDecoration(
                            labelText: 'الحالة',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'الكل', child: Text('الكل')),
                            DropdownMenuItem(value: 'نشط', child: Text('نشط')),
                            DropdownMenuItem(value: 'غير نشط', child: Text('غير نشط')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterStatus = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // عدد المستخدمين
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إجمالي المستخدمين: ${filteredUsers.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'عرض ${filteredUsers.length} من ${_users.length}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // قائمة المستخدمين
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد مستخدمين'),
                ],
              ),
            )
                : ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return _UserListItem(
                  user: user,
                  onEdit: () => _showEditUserDialog(user),
                  onDelete: () => _deleteUser(user['id'], user['username']),
                  onPermissions: () => _showUserPermissionsDialog(user),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserListItem extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPermissions;

  const _UserListItem({
    required this.user,
    required this.onEdit,
    required this.onDelete,
    required this.onPermissions,
  });

  String _getRoleName(String role) {
    switch (role) {
      case 'admin': return 'مدير النظام';
      case 'manager': return 'مدير مخزن';
      case 'warehouse': return 'موظف مخازن';
      case 'cashier': return 'كاشير';
      case 'viewer': return 'مشاهد';
      default: return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user['is_active'] == 1 ? Colors.green : Colors.grey,
          child: Text(
            user['name'][0],
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          user['name'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: user['is_active'] == 0 ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اسم المستخدم: ${user['username']}'),
            Text('الدور: ${_getRoleName(user['role'])}'),
            Text(
              'آخر دخول: ${user['last_login'] ?? 'لم يسجل دخول'}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
              tooltip: 'تعديل',
            ),
            IconButton(
              icon: const Icon(Icons.security, color: Colors.orange),
              onPressed: onPermissions,
              tooltip: 'الصلاحيات',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'حذف',
            ),
          ],
        ),
      ),
    );
  }
}

class _UserEditDialog extends StatefulWidget {
  final Map<String, dynamic>? user;
  final VoidCallback? onUserAdded;
  final VoidCallback? onUserUpdated;

  const _UserEditDialog({
    this.user,
    this.onUserAdded,
    this.onUserUpdated,
  });

  @override
  State<_UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<_UserEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _selectedRole = 'cashier';
  bool _isActive = true;
  bool _isEditMode = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _isEditMode = true;
      _usernameController.text = widget.user!['username'];
      _nameController.text = widget.user!['name'];
      _selectedRole = widget.user!['role'];
      _isActive = widget.user!['is_active'] == 1;
    }
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        final userData = {
          'username': _usernameController.text,
          'name': _nameController.text,
          'role': _selectedRole,
          'is_active': _isActive ? 1 : 0,
        };

        if (_passwordController.text.isNotEmpty) {
          userData['password'] = _passwordController.text;
        }

        if (_isEditMode) {
          await _dbHelper.updateUser(widget.user!['id'], userData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث المستخدم بنجاح')),
          );
          widget.onUserUpdated?.call();
        } else {
          await _dbHelper.insertUser(userData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة المستخدم بنجاح')),
          );
          widget.onUserAdded?.call();
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حفظ المستخدم: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditMode ? 'تعديل المستخدم' : 'إضافة مستخدم جديد'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'اسم المستخدم مطلوب';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الاسم الكامل مطلوب';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: _isEditMode ? 'كلمة المرور (اترك فارغاً للحفاظ على القديمة)' : 'كلمة المرور',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (!_isEditMode && (value == null || value.isEmpty)) {
                    return 'كلمة المرور مطلوبة';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  border: OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (_passwordController.text.isNotEmpty && value != _passwordController.text) {
                    return 'كلمات المرور غير متطابقة';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'الدور',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('مدير النظام')),
                  DropdownMenuItem(value: 'manager', child: Text('مدير مخزن')),
                  DropdownMenuItem(value: 'warehouse', child: Text('موظف مخازن')),
                  DropdownMenuItem(value: 'cashier', child: Text('كاشير')),
                  DropdownMenuItem(value: 'viewer', child: Text('مشاهد')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),

              const SizedBox(height: 10),

              SwitchListTile(
                title: const Text('الحساب نشط'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _saveUser,
          child: Text(_isEditMode ? 'تحديث' : 'إضافة'),
        ),
      ],
    );
  }
}