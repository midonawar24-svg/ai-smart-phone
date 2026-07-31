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

// ===================== 1. شاشة القفل =====================
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
    } catch (e) {
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
      setState(() => _errorMessage = 'تعذر التحقق من البصمة: ${e.toString()}');
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
                    hintStyle: const TextStyle(letterSpacing: 4),
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
                      elevation: 8,
                    ),
                    child: const Text('دخول النظام', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 32),
                if (_canCheckBiometrics)
                  Column(
                    children: [
                      const Text('أو', style: TextStyle(color: Colors.white30)),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _authenticateBiometrics,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.cyanAccent)),
                          child: const Icon(Icons.fingerprint, size: 48, color: Colors.cyanAccent),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                if (_errorMessage.isNotEmpty)
                  Text(_errorMessage, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== 2. شاشة الذكاء =====================
class AIDashboardScreen extends StatefulWidget {
  const AIDashboardScreen({super.key});
  @override
  State<AIDashboardScreen> createState() => _AIDashboardScreenState();
}

class _AIDashboardScreenState extends State<AIDashboardScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isListening = false;
  bool _isProcessing = false;
  String _thinkingProcess = 'بانتظار أمرك...';
  String _aiResponse = 'مرحباً يا ميدو، أنا نظامك الذكي. اضغط على الإعدادات فوق لوضع مفتاح Gemini.';
  double _evolutionProgress = 0.53;
  String _savedApiKey = "";

  // مفتاح احتياطي ممكن تحطه في الكود
  final String _hardcodedApiKey = "";

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _initAudioEngine();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _evolutionProgress = prefs.getDouble('evo') ?? 0.53;
      _savedApiKey = prefs.getString('gemini_api_key') ?? "";
    });
    if (_savedApiKey.isNotEmpty) {
      _apiKeyController.text = _savedApiKey;
    }
    // لو مفيش مفتاح خالص افتح له النافذة تلقائي بعد ثانية
    if (_savedApiKey.isEmpty && _hardcodedApiKey.isEmpty) {
      Future.delayed(const Duration(milliseconds: 800), () {
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
    _apiKeyController.text = _savedApiKey;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.key, color: Colors.cyanAccent),
            SizedBox(width: 8),
            Text('مفتاح Gemini API', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ضع مفتاح Gemini هنا عشان الذكاء يشتغل حقيقي، مش تجريبي:', style: TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.vpn_key),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            const Text('هاته من: aistudio.google.com/app/apikey', style: TextStyle(fontSize: 10, color: Colors.cyanAccent)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('المفتاح بيتخزن على جهازك بس، مش بيروح لحد.', style: TextStyle(fontSize: 10, color: Colors.amber)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              _saveApiKey(_apiKeyController.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_apiKeyController.text.trim().isEmpty ? 'تم مسح المفتاح - الوضع التجريبي شغال' : 'تم حفظ المفتاح بنجاح! جرب تسأل سؤال')),
              );
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
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.85);
    await _tts.setVolume(1.0);
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

  Future<void> _processAICommand(String input) async {
    if (input.trim().isEmpty) return;
    setState(() {
      _isProcessing = true;
      _thinkingProcess = '🧠 جاري التحليل...\n- المدخل: "$input"\n- فحص المفتاح...\n- الاتصال بـ Gemini...';
      _aiResponse = 'لحظة...';
    });

    try {
      String activeKey = _savedApiKey.isNotEmpty ? _savedApiKey : _hardcodedApiKey;
      String responseText = "";
      bool isRealAI = false;

      if (activeKey.isNotEmpty && activeKey.startsWith("AIza")) {
        final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$activeKey");
        final body = jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": "انت مساعد ذكي عربي اسمه AI SYSTEM OS، بترد بالعربي المصري بشكل ذكي ومختصر ومفيد. المستخدم بيقول: $input"}
              ]
            }
          ]
        });
        final res = await http.post(url, headers: {"Content-Type": "application/json"}, body: body);
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          responseText = data['candidates'][0]['content']['parts'][0]['text'];
          isRealAI = true;
        } else {
          responseText = "خطأ من Gemini (${res.statusCode}):\n${res.body.substring(0, res.body.length > 400 ? 400 : res.body.length)}\n\nتأكد ان المفتاح صحيح.";
        }
      } else {
        await Future.delayed(const Duration(seconds: 1));
        responseText = "تم تحليل أمرك: '$input'.\n\n⚠️ ده رد تجريبي لأنك لسه محطيتش مفتاح Gemini.\n\nدوس على أيقونة المفتاح 🔑 فوق عشان تحط المفتاح، وهاته من:\naistudio.google.com/app/apikey\n\nبعد ما تحطه، النظام هيرد بذكاء حقيقي ويطور نفسه +2% كل مرة.";
      }

      setState(() {
        _thinkingProcess = isRealAI
            ? '✓ تم التحليل بنجاح (ذكاء حقيقي)\n- المفتاح: موجود وفعال\n- الاتصال: Gemini 1.5 Flash\n- الذاكرة: تم التحديث\n- النطق: جاري'
            : '✓ تم التحليل بنجاح (وضع تجريبي)\n- المفتاح: غير موجود\n- الذاكرة: تم التحديث\n- النمط المعرفي: مُثبّت\n- الاستجابة: جاهزة';
        _aiResponse = responseText;
        _evolutionProgress = (_evolutionProgress + 0.02).clamp(0.0, 1.0);
        _isProcessing = false;
      });
      _saveProgress();
      await _tts.speak(_aiResponse);
    } catch (e) {
      setState(() {
        _thinkingProcess = '✗ خطأ: $e';
        _aiResponse = 'تعذر الاتصال. تأكد من النت والمفتاح. دوس على 🔑 فوق.';
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
    bool hasKey = _savedApiKey.isNotEmpty || _hardcodedApiKey.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('عقل النظام (Core Engine)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black.withOpacity(0.4),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.vpn_key, color: hasKey ? Colors.greenAccent : Colors.amber),
            tooltip: 'مفتاح Gemini',
            onPressed: _showApiKeyDialog,
          ),
          IconButton(icon: const Icon(Icons.lock_outline), onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LockScreen())))
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
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.cyanAccent.withOpacity(0.2))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Row(children: [Icon(Icons.auto_graph, size: 16, color: Colors.white70), SizedBox(width: 6), Text('مستوى التطور التراكمي', style: TextStyle(color: Colors.white70, fontSize: 12))]),
                      Text('${(_evolutionProgress * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 10),
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: _evolutionProgress, minHeight: 8, backgroundColor: Colors.white12, color: Colors.cyanAccent)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(hasKey ? Icons.check_circle : Icons.warning, size: 12, color: hasKey ? Colors.greenAccent : Colors.amber),
                        const SizedBox(width: 4),
                        Text(hasKey ? 'المفتاح: موجود - الذكاء الحقيقي شغال' : 'المفتاح: مش موجود - وضع تجريبي - دوس 🔑 فوق',
                            style: TextStyle(fontSize: 10, color: hasKey ? Colors.greenAccent : Colors.amber)),
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
                  child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [Icon(Icons.memory, color: Colors.deepPurpleAccent, size: 18), SizedBox(width: 8), Text('مسار التفكير الداخلي:', style: TextStyle(fontSize: 13, color: Colors.deepPurpleAccent, fontWeight: FontWeight.bold))]),
                    const Divider(color: Colors.white12),
                    Text(_thinkingProcess, style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 12, height: 1.5)),
                  ])),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                  child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [Icon(Icons.forum_outlined, color: Colors.cyanAccent, size: 18), SizedBox(width: 8), Text('الرد الناطق:', style: TextStyle(fontSize: 13, color: Colors.cyanAccent, fontWeight: FontWeight.bold))]),
                    const Divider(color: Colors.white12),
                    Text(_aiResponse, style: const TextStyle(fontSize: 15, height: 1.6)),
                  ])),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(
                  controller: _textController,
                  onSubmitted: (val) => _processAICommand(val),
            
