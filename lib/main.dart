import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MaterialApp(home: AISmartPhone(), debugShowCheckedModeBanner: false));

class AISmartPhone extends StatefulWidget { @override State<AISmartPhone> createState() => _AISmartPhoneState(); }

class _AISmartPhoneState extends State<AISmartPhone> {
  final _textController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _tts = FlutterTts();
  final _speech = SpeechToText();
  String _thinkingProcess = 'جاهز...'; String _aiResponse = 'اسألني اي حاجة'; bool _isProcessing = false; bool _isListening = false;
  String _savedApiKey = ''; double _evolutionProgress = 0.63;

  @override void initState() { super.initState(); _loadKey(); _initAudio(); }
  void _loadKey() async { final p = await SharedPreferences.getInstance(); setState(() { _savedApiKey = p.getString('api_key') ?? ''; }); }
  void _saveKey() async { final p = await SharedPreferences.getInstance(); await p.setString('api_key', _apiKeyController.text.trim()); setState(() { _savedApiKey = _apiKeyController.text.trim(); }); Navigator.pop(context); }
  void _initAudio() async { await Permission.microphone.request(); await _speech.initialize(); await _tts.setLanguage("ar-EG"); await _tts.setSpeechRate(0.85); }
  void _toggleListening() async { if (_isListening) { setState(() => _isListening = false); _speech.stop(); if (_textController.text.isNotEmpty) _processAICommand(_textController.text); } else { bool av = await _speech.initialize(); if (av) { setState(() => _isListening = true); _speech.listen(localeId: "ar-EG", listenFor: Duration(seconds: 30), onResult: (val) => setState(() => _textController.text = val.recognizedWords)); } } }
  Future<void> _processAICommand(String input) async {
    if (input.trim().isEmpty) return;
    setState(() { _isProcessing = true; _thinkingProcess = 'جاري التحليل...\n$input'; _aiResponse = 'لحظة...'; });
    try {
      String responseText = ''; bool isReal = false;
      if (_savedApiKey.trim().isNotEmpty) {
        final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_savedApiKey');
        final body = jsonEncode({"contents": [{"parts": [{"text": "انت مساعد ذكي عربي مصري. رد باختصار: $input"}]}]});
        final res = await http.post(url, headers: {"Content-Type": "application/json"}, body: body);
        if (res.statusCode == 200) { final data = jsonDecode(res.body); responseText = data['candidates'][0]['content']['parts'][0]['text']; isReal = true; }
        else { responseText = 'خطأ ${res.statusCode}: ${res.body.substring(0, 200)}'; }
      } else { await Future.delayed(Duration(seconds: 1)); responseText = 'حط مفتاح Gemini من aistudio.google.com/app/apikey - دوس 🔑 فوق'; }
      setState(() { _thinkingProcess = isReal ? '✓ Gemini 2.0 Flash شغال' : 'تجريبي'; _aiResponse = responseText; _evolutionProgress = (_evolutionProgress + 0.02).clamp(0,1); _isProcessing = false; });
      _tts.speak(_aiResponse);
    } catch (e) { setState(() { _thinkingProcess = 'خطأ: $e'; _aiResponse = 'تعذر الاتصال'; _isProcessing = false; }); }
  }
  @override Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Color(0xFF0a0a0a), appBar: AppBar(backgroundColor: Colors.black, title: Text('عقل النظام (Core Engine)', style: TextStyle(color: Colors.white)), actions: [IconButton(icon: Icon(Icons.key, color: Colors.cyan), onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(title: Text('مفتاح Gemini'), content: TextField(controller: _apiKeyController, decoration: InputDecoration(hintText: 'الصق المفتاح هنا AQ. او AIza')), actions: [TextButton(onPressed: _saveKey, child: Text('حفظ'))]))), IconButton(icon: Icon(Icons.lock, color: Colors.white), onPressed: () {})]),
      body: Padding(padding: EdgeInsets.all(16), child: Column(children: [
        Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.cyan.withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('مستوى التطور', style: TextStyle(color: Colors.white70)), Text('${(_evolutionProgress*100).toStringAsFixed(1)}%', style: TextStyle(color: Colors.cyan))]), SizedBox(height: 8), LinearProgressIndicator(value: _evolutionProgress, backgroundColor: Colors.white10, color: Colors.cyan), SizedBox(height: 8), Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 16), SizedBox(width: 4), Text(_savedApiKey.isNotEmpty ? 'المفتاح موجود - ذكاء حقيقي' : 'حط المفتاح', style: TextStyle(color: Colors.greenAccent, fontSize: 12))])])),
        SizedBox(height: 16), Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.purple.withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('مسار التفكير:', style: TextStyle(color: Colors.purpleAccent)), Divider(color: Colors.white10), Text(_thinkingProcess, style: TextStyle(color: Colors.greenAccent, fontSize: 12))])), 
        SizedBox(height: 16), Expanded(child: Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('الرد الناطق:', style: TextStyle(color: Colors.cyan)), Divider(color: Colors.white10), Text(_aiResponse, style: TextStyle(color: Colors.white))])))),
        SizedBox(height: 16), Row(children: [Expanded(child: TextField(controller: _textController, decoration: InputDecoration(hintText: 'انت بتعمل ايه هاي', hintStyle: TextStyle(color: Colors.white54), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)))), SizedBox(width: 8), FloatingActionButton(onPressed: _toggleListening, backgroundColor: _isListening ? Colors.red : Colors.purple, child: Icon(_isListening ? Icons.stop : Icons.mic)), SizedBox(width: 8), FloatingActionButton(onPressed: () => _processAICommand(_textController.text), backgroundColor: Colors.purple, child: Icon(Icons.send))])
      ])),
    );
  }
}
