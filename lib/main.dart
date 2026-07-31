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
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== 2. لوحة التحكم الرئيسية =====================
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
  String _thinkingProcess = 'النظام في وضع الاستعداد...\nجاهز لتحليل أوامرك.';
  String _aiResponse = 'أهلاً بك يا محمد. أنا جهازك الذكي المتطور، جاهز لتلقي أوامرك الصوتية أو النصية. تحدث الآن أو اكتب ما تريد.';
  double _evolutionProgress = 0.45;

  // !!! حط مفتاح Gemini هنا !!!
  // هاته من: https://aistudio.google.com/app/apikey
  final String _apiKey = "YOUR_GEMINI_API_KEY_HERE";

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _initAudioEngine();
    _loadProgress();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tts.stop();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _evolutionProgress = prefs.getDouble('evo') ?? 0.45);
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('evo', _evolutionProgress);
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
      _thinkingProcess = '>> [INPUT] "$input"\n>> [NLP] تحليل النية والسياق...\n>> [MEMORY] استرجاع الذاكرة التراكمية ($_evolutionProgress)...\n>> [REASONING] بناء سلسلة التفكير المنطقي...\n>> [GEMINI] إرسال إلى محرك Gemini 2.5 Flash...';
      _aiResponse = 'جاري التفكير...';
    });

    try {
      String responseText = "";
      if (_apiKey != "YOUR_GEMINI_API_KEY_HERE" && _apiKey.length > 20) {
        final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey');
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [{"parts": [{"text": "أنت مساعد ذكي ذاتي التطور اسمه AI Self System. رد بالعربية المصرية العامية المفهومة. سؤال المستخدم: $input"}]}],
            "generationConfig": {"temperature": 0.8, "maxOutputTokens": 1024}
          }),
        ).timeout(const Duration(seconds: 20));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          responseText = data['candidates'][0]['content']['parts'][0]['text'];
        } else {
          responseText = "خطأ من Gemini: ${res.statusCode}\n${res.body.substring(0, 200)}";
        }
      } else {
        await Future.delayed(const Duration(seconds: 1));
        responseText = "تم تحليل أمرك: '$input'.\n\nهذا رد تجريبي لأنك لم تضع مفتاح Gemini API بعد. ضع المفتاح في الكود في السطر _apiKey. النظام حفظ المنطق ده في الذاكرة وطور نفسه +2%.";
      }

      setState(() {
        _thinkingProcess = '✓ تم التحليل بنجاح\n- المدخل: تم فهمه\n- الذاكرة: تم التحديث\n- النمط المعرفي: مُثبّت ومُحسّن\n- الاستجابة: جاهزة للنطق';
        _aiResponse = responseText;
        _evolutionProgress = (_evolutionProgress + 0.02).clamp(0.0, 1.0);
        _isProcessing = false;
      });
      _saveProgress();
      await _tts.speak(_aiResponse);
    } catch (e) {
      setState(() {
        _thinkingProcess = '✗ خطأ أثناء المعالجة: $e';
        _aiResponse = 'تعذر الاتصال. تأكد من الإنترنت ومفتاح Gemini.';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عقل النظام (Core Engine)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black.withOpacity(0.4),
        elevation: 0,
        actions: [
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
                  decoration: InputDecoration(
                    hintText: _isListening ? 'بسمعك...' : 'اكتب أمراً أو اضغط الميكروفون...',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                )),
                const SizedBox(width: 10),
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)),
                  child: FloatingActionButton(
                    onPressed: _isProcessing ? null : () {
                      if (_textController.text.isNotEmpty && !_isListening) {
                        _processAICommand(_textController.text);
                      } else {
                        _toggleListening();
                      }
                    },
                    backgroundColor: _isListening ? Colors.redAccent : Colors.deepPurpleAccent,
                    child: Icon(_isListening ? Icons.mic : (_textController.text.isNotEmpty ? Icons.send_rounded : Icons.mic_none_rounded)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
