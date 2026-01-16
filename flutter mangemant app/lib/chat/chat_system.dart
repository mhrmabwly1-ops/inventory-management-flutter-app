
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';  // أضف هذا الاستيراد

import '../database_helper.dart';
import 'intent_recognizer.dart';
import 'chat_controller.dart';

class ChatSystem {
  late ChatController _chatController;
  late DatabaseHelper _dbHelper;
  bool _isInitialized = false;
  String? _openAIKey;  // إضافة متغير لمفتاح OpenAI

  ChatSystem();

  /// تهيئة نظام الدردشة
  Future<void> initialize() async {
  if (_isInitialized) return;

  try {
  // تحميل متغيرات البيئة
  await dotenv.load();
  _openAIKey = dotenv.env['OPENAI_API_KEY'];

  if (_openAIKey != null && _openAIKey!.isNotEmpty) {
  print('✅ OpenAI Key loaded from environment variables');
  } else {
  print('⚠️ OpenAI Key not found in environment variables');
  }

  // تهيئة قاعدة البيانات
  _dbHelper = DatabaseHelper();
  await _dbHelper.initDb();

  // تحميل ملف chat_brain.json
  final String intentsJson = await rootBundle.loadString('assets/chat_brain.json');

  // إنشاء المتحكم مع تمرير مفتاح OpenAI
  _chatController = ChatController(
  dbHelper: _dbHelper,
  intentsJson: intentsJson,
  openAIKey: _openAIKey,  // تمرير المفتاح
  );

  _isInitialized = true;
  print('✅ نظام الدردشة تم تهيئته بنجاح');
  } catch (e) {
  print('❌ خطأ في تهيئة نظام الدردشة: $e');
  rethrow;
  }
  }

  /// معالجة رسالة المستخدم
  Future<Map<String, dynamic>> processMessage(String message) async {
  if (!_isInitialized) {
  await initialize();
  }

  return await _chatController.processQuery(message);
  }

  /// الحصول على رسالة ترحيبية
  Map<String, dynamic> getWelcomeMessage() {
  return {
  'success': true,
  'response': '''
  🤖 **مرحباً بك في مساعد المخزون الذكي!**
  
  أنا هنا لمساعدتك في إدارة مخزونك. يمكنني:
  
  📦 **الرد على أسئلة المخزون**
  💰 **عرض التقارير المالية**
  👥 **معلومات الموردين والعملاء**
  🏭 **تفاصيل المخازن**
  
  💬 **جرب أن تسألني:**
  • "كم كمية منتج التفاح؟"
  • "ما هي المنتجات المنخفضة؟"
  • "عرض إجمالي المبيعات اليوم"
  • "مساعدة" - لعرض جميع الأوامر
  
  أنا أعمل 100% بدون إنترنت! 🔒
  ${_openAIKey != null ? '\n✨ **النظام الاحتياطي (OpenAI) متاح**' : ''}
  ''',
  'response_type': 'text',
  'is_welcome': true,
  };
  }

  /// إغلاق النظام
  Future<void> close() async {
  if (_isInitialized) {
  await _dbHelper.close();
  _isInitialized = false;
  }
  }
  }
