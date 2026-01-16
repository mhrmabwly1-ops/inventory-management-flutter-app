// service/password_policy.dart
import 'package:flutter/material.dart';

import '../database_helper.dart';

class PasswordPolicyScreen extends StatefulWidget {
  @override
  _PasswordPolicyScreenState createState() => _PasswordPolicyScreenState();
}

class _PasswordPolicyScreenState extends State<PasswordPolicyScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // إعدادات سياسة كلمة المرور
  bool _requireUppercase = false;
  bool _requireLowercase = false;
  bool _requireNumbers = false;
  bool _requireSpecialChars = false;
  int _minLength = 6;
  int _maxLength = 20;
  int _maxFailedAttempts = 5;
  int _lockoutDuration = 30; // بالدقائق
  bool _preventReuse = false;
  int _passwordExpiryDays = 90;
  bool _enableTwoFactorAuth = false;

  final TextEditingController _minLengthController = TextEditingController();
  final TextEditingController _maxLengthController = TextEditingController();
  final TextEditingController _maxAttemptsController = TextEditingController();
  final TextEditingController _lockoutController = TextEditingController();
  final TextEditingController _expiryDaysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPasswordPolicy();
  }

  Future<void> _loadPasswordPolicy() async {
    try {
      // تحميل الإعدادات من قاعدة البيانات
      final settings = await _dbHelper.getSettings();

      setState(() {
        _requireUppercase = settings['password_require_uppercase'] == '1';
        _requireLowercase = settings['password_require_lowercase'] == '1';
        _requireNumbers = settings['password_require_numbers'] == '1';
        _requireSpecialChars = settings['password_require_special_chars'] == '1';
        _minLength = int.tryParse(settings['password_min_length'] ?? '6') ?? 6;
        _maxLength = int.tryParse(settings['password_max_length'] ?? '20') ?? 20;
        _maxFailedAttempts = int.tryParse(settings['password_max_attempts'] ?? '5') ?? 5;
        _lockoutDuration = int.tryParse(settings['password_lockout_duration'] ?? '30') ?? 30;
        _preventReuse = settings['password_prevent_reuse'] == '1';
        _passwordExpiryDays = int.tryParse(settings['password_expiry_days'] ?? '90') ?? 90;
        _enableTwoFactorAuth = settings['enable_two_factor_auth'] == '1';

        // تعيين القيم في المتحكمات
        _minLengthController.text = _minLength.toString();
        _maxLengthController.text = _maxLength.toString();
        _maxAttemptsController.text = _maxFailedAttempts.toString();
        _lockoutController.text = _lockoutDuration.toString();
        _expiryDaysController.text = _passwordExpiryDays.toString();
      });
    } catch (e) {
      print('خطأ في تحميل سياسة كلمة المرور: $e');
    }
  }

  Future<void> _savePasswordPolicy() async {
    try {
      // حفظ الإعدادات في قاعدة البيانات
      await _dbHelper.setSetting('password_require_uppercase', _requireUppercase ? '1' : '0');
      await _dbHelper.setSetting('password_require_lowercase', _requireLowercase ? '1' : '0');
      await _dbHelper.setSetting('password_require_numbers', _requireNumbers ? '1' : '0');
      await _dbHelper.setSetting('password_require_special_chars', _requireSpecialChars ? '1' : '0');
      await _dbHelper.setSetting('password_min_length', _minLengthController.text);
      await _dbHelper.setSetting('password_max_length', _maxLengthController.text);
      await _dbHelper.setSetting('password_max_attempts', _maxAttemptsController.text);
      await _dbHelper.setSetting('password_lockout_duration', _lockoutController.text);
      await _dbHelper.setSetting('password_prevent_reuse', _preventReuse ? '1' : '0');
      await _dbHelper.setSetting('password_expiry_days', _expiryDaysController.text);
      await _dbHelper.setSetting('enable_two_factor_auth', _enableTwoFactorAuth ? '1' : '0');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ سياسة كلمة المرور بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حفظ سياسة كلمة المرور: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getPasswordRequirements() {
    List<String> requirements = [];

    if (_requireUppercase) requirements.add('حرف كبير (A-Z)');
    if (_requireLowercase) requirements.add('حرف صغير (a-z)');
    if (_requireNumbers) requirements.add('رقم (0-9)');
    if (_requireSpecialChars) requirements.add('رمز خاص (!@#\$%...)');

    requirements.add('طول بين $_minLength و $_maxLength حرف');

    return requirements.join('، ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سياسة كلمة المرور'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // قسم المتطلبات الأساسية
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'متطلبات كلمة المرور',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 10),

                    SwitchListTile(
                      title: const Text('تتضمن حروف كبيرة'),
                      subtitle: const Text('مطلوب حرف كبير واحد على الأقل (A-Z)'),
                      value: _requireUppercase,
                      onChanged: (value) {
                        setState(() {
                          _requireUppercase = value;
                        });
                      },
                    ),

                    SwitchListTile(
                      title: const Text('تتضمن حروف صغيرة'),
                      subtitle: const Text('مطلوب حرف صغير واحد على الأقل (a-z)'),
                      value: _requireLowercase,
                      onChanged: (value) {
                        setState(() {
                          _requireLowercase = value;
                        });
                      },
                    ),

                    SwitchListTile(
                      title: const Text('تتضمن أرقام'),
                      subtitle: const Text('مطلوب رقم واحد على الأقل (0-9)'),
                      value: _requireNumbers,
                      onChanged: (value) {
                        setState(() {
                          _requireNumbers = value;
                        });
                      },
                    ),

                    SwitchListTile(
                      title: const Text('تتضمن رموز خاصة'),
                      subtitle: const Text('مطلوب رمز خاص واحد على الأقل (!@#\$%^&*)'),
                      value: _requireSpecialChars,
                      onChanged: (value) {
                        setState(() {
                          _requireSpecialChars = value;
                        });
                      },
                    ),

                    const Divider(),

                    // طول كلمة المرور
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minLengthController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'الحد الأدنى للأحرف',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _minLength = int.tryParse(value) ?? 6;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _maxLengthController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'الحد الأقصى للأحرف',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _maxLength = int.tryParse(value) ?? 20;
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

            const SizedBox(height: 20),

            // قسم الأمان
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إعدادات الأمان',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _maxAttemptsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'الحد الأقصى لمحاولات تسجيل الدخول الفاشلة',
                        border: OutlineInputBorder(),
                        hintText: '5',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _maxFailedAttempts = int.tryParse(value) ?? 5;
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _lockoutController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'مدة قفل الحساب بعد فشل المحاولات (بالدقائق)',
                        border: OutlineInputBorder(),
                        hintText: '30',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _lockoutDuration = int.tryParse(value) ?? 30;
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _expiryDaysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'عدد أيام صلاحية كلمة المرور',
                        border: OutlineInputBorder(),
                        hintText: '90',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _passwordExpiryDays = int.tryParse(value) ?? 90;
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    SwitchListTile(
                      title: const Text('منع إعادة استخدام كلمات المرور القديمة'),
                      subtitle: const Text('يجب أن تكون كلمة المرور الجديدة مختلفة عن السابقة'),
                      value: _preventReuse,
                      onChanged: (value) {
                        setState(() {
                          _preventReuse = value;
                        });
                      },
                    ),

                    SwitchListTile(
                      title: const Text('تمكين المصادقة الثنائية'),
                      subtitle: const Text('طلب رمز التحقق بالإضافة إلى كلمة المرور'),
                      value: _enableTwoFactorAuth,
                      onChanged: (value) {
                        setState(() {
                          _enableTwoFactorAuth = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // عرض الملخص
            Card(
              elevation: 3,
              color: Colors.blueGrey[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ملخص سياسة كلمة المرور',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      'متطلبات كلمة المرور الجديدة:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(_getPasswordRequirements()),

                    const SizedBox(height: 10),

                    const Text(
                      'إعدادات الأمان:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text('• أقصى محاولات فاشلة: $_maxFailedAttempts محاولة'),
                    Text('• مدة قفل الحساب: $_lockoutDuration دقيقة'),
                    Text('• صلاحية كلمة المرور: $_passwordExpiryDays يوم'),
                    Text('• منع إعادة الاستخدام: ${_preventReuse ? 'مفعل' : 'معطل'}'),
                    Text('• المصادقة الثنائية: ${_enableTwoFactorAuth ? 'مفعلة' : 'معطلة'}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // أمثلة لكلمات المرور المقبولة
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أمثلة لكلمات مرور مقبولة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 10),

                    const Text('🔒 كلمات مرور قوية:'),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('✅ MyP@ssw0rd2024'),
                          const Text('✅ Secure#2024!Pass'),
                          const Text('✅ Admin@System2024'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text('⚠️ كلمات مرور ضعيفة:'),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('❌ password'),
                          const Text('❌ 123456'),
                          const Text('❌ admin'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // زر الحفظ
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text(
                  'حفظ سياسة كلمة المرور',
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: _savePasswordPolicy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[900],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // معلومات إضافية
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blueGrey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'سياسة كلمة المرور تنطبق على المستخدمين الجدد وعند تغيير كلمة المرور. لن تؤثر على كلمات المرور الحالية.',
                      style: TextStyle(
                        color: Colors.blueGrey[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _minLengthController.dispose();
    _maxLengthController.dispose();
    _maxAttemptsController.dispose();
    _lockoutController.dispose();
    _expiryDaysController.dispose();
    super.dispose();
  }
}