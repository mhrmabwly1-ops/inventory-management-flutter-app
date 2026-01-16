// invoice_numbering_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../color.dart';

import '../database_helper.dart';
import 'settings_controller.dart';


class InvoiceNumberingScreen extends StatefulWidget {
  const InvoiceNumberingScreen({super.key});

  @override
  State<InvoiceNumberingScreen> createState() => _InvoiceNumberingScreenState();
}

class _InvoiceNumberingScreenState extends State<InvoiceNumberingScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _startNumberController = TextEditingController();
  final TextEditingController _yearFormatController = TextEditingController();
  final TextEditingController _monthFormatController = TextEditingController();

  Map<String, dynamic> _invoiceNumberingSettings = {};
  bool _isLoading = true;
  int _nextInvoiceNumber = 1;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = Provider.of<SettingsController>(context, listen: false);
      _invoiceNumberingSettings = {
        'prefix': settings.getAdvancedSetting('invoice_prefix', defaultValue: 'INV'),
        'start_number': settings.getAdvancedSetting('invoice_start_number', defaultValue:""),
        'year_format': settings.getAdvancedSetting('invoice_year_format', defaultValue: 'YYYY'),
        'month_format': settings.getAdvancedSetting('invoice_month_format', defaultValue: 'MM'),
        'next_number': settings.getAdvancedSetting('invoice_next_number', defaultValue: ""),
      };

      _prefixController.text = _invoiceNumberingSettings['prefix'];
      _startNumberController.text = _invoiceNumberingSettings['start_number'].toString();
      _yearFormatController.text = _invoiceNumberingSettings['year_format'];
      _monthFormatController.text = _invoiceNumberingSettings['month_format'];
      _nextInvoiceNumber = _invoiceNumberingSettings['next_number'];

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل الإعدادات: $e')),
      );
    }
  }

  Future<void> _saveSettings() async {
    try {
      final settings = Provider.of<SettingsController>(context, listen: false);

      await settings.updateAdvancedSetting('invoice_prefix', _prefixController.text);
      await settings.updateAdvancedSetting('invoice_start_number', int.parse(_startNumberController.text) as String);
      await settings.updateAdvancedSetting('invoice_year_format', _yearFormatController.text);
      await settings.updateAdvancedSetting('invoice_month_format', _monthFormatController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ إعدادات ترقيم الفواتير بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في حفظ الإعدادات: $e')),
      );
    }
  }

  String _generateSampleInvoice() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');

    return '${_prefixController.text}-$year-$month-${_nextInvoiceNumber.toString().padLeft(4, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ترقيم الفواتير'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'حفظ الإعدادات',
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
            // بطاقة نموذج الترقيم
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'نموذج الترقيم',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _generateSampleInvoice(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'ملاحظة: يمكنك استخدام الرموز التالية:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 5),
                    const Text('• {PREFIX}: بادئة الفاتورة'),
                    const Text('• {YYYY}: السنة بأربعة أرقام'),
                    const Text('• {YY}: السنة برقمين'),
                    const Text('• {MM}: الشهر برقمين'),
                    const Text('• {DD}: اليوم برقمين'),
                    const Text('• {NNNN}: الرقم التسلسلي (4 أرقام)'),
                    const Text('• {NNN}: الرقم التسلسلي (3 أرقام)'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // إعدادات الترقيم
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إعدادات الترقيم',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // البادئة
                    TextField(
                      controller: _prefixController,
                      decoration: const InputDecoration(
                        labelText: 'بادئة الفاتورة',
                        hintText: 'مثال: INV, BIL, SAL',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.text_fields),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 15),

                    // رقم البداية
                    TextField(
                      controller: _startNumberController,
                      decoration: const InputDecoration(
                        labelText: 'رقم البداية',
                        hintText: 'ابدأ الترقيم من',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 15),

                    // تنسيق السنة
                    TextField(
                      controller: _yearFormatController,
                      decoration: const InputDecoration(
                        labelText: 'تنسيق السنة',
                        hintText: 'YYYY أو YY',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // تنسيق الشهر
                    TextField(
                      controller: _monthFormatController,
                      decoration: const InputDecoration(
                        labelText: 'تنسيق الشهر',
                        hintText: 'MM أو M',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.date_range),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // خيارات إضافية
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('إعادة التعيين الشهري'),
                              subtitle: const Text('إعادة الرقم التسلسلي إلى البداية كل شهر'),
                              value: _invoiceNumberingSettings['reset_monthly'] ?? false,
                              onChanged: (value) {
                                setState(() {
                                  _invoiceNumberingSettings['reset_monthly'] = value;
                                });
                              },
                            ),
                            SwitchListTile(
                              title: const Text('إعادة التعيين السنوي'),
                              subtitle: const Text('إعادة الرقم التسلسلي إلى البداية كل سنة'),
                              value: _invoiceNumberingSettings['reset_yearly'] ?? false,
                              onChanged: (value) {
                                setState(() {
                                  _invoiceNumberingSettings['reset_yearly'] = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // قسم المحاكاة
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'محاكاة الترقيم',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'الرقم التالي: $_nextInvoiceNumber',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _nextInvoiceNumber++;
                            });
                          },
                          child: const Text('زيادة الرقم'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _nextInvoiceNumber = int.parse(_startNumberController.text);
                            });
                          },
                          child: const Text('إعادة التعيين'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // عرض نماذج الفواتير
                    const Text(
                      'نماذج الفواتير القادمة:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    for (int i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          '${_generateSampleInvoice().replaceAll(_nextInvoiceNumber.toString().padLeft(4, '0'), (_nextInvoiceNumber + i).toString().padLeft(4, '0'))}',
                          style: const TextStyle(fontSize: 14),
                        ),
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