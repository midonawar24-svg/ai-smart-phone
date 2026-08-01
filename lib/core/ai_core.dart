import 'memory.dart';
import 'knowledge.dart';
import 'decision.dart';
import 'learning.dart';
import 'brain.dart';
import 'personality.dart';
import '../database/database.dart';

/// class AICore - العقل الذي يدير كل شيء
/// أي رسالة ستصل للنظام ستدخل هنا أولًا:
/// المستخدم -> AICore -> Brain, Memory, Knowledge, Decision, Learning -> الرد النهائي

class AICore {
  static final AICore _instance = AICore._internal();
  factory AICore() => _instance;
  AICore._internal();

  late Memory memory;
  late Knowledge knowledge;
  late DecisionEngine decisionEngine;
  late Learning learning;
  late Brain brain;
  late Personality personality;
  late AppDatabase database;

  bool _initialized = false;
  double _evolution = 50.0;

  double get evolutionLevel => _evolution;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    database = AppDatabase();
    memory = Memory();
    knowledge = Knowledge();
    decisionEngine = DecisionEngine();
    learning = Learning();
    personality = Personality();

    await database.db;
    await memory.init();
    await knowledge.init();
    await learning.init();

    brain = Brain(memory: memory, knowledge: knowledge, decisionEngine: decisionEngine);

    await _calcEvolution();
    _initialized = true;
  }

  Future<void> _calcEvolution() async {
    final convCount = await memory.count();
    final facts = await memory.getAllFacts();
    double level = 50.0 + (convCount * 0.5) + (facts.length * 3.0);
    _evolution = level.clamp(0, 100);

    await database.updateEvolution(_evolution, convCount, convCount, facts.length, 0);
  }

  /// نقطة الدخول الرئيسية - أي رسالة تدخل هنا
  Future<Map<String, dynamic>> process(String input) async {
    if (!_initialized) await init();

    // 1. Brain يحلل
    final analysis = await brain.analyze(input);
    final decision = analysis['decision'] as Decision;
    String response = analysis['response'] as String;

    // 2. معالجة أوامر خاصة
    if (decision.command == CommandType.time) {
      final now = DateTime.now();
      response = 'الساعة ${now.hour}:${now.minute.toString().padLeft(2, '0')} ⏰';
    } else if (decision.command == CommandType.date) {
      final now = DateTime.now();
      response = 'النهاردة ${now.day}/${now.month}/${now.year} 📅';
    } else if (decision.intent == Intent.clearMemory) {
      if (input.contains('فعلاً')) {
        await clearAll();
        response = 'تم مسح كل شيء - نوار بدأ من الصفر 🗑️';
      } else {
        response = 'عايز أمسح الذاكرة وفيها ${await memory.count()} محادثة؟ قول "امسح الذاكرة فعلاً"';
      }
    }

    // 3. حفظ المحادثة في SQLite
    await memory.saveConversation(
      input: input,
      output: response,
      intent: decision.intent.toString(),
      command: decision.command.toString(),
      confidence: analysis['confidence'],
      success: true,
    );

    // 4. تعلم
    await learning.learnFromInput(input);

    // 5. تحديث التطور
    await _calcEvolution();

    // 6. مسار التفكير النهائي
    final thinking = personality.thinking(decision, analysis['elapsed'], await memory.count());

    return {
      'thinking': thinking,
      'response': response,
      'decision': decision,
      'evolution': _evolution,
    };
  }

  Future<void> clearAll() async {
    await database.clearAll();
    _evolution = 50.0;
  }

  String evolutionDesc() {
    if (_evolution < 55) return 'مرحلة البداية - نوار لسه بيتعلم منك 🌱';
    if (_evolution < 65) return 'مرحلة التطور - بدأ يفهم ويتذكر 🧠';
    if (_evolution < 80) return 'مرحلة الذكاء - ذاكرة SQLite قوية 🚀';
    if (_evolution < 90) return 'مرحلة متقدمة - عقل مستقل أوفلاين 💎';
    return 'مرحلة الوعي الكامل - AI Core OS مكتمل! 👑';
  }

  Future<Map<String, dynamic>> getStats() async {
    final evo = await database.getEvolution();
    final facts = await memory.getAllFacts();
    final recent = await memory.getRecent(5);
    return {
      'evolution': _evolution,
      'description': evolutionDesc(),
      'evolutionData': evo,
      'facts': facts,
      'recent': recent,
      'total': await memory.count(),
    };
  }
}
