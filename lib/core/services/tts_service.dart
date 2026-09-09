import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> speakEnglish(String text) async {
    await _flutterTts.stop();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.speak(text);
  }

  Future<void> speakSpanish(String text) async {
    await _flutterTts.stop();
    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.speak(text);
  }

  Future<void> speakEnglishSlow(String text) async {
  await _flutterTts.stop();
  await _flutterTts.setLanguage('en-US');
  await _flutterTts.setSpeechRate(0.20);
  await _flutterTts.speak(text);
}

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}