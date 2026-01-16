import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:untitled43/screens/permission_service.dart';

import '../dashboard_screen.dart';
import '../database_helper.dart';
import '../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  final int? userId;

  const LoginScreen({super.key, this.userId});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final PermissionService _permissionService = PermissionService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isLocked = false;
  int _remainingSeconds = 0;
  Timer? _lockTimer;
  int _failedAttempts = 0;

  static const int MAX_FAILED_ATTEMPTS = 5;
  static const int LOCK_DURATION_SECONDS = 5;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _lockTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lockedUntil = prefs.getString('locked_until');

    if (lockedUntil != null) {
      final lockedUntilTime = DateTime.parse(lockedUntil);
      final now = DateTime.now();

      if (lockedUntilTime.isAfter(now)) {
        final difference = lockedUntilTime.difference(now).inSeconds;
        setState(() {
          _isLocked = true;
          _remainingSeconds = difference;
        });
        _startLockTimer();
      } else {
        // انتهت فترة القفل
        await prefs.remove('locked_until');
        await prefs.setInt('failed_attempts', 0);
      }
    }

    // تحميل عدد المحاولات الفاشلة
    _failedAttempts = prefs.getInt('failed_attempts') ?? 0;
  }

  void _startLockTimer() {
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _unlockAccount();
      }
    });
  }

  Future<void> _unlockAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('locked_until');
    await prefs.setInt('failed_attempts', 0);

    setState(() {
      _isLocked = false;
      _failedAttempts = 0;
      _remainingSeconds = 0;
    });
  }

  Future<void> _lockAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final lockedUntil = DateTime.now().add(const Duration(seconds: LOCK_DURATION_SECONDS));

    await prefs.setString('locked_until', lockedUntil.toIso8601String());
    await prefs.setInt('failed_attempts', _failedAttempts);

    setState(() {
      _isLocked = true;
      _remainingSeconds = LOCK_DURATION_SECONDS;
    });

    _startLockTimer();

    // إظهار تنبيه للمستخدم
    _showLockMessage();
  }

  void _showLockMessage() {
    final localizations = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizations.translate('account_temporarily_suspended')),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _incrementFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    _failedAttempts++;
    await prefs.setInt('failed_attempts', _failedAttempts);

    // إذا وصلت المحاولات الفاشلة إلى الحد الأقصى
    if (_failedAttempts >= MAX_FAILED_ATTEMPTS) {
      await _lockAccount();
    }
  }

  Future<void> _resetFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    _failedAttempts = 0;
    await prefs.setInt('failed_attempts', 0);
    await prefs.remove('locked_until');
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password + 'salt_12345');
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _login() async {
    final localizations = AppLocalizations.of(context);

    // التحقق من حالة القفل
    if (_isLocked) {
      _showError('${localizations.translate('account_locked_wait')} $_remainingSeconds ${localizations.translate('seconds')}');
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showError(localizations.translate('enter_username_password'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = await _dbHelper.database;

      // البحث عن المستخدم بالاسم فقط
      final users = await db.query(
        'users',
        where: 'username = ? AND is_active = 1',
        whereArgs: [username],
        limit: 1,
      );

      if (users.isEmpty) {
        await _incrementFailedAttempts();
        _showError(localizations.translate('invalid_username_password'));
        setState(() => _isLoading = false);
        return;
      }

      final user = users.first;
      final storedPassword = user['password'] as String;
      final hashedPassword = _hashPassword(password);

      if (hashedPassword != storedPassword) {
        await _incrementFailedAttempts();

        // عرض عدد المحاولات المتبقية
        final remainingAttempts = MAX_FAILED_ATTEMPTS - _failedAttempts;
        if (remainingAttempts > 0) {
          _showError('${localizations.translate('incorrect_password')} $remainingAttempts ${localizations.translate('attempts_remaining')}');
        }

        setState(() => _isLoading = false);
        return;
      }

      // تسجيل الدخول ناجح - إعادة تعيين المحاولات الفاشلة
      await _resetFailedAttempts();

      _permissionService.setUserPermissions(user['role'] as String);

      // تحديث آخر وقت دخول
      await db.update(
        'users',
        {'last_login': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [user['id']],
      );

      // تسجيل محاولة الدخول الناجحة
      await _logLoginAttempt(db, user['id'] as int, true);

      // الانتقال إلى الشاشة الرئيسية
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            username: user['name'] as String,
            role: user['role'] as String,
          ),
        ),
      );

    } catch (e) {
      _showError(localizations.translate('login_error_occurred'));
      print('Login error: $e');
      await _logSystemError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logLoginAttempt(Database db, int userId, bool success) async {
    try {
      await db.insert('audit_log', {
        'user_id': userId,
        'action': 'login',
        'details': json.encode({
          'success': success,
          'timestamp': DateTime.now().toIso8601String(),
          'ip_address': 'local',
          'failed_attempts': _failedAttempts,
        }),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to log login attempt: $e');
    }
  }

  Future<void> _logSystemError(String error) async {
    try {
      final db = await _dbHelper.database;
      await db.insert('audit_log', {
        'action': 'system_error',
        'details': json.encode({
          'error': error,
          'screen': 'LoginScreen',
          'timestamp': DateTime.now().toIso8601String(),
        }),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to log system error: $e');
    }
  }

  Future<void> _resetAdminPassword() async {
    if (!kDebugMode) return;

    final localizations = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      final db = await _dbHelper.database;
      final hashedPassword = _hashPassword('admin123');

      final result = await db.update(
        'users',
        {'password': hashedPassword},
        where: 'username = ?',
        whereArgs: ['admin'],
      );

      if (result > 0) {
        _showSuccess(localizations.translate('admin_password_reset_success'));
      } else {
        _showError(localizations.translate('admin_user_not_found'));
      }
    } catch (e) {
      _showError('${localizations.translate('reset_error')}: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // شعار التطبيق
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 30),

              // عنوان التطبيق
              Text(
                localizations.translate('inventory_management_system'),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.translate('login_to_your_account'),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),

              // عرض حالة القفل
              if (_isLocked)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_clock, color: Colors.orange),
                      const SizedBox(width: 10),
                      Text(
                        '${localizations.translate('account_temporarily_locked')}: $_remainingSeconds ${localizations.translate('seconds')}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // حقل اسم المستخدم
              TextFormField(
                controller: _usernameController,
                enabled: !_isLocked,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: localizations.translate('username'),
                  prefixIcon: const Icon(Icons.person, color: Colors.deepPurple),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                  ),
                  filled: true,
                  fillColor: _isLocked ? Colors.grey[200] : Colors.white,
                ),
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 20),

              // حقل كلمة المرور
              TextFormField(
                controller: _passwordController,
                enabled: !_isLocked,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: localizations.translate('password'),
                  prefixIcon: const Icon(Icons.lock, color: Colors.deepPurple),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.deepPurple,
                    ),
                    onPressed: _isLocked
                        ? null
                        : () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                  ),
                  filled: true,
                  fillColor: _isLocked ? Colors.grey[200] : Colors.white,
                ),
                onFieldSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 10),

              // عرض عدد المحاولات المتبقية
              if (_failedAttempts > 0 && !_isLocked)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${localizations.translate('failed_attempts')}: $_failedAttempts/$MAX_FAILED_ATTEMPTS',
                    style: TextStyle(
                      color: _failedAttempts >= MAX_FAILED_ATTEMPTS - 1
                          ? Colors.red
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // نسيت كلمة المرور
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _isLocked
                      ? null
                      : () {
                    _showError(localizations.translate('contact_system_admin'));
                  },
                  child: Text(
                    localizations.translate('forgot_password'),
                    style: TextStyle(
                      color: _isLocked ? Colors.grey : Colors.deepPurple,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // زر تسجيل الدخول
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading || _isLocked ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLocked
                        ? Colors.grey
                        : Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    shadowColor: Colors.deepPurple.withOpacity(0.3),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    _isLocked ? localizations.translate('locked') : localizations.translate('login'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // زر إصلاح كلمة المرور (للتطوير فقط)
              if (kDebugMode)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: OutlinedButton(
                    onPressed: _isLoading || _isLocked ? null : _resetAdminPassword,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _isLocked ? Colors.grey : Colors.orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      localizations.translate('fix_admin_password_debug'),
                      style: TextStyle(color: _isLocked ? Colors.grey : Colors.orange),
                    ),
                  ),
                ),

              // معلومات إضافية
              const SizedBox(height: 40),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 20),
              Text(
                '${localizations.translate('system_version')}: 1.1.0',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '© 2024 ${localizations.translate('inventory_management_system')}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}