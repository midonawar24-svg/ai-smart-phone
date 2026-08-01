
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

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

String _hashPin(String pin) {
  return sha256.convert(utf8.encode(pin)).toString();
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final TextEditingController _pinController = TextEditingController();
  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  String _errorMessage = '';
  bool _canCheckBiometrics = false;
  String _savedPinHash = '';

  @override
  void initState() {
    super.initState();
    _checkBioAvailable();
    _loadPin();
  }

  Future<void> _loadPin() async {
    String? hash = await _secure.read(key: 'user_pin_hash');
    if (hash == null) {
      final prefs = await SharedPreferences.getInstance();
      final oldPin = prefs.getString('user_pin');
      if (oldPin != null) {
        hash = _hashPin(oldPin);
      } else {
        hash = _hashPin('1234');
      }
      await _secure.write(key: 'user_pin_hash', value: hash);
      await prefs.remove('user_pin');
      await _secure.delete(key: 'user_pin');
    }
    if (!mounted) return;
    setState(() => _savedPinHash = hash!);
  }

  Future<void> _checkBioAvailable() async {
    try {
      bool canCheck = await auth.canCheckBiometrics;
      bool isSupported = await auth.isDeviceSupported();
      if (!mounted) return;
      setState(() => _canCheckBiometrics = canCheck && isSupported);
    } catch (_) {
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() => _errorMessage = 'تعذر التحقق من البصمة: $e');
    }
  }

  void _checkPin() {
    if (_hashPin(_pinController.text) == _savedPinHash) {
      _navigateToDashboard();
    } else {
      setState(() => _errorMessage = 'رمز PIN غير صحيح');
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
                    child: const Icon(Icons.psychology, size: 80, color: Colors.cyanAccent)),
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
                    onSubmitted: (_) => _checkPin()),
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
                    )),
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
  late AnimationController _pulseController;
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final http.Client _httpClient = http.Client();
  bool _isListening = false;
  bool _isProcessing = false;
  bool _speechInitialized = false;
  String _thinkingProcess = 'النظام جاهز...';
  String _aiResponse = 'أهلاً! أنا جاهز لمساعدتك.';
  double _evolutionProgress = 0.53;
  String _savedApiKey = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _loadData();
    _initAudioEngine();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String? key = await _secureStorage.read(key: 'gemini_api_key');
    key ??= prefs.getString('gemini_api_key') ?? '';
    if (key.isNotEmpty) {
      await _secureStorage.write(key: 'gemini_api_key', value: key);
      await prefs.remove('gemini_api_key');
    }
    if (!mounted) return;
    setState(() {
      _evolutionProgress = prefs.getDouble('evo') ?? 0.53;
      _savedApiKey = key!;
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
    await _secureStorage.write(key: 'gemini_api_key', value: key.trim());
    if (!mounted) return;
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
            const Text('حط مفتاح Gemini هنا (يتخزن بشكل آمن):', style: TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                hintText: 'AIza...',
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
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ المفتاح بشكل آمن!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _initAudioEngine() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return;
    }
    if (!_speechInitialized) {
      _speechInitialized = await _speech.initialize(onStatus: (s) {
        if (!mounted) return;
        if (s == 'done' || s == 'notListening') setState(() => _isListening = false);
      });
    }
    await _tts.setLanguage("ar-EG");
    await _tts.setSpeechRate(0.85);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> _toggleListening() async {
    if (_isProcessing) return;
    if (!_isListening) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (!mounted) return;
        setState(() => _thinkingProcess = '⚠️ إذن الميكروفون مرفوض. فعّله من الإعدادات.');
        return;
      }
      if (!_speechInitialized) {
        _speechInitialized = await _speech.initialize();
      }
      if (_speechInitialized) {
        if (!mounted) return;
        setState(() => _isListening = true);
        await _speech.listen(
          localeId: "ar_EG",
          listenFor: const Duration(seconds: 30),
          onResult: (val) {
            if (!mounted) return;
            setState(() => _textController.text = val.recognizedWords);
          },
        );
      }
    } else {
      if (!mounted) return;
      setState(() => _isListening = false);
      await _speech.stop();
      if (_textController.text.isNotEmpty) _processAICommand(_textController.text);
    }
  }

  Future<List<String>> _getAvailableModels() async {
    if (_savedApiKey.trim().isEmpty) {
      throw Exception("يرجى إدخال مفتاح Gemini API.");
    }
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$_savedApiKey');
    http.Response res;
    try {
      res = await _httpClient.get(url).timeout(const Duration(seconds: 30));
    } on TimeoutException {
      // إعادة محاولة تلقائية مرة واحدة
      try {
        res = await _httpClient.get(url).timeout(const Duration(seconds: 30));
      } on TimeoutException {
        throw Exception("انتهت مهلة الاتصال (Timeout) أثناء جلب الموديلات.");
      }
    } catch (e) {
      throw Exception("فشل الاتصال: $e");
    }

    if (res.statusCode == 401) throw Exception("401 Unauthorized: المفتاح غير صحيح.");
    if (res.statusCode == 403) throw Exception("403 Forbidden: المفتاح محظور.");
    if (res.statusCode == 429) throw Exception("429 Quota: الكوتة خلصت.");
    if (res.statusCode != 200) {
      throw Exception("خطأ ${res.statusCode}: ${res.body.substring(0, res.body.length > 300 ? 300 : res.body.length)}");
    }

    final data = jsonDecode(res.body);
    if (data["models"] == null) return [];
    List<String> allModels = [];
    for (final model in data["models"]) {
      final methods = List<String>.from(model["supportedGenerationMethods"] ?? []);
      if (methods.contains("generateContent")) {
        allModels.add((model["name"] as String).replaceFirst("models/", ""));
      }
    }
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
    for (var m in allModels) {
      if (!sorted.contains(m)) sorted.add(m);
    }
    return sorted;
  }

  Future<void> _processAICommand(String input) async {
    if (input.trim().isEmpty || _isProcessing) return;
    if (_savedApiKey.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _thinkingProcess = 'تنبيه: لا يوجد مفتاح';
        _aiResponse = 'يرجى إدخال مفتاح Gemini API. دوس على 🔑 فوق.';
        _isProcessing = false;
      });
      _showApiKeyDialog();
      return;
    }
    if (!mounted) return;
    setState(() {
      _isProcessing = true;
      _thinkingProcess = 'جاري التحليل...\n- المدخل: $input\n- جلب الموديلات...';
      _aiResponse = 'لحظة...';
    });

    List<String> models = [];
    bool quotaHit = false;
    String? lastErrorBody;
    String usedModel = '';
    http.Response? lastRes;
    String responseText = '';
    bool isReal = false;

    try {
      models = await _getAvailableModels();
      if (!mounted) return;
      if (models.isEmpty) throw Exception("لم يتم العثور على أي موديل يدعم generateContent.");
      if (!mounted) return;
      setState(() {
        _thinkingProcess = 'جاري التحليل...\n- الموديلات: ${models.join(', ')}\n- بجرب...';
      });

      for (final model in models) {
        usedModel = model;
        final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_savedApiKey');
        final body = jsonEncode({
          "contents": [
            {"parts": [{"text": "انت مساعد ذكي عربي. رد بالعربي المصري باختصار ومفيد: $input"}]}
          ]
        });
        http.Response res;
        try {
          res = await _httpClient.post(url, headers: {"Content-Type": "application/json"}, body: body).timeout(const Duration(seconds: 30));
        } on TimeoutException {
          lastErrorBody = "Timeout 30s مع $model - إعادة محاولة...";
          // إعادة محاولة تلقائية
          try {
            res = await _httpClient.post(url, headers: {"Content-Type": "application/json"}, body: body).timeout(const Duration(seconds: 30));
          } on TimeoutException {
            lastErrorBody = "Timeout ثانية مرة مع $model";
            continue;
          }
        } catch (e) {
          lastErrorBody = "خطأ اتصال $model: $e";
          continue;
        }
        lastRes = res;
        lastErrorBody = res.body;
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data["candidates"] == null || (data["candidates"] as List).isEmpty) {
            final blockReason = data["promptFeedback"]?["blockReason"] ?? "غير معروف";
            responseText = "لم يتمكن Gemini من إنشاء رد. السبب: $blockReason (Safety Block).";
            isReal = false;
            break;
          }
          responseText = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "لم يتم إرجاع أي رد.";
          isReal = true;
          break;
        }
        if (res.statusCode == 404 || res.statusCode == 400) continue;
        if (res.statusCode == 429) {
          quotaHit = true;
          break;
        }
        if (res.statusCode == 401 || res.statusCode == 403) {
          responseText = 'خطأ ${res.statusCode}: تحقق من المفتاح.';
          break;
        }
        break;
      }

      if (!mounted) return;
      if (!isReal && responseText.isEmpty) {
        if (quotaHit) {
          responseText = '❌ الكوتة خلصت (429) - $usedModel\nانتظر دقيقة أو استخدم مفتاح جديد.';
        } else if (lastRes != null) {
          String body = lastErrorBody ?? '';
          if (body.length > 600) body = body.substring(0, 600);
          responseText = 'خطأ ${lastRes.statusCode} مع $usedModel: $body';
        }
      }
      if (!mounted) return;
      setState(() {
        _thinkingProcess = isReal ? '✓ تم بنجاح ($usedModel)' : '⚠️ فشل - $usedModel';
        _aiResponse = responseText;
        if (isReal) _evolutionProgress = (_evolutionProgress + 0.02).clamp(0.0, 1.0);
        _isProcessing = false;
      });
      if (isReal) _saveProgress();
      await _tts.stop();
      await _tts.speak(_aiResponse.length > 250 ? _aiResponse.substring(0, 250) : _aiResponse);
    } catch (e) {
      if (!mounted) return;
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
    _speech.stop();
    _httpClient.close();
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
            onPressed: _isProcessing ? null : _showApiKeyDialog,
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
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.2))),
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
                        Text(hasKey ? 'المفتاح موجود - آمن' : 'لا يوجد مفتاح - دوس 🔑', style: TextStyle(fontSize: 10, color: hasKey ? Colors.greenAccent : Colors.amber)),
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
                      enabled: !_isProcessing,
                      onSubmitted: (val) => _processAICommand(val),
                      decoration: InputDecoration(
                        hintText: _isListening ? 'بسمعك...' : (_isProcessing ? 'جاري المعالجة...' : 'اكتب أمراً...'),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: _isProcessing ? null : () {
                      if (_textController.text.isNotEmpty && !_isListening) {
                        _processAICommand(_textController.text);
                      } else {
                        _toggleListening();
                      }
                    },
                    backgroundColor: _isProcessing ? Colors.grey : (_isListening ? Colors.redAccent : Colors.deepPurpleAccent),
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
