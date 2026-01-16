// payment_terms_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../color.dart';
import 'settings_controller.dart';


class PaymentTermsScreen extends StatefulWidget {
  const PaymentTermsScreen({super.key});

  @override
  State<PaymentTermsScreen> createState() => _PaymentTermsScreenState();
}

class _PaymentTermsScreenState extends State<PaymentTermsScreen> {
  Map<String, dynamic> _paymentTerms = {};
  bool _isLoading = true;

  final TextEditingController _defaultTermController = TextEditingController();
  final TextEditingController _earlyDiscountController = TextEditingController();
  final TextEditingController _lateFeeController = TextEditingController();
  final TextEditingController _gracePeriodController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }
  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  double _calculateEarlyDiscount(double amount) {
    double discountPercent = _parseDouble(_paymentTerms['early_discount_percent']);
    return amount - (amount * (discountPercent / 100));
  }

  double _calculateLateFee(double amount) {
    double lateFeePercent = _parseDouble(_paymentTerms['late_fee_percent']);
    return amount + (amount * (lateFeePercent / 100));
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(2);
  }
  Future<void> _loadTerms() async {
    setState(() => _isLoading = true);
    try {
      final settings = Provider.of<SettingsController>(context, listen: false);

      _paymentTerms = {
        'default_term': settings.getAdvancedSetting('payment_default_term', defaultValue: 30),
        'early_discount_percent': settings.getAdvancedSetting('payment_early_discount', defaultValue: 2.0),
        'early_discount_days': settings.getAdvancedSetting('payment_early_discount_days', defaultValue: 10),
        'late_fee_percent': settings.getAdvancedSetting('payment_late_fee', defaultValue: 5.0),
        'late_fee_days': settings.getAdvancedSetting('payment_late_fee_days', defaultValue: 7),
        'grace_period': settings.getAdvancedSetting('payment_grace_period', defaultValue: 3),
        'auto_apply_fees': settings.getAdvancedSetting('payment_auto_apply_fees', defaultValue: true),
        'send_reminders': settings.getAdvancedSetting('payment_send_reminders', defaultValue: true),
        'reminder_days': settings.getAdvancedSetting('payment_reminder_days', defaultValue: 3),
      };

      _defaultTermController.text = _paymentTerms['default_term'].toString();
      _earlyDiscountController.text = _paymentTerms['early_discount_percent'].toString();
      _lateFeeController.text = _paymentTerms['late_fee_percent'].toString();
      _gracePeriodController.text = _paymentTerms['grace_period'].toString();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل الشروط: $e')),
      );
    }
  }

  Future<void> _saveTerms() async {
    try {
      final settings = Provider.of<SettingsController>(context, listen: false);

      await settings.updateAdvancedSetting('payment_default_term', int.parse(_defaultTermController.text) as String);
      await settings.updateAdvancedSetting('payment_early_discount', double.parse(_earlyDiscountController.text) as String);
      await settings.updateAdvancedSetting('payment_late_fee', double.parse(_lateFeeController.text) as String);
      await settings.updateAdvancedSetting('payment_grace_period', int.parse(_gracePeriodController.text) as String);

      // تحديث القيم الأخرى
      for (var key in _paymentTerms.keys) {
        if (!key.toString().contains('controller')) {
          await settings.updateAdvancedSetting('payment_$key', _paymentTerms[key]);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ شروط الدفع بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في حفظ الشروط: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شروط الدفع'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTerms,
            tooltip: 'حفظ الشروط',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة شروط الدفع الأساسية
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'شروط الدفع الأساسية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: _defaultTermController,
                      decoration: const InputDecoration(
                        labelText: 'فترة السداد الافتراضية (أيام)',
                        hintText: 'عدد الأيام المسموح بها للسداد',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: _gracePeriodController,
                      decoration: const InputDecoration(
                        labelText: 'فترة السماح (أيام)',
                        hintText: 'فترة السماح بعد تاريخ الاستحقاق',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // بطاقة خصم السداد المبكر
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'خصم السداد المبكر',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: _earlyDiscountController,
                      decoration: const InputDecoration(
                        labelText: 'نسبة الخصم (%)',
                        hintText: 'نسبة الخصم عند السداد المبكر',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.percent),
                        suffixText: '%',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),

                    const SizedBox(height: 15),

                    Slider(
                      value: (_paymentTerms['early_discount_days'] as int).toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '${_paymentTerms['early_discount_days']}',
                      onChanged: (value) {
                        setState(() {
                          _paymentTerms['early_discount_days'] = value.toInt();
                        });
                      },
                    ),
                    const Text('عدد الأيام المسموح بها للحصول على الخصم'),
                    Text('الخصم متاح إذا تم السداد خلال ${_paymentTerms['early_discount_days']} أيام', style: const TextStyle(fontWeight: FontWeight.bold)),

                    const SizedBox(height: 10),

                    SwitchListTile(
                      title: const Text('تطبيق الخصم تلقائياً'),
                      value: _paymentTerms['auto_apply_discount'] ?? true,
                      onChanged: (value) {
                        setState(() {
                          _paymentTerms['auto_apply_discount'] = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // بطاقة رسوم التأخير
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'رسوم التأخير',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: _lateFeeController,
                      decoration: const InputDecoration(
                        labelText: 'نسبة الرسوم (%)',
                        hintText: 'نسبة الرسوم عند التأخير',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.money_off),
                        suffixText: '%',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),

                    const SizedBox(height: 15),

                    Slider(
                      value: (_paymentTerms['late_fee_days'] as int).toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '${_paymentTerms['late_fee_days']}',
                      onChanged: (value) {
                        setState(() {
                          _paymentTerms['late_fee_days'] = value.toInt();
                        });
                      },
                    ),
                    const Text('عدد الأيام المسموح بها قبل تطبيق الرسوم'),
                    Text('تطبق الرسوم بعد ${_paymentTerms['late_fee_days']} أيام من تاريخ الاستحقاق', style: const TextStyle(fontWeight: FontWeight.bold)),

                    const SizedBox(height: 10),

                    SwitchListTile(
                      title: const Text('تطبيق الرسوم تلقائياً'),
                      value: _paymentTerms['auto_apply_fees'],
                      onChanged: (value) {
                        setState(() {
                          _paymentTerms['auto_apply_fees'] = value;
                        });
                      },
                    ),

                    SwitchListTile(
                      title: const Text('إضافة الرسوم بشكل تراكمي'),
                      subtitle: const Text('تراكم الرسوم كل فترة تأخير'),
                      value: _paymentTerms['compound_late_fees'] ?? false,
                      onChanged: (value) {
                        setState(() {
                          _paymentTerms['compound_late_fees'] = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // بطاقة التذكيرات والإشعارات
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'التذكيرات والإشعارات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    SwitchListTile(
                      title: const Text('إرسال تذكيرات السداد'),
                      value: _paymentTerms['send_reminders'],
                      onChanged: (value) {
                        setState(() {
                          _paymentTerms['send_reminders'] = value;
                        });
                      },
                    ),

                    if (_paymentTerms['send_reminders']) ...[
                      const SizedBox(height: 10),
                      Slider(
                        value: (_paymentTerms['reminder_days'] as int).toDouble(),
                        min: 1,
                        max: 7,
                        divisions: 6,
                        label: '${_paymentTerms['reminder_days']}',
                        onChanged: (value) {
                          setState(() {
                            _paymentTerms['reminder_days'] = value.toInt();
                          });
                        },
                      ),
                      const Text('عدد الأيام قبل تاريخ الاستحقاق لإرسال التذكير'),
                      Text('يتم إرسال التذكير قبل ${_paymentTerms['reminder_days']} أيام', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],

                    const SizedBox(height: 15),

                    SwitchListTile(
                      title: const Text('إرسال تنبيهات بعد التأخير'),
                      value: _paymentTerms['send_late_notifications'] ?? true,
                      onChanged: (value) {
                        setState(() {
                          _paymentTerms['send_late_notifications'] = value;
                        });
                      },
                    ),

                    SwitchListTile(
                      title: const Text('إشعارات عبر البريد الإلكتروني'),
                      value: _paymentTerms['email_notifications'] ?? true,
                      onChanged: (value) {
                        setState(() {
                          _paymentTerms['email_notifications'] = value;
                        });
                      },
                    ),

                    SwitchListTile(
                      title: const Text('إشعارات عبر الرسائل القصيرة'),
                      value: _paymentTerms['sms_notifications'] ?? false,
                      onChanged: (value) {
                        setState(() {
                          _paymentTerms['sms_notifications'] = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // بطاقة شروط الدفع المخصصة
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'شروط الدفع المخصصة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    DataTable(
                      columns: const [
                        DataColumn(label: Text('الاسم')),
                        DataColumn(label: Text('الأيام')),
                        DataColumn(label: Text('الخصم')),
                        DataColumn(label: Text('الإجراءات')),
                      ],
                      rows: [
                        DataRow(cells: [
                          const DataCell(Text('صافي 0')),
                          const DataCell(Text('0')),
                          const DataCell(Text('0%')),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                onPressed: () {},
                              ),
                            ],
                          )),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('صافي 30')),
                          const DataCell(Text('30')),
                          const DataCell(Text('0%')),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                onPressed: () {},
                              ),
                            ],
                          )),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('خصم 2/10 صافي 30')),
                          const DataCell(Text('30')),
                          const DataCell(Text('2%')),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                onPressed: () {},
                              ),
                            ],
                          )),
                        ]),
                      ],
                    ),

                    const SizedBox(height: 10),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة شرط دفع مخصص'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('سيتم إضافة هذه الميزة في نسخة لاحقة')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // بطاقة مثال حسابي
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مثال حسابي',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    const Text('للفاتورة بقيمة 1,000 وحدة نقدية:'),
                    const SizedBox(height: 10),
                    DataTable(
                      columns: const [
                        DataColumn(label: Text('السيناريو')),
                        DataColumn(label: Text('المبلغ')),
                      ],
                      rows: [
                        DataRow(cells: [
                          DataCell(Text('السداد خلال ${_paymentTerms['early_discount_days']} أيام')),
                          DataCell(Text('${_calculateEarlyDiscount(1000)}')),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('السداد في الموعد')),
                          const DataCell(Text('1,000')),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('السداد بعد ${_paymentTerms['late_fee_days']} أيام من الاستحقاق')),
                          DataCell(Text('${_calculateLateFee(1000)}')),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}