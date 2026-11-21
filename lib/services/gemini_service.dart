// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../config/api_config.dart';
import '../features/glossary/glossary_data.dart';
import '../features/glossary/glossary_repository.dart';
import '../features/glossary/glossary_word.dart';
import 'gemini_flash_api_service.dart';

export 'gemini_flash_api_service.dart';

/// Resultado estructurado de la inferencia visual de objetos A1 con Gemini Flash.
class GeminiObjectResult {
  final bool isRecognized;
  final String? wordEn;
  final String? wordEs;
  final String? exampleSentence;
  final String? exampleSentenceEs;
  final String? category;
  final double? confidence;
  final String? errorMessage;

  const GeminiObjectResult({
    required this.isRecognized,
    this.wordEn,
    this.wordEs,
    this.exampleSentence,
    this.exampleSentenceEs,
    this.category,
    this.confidence,
    this.errorMessage,
  });

  /// Alias de compatibilidad para el ejemplo en inglés
  String? get example => exampleSentence;
  String? get exampleEn => exampleSentence;
  String? get exampleEs => exampleSentenceEs;

  factory GeminiObjectResult.error(
    String message, {
    double? confidence,
  }) =>
      GeminiObjectResult(
        isRecognized: false,
        confidence: confidence,
        errorMessage: message,
      );

  factory GeminiObjectResult.success({
    required String wordEn,
    required String wordEs,
    required String exampleSentence,
    String? exampleSentenceEs,
    String? category,
    double? confidence,
  }) =>
      GeminiObjectResult(
        isRecognized: true,
        wordEn: wordEn,
        wordEs: wordEs,
        exampleSentence: exampleSentence,
        exampleSentenceEs: exampleSentenceEs,
        category: category,
        confidence: confidence,
      );

  Map<String, dynamic> toMap() {
    return {
      'isRecognized': isRecognized,
      'wordEn': wordEn,
      'wordEs': wordEs,
      'exampleSentence': exampleSentence,
      'exampleSentenceEs': exampleSentenceEs,
      'category': category,
      if (confidence != null) 'confidence': confidence,
      'errorMessage': errorMessage,
    };
  }
}

/// Intenciones comunicativas reconocidas por el tutor de voz según RF-11 (IEEE 830)
enum VoiceQueryIntent {
  /// "¿Cómo se dice [palabra] en inglés?"
  howToSay,

  /// "¿Qué significa [palabra] en español?"
  whatDoesItMean,

  /// "¿Cómo se pronuncia [palabra]?"
  howToPronounce,
}

/// Resultado estructurado del asistente lingüístico de búsqueda por voz con Gemini.
class GeminiVoiceResult {
  final bool success;
  final String query;
  final String? wordOrTerm;
  final String? translation;
  final String? phonetic;
  final String? exampleEn;
  final String? exampleEs;
  final String? explanation;
  final String? errorMessage;
  final VoiceQueryIntent intent;

  const GeminiVoiceResult({
    required this.success,
    required this.query,
    this.wordOrTerm,
    this.translation,
    this.phonetic,
    this.exampleEn,
    this.exampleEs,
    this.explanation,
    this.errorMessage,
    this.intent = VoiceQueryIntent.howToSay,
  });

  /// Alias de compatibilidad
  String? get term => wordOrTerm;
  String? get example => exampleEn;

  factory GeminiVoiceResult.error({
    required String query,
    required String message,
    VoiceQueryIntent intent = VoiceQueryIntent.howToSay,
  }) =>
      GeminiVoiceResult(
        success: false,
        query: query,
        errorMessage: message,
        intent: intent,
      );

  factory GeminiVoiceResult.success({
    required String query,
    required String wordOrTerm,
    required String translation,
    required String phonetic,
    required String exampleEn,
    required String exampleEs,
    String? explanation,
    VoiceQueryIntent intent = VoiceQueryIntent.howToSay,
  }) =>
      GeminiVoiceResult(
        success: true,
        query: query,
        wordOrTerm: wordOrTerm,
        translation: translation,
        phonetic: phonetic,
        exampleEn: exampleEn,
        exampleEs: exampleEs,
        explanation: explanation,
        intent: intent,
      );

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'query': query,
      'wordOrTerm': wordOrTerm,
      'translation': translation,
      'phonetic': phonetic,
      'exampleEn': exampleEn,
      'exampleEs': exampleEs,
      'explanation': explanation,
      'errorMessage': errorMessage,
      'intent': intent.name,
    };
  }
}

/// Resultado de la validación local de palabra individual según RF-11 (IEEE 830).
class ResultadoValidacionPalabra {
  final bool esValida;
  final String palabraExtraida;
  final String? mensajeError;

  const ResultadoValidacionPalabra.valida(this.palabraExtraida)
      : esValida = true,
        mensajeError = null;

  const ResultadoValidacionPalabra.invalida(this.mensajeError)
      : esValida = false,
        palabraExtraida = '';
}

/// Maneja dos flujos diferenciados de manera 100% transparente y accesible:
/// 1. Cámara (Restringido): Inferencia visual limitada al catálogo controlado A1 de objetos cotidianos.
/// 2. Búsqueda por Voz (Abierto): Asistente de traducción que responde a consultas en lenguaje natural.
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  static GeminiService get instance => _instance;

  // Modelo oficial del proyecto AirSight: gemini-3.8-flash
  static const String defaultModel = 'gemini-3.8-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$defaultModel:generateContent';

  static String get baseUrl => _baseUrl;

  /// Lista de modelos de alta disponibilidad ordenada por estabilidad y menor congestión (evita 503/404)
  static const List<String> modelosCandidatos = [
    'gemini-3.5-flash',
    'gemini-3.6-flash',
    'gemini-3-flash-preview',
    'gemini-3.8-flash',
    'gemini-3.1-flash-lite',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-1.5-flash',
    'gemini-1.5-flash-8b',
  ];

  /// Alias de compatibilidad hacia la lista de modelos
  static List<String> get modelosDisponibles => modelosCandidatos;

  /// Comprime y redimensiona la imagen en memoria volátil (máx 800px, JPEG calidad 65%)
  /// para reducir el tamaño del payload Base64 a < 150 KB, eliminando timeouts y latencia.
  static Uint8List comprimirImagenParaInferencia(
    Uint8List rawBytes, {
    int maxDimension = 800,
    int quality = 65,
  }) {
    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) return rawBytes;

      img.Image processed = decoded;
      if (decoded.width > maxDimension || decoded.height > maxDimension) {
        if (decoded.width >= decoded.height) {
          processed = img.copyResize(decoded, width: maxDimension);
        } else {
          processed = img.copyResize(decoded, height: maxDimension);
        }
      }

      final compressed = Uint8List.fromList(
        img.encodeJpg(processed, quality: quality),
      );
      debugPrint(
        '>>> [AIRSIGHT IMAGE COMPRESSION] Original: ${rawBytes.length} bytes -> Comprimida: ${compressed.length} bytes (${processed.width}x${processed.height}, quality $quality%)',
      );
      return compressed;
    } catch (e) {
      debugPrint('>>> [AIRSIGHT IMAGE COMPRESSION WARNING]: $e');
      return rawBytes;
    }
  }

  /// Extrae y limpia una cadena JSON eliminando bloques markdown (```json ... ```)
  /// y recortando texto residual antes del primer '{' y después del último '}'.
  static String extractCleanJson(String rawText) {
    String cleaned = rawText.replaceAll(RegExp(r'```json|```'), '').trim();
    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace >= firstBrace) {
      cleaned = cleaned.substring(firstBrace, lastBrace + 1).trim();
    }
    return cleaned;
  }

  /// Extrae el valor de un campo clave en un JSON crudo o truncado mediante expresiones regulares (Fallback defensivo).
  static String? extractRegex(String source, String key) {
    // 1. Busca clave con comillas cerradas: "key": "value"
    final closedPattern = RegExp(
      '"$key"\\s*:\\s*"([^"\\\\]*(?:\\\\.[^"\\\\]*)*)"',
      caseSensitive: false,
    );
    final closedMatch = closedPattern.firstMatch(source);
    if (closedMatch != null && closedMatch.groupCount >= 1) {
      return closedMatch
          .group(1)
          ?.replaceAll(r'\"', '"')
          .replaceAll(r'\n', ' ')
          .trim();
    }

    // 2. Fallback para cadenas truncadas antes de cerrar comillas (ej: "respuesta": "texto incompleto...)
    final unclosedPattern = RegExp(
      '"$key"\\s*:\\s*"([^"\\r\\n}]+)',
      caseSensitive: false,
    );
    final unclosedMatch = unclosedPattern.firstMatch(source);
    if (unclosedMatch != null && unclosedMatch.groupCount >= 1) {
      return unclosedMatch
          .group(1)
          ?.replaceAll(r'\"', '"')
          .replaceAll(r'\n', ' ')
          .trim();
    }

    // 3. Fallback para números o booleanos: "key": 0.95 o "key": true
    final numBoolPattern = RegExp(
      '"$key"\\s*:\\s*([0-9.]+|true|false)',
      caseSensitive: false,
    );
    final numBoolMatch = numBoolPattern.firstMatch(source);
    if (numBoolMatch != null && numBoolMatch.groupCount >= 1) {
      return numBoolMatch.group(1)?.trim();
    }

    return null;
  }

  /// Umbral de confianza mínimo exigido para el reconocimiento visual según IEEE 830 RF-03.b (70% / 0.70)
  static const double umbralConfianzaMinimo = 0.70;

  /// Mensaje de contingencia estricto ante objeto no reconocido o fuera del glosario A1 según IEEE 830 RF-03.e
  static const String mensajeObjetoNoReconocido =
      'Objeto no reconocido o no disponible en el glosario A1';

  /// Busca y empareja una etiqueta detectada contra el catálogo controlado de vocabulario A1 (RF-03.c).
  /// Prioriza coincidencia exacta en inglés (`wordEn`), luego en español (`wordEs`), y finalmente en `aliases`/`etiquetasIA`.
  static GlossaryWord? buscarPalabraEnCatalogoA1(
    String etiqueta, {
    List<GlossaryWord>? catalogo,
  }) {
    final cleanLabel = GlossaryWord.normalize(etiqueta);
    if (cleanLabel.isEmpty) return null;

    final listaCatalogo = catalogo ?? glossaryWords;

    // 1. Coincidencia exacta con el término principal en inglés (wordEn)
    for (final w in listaCatalogo) {
      if (GlossaryWord.normalize(w.wordEn) == cleanLabel) {
        return w;
      }
    }

    // 2. Coincidencia exacta con la traducción principal en español (wordEs)
    for (final w in listaCatalogo) {
      if (GlossaryWord.normalize(w.wordEs) == cleanLabel) {
        return w;
      }
    }

    // 3. Coincidencia con aliases o etiquetas de visión artificial (etiquetasIA)
    for (final w in listaCatalogo) {
      if (w.matchesAiLabel(cleanLabel)) {
        return w;
      }
    }

    return null;
  }

  /// Verifica si una etiqueta pertenece al catálogo controlado de vocabulario A1 (RF-03.c).
  static bool esEtiquetaValidaA1(
    String etiqueta, {
    List<GlossaryWord>? catalogo,
  }) {
    return buscarPalabraEnCatalogoA1(etiqueta, catalogo: catalogo) != null;
  }

  /// Valida estrictamente la inferencia de visión para el requerimiento RF-03:
  /// 1) Descarta cualquier objeto con confidence score menor a 0.70.
  /// 2) Valida la etiqueta contra el catálogo/array de vocabulario A1.
  /// 3) Si falla cualquiera de las dos condiciones anteriores, devuelve estrictamente
  ///    el string 'Objeto no reconocido o no disponible en el glosario A1'.
  static String validarDeteccionRF03({
    required String etiqueta,
    required double confidence,
    List<GlossaryWord>? catalogo,
  }) {
    final double normalizedConfidence =
        (confidence > 1.0 && confidence <= 100.0) ? confidence / 100.0 : confidence;

    if (normalizedConfidence.isNaN || normalizedConfidence < umbralConfianzaMinimo) {
      return mensajeObjetoNoReconocido;
    }

    final matchedWord = buscarPalabraEnCatalogoA1(etiqueta, catalogo: catalogo);
    if (matchedWord == null) {
      return mensajeObjetoNoReconocido;
    }

    return matchedWord.wordEn.toLowerCase();
  }

  /// Valida y estructura el mapa JSON de respuesta del clasificador visual según RF-03:
  /// 1) Verifica que el confidence score sea >= 0.70 (descarta si < 0.70).
  /// 2) Valida la etiqueta detectada contra el catálogo/array de vocabulario A1 (`glossaryWords`).
  /// 3) Si falla cualquiera de las dos condiciones, retorna `'exito': false` y estrictamente
  ///    `'mensaje': 'Objeto no reconocido o no disponible en el glosario A1'`.
  static Map<String, dynamic> validarResultadoVisionA1(
    Map<String, dynamic> jsonMap, {
    List<GlossaryWord>? catalogo,
  }) {
    final bool exito = (jsonMap['exito'] == true) ||
        (jsonMap['recognized'] == true && jsonMap['exito'] != false);

    if (!exito) {
      return {
        'exito': false,
        'mensaje': mensajeObjetoNoReconocido,
      };
    }

    // 1. Extracción y validación estricta del confidence score (>= 0.70) (RF-03.b)
    final rawConfidence = jsonMap['confidence'] ??
        jsonMap['confidenceScore'] ??
        jsonMap['confianza'] ??
        jsonMap['score'];

    double? parsedConfidence;
    if (rawConfidence is num) {
      parsedConfidence = rawConfidence.toDouble();
    } else if (rawConfidence is String) {
      final cleanedConf = rawConfidence.trim().replaceAll('%', '');
      parsedConfidence = double.tryParse(cleanedConf);
      if (parsedConfidence != null && rawConfidence.contains('%') && parsedConfidence > 1.0) {
        parsedConfidence = parsedConfidence / 100.0;
      }
    }

    if (parsedConfidence != null && parsedConfidence > 1.0 && parsedConfidence <= 100.0) {
      parsedConfidence = parsedConfidence / 100.0;
    }

    if (parsedConfidence == null ||
        parsedConfidence.isNaN ||
        parsedConfidence < umbralConfianzaMinimo) {
      return {
        'exito': false,
        'confidence': parsedConfidence ?? 0.0,
        'mensaje': mensajeObjetoNoReconocido,
      };
    }

    // 2. Extracción y validación de la etiqueta contra el catálogo/array de vocabulario A1 (RF-03.c)
    final rawPalabraIngles = (jsonMap['palabraIngles'] as String? ??
            jsonMap['wordEn'] as String? ??
            jsonMap['label'] as String? ??
            jsonMap['etiqueta'] as String? ??
            '')
        .trim();
    final rawTraduccionEspanol = (jsonMap['traduccionEspanol'] as String? ??
            jsonMap['wordEs'] as String? ??
            '')
        .trim();

    GlossaryWord? matchedWord = buscarPalabraEnCatalogoA1(
      rawPalabraIngles,
      catalogo: catalogo,
    );
    if (matchedWord == null && rawPalabraIngles.isEmpty && rawTraduccionEspanol.isNotEmpty) {
      matchedWord = buscarPalabraEnCatalogoA1(
        rawTraduccionEspanol,
        catalogo: catalogo,
      );
    }

    // 3. Si la etiqueta no pertenece al catálogo A1, devolver estrictamente el string normado (RF-03.e)
    if (matchedWord == null) {
      return {
        'exito': false,
        'confidence': parsedConfidence,
        'mensaje': mensajeObjetoNoReconocido,
      };
    }

    final palabraIngles = matchedWord.wordEn.trim().toLowerCase();
    final traduccionEspanol = rawTraduccionEspanol.isNotEmpty
        ? rawTraduccionEspanol.toLowerCase()
        : matchedWord.wordEs.trim().toLowerCase();
    final categoria = (jsonMap['categoria'] as String? ??
            jsonMap['category'] as String? ??
            matchedWord.category)
        .trim();
    final fraseIngles = (jsonMap['fraseIngles'] as String? ??
            jsonMap['exampleSentence'] as String? ??
            matchedWord.exampleEn)
        .trim();
    final fraseEspanol = (jsonMap['fraseEspanol'] as String? ??
            jsonMap['exampleSentenceEs'] as String? ??
            matchedWord.exampleEs)
        .trim();

    return {
      'exito': true,
      'confidence': parsedConfidence,
      'palabraIngles': palabraIngles,
      'traduccionEspanol': traduccionEspanol,
      'categoria': categoria.isNotEmpty ? categoria : matchedWord.category,
      'fraseIngles': fraseIngles.isNotEmpty ? fraseIngles : matchedWord.exampleEn,
      'fraseEspanol': fraseEspanol.isNotEmpty ? fraseEspanol : matchedWord.exampleEs,
    };
  }

  /// Procesa una cadena JSON cruda proveniente del clasificador visual aplicando las reglas de RF-03.
  static Map<String, dynamic> parseObjectJsonResponse(
    String rawText, {
    List<GlossaryWord>? catalogo,
  }) {
    if (rawText.trim().isEmpty) {
      return {
        'exito': false,
        'mensaje': mensajeObjetoNoReconocido,
      };
    }
    final jsonMap = _parseJsonResponse(rawText);
    return validarResultadoVisionA1(jsonMap, catalogo: catalogo);
  }

  /// Mensaje de contingencia estricto según IEEE 830 v3.2 (RF-11.e y Apéndice B.5.2)
  static const String mensajeContingenciaPalabraUnica =
      'Por favor consulta únicamente una palabra a la vez para tu práctica de vocabulario.';
  static ResultadoValidacionPalabra validarConsultaPalabraIndividual(String entrada) {
    final clean = entrada.trim();
    if (clean.isEmpty) {
      return const ResultadoValidacionPalabra.invalida(
        'No se detectó audio ni palabras en la consulta de voz.',
      );
    }

    String termino = clean;

    final patrones = [
      // "¿Cómo se dice X en inglés?" o "Cómo se dice X"
      RegExp(r'^(?:¿|\s)*(?:c[oó]mo\s+se\s+dice)\s+(.+?)(?:\s+en\s+ingl[eé]s)?(?:\?|\s)*$', caseSensitive: false),
      // "¿Cómo se traduce X al inglés?"
      RegExp(r'^(?:¿|\s)*(?:c[oó]mo\s+se\s+traduce)\s+(.+?)(?:\s+(?:al|en)\s+ingl[eé]s)?(?:\?|\s)*$', caseSensitive: false),
      // "¿Qué significa X en español?"
      RegExp(r'^(?:¿|\s)*(?:qu[eé]\s+significa)\s+(.+?)(?:\s+en\s+espa[ñn]ol)?(?:\?|\s)*$', caseSensitive: false),
      // "¿Cómo se pronuncia X?"
      RegExp(r'^(?:¿|\s)*(?:c[oó]mo\s+se\s+pronuncia)\s+(.+?)(?:\?|\s)*$', caseSensitive: false),
      // "Traduce X" / "Traducción de X"
      RegExp(r'^(?:tradu(?:ce|cci[oó]n\s+de|cir))\s+(.+?)(?:\?|\s)*$', caseSensitive: false),
      // "Dime X en inglés"
      RegExp(r'^(?:dime|diga)\s+(.+?)(?:\s+en\s+ingl[eé]s)?(?:\?|\s)*$', caseSensitive: false),
      // Patrones en inglés
      RegExp(r'^(?:how\s+do\s+you\s+say)\s+(.+?)(?:\s+in\s+(?:english|spanish))?(?:\?|\s)*$', caseSensitive: false),
      RegExp(r'^(?:what\s+does)\s+(.+?)\s+mean(?:\?|\s)*$', caseSensitive: false),
    ];

    for (final regex in patrones) {
      final match = regex.firstMatch(termino);
      if (match != null && match.groupCount >= 1) {
        termino = match.group(1)?.trim() ?? termino;
        break;
      }
    }

    // Limpieza de signos ortográficos y comillas
    termino = termino.replaceAll(RegExp(r'["\?¿!¡\.,;:_]'), '').trim();

    // Remover artículos iniciales si existen (ej. "el lápiz" -> "lápiz")
    final articulos = RegExp(r'^(?:el|la|los|las|un|una|unos|unas|the|a|an)\s+', caseSensitive: false);
    termino = termino.replaceFirst(articulos, '').trim();

    final palabras = termino.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

    if (palabras.isEmpty) {
      return const ResultadoValidacionPalabra.invalida(
        'No se detectó un término léxico para consultar.',
      );
    }

    // Si tiene más de 2 palabras (oración completa o frase larga), rechazar inmediatamente sin llamada a API
    if (palabras.length > 2) {
      return const ResultadoValidacionPalabra.invalida(
        mensajeContingenciaPalabraUnica,
      );
    }

    // Si tiene exactamente 2 palabras, verificar si es una oración o frase con pronombres/verbos/conectores
    if (palabras.length == 2) {
      const palabrasOracion = {
        'yo', 'tu', 'tú', 'el', 'él', 'ella', 'nosotros', 'ellos', 'ellas',
        'quiero', 'quieres', 'quiere', 'ir', 'vamos', 'comer', 'comprar',
        'tengo', 'tienes', 'tiene', 'es', 'son', 'esta', 'está', 'estan', 'están',
        'para', 'por', 'con', 'sin', 'en', 'de', 'a', 'y', 'o', 'pero', 'que', 'qué',
        'i', 'you', 'he', 'she', 'we', 'they', 'want', 'go', 'eat', 'buy', 'have',
        'is', 'are', 'am', 'to', 'for', 'with', 'in', 'on', 'at', 'and', 'but'
      };

      final p1 = palabras[0].toLowerCase();
      final p2 = palabras[1].toLowerCase();
      if (palabrasOracion.contains(p1) || palabrasOracion.contains(p2)) {
        return const ResultadoValidacionPalabra.invalida(
          mensajeContingenciaPalabraUnica,
        );
      }
    }

    return ResultadoValidacionPalabra.valida(termino);
  }

  String? _apiKeyOverride;
  String _modelName = defaultModel;

  GeminiService._internal();

  /// Constructor para inyección de dependencias o pruebas unitarias
  GeminiService.custom({String? apiKey, String modelName = defaultModel})
      : _apiKeyOverride = apiKey,
        _modelName = modelName;

  /// Clave de API activa, consumida directamente desde ApiConfig de forma interna y transparente
  String get activeApiKey {
    if (_apiKeyOverride != null && _apiKeyOverride!.isNotEmpty) {
      return _apiKeyOverride!;
    }
    final configKey = ApiConfig.geminiApiKey;
    if (configKey.isNotEmpty && configKey != 'CI_STUB_KEY' && configKey != 'TU_API_KEY_AQUI') {
      return configKey;
    }
    return GeminiFlashApiService.apiKey;
  }

  /// Permite sobrescribir la clave en memoria (utilizado exclusivamente en tests)
  void setApiKey(String key) {
    _apiKeyOverride = key.trim();
  }

  /// Cambia el modelo de Gemini Flash
  void setModelName(String model) {
    _modelName = model.trim();
  }

  String get modelName => _modelName;

  /// Inferencia HTTP directa con diagnóstico explícito (`GeminiFlashApiService.postGenerateContent`)
  /// y rotación inmediata ante congestión 503, 429, 404 o Timeout.
  Future<String> _generarContenidoHttp({
    required Map<String, dynamic> payload,
    required String apiKey,
  }) async {
    final candidatos = <String>[
      _modelName,
      ...modelosCandidatos.where((m) => m != _modelName),
    ];

    const int maxIntentos = 5;
    final int limite =
        candidatos.length > maxIntentos ? maxIntentos : candidatos.length;

    dynamic ultimoError;

    for (int i = 0; i < limite; i++) {
      final modelo = candidatos[i];
      try {
        debugPrint(
          '[GEMINI] Intento ${i + 1}/$limite con modelo: $modelo',
        );
        final cleanText = await GeminiFlashApiService.postGenerateContent(
          payload: payload,
          model: modelo,
          apiKeyOverride: apiKey,
          timeout: const Duration(seconds: 10),
        );

        if (_modelName != modelo) {
          debugPrint(
            '[GEMINI FAILOVER] ¡Éxito con modelo alternativo! Estableciendo como predeterminado: $modelo',
          );
          _modelName = modelo;
        }
        return cleanText;
      } catch (e) {
        ultimoError = e;
        final errorStr = e.toString().toLowerCase();

        final esRotable = errorStr.contains('503') ||
            errorStr.contains('429') ||
            errorStr.contains('500') ||
            errorStr.contains('high demand') ||
            errorStr.contains('unavailable') ||
            errorStr.contains('404') ||
            errorStr.contains('not found') ||
            errorStr.contains('not supported') ||
            errorStr.contains('timeoutexception');

        if (esRotable && (i + 1 < limite)) {
          debugPrint(
            '[GEMINI FAILOVER] Modelo "$modelo" falló ($e). '
            'Rotando inmediatamente al siguiente modelo candidato: ${candidatos[i + 1]}...',
          );
          continue;
        }

        rethrow;
      }
    }

    throw ultimoError ??
        Exception(
          'Ningún modelo candidato pudo procesar la solicitud tras $limite intentos.',
        );
  }

  /// Diagnóstico automático: Descubre por código la lista exacta de modelos activos en Google AI Studio (ListModels)
  /// que admiten el método 'generateContent' con nuestra API Key.
  Future<List<String>> inspeccionarModelosDisponibles() async {
    try {
      if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
        return [];
      }
    } catch (_) {}
    final key = activeApiKey;
    if (key.isEmpty || key == 'TU_API_KEY_AQUI') {
      debugPrint('[GEMINI INSPECCIÓN] Clave de API no configurada.');
      return [];
    }

    try {
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$key');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final models = (data['models'] as List<dynamic>?) ?? [];
        final generateContentModels = <String>[];
        for (final m in models) {
          final methods = (m['supportedGenerationMethods'] as List<dynamic>?) ?? [];
          if (methods.contains('generateContent')) {
            final String rawName = m['name'] ?? '';
            final cleanName = rawName.replaceFirst('models/', '');
            generateContentModels.add(cleanName);
          }
        }
        debugPrint('================================================================');
        debugPrint('[GEMINI MODELOS ACTIVOS DISPONIBLES]:');
        for (final model in generateContentModels) {
          debugPrint('  -> $model');
        }
        debugPrint('================================================================');
        return generateContentModels;
      } else {
        debugPrint('[GEMINI INSPECCIÓN ERROR HTTP ${response.statusCode}]: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error al listar modelos: $e');
    }
    return [];
  }

  /// Diagnóstico rápido de conexión con la API de Gemini (Google AI Studio)
  Future<bool> probarConexionGemini() async {
    final key = activeApiKey;
    print('[GEMINI KEY CHECK]: ${key.length > 6 ? key.substring(0, 6) + "..." : key}');
    try {
      final rawText = await _generarContenidoHttp(
        payload: {
          'contents': [
            {
              'parts': [
                {'text': 'Test'},
              ],
            },
          ],
        },
        apiKey: key,
      );
      print('[GEMINI TEST EXITOSO con modelo $_modelName]: $rawText');
      return true;
    } catch (e) {
      print('[GEMINI TEST FALLIDO]: $e');
      print('[GEMINI ERROR DETALLADO]: ${e.toString()}');
      return false;
    }
  }

  /// Inferencia visual multimodal restringida al glosario de objetos cotidianos A1 (IEEE 830 RF-03 / RNF-03).
  /// Procesa imágenes en memoria como Uint8List (RNF-03), exige un confidence score >= 0.70 (RF-03.b),
  /// valida la etiqueta contra el catálogo controlado A1 (RF-03.c) y devuelve estrictamente
  /// 'Objeto no reconocido o no disponible en el glosario A1' si falla cualquiera de las condiciones (RF-03.e).
  Future<Map<String, dynamic>> identificarObjetoA1(
    Uint8List imageBytes, {
    String? apiKey,
    List<GlossaryWord>? catalogo,
  }) async {
    if (imageBytes.isEmpty) {
      return {
        'exito': false,
        'mensaje': 'La imagen capturada está vacía.',
      };
    }

    final key = apiKey ?? activeApiKey;
    print('[GEMINI KEY CHECK]: ${key.length > 6 ? key.substring(0, 6) + "..." : key}');
    if (key.isEmpty || key == 'TU_API_KEY_AQUI') {
      print('[GEMINI ERROR DETALLADO]: ApiConfig.geminiApiKey está vacía o tiene el valor por defecto ("TU_API_KEY_AQUI").');
      debugPrint('ERROR REAL GEMINI: ApiConfig.geminiApiKey está vacía o tiene el valor por defecto ("TU_API_KEY_AQUI"). Configura tu clave en lib/config/api_config.dart o con --dart-define=GEMINI_API_KEY=...');
      return {
        'exito': false,
        'mensaje': 'Servicio no disponible temporalmente.',
      };
    }

    try {
      List<GlossaryWord> catalogoActivo;
      if (catalogo != null) {
        catalogoActivo = catalogo;
      } else {
        try {
          catalogoActivo = await GlossaryRepository.getWords();
        } catch (_) {
          catalogoActivo = glossaryWords;
        }
      }

      final listaVocabulario = catalogoActivo
          .map((w) => w.wordEn.toLowerCase().trim())
          .toSet()
          .join(', ');

      final systemInstruction = '''
Eres el clasificador visual del proyecto accesible AirSight para estudiantes con discapacidad visual (requerimiento RF-03). Tu tarea es identificar el objeto principal en la imagen, estimar tu nivel de confianza (confidence score entre 0.0 y 1.0) y asociarlo exclusivamente al catálogo de vocabulario básico en inglés de nivel A1: [$listaVocabulario].

Reglas estrictas de respuesta:
1. Si el objeto se identifica con un confidence score mayor o igual a 0.70 (70%) y pertenece al catálogo de vocabulario A1, simplifícalo a su término exacto del catálogo A1 (ejemplo: si ves un portátil Asus responde "laptop" o "computer"; si ves una silla de oficina responde "chair") y responde ÚNICAMENTE en JSON válido en una sola línea o sin saltos de línea internos dentro de los valores de texto. Usa comillas dobles y asegura cerrar todas las llaves:
{
  "exito": true,
  "confidence": 0.92,
  "palabraIngles": "laptop",
  "traduccionEspanol": "computador portátil",
  "categoria": "Technology",
  "fraseIngles": "The laptop is on the desk.",
  "fraseEspanol": "El computador portátil está en el escritorio."
}
2. Si el confidence score es menor a 0.70, la imagen es borrosa/oscura, o el objeto NO pertenece al catálogo de vocabulario A1, responde ÚNICAMENTE:
{
  "exito": false,
  "confidence": 0.0,
  "mensaje": "$mensajeObjetoNoReconocido"
}
''';

      // Optimización crítica de latencia: redimensiona y comprime la captura (máx 800px, quality 65%)
      final optimizedBytes = comprimirImagenParaInferencia(imageBytes);
      final base64Image = base64Encode(optimizedBytes);

      final payload = <String, dynamic>{
        'contents': [
          {
            'parts': [
              {
                'text':
                    '$systemInstruction\nIdentifica el objeto principal de la imagen:',
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                },
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 800,
          'responseMimeType': 'application/json',
        },
      };

      final rawText = await _generarContenidoHttp(
        payload: payload,
        apiKey: key,
      );

      if (rawText.trim().isEmpty) {
        return {
          'exito': false,
          'mensaje': mensajeObjetoNoReconocido,
        };
      }

      return parseObjectJsonResponse(rawText, catalogo: catalogoActivo);
    } on SocketException catch (e) {
      print('[GEMINI ERROR DETALLADO]: Conexión fallida: $e');
      debugPrint('ERROR REAL GEMINI: Conexión fallida: $e');
      return {
        'exito': false,
        'mensaje': 'Sin conexión a internet. Verifica tu conexión de red.',
        'esErrorConexion': true,
      };
    } catch (e) {
      print('[GEMINI ERROR DETALLADO]: ${e.toString()}');
      debugPrint('>>> [AIRSIGHT VISION ERROR]: $e');
      final msg = _formatErrorMessage(e);
      final errorLower = e.toString().toLowerCase();

      if (msg.contains('SocketException') || msg.contains('Failed host lookup')) {
        return {
          'exito': false,
          'mensaje': 'Sin conexión a internet. Verifica tu conexión de red.',
          'esErrorConexion': true,
        };
      }

      if (errorLower.contains('timeoutexception') || errorLower.contains('timed out')) {
        return {
          'exito': false,
          'mensaje': 'Tiempo de espera agotado al analizar la imagen. Intenta nuevamente.',
        };
      }

      if (errorLower.contains('503') ||
          errorLower.contains('429') ||
          errorLower.contains('unavailable') ||
          errorLower.contains('high demand')) {
        return {
          'exito': false,
          'mensaje': 'Servicio de reconocimiento no disponible temporalmente. Intenta en un momento.',
          'esError503': true,
        };
      }

      if (msg.contains('API_KEY_INVALID') ||
          msg.contains('403') ||
          msg.contains('401') ||
          msg.contains('Fallo HTTP')) {
        return {
          'exito': false,
          'mensaje': 'Error de comunicación con el servicio de IA ($msg).',
        };
      }

      return {
        'exito': false,
        'mensaje': mensajeObjetoNoReconocido,
      };
    }
  }

  /// Adaptador de compatibilidad para código y pruebas existentes
  Future<GeminiObjectResult> identificarObjeto(
    Uint8List imageBytes, {
    String? apiKey,
    String? mimeType,
    List<GlossaryWord>? catalogo,
  }) async {
    final result = await identificarObjetoA1(
      imageBytes,
      apiKey: apiKey,
      catalogo: catalogo,
    );
    if (result['exito'] == true) {
      return GeminiObjectResult.success(
        wordEn: result['palabraIngles'] ?? '',
        wordEs: result['traduccionEspanol'] ?? '',
        exampleSentence: result['fraseIngles'] ?? '',
        exampleSentenceEs: result['fraseEspanol'],
        category: result['categoria'],
        confidence: (result['confidence'] as num?)?.toDouble(),
      );
    } else {
      return GeminiObjectResult.error(
        result['mensaje'] ?? mensajeObjetoNoReconocido,
        confidence: (result['confidence'] as num?)?.toDouble(),
      );
    }
  }

  /// Detecta la intención pedagógica de la consulta del estudiante según RF-11 (IEEE 830)
  static VoiceQueryIntent detectarIntencion(String query) {
    final clean = query.toLowerCase();
    if (clean.contains('pronuncia') ||
        clean.contains('pronounce') ||
        clean.contains('fonética') ||
        clean.contains('fonetica')) {
      return VoiceQueryIntent.howToPronounce;
    }
    if (clean.contains('significa') ||
        clean.contains('significado') ||
        clean.contains('mean') ||
        clean.contains('defin')) {
      return VoiceQueryIntent.whatDoesItMean;
    }
    return VoiceQueryIntent.howToSay;
  }

  /// Búsqueda lingüística abierta por voz: Asistente que responde a cualquier
  /// consulta en lenguaje natural capturada desde el micrófono.
  /// Devuelve: traducción, pronunciación fonética aproximada y frase corta de ejemplo en inglés y español.
  Future<GeminiVoiceResult> consultarPorVoz(
    String promptVoz, {
    String? apiKey,
  }) async {
    final query = promptVoz.trim();
    if (query.isEmpty) {
      return GeminiVoiceResult.error(
        query: promptVoz,
        message: 'No se detectó audio ni palabras en la consulta de voz.',
      );
    }

    // 1. VALIDACIÓN LOCAL DEL RF-11 (FILTRO DE PALABRA INDIVIDUAL)
    final validacion = validarConsultaPalabraIndividual(query);
    if (!validacion.esValida) {
      return GeminiVoiceResult.error(
        query: query,
        message: validacion.mensajeError ?? mensajeContingenciaPalabraUnica,
      );
    }

    final palabraAEnviar = validacion.palabraExtraida;
    final intencion = detectarIntencion(query);

    final key = apiKey ?? activeApiKey;
    print('[GEMINI KEY CHECK]: ${key.length > 6 ? key.substring(0, 6) + "..." : key}');
    if (key.isEmpty || key == 'TU_API_KEY_AQUI') {
      print('[GEMINI ERROR DETALLADO]: ApiConfig.geminiApiKey está vacía o tiene el valor por defecto ("TU_API_KEY_AQUI").');
      debugPrint('ERROR REAL GEMINI: ApiConfig.geminiApiKey está vacía o tiene el valor por defecto ("TU_API_KEY_AQUI"). Configura tu clave en lib/config/api_config.dart o con --dart-define=GEMINI_API_KEY=...');
      return GeminiVoiceResult.error(
        query: query,
        message: 'ApiKey de Gemini no configurada ("TU_API_KEY_AQUI"). Configura tu clave en lib/config/api_config.dart.',
        intent: intencion,
      );
    }

    try {
      final promptText = '''
Eres el tutor lingüístico accesible de Air Sight para estudiantes universitarios con discapacidad visual que aprenden inglés nivel A1.
El estudiante realizó la siguiente consulta de vocabulario: "$palabraAEnviar"
Intención detectada: ${intencion.name}

Reglas estrictas de respuesta pedagógica (Nivel A1):
1. Traduce o explica ÚNICAMENTE la palabra o concepto léxico individual indicado: "$palabraAEnviar".
2. Si el término excede una palabra individual, responde ÚNICAMENTE:
{
  "exito": false,
  "mensaje": "$mensajeContingenciaPalabraUnica"
}

3. Si la consulta corresponde a una palabra individual o término simple:
   - Si la intención es "howToSay" ("¿Cómo se dice...?"): Entrega la traducción directa en inglés, significado en español y frase corta de ejemplo nivel A1.
   - Si la intención es "whatDoesItMean" ("¿Qué significa...?"): Entrega la traducción directa al español y un breve contexto pedagógico de uso.
   - Si la intención es "howToPronounce" ("¿Cómo se pronuncia...?"): Entrega la transcripción fonética legible clara (ej: /'æpl/ o á-pl) y explicación amigable para síntesis oral.

Responde ÚNICAMENTE en JSON válido en una sola línea o sin saltos de línea internos dentro de los valores de texto. Usa comillas dobles y asegura cerrar todas las llaves:
{
  "exito": true,
  "terminoConsultado": "$palabraAEnviar",
  "traduccionIngles": "<traducción al inglés si consultó en español, o al español si consultó en inglés>",
  "fonetica": "<pronunciación fonética aproximada y sencilla, ej: pén-sil o á-pl>",
  "fraseEjemploIngles": "<oración corta y clara de ejemplo en inglés nivel A1>",
  "fraseEjemploEspanol": "<traducción al español de la oración de ejemplo>",
  "respuestaHablada": "<explicación breve y amigable en español de 1 oración para síntesis de voz, ej: 'Lápiz se dice pencil y se pronuncia pén-sil.'>"
}
''';

      final payload = <String, dynamic>{
        'contents': [
          {
            'parts': [
              {'text': promptText},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 800, // Evita truncamiento del JSON pedagógico
          'responseMimeType': 'application/json',
        },
      };

      final rawText = await _generarContenidoHttp(
        payload: payload,
        apiKey: key,
      );

      return parseVoiceJsonResponse(rawText, query, intent: intencion);
    } on SocketException catch (e) {
      print('[GEMINI ERROR DETALLADO]: Conexión fallida: $e');
      debugPrint('ERROR REAL GEMINI: Conexión fallida: $e');
      return GeminiVoiceResult.error(
        query: query,
        message: 'SocketException (sin conexión a internet): $e',
        intent: intencion,
      );
    } catch (e) {
      print('[GEMINI ERROR DETALLADO]: ${e.toString()}');
      debugPrint('>>> [AIRSIGHT TUTOR ERROR]: $e');
      return GeminiVoiceResult.error(
        query: query,
        message: e.toString(),
        intent: intencion,
      );
    }
  }

  /// Procesa y deserializa la respuesta del Tutor de Voz con Gemini.
  /// Cumple estrictamente con el estándar IEEE 830 v3.2 (RF-11 y Apéndice B.5.2),
  /// soportando tanto la nomenclatura canónica del apéndice como claves legadas y fallbacks por Regex.
  static GeminiVoiceResult parseVoiceJsonResponse(
    String rawText,
    String query, {
    VoiceQueryIntent? intent,
  }) {
    final effectiveIntent = intent ?? detectarIntencion(query);

    if (rawText.trim().isEmpty) {
      return GeminiVoiceResult.error(
        query: query,
        message: 'No se recibió respuesta del asistente de voz de Gemini.',
        intent: effectiveIntent,
      );
    }

    final jsonMap = _parseJsonResponse(rawText);
    final bool exito = (jsonMap['exito'] == true) ||
        (jsonMap['success'] == true && jsonMap['exito'] != false) ||
        (jsonMap['terminoConsultado'] != null || jsonMap['traduccionIngles'] != null);

    if (!exito) {
      final errorMsg = (jsonMap['mensaje'] as String? ??
              jsonMap['error'] as String? ??
              mensajeContingenciaPalabraUnica)
          .trim();
      return GeminiVoiceResult.error(
        query: query,
        message: errorMsg,
        intent: effectiveIntent,
      );
    }

    final rawTermino = (jsonMap['terminoConsultado'] as String? ?? '').trim();
    final rawTraduccion = (jsonMap['traduccionIngles'] as String? ??
            jsonMap['translation'] as String? ??
            '')
        .trim();
    final rawTerm = (jsonMap['term'] as String? ?? '').trim();

    String termEn;
    String translationEs;

    if (rawTerm.isNotEmpty) {
      termEn = rawTerm;
      translationEs = rawTraduccion.isNotEmpty ? rawTraduccion : rawTermino;
    } else if (rawTraduccion.isNotEmpty && rawTermino.isNotEmpty) {
      termEn = rawTraduccion;
      translationEs = rawTermino;
    } else {
      termEn = rawTraduccion.isNotEmpty
          ? rawTraduccion
          : (rawTermino.isNotEmpty ? rawTermino : query);
      translationEs = rawTermino.isNotEmpty ? rawTermino : termEn;
    }

    final phonetic = (jsonMap['fonetica'] as String? ??
            jsonMap['phonetic'] as String? ??
            '')
        .trim();
    final exampleEn = (jsonMap['fraseEjemploIngles'] as String? ??
            jsonMap['exampleEn'] as String? ??
            '')
        .trim();
    final exampleEs = (jsonMap['fraseEjemploEspanol'] as String? ??
            jsonMap['exampleEs'] as String? ??
            '')
        .trim();
    final explanation = (jsonMap['respuestaHablada'] as String? ??
            jsonMap['respuesta'] as String? ??
            jsonMap['explanation'] as String? ??
            '')
        .trim();

    return GeminiVoiceResult.success(
      query: query,
      wordOrTerm: termEn,
      translation: translationEs.isNotEmpty ? translationEs : termEn,
      phonetic: phonetic.isNotEmpty ? phonetic : '/$termEn/',
      exampleEn: exampleEn.isNotEmpty ? exampleEn : 'This is $termEn.',
      exampleEs: exampleEs.isNotEmpty ? exampleEs : 'Esto es $translationEs.',
      explanation: explanation.isNotEmpty
          ? explanation
          : '$termEn significa $translationEs.',
      intent: effectiveIntent,
    );
  }

  /// Limpia y decodifica respuestas JSON que puedan venir dentro de bloques markdown ```json ... ```
  /// o sufrir de truncamiento ('FormatException: Unterminated string') aplicando fallback defensivo por Regex.
  static Map<String, dynamic> _parseJsonResponse(String raw) {
    // 1. Limpieza de bloques markdown
    String rawText = raw.replaceAll(RegExp(r'```json|```'), '').trim();
    rawText = extractCleanJson(rawText);

    if (rawText.isEmpty) {
      return {'error': 'Cadena JSON vacía tras limpieza', 'exito': false};
    }

    try {
      final decoded = jsonDecode(rawText);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'error': 'Formato inesperado: el JSON decodificado no es un Map', 'exito': false};
    } catch (e, stacktrace) {
      debugPrint('>>> [JSON ERROR RAW]: $rawText');
      debugPrint('>>> [JSON ERROR]: $e');
      debugPrint('>>> [STACKTRACE]: $stacktrace');

      // FALLBACK DE EMERGENCIA: Si el JSON viene incompleto (Unterminated string)
      // o con saltos de línea internos sin escapar, extrae los datos clave mediante regex.
      final fallbackMap = <String, dynamic>{
        'recuperadoPorRegex': true,
      };

      final exitoVal = extractRegex(rawText, 'exito');
      if (exitoVal != null) {
        fallbackMap['exito'] = exitoVal.toLowerCase() == 'true';
      }

      final term = extractRegex(rawText, 'terminoConsultado') ??
          extractRegex(rawText, 'term') ??
          extractRegex(rawText, 'wordEn') ??
          extractRegex(rawText, 'palabraIngles');
      if (term != null) fallbackMap['terminoConsultado'] = term;

      final trad = extractRegex(rawText, 'traduccionIngles') ??
          extractRegex(rawText, 'translation') ??
          extractRegex(rawText, 'wordEs') ??
          extractRegex(rawText, 'traduccionEspanol');
      if (trad != null) fallbackMap['traduccionIngles'] = trad;

      final fon = extractRegex(rawText, 'fonetica') ?? extractRegex(rawText, 'phonetic');
      if (fon != null) fallbackMap['fonetica'] = fon;

      final fraseEn = extractRegex(rawText, 'fraseEjemploIngles') ??
          extractRegex(rawText, 'exampleEn') ??
          extractRegex(rawText, 'exampleSentence');
      if (fraseEn != null) fallbackMap['fraseEjemploIngles'] = fraseEn;

      final fraseEs = extractRegex(rawText, 'fraseEjemploEspanol') ??
          extractRegex(rawText, 'exampleEs') ??
          extractRegex(rawText, 'exampleSentenceEs');
      if (fraseEs != null) fallbackMap['fraseEjemploEspanol'] = fraseEs;

      final resp = extractRegex(rawText, 'respuestaHablada') ??
          extractRegex(rawText, 'respuesta') ??
          extractRegex(rawText, 'explanation');
      if (resp != null) fallbackMap['respuestaHablada'] = resp;

      final mensaje = extractRegex(rawText, 'mensaje') ?? extractRegex(rawText, 'error');
      if (mensaje != null) fallbackMap['mensaje'] = mensaje;

      final conf = extractRegex(rawText, 'confidence');
      if (conf != null) fallbackMap['confidence'] = double.tryParse(conf);

      final cat = extractRegex(rawText, 'categoria') ?? extractRegex(rawText, 'category');
      if (cat != null) fallbackMap['categoria'] = cat;

      // Si se logró extraer término o traducción, habilitamos exito para evitar que la UI colapse
      if (term != null || trad != null) {
        fallbackMap['exito'] = true;
      }

      if (fallbackMap.containsKey('exito') || fallbackMap.containsKey('mensaje')) {
        debugPrint('>>> [FALLBACK REGEX EXITOSO]: $fallbackMap');
        return fallbackMap;
      }

      return {'error': 'FormatException al decodificar JSON: $e', 'exito': false};
    }
  }

  static String _formatErrorMessage(dynamic error) {
    final str = error.toString();
    return str.replaceAll(RegExp(r'Exception: '), '');
  }
}
