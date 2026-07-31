import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartAiPhoneApp());
}

class SmartAiPhoneApp extends StatelessWidget {
  const SmartAiPhoneApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Self-Evolving System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF090A0F),
        primaryColor: Colors.deepPurpleAccent,
        useMaterial3: true,
      ),
      home: const LockScreen(),
    );
  }
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final TextEditingController _pinController = TextEditingController();
  String _errorMessage = '';
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBioAvailable();
  }

  Future<void> _checkBioAvailable() async {
    try {
      bool canCheck = await auth.canCheckBiometrics;
      bool isSupported = await auth.isDeviceSupported();
      setState(() => _canCheckBiometrics = canCheck && isSupported);
    } catch (_) {
      setState(() => _canCheckBiometrics = false);
    }
  }

  Future<void> _authenticateBiometrics() async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'ضع بصمتك للدخول إلى النظام الذكي',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (authenticated && mounted) _navigateToDashboard();
    } catch (e) {
      setState(() => _errorMessage = 'تعذر التحقق من البصمة: $e');
    }
  }

  void _checkPin() {
    if (_pinController.text == "1234") {
      _navigateToDashboard();
    } else {
      setState(() => _errorMessage = 'رمز PIN غير صحيح (جرب 1234)');
    }
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AIDashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF090A0F), Color(0xFF181B26), Color(0xFF221A3A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.cyanAccent.withOpacity(0.1),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.psychology, size: 80, color: Colors.cyanAccent),
                ),
                const SizedBox(height: 24),
                const Text('AI SYSTEM OS', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 3.0, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('نظام الذكاء الاصطناعي الذاتي التطور', style: TextStyle(color: Colors.white60, fontSize: 14)),
                const SizedBox(height: 48),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, letterSpacing: 10, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '• • • •',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                  ),
                  onSubmitted: (_) => _checkPin(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _checkPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('دخول النظام', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 24),
                if (_canCheckBiometrics)
                  InkWell(
                    onTap: _authenticateBiometrics,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.cyanAccent)),
                      child: const Icon(Icons.fingerprint, size: 48, color: Colors.cyanAccent),
                    ),
                  ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AIDashboardScreen extends StatefulWidget {
  const AIDashboardScreen({super.key});
  @override
  State<AIDashboardScreen> createState() => _AIDashboardScreenState();
}

class _AIDashboardScreenState extends State<AIDashboardScreen> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  late AnimationController _pulseController;
  bool _isListening = false;
  bool _isProcessing = false;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  String _thinkingProcess = 'النظام في وضع الاستعداد...';
  String _aiResponse = 'أهلاً يا محمد. اضغط على أيقونة المفتاح فوق لإضافة مفتاح Gemini.';
  double _evolutionProgress = 0.53;
  String _savedApiKey = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _initAudioEngine();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _evolutionProgress = prefs.getDouble('evo') ?? 0.53;
      _savedApiKey = prefs.getString('gemini_api_key') ?? '';
    });
    _apiKeyController.text = _savedApiKey;
    if (_savedApiKey.isEmpty) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _showApiKeyDialog();
      });
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('evo', _evolutionProgress);
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key.trim());
    setState(() => _savedApiKey = key.trim());
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.key, color: Colors.cyanAccent), SizedBox(width: 8), Text('مفتاح Gemini API', style: TextStyle(fontSize: 16))]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('حط مفتاح Gemini هنا عشان الذكاء الحقيقي يشتغل:', style: TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                hintText: 'حط اي مفتاح هنا - AQ... او AIza...',
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text('aistudio.google.com/app/apikey', style: TextStyle(fontSize: 10, color: Colors.cyanAccent)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              _saveApiKey(_apiKeyController.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ المفتاح!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _initAudioEngine() async {
    await Permission.microphone.request();
    await _speech.initialize(onStatus: (s) {
      if (s == 'done' || s == 'notListening') setState(() => _isListening = false);
    });
    await _tts.setLanguage("ar-EG");
    await _tts.setSpeechRate(0.85);
  }

  void _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        await _speech.listen(
          localeId: "ar_EG",
          listenFor: const Duration(seconds: 30),
          onResult: (val) => setState(() => _textController.text = val.recognizedWords),
        );
      }
    } else {
      setState(() => _isListening = false);
      await _speech.stop();
      if (_textController.text.isNotEmpty) _processAICommand(_textController.text);
    }
  }

  Future<List<String>> _getAvailableModels() async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models?key=$_savedApiKey',
    );

    final res = await http.get(url);

    if (res.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(res.body);

    if (data["models"] == null) return [];

    List<String> allModels = [];
    for (final model in data["models"]) {
      final name = model["name"] as String;
      final methods =
          List<String>.from(model["supportedGenerationMethods"] ?? []);

      if (methods.contains("generateContent") &&
          (name.contains("flash") || name.contains("pro"))) {
        allModels.add(name.replaceFirst("models/", ""));
      }
    }

    // ترتيب الأفضلية: الجديد والمستقر أولاً
    List<String> preferredOrder = [
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
      'gemini-2.0-flash',
      'gemini-2.0-flash-lite',
      'gemini-1.5-pro',
      'gemini-1.5-flash',
    ];

    List<String> sorted = [];
    for (var p in preferredOrder) {
      if (allModels.contains(p)) sorted.add(p);
    }
    // ضيف الباقي
    for (var m in allModels) {
      if (!sorted.contains(m)) sorted.add(m);
    }

    return sorted;
  }

  Future<void> _processAICommand(String input) async {
    if (input.trim().isEmpty) return;
    setState(() {
      _isProcessing = true;
      _thinkingProcess = 'جاري التحليل...\n- المدخل: $input\n- جلب قائمة الموديلات (flash/pro)...';
      _aiResponse = 'لحظة...';
    });

    try {
      String responseText = '';
      bool isReal = false;
      String usedModel = '';
      http.Response? lastRes;

      if (_savedApiKey.trim().isNotEmpty) {
        final models = await _getAvailableModels();

        if (models.isEmpty) {
          throw Exception("لم يتم العثور على أي موديل يدعم generateContent.");
        }

        setState(() {
          _thinkingProcess = 'جاري التحليل...\n- الموديلات المتاحة: ${models.join(', ')}\n- بجرب واحد واحد...';
        });

        bool quotaHit = false;

        for (final model in models) {
          usedModel = model;
          final url = Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_savedApiKey');
          final body = jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": "انت مساعد ذكي عربي. رد بالعربي المصري باختصار ومفيد: $input"}
                ]
              }
            ]
          });

          final res = await http.post(
              url, headers: {"Content-Type": "application/json"}, body: body);
          lastRes = res;

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            // استخراج آمن
            responseText = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ??
                "لم يتم إرجاع أي رد.";
            isReal = true;
            break;
          }

          if (res.statusCode == 404 || res.statusCode == 400) {
            // الموديل مش مدعوم - جرب اللي بعده
            continue;
          }

          if (res.statusCode == 429) {
            quotaHit = true;
            break; // الكوتة خلصت، مفيش داعي نكمل
          }

          // أي خطأ تاني - اطلع
          break;
        }

        if (!isReal) {
          if (quotaHit) {
            responseText = '''
❌ الكوتة خلصت (429) - آخر موديل جربناه: $usedModel

الحل:
1️⃣ استنى دقيقة
2️⃣ اعمل مفتاح جديد من aistudio.google.com/app/apikey وحطه بدوسة 🔑
الموديلات اللي اتجربت: ${models.join(', ')}
''';
          } else if (lastRes != null) {
            String body = lastRes.body;
            if (body.length > 600) body = body.substring(0, 600);
            responseText = 'خطأ ${lastRes.statusCode} مع $usedModel: $body';
          }
        }
      } else {
        await Future.delayed(const Duration(seconds: 1));
        responseText =
            'تم تحليل: $input\n\n⚠️ ده رد تجريبي. دوس على 🔑 فوق وحط مفتاح Gemini';
      }

      setState(() {
        _thinkingProcess = isReal
            ? '✓ تم بنجاح ($usedModel)\n- تمت تجربة ${models.length} موديل ديناميكي'
            : '⚠️ فشل - آخر موديل: $usedModel';
        _aiResponse = responseText;
        if (isReal) _evolutionProgress = (_evolutionProgress + 0.02).clamp(0.0, 1.0);
        _isProcessing = false;
      });
      if (isReal) _saveProgress();
      await _tts.speak(_aiResponse.length > 250
          ? _aiResponse.substring(0, 250)
          : _aiResponse);
    } catch (e) {
      setState(() {
        _thinkingProcess = 'خطأ: $e';
        _aiResponse = 'تعذر الاتصال: $e';
        _isProcessing = false;
      });
    }
  }


  @override
  void dispose() {
    _pulseController.dispose();
    _tts.stop();
    _textController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool hasKey = _savedApiKey.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('عقل النظام (Core Engine)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black.withOpacity(0.4),
        actions: [
          IconButton(
            icon: Icon(Icons.vpn_key, color: hasKey ? Colors.greenAccent : Colors.amber),
            onPressed: _showApiKeyDialog,
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline),
            onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LockScreen())),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF090A0F), Color(0xFF10121E)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(children: [Icon(Icons.auto_graph, size: 16, color: Colors.white70), SizedBox(width: 6), Text('مستوى التطور', style: TextStyle(color: Colors.white70, fontSize: 12))]),
                        Text('${(_evolutionProgress * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(value: _evolutionProgress, minHeight: 8, backgroundColor: Colors.white12, color: Colors.cyanAccent),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(hasKey ? Icons.check_circle : Icons.warning, size: 12, color: hasKey ? Colors.greenAccent : Colors.amber),
                        const SizedBox(width: 4),
                        Text(hasKey ? 'المفتاح موجود - ذكاء حقيقي' : 'لا يوجد مفتاح - دوس 🔑 فوق', style: TextStyle(fontSize: 10, color: hasKey ? Colors.greenAccent : Colors.amber)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.4))),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [Icon(Icons.memory, color: Colors.deepPurpleAccent, size: 18), SizedBox(width: 8), Text('مسار التفكير:', style: TextStyle(fontSize: 13, color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold))]),
                        const Divider(color: Colors.white12),
                        Text(_thinkingProcess, style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [Icon(Icons.forum_outlined, color: Colors.cyanAccent, size: 18), SizedBox(width: 8), Text('الرد الناطق:', style: TextStyle(fontSize: 13, color: Colors.cyanAccent, fontWeight: FontWeight.bold))]),
                        const Divider(color: Colors.white12),
                        Text(_aiResponse, style: const TextStyle(fontSize: 15, height: 1.6)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: (val) => _processAICommand(val),
                      decoration: InputDecoration(
                        hintText: _isListening ? 'بسمعك...' : 'اكتب أمراً...',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            if (_textController.text.isNotEmpty && !_isListening) {
                              _processAICommand(_textController.text);
                            } else {
                              _toggleListening();
                            }
                          },
                    backgroundColor: _isListening ? Colors.redAccent : Colors.deepPurpleAccent,
                    child: Icon(_isListening ? Icons.mic : (_textController.text.isNotEmpty ? Icons.send : Icons.mic_none)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
