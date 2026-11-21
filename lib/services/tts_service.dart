import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de síntesis de voz (TTS) optimizado para accesibilidad (WCAG 2.2 AA).
/// Implementa un patrón Singleton para persistir la locución entre navegaciones y transiciones de vistas.
/// Maneja pronunciación bilingüe fluida esperando la finalización real del audio,
/// detiene audios previos para evitar superposiciones y persiste la tasa de velocidad en SharedPreferences.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  static TtsService get instance => _instance;

  static const String _speechRateKey = 'pref_speech_rate';
  static const String _soundsEnabledKey = 'pref_sounds_enabled';

  final FlutterTts _flutterTts = FlutterTts();
  bool _isConfigured = false;
  int _currentSpeechSession = 0;

  static bool get _isTest {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  /// Velocidad estándar pedagógica por defecto
  static const double defaultSpeechRate = 0.50;

  /// Velocidad lenta para refuerzo de articulación y fonética
  static const double slowSpeechRate = 0.25;

  /// Velocidad moderada pedagógica para oraciones bilingües
  static const double bilingualExampleSpeechRate = 0.45;

  double _userSpeechRate = defaultSpeechRate;
  bool _soundsEnabled = true;
  bool _isWelcomePlaying = false;

  double get currentSpeechRate => _userSpeechRate;
  bool get soundsEnabled => _soundsEnabled;
  bool get isWelcomePlaying => _isWelcomePlaying;

  TtsService._internal() {
    _ensureConfigured();
  }

  Future<void> _ensureConfigured() async {
    if (_isConfigured) return;
    if (_isTest) {
      _isConfigured = true;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _userSpeechRate = (prefs.getDouble(_speechRateKey) ?? defaultSpeechRate).clamp(0.40, 0.70);
      _soundsEnabled = prefs.getBool(_soundsEnabledKey) ?? true;

      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.setSpeechRate(_userSpeechRate);
      _isConfigured = true;
    } catch (_) {}
  }

  /// Actualiza la tasa de velocidad del motor TTS y la persiste en SharedPreferences
  Future<void> setSpeechRate(double rate) async {
    final clamped = rate.clamp(0.40, 0.70);
    _userSpeechRate = clamped;
    if (_isTest) return;
    try {
      await _flutterTts.setSpeechRate(clamped);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_speechRateKey, clamped);
    } catch (_) {}
  }

  /// Activa o desactiva efectos de sonido y persiste la preferencia
  Future<void> setSoundsEnabled(bool enabled) async {
    _soundsEnabled = enabled;
    if (_isTest) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundsEnabledKey, enabled);
    } catch (_) {}
  }

  Future<void> speakEnglish(String text) async {
    _currentSpeechSession++;
    if (_isTest) return;
    await _ensureConfigured();
    await _flutterTts.stop();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(_userSpeechRate);
    await _flutterTts.speak(text);
  }

  Future<void> speakSpanish(String text) async {
    _currentSpeechSession++;
    debugPrint('[TtsService] speakSpanish: "$text"');
    if (_isTest) return;
    await _ensureConfigured();
    await _flutterTts.stop();
    await _flutterTts.setLanguage('es-ES');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(_userSpeechRate);
    await _flutterTts.speak(text);
  }

  Future<void> speakEnglishSlow(String text) async {
    _currentSpeechSession++;
    if (_isTest) return;
    await _ensureConfigured();
    await _flutterTts.stop();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(slowSpeechRate);
    await _flutterTts.speak(text);
  }

  /// Reproduce una oración con espacio en blanco sin vocalizar la palabra "blank" ni guiones bajos.
  /// Divide la oración antes y después de '_____' e inserta una pausa de silencio limpio de 1 segundo.
  Future<void> speakSentenceWithBlank({
    required String sentenceWithBlank,
    bool slow = false,
  }) async {
    final session = ++_currentSpeechSession;
    if (_isTest) return;
    await _ensureConfigured();
    await _flutterTts.stop();

    if (session != _currentSpeechSession) return;

    final rate = slow ? slowSpeechRate : _userSpeechRate;
    final parts = sentenceWithBlank.split('_____');

    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(rate);

      if (parts.length >= 2 && parts[0].trim().isNotEmpty) {
        await _flutterTts.speak(parts[0].trim());
        if (session != _currentSpeechSession) return;

        await Future.delayed(const Duration(milliseconds: 1000));
        if (session != _currentSpeechSession) return;

        final secondPart = parts.sublist(1).join(' ').trim();
        if (secondPart.isNotEmpty) {
          await _flutterTts.speak(secondPart);
        }
      } else {
        final clean = sentenceWithBlank.replaceAll('_____', '... ');
        await _flutterTts.speak(clean);
      }
    } finally {
      if (session == _currentSpeechSession) {
        await _flutterTts.setSpeechRate(_userSpeechRate);
      }
    }
  }

  /// Reproduce un texto en inglés y español a una velocidad pedagógica,
  /// aguarda su finalización real con awaitSpeakCompletion y restaura la velocidad configurada.
  Future<void> speakBilingual({
    required String textEn,
    required String textEs,
    Duration pause = const Duration(milliseconds: 300),
    double? exampleRate,
  }) async {
    final session = ++_currentSpeechSession;
    if (_isTest) return;
    await _ensureConfigured();
    await _flutterTts.stop();

    if (session != _currentSpeechSession) return;

    final rate = exampleRate ?? (_userSpeechRate * 0.90).clamp(0.35, 0.65);

    try {
      // 1. Oración en inglés
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(rate);
      await _flutterTts.speak(textEn);

      if (session != _currentSpeechSession) return;
      await Future.delayed(pause);
      if (session != _currentSpeechSession) return;

      // 2. Traducción en español
      await _flutterTts.setLanguage('es-ES');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(rate);
      await _flutterTts.speak(textEs);
    } finally {
      if (session == _currentSpeechSession) {
        await _flutterTts.setSpeechRate(_userSpeechRate);
      }
    }
  }

  /// Reproduce la respuesta del tutor de voz según la intención detectada:
  /// - Explicación didáctica en español
  /// - Frase de ejemplo en inglés
  /// - Traducción de la frase en español
  Future<void> speakVoiceAssistantResponse({
    required String explanationEs,
    required String exampleEn,
    required String exampleEs,
    Duration pause = const Duration(milliseconds: 350),
    double? exampleRate,
  }) async {
    final session = ++_currentSpeechSession;
    if (_isTest) return;
    await _ensureConfigured();
    await _flutterTts.stop();

    if (session != _currentSpeechSession) return;

    final rate = exampleRate ?? (_userSpeechRate * 0.90).clamp(0.35, 0.65);

    try {
      // 1. Explicación en español
      if (explanationEs.trim().isNotEmpty) {
        await _flutterTts.setLanguage('es-ES');
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setSpeechRate(_userSpeechRate);
        await _flutterTts.speak(explanationEs.trim());
      }

      if (session != _currentSpeechSession) return;
      await Future.delayed(pause);
      if (session != _currentSpeechSession) return;

      // 2. Frase de ejemplo en inglés
      if (exampleEn.trim().isNotEmpty) {
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setSpeechRate(rate);
        await _flutterTts.speak(exampleEn.trim());
      }

      if (session != _currentSpeechSession) return;
      await Future.delayed(pause);
      if (session != _currentSpeechSession) return;

      // 3. Traducción de la frase en español
      if (exampleEs.trim().isNotEmpty) {
        await _flutterTts.setLanguage('es-ES');
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setSpeechRate(rate);
        await _flutterTts.speak(exampleEs.trim());
      }
    } finally {
      if (session == _currentSpeechSession) {
        await _flutterTts.setSpeechRate(_userSpeechRate);
      }
    }
  }

  /// Reproduce la respuesta para consultas de pronunciación:
  /// 1. Explicación en español: "[X] se pronuncia [fonética]. Escucha:"
  /// 2. Audio pausado en inglés repetido dos veces
  Future<void> speakPronunciationResponse({
    required String explanationEs,
    required String wordEn,
    Duration pause = const Duration(milliseconds: 400),
  }) async {
    final session = ++_currentSpeechSession;
    if (_isTest) return;
    await _ensureConfigured();
    await _flutterTts.stop();

    if (session != _currentSpeechSession) return;

    try {
      // 1. Explicación en español
      await _flutterTts.setLanguage('es-ES');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(_userSpeechRate);
      await _flutterTts.speak(explanationEs.trim());

      if (session != _currentSpeechSession) return;
      await Future.delayed(pause);
      if (session != _currentSpeechSession) return;

      // 2. Primera repetición en inglés (lenta y clara)
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(slowSpeechRate);
      await _flutterTts.speak(wordEn.trim());

      if (session != _currentSpeechSession) return;
      await Future.delayed(const Duration(milliseconds: 600));
      if (session != _currentSpeechSession) return;

      // 3. Segunda repetición en inglés (velocidad natural)
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(_userSpeechRate);
      await _flutterTts.speak(wordEn.trim());
    } finally {
      if (session == _currentSpeechSession) {
        await _flutterTts.setSpeechRate(_userSpeechRate);
      }
    }
  }

  /// Locución bilingüe secuencial de 5 fases para el reconocimiento visual de objetos (RF-04 / RF-05)
  Future<void> speakCameraRecognitionResult({
    required String wordEn,
    required String wordEs,
    required String sentenceEn,
    required String sentenceEs,
    Duration pause = const Duration(milliseconds: 300),
    double? exampleRate,
  }) async {
    final session = ++_currentSpeechSession;
    if (_isTest) return;
    await _ensureConfigured();
    await _flutterTts.stop();

    if (session != _currentSpeechSession) return;

    final rate = exampleRate ?? (_userSpeechRate * 0.90).clamp(0.35, 0.65);

    try {
      // 1. es-ES: "Objeto detectado: "
      await _flutterTts.setLanguage('es-ES');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(_userSpeechRate);
      await _flutterTts.speak('Objeto detectado: ');

      if (session != _currentSpeechSession) return;
      await Future.delayed(pause);
      if (session != _currentSpeechSession) return;

      // 2. en-US: [palabraIngles]
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(_userSpeechRate);
      await _flutterTts.speak(wordEn.trim());

      if (session != _currentSpeechSession) return;
      await Future.delayed(pause);
      if (session != _currentSpeechSession) return;

      // 3. es-ES: ", que significa: [traduccionEspanol]. Ejemplo: "
      await _flutterTts.setLanguage('es-ES');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(_userSpeechRate);
      await _flutterTts.speak(', que significa: ${wordEs.trim()}. Ejemplo: ');

      if (session != _currentSpeechSession) return;
      await Future.delayed(pause);
      if (session != _currentSpeechSession) return;

      // 4. en-US: [fraseIngles]
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(rate);
      await _flutterTts.speak(sentenceEn.trim());

      if (session != _currentSpeechSession) return;
      await Future.delayed(pause);
      if (session != _currentSpeechSession) return;

      // 5. es-ES: ", traducción: [fraseEspanol]."
      await _flutterTts.setLanguage('es-ES');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(rate);
      await _flutterTts.speak(', traducción: ${sentenceEs.trim()}.');
    } finally {
      if (session == _currentSpeechSession) {
        await _flutterTts.setSpeechRate(_userSpeechRate);
      }
    }
  }

  /// Locución estándar completa y pedagógica para las respuestas del tutor de voz:
  /// 1. Palabra en inglés y significado en español.
  /// 2. Pronunciación fonética.
  /// 3. Frase de ejemplo en inglés: "Frase de ejemplo: [exampleEn]." (leída pausada en inglés).
  /// 4. Traducción del ejemplo en español: "[exampleEs]" (leída en español).
  Future<void> speakTutorStandardResponse({
    required String wordEn,
    required String wordEs,
    String? phonetic,
    String? explanationEs,
    String? exampleEn,
    String? exampleEs,
    Duration pause = const Duration(milliseconds: 350),
    double? exampleRate,
  }) async {
    final session = ++_currentSpeechSession;
    if (_isTest) return;
    await _ensureConfigured();
    await _flutterTts.stop();

    if (session != _currentSpeechSession) return;

    final rate = exampleRate ?? (_userSpeechRate * 0.90).clamp(0.35, 0.65);

    try {
      // 1. Explicación y significado en ESPAÑOL
      final String significado;
      if (explanationEs != null && explanationEs.trim().isNotEmpty) {
        significado = explanationEs.trim().endsWith('.')
            ? '$explanationEs Se pronuncia:'
            : '$explanationEs. Se pronuncia:';
      } else {
        significado = '$wordEn significa $wordEs. Se pronuncia:';
      }
      await _flutterTts.setLanguage('es-ES');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(_userSpeechRate);
      await _flutterTts.speak(significado);

      if (session != _currentSpeechSession) return;
      await Future.delayed(const Duration(milliseconds: 350));
      if (session != _currentSpeechSession) return;

      // 2. Pausa breve y pronunciación de la palabra en INGLÉS (estrictamente wordEn)
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.35); // Pronunciación pausada A1
      await _flutterTts.speak(wordEn.trim());

      if (session != _currentSpeechSession) return;
      await Future.delayed(const Duration(milliseconds: 400));
      if (session != _currentSpeechSession) return;

      // 3. Frase de ejemplo en INGLÉS
      if (exampleEn != null && exampleEn.trim().isNotEmpty) {
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setSpeechRate(rate);
        await _flutterTts.speak(exampleEn.trim());

        if (session != _currentSpeechSession) return;
        await Future.delayed(const Duration(milliseconds: 350));
        if (session != _currentSpeechSession) return;
      }

      // 4. Traducción del ejemplo en ESPAÑOL
      if (exampleEs != null && exampleEs.trim().isNotEmpty) {
        await _flutterTts.setLanguage('es-ES');
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setSpeechRate(0.45);
        await _flutterTts.speak('Ejemplo: ${exampleEs.trim()}');
      }
    } finally {
      if (session == _currentSpeechSession) {
        await _flutterTts.setSpeechRate(_userSpeechRate);
      }
    }
  }

  /// Reproduce un efecto sonoro accesible de victoria al finalizar una sesión de práctica (WCAG 2.2 AA).
  /// Emite un tono limpio y nítido del sistema respetando la preferencia de efectos sonoros del estudiante.
  Future<void> playVictorySound() async {
    if (!_soundsEnabled || _isTest) return;
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  /// Locución accesible de balance final para cualquier práctica gamificada (WCAG 2.2 AA).
  /// Verbaliza el total de preguntas, respuestas correctas, incorrectas, porcentaje de precisión
  /// y añade un refuerzo pedagógico adaptativo precedido del sonido de victoria.
  Future<void> speakPracticeSummary({
    required int totalPreguntas,
    required int totalAciertos,
    required int totalFallos,
  }) async {
    await playVictorySound();
    final int porcentajePrecision = totalPreguntas > 0
        ? ((totalAciertos / totalPreguntas) * 100).round()
        : 0;
    final String refuerzo = porcentajePrecision >= 80
        ? ' ¡Excelente trabajo!'
        : ' Sigue practicando para mejorar tu racha.';
    final String resumenVoz =
        '¡Práctica finalizada! Completaste $totalPreguntas preguntas. Obtuviste $totalAciertos respuestas correctas y $totalFallos incorrectas. Precisión del $porcentajePrecision por ciento.$refuerzo';
    await speakSpanish(resumenVoz);
  }

  /// Alias de conveniencia para sintetizar en español
  Future<void> speak(String text) async => speakSpanish(text);

  /// Emite un mensaje prioritario de bienvenida que no es cancelable por toques involuntarios iniciales
  Future<void> speakWelcome(String text) async {
    _isWelcomePlaying = true;
    try {
      await speakSpanish(text);
    } finally {
      _isWelcomePlaying = false;
    }
  }

  /// Detiene inmediatamente cualquier locución en curso e invalida sesiones activas.
  /// Protege el mensaje de bienvenida a menos que force == true.
  Future<void> stopAll({bool force = false}) async => stop(force: force);

  Future<void> stop({bool force = false}) async {
    if (_isWelcomePlaying && !force) {
      debugPrint('[TtsService] Detención ignorada: locución de bienvenida en reproducción');
      return;
    }
    _currentSpeechSession++;
    debugPrint('[TtsService] stop solicitado');
    if (_isTest) return;
    await _flutterTts.stop();
    await _flutterTts.setSpeechRate(_userSpeechRate);
  }
}