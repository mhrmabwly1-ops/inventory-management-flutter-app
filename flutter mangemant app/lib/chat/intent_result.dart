// lib/chat/models/intent_result.dart
class IntentResult {
  final String intent;
  final double confidence;
  final String source;
  final String entity;

  IntentResult({
    required this.intent,
    required this.confidence,
    required this.source,
    this.entity = 'unknown',
  });

  @override
  String toString() {
    return 'IntentResult(intent: $intent, confidence: $confidence, source: $source, entity: $entity)';
  }
}