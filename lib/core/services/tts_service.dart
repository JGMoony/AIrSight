import 'package:flutter_tts/flutter_tts.dart';

/// Servicio de síntesis de voz (TTS) optimizado para accesibilidad (WCAG 2.2 AA).
/// Maneja pronunciación bilingüe fluida esperando la finalización real del audio
/// en lugar de retardos fijos, evitando solapamientos y cortes abruptos.
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isConfigured = false;
  int _currentSpeechSession = 0;

  TtsService() {
    _configureTts();
  }

  void _configureTts() {
    if (_isConfigured) return;
    _flutterTts.awaitSpeakCompletion(true);
    _isConfigured = true;
  }

  Future<void> speakEnglish(String text) async {
    _currentSpeechSession++;
    await _flutterTts.stop();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.speak(text);
  }

  Future<void> speakSpanish(String text) async {
    _currentSpeechSession++;
    await _flutterTts.stop();
    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.speak(text);
  }

  Future<void> speakEnglishSlow(String text) async {
    _currentSpeechSession++;
    await _flutterTts.stop();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.20);
    await _flutterTts.speak(text);
  }

  /// Reproduce un texto en inglés, aguarda su finalización real con awaitSpeakCompletion,
  /// aplica una pausa deliberada para separación cognitiva (~300ms) y reproduce
  /// la traducción/explicación en español sin colisión.
  Future<void> speakBilingual({
    required String textEn,
    required String textEs,
    Duration pause = const Duration(milliseconds: 300),
  }) async {
    final session = ++_currentSpeechSession;
    await _flutterTts.stop();

    if (session != _currentSpeechSession) return;

    // Paso 1: Audio en inglés
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.speak(textEn);

    if (session != _currentSpeechSession) return;

    // Paso 2: Pausa para procesamiento cognitivo
    await Future.delayed(pause);

    if (session != _currentSpeechSession) return;

    // Paso 3: Audio en español
    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.speak(textEs);
  }

  Future<void> stop() async {
    _currentSpeechSession++;
    await _flutterTts.stop();
  }
}