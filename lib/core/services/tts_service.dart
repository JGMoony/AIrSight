import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Servicio de síntesis de voz (TTS) optimizado para accesibilidad (WCAG 2.2 AA).
/// Implementa un patrón Singleton para persistir la locución entre navegaciones y transiciones de vistas.
/// Maneja pronunciación bilingüe fluida esperando la finalización real del audio
/// en lugar de retardos fijos, evitando solapamientos y cortes abruptos.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  static TtsService get instance => _instance;

  final FlutterTts _flutterTts = FlutterTts();
  bool _isConfigured = false;
  int _currentSpeechSession = 0;

  /// Velocidad estándar pedagógica para palabras individuales (inglés y español).
  static const double defaultSpeechRate = 0.45;

  /// Velocidad lenta para refuerzo de articulación y fonética.
  static const double slowSpeechRate = 0.20;

  /// Velocidad moderada pedagógica para oraciones y ejemplos bilingües
  /// (aproximadamente un 10-15% más pausada para favorecer la asimilación auditiva).
  static const double bilingualExampleSpeechRate = 0.42;

  TtsService._internal() {
    _ensureConfigured();
  }

  Future<void> _ensureConfigured() async {
    if (_isConfigured) return;
    try {
      await _flutterTts.awaitSpeakCompletion(true);
      _isConfigured = true;
    } catch (_) {}
  }

  Future<void> speakEnglish(String text) async {
    _currentSpeechSession++;
    await _ensureConfigured();
    await _flutterTts.stop();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(defaultSpeechRate);
    await _flutterTts.speak(text);
  }

  Future<void> speakSpanish(String text) async {
    _currentSpeechSession++;
    debugPrint('[TtsService] speakSpanish: "$text"');
    await _ensureConfigured();
    await _flutterTts.stop();
    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(defaultSpeechRate);
    await _flutterTts.speak(text);
  }

  Future<void> speakEnglishSlow(String text) async {
    _currentSpeechSession++;
    await _ensureConfigured();
    await _flutterTts.stop();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(slowSpeechRate);
    await _flutterTts.speak(text);
  }

  /// Reproduce un texto en inglés y español a una velocidad moderada pedagógica (0.42),
  /// aguarda su finalización real con awaitSpeakCompletion, aplica una pausa
  /// deliberada para procesamiento cognitivo (~300ms) y restaura la velocidad estándar (0.45).
  Future<void> speakBilingual({
    required String textEn,
    required String textEs,
    Duration pause = const Duration(milliseconds: 300),
    double exampleRate = bilingualExampleSpeechRate,
  }) async {
    final session = ++_currentSpeechSession;
    await _ensureConfigured();
    await _flutterTts.stop();

    if (session != _currentSpeechSession) return;

    try {
      // Paso 1: Audio de la oración en inglés a velocidad moderada pedagógica
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(exampleRate);
      await _flutterTts.speak(textEn);

      if (session != _currentSpeechSession) return;

      // Paso 2: Pausa de cortesía para procesamiento cognitivo (~300ms)
      await Future.delayed(pause);

      if (session != _currentSpeechSession) return;

      // Paso 3: Audio de la traducción contextual en español a velocidad moderada pedagógica
      await _flutterTts.setLanguage('es-ES');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(exampleRate);
      await _flutterTts.speak(textEs);
    } finally {
      // Restauración garantizada de la tasa de velocidad original configurada para palabras aisladas
      if (session == _currentSpeechSession) {
        await _flutterTts.setSpeechRate(defaultSpeechRate);
      }
    }
  }

  /// Reproduce la respuesta del asistente de voz alternando idiomas pedagógicamente:
  /// 1. Explicación en español (es-ES)
  /// 2. Pausa cognitiva (~350ms)
  /// 3. Frase o ejemplo en inglés con acento en-US
  /// 4. Pausa cognitiva (~300ms)
  /// 5. Traducción de la frase en español (es-ES)
  Future<void> speakVoiceAssistantResponse({
    required String explanationEs,
    required String exampleEn,
    required String exampleEs,
    Duration pause = const Duration(milliseconds: 350),
    double exampleRate = bilingualExampleSpeechRate,
  }) async {
    final session = ++_currentSpeechSession;
    await _ensureConfigured();
    await _flutterTts.stop();

    if (session != _currentSpeechSession) return;

    try {
      // 1. Explicación en español
      if (explanationEs.trim().isNotEmpty) {
        await _flutterTts.setLanguage('es-ES');
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setSpeechRate(defaultSpeechRate);
        await _flutterTts.speak(explanationEs.trim());
      }

      if (session != _currentSpeechSession) return;
      await Future.delayed(pause);
      if (session != _currentSpeechSession) return;

      // 2. Frase de ejemplo en inglés (en-US)
      if (exampleEn.trim().isNotEmpty) {
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setSpeechRate(exampleRate);
        await _flutterTts.speak(exampleEn.trim());
      }

      if (session != _currentSpeechSession) return;
      await Future.delayed(pause);
      if (session != _currentSpeechSession) return;

      // 3. Traducción de la frase en español (es-ES)
      if (exampleEs.trim().isNotEmpty) {
        await _flutterTts.setLanguage('es-ES');
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setSpeechRate(exampleRate);
        await _flutterTts.speak(exampleEs.trim());
      }
    } finally {
      if (session == _currentSpeechSession) {
        await _flutterTts.setSpeechRate(defaultSpeechRate);
      }
    }
  }

  /// Locución bilingüe secuencial de 5 fases para el reconocimiento visual de objetos (RF-04 / RF-05):
  /// 1. es-ES: "Se identificó: "
  /// 2. en-US: [palabraIngles] (velocidad clara)
  /// 3. es-ES: ", que significa: [traduccionEspanol]. Ejemplo: "
  /// 4. en-US: [fraseIngles]
  /// 5. es-ES: ", traducción: [fraseEspanol]."
  Future<void> speakCameraRecognitionResult({
    required String wordEn,
    required String wordEs,
    required String sentenceEn,
    required String sentenceEs,
    Duration pause = const Duration(milliseconds: 300),
    double exampleRate = bilingualExampleSpeechRate,
  }) async {
    final session = ++_currentSpeechSession;
    await _ensureConfigured();
    await _flutterTts.stop();

    if (session != _currentSpeechSession) return;

    try {
      // 1. es-ES: "Se identificó: "
      await _flutterTts.setLanguage('es-ES');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(defaultSpeechRate);
      await _flutterTts.speak('Se identificó: ');

      if (session != _currentSpeechSession) return;
      await Future.delayed(pause);
      if (session != _currentSpeechSession) return;

      // 2. en-US: [palabraIngles] (velocidad clara)
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(defaultSpeechRate);
      await _flutterTts.speak(wordEn.trim());

      if (session != _currentSpeechSession) return;
      await Future.delayed(pause);
      if (session != _currentSpeechSession) return;

      // 3. es-ES: ", que significa: [traduccionEspanol]. Ejemplo: "
      await _flutterTts.setLanguage('es-ES');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(defaultSpeechRate);
      await _flutterTts.speak(', que significa: ${wordEs.trim()}. Ejemplo: ');

      if (session != _currentSpeechSession) return;
      await Future.delayed(pause);
      if (session != _currentSpeechSession) return;

      // 4. en-US: [fraseIngles]
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(exampleRate);
      await _flutterTts.speak(sentenceEn.trim());

      if (session != _currentSpeechSession) return;
      await Future.delayed(pause);
      if (session != _currentSpeechSession) return;

      // 5. es-ES: ", traducción: [fraseEspanol]."
      await _flutterTts.setLanguage('es-ES');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(exampleRate);
      await _flutterTts.speak(', traducción: ${sentenceEs.trim()}.');
    } finally {
      if (session == _currentSpeechSession) {
        await _flutterTts.setSpeechRate(defaultSpeechRate);
      }
    }
  }

  Future<void> stop() async {
    _currentSpeechSession++;
    debugPrint('[TtsService] stop solicitado');
    await _flutterTts.stop();
    await _flutterTts.setSpeechRate(defaultSpeechRate);
  }
}