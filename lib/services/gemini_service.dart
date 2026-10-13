// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Resultado estructurado de la inferencia visual de objetos A1 con Gemini Flash.
class GeminiObjectResult {
  final bool isRecognized;
  final String? wordEn;
  final String? wordEs;
  final String? exampleSentence;
  final String? exampleSentenceEs;
  final String? category;
  final String? errorMessage;

  const GeminiObjectResult({
    required this.isRecognized,
    this.wordEn,
    this.wordEs,
    this.exampleSentence,
    this.exampleSentenceEs,
    this.category,
    this.errorMessage,
  });

  /// Alias de compatibilidad para el ejemplo en inglés
  String? get example => exampleSentence;
  String? get exampleEn => exampleSentence;
  String? get exampleEs => exampleSentenceEs;

  factory GeminiObjectResult.error(String message) => GeminiObjectResult(
        isRecognized: false,
        errorMessage: message,
      );

  factory GeminiObjectResult.success({
    required String wordEn,
    required String wordEs,
    required String exampleSentence,
    String? exampleSentenceEs,
    String? category,
  }) =>
      GeminiObjectResult(
        isRecognized: true,
        wordEn: wordEn,
        wordEs: wordEs,
        exampleSentence: exampleSentence,
        exampleSentenceEs: exampleSentenceEs,
        category: category,
      );

  Map<String, dynamic> toMap() {
    return {
      'isRecognized': isRecognized,
      'wordEn': wordEn,
      'wordEs': wordEs,
      'exampleSentence': exampleSentence,
      'exampleSentenceEs': exampleSentenceEs,
      'category': category,
      'errorMessage': errorMessage,
    };
  }
}

/// Resultado estructurado del asistente lingüístico de búsqueda por voz con Gemini Flash.
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
  });

  /// Alias de compatibilidad
  String? get term => wordOrTerm;
  String? get example => exampleEn;

  factory GeminiVoiceResult.error({
    required String query,
    required String message,
  }) =>
      GeminiVoiceResult(
        success: false,
        query: query,
        errorMessage: message,
      );

  factory GeminiVoiceResult.success({
    required String query,
    required String wordOrTerm,
    required String translation,
    required String phonetic,
    required String exampleEn,
    required String exampleEs,
    String? explanation,
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

/// Servicio de integración oficial con Gemini Flash (Google AI Studio) usando `google_generative_ai`.
/// Maneja dos flujos diferenciados de manera 100% transparente y accesible:
/// 1. Cámara (Restringido): Inferencia visual limitada al catálogo controlado A1 de objetos cotidianos.
/// 2. Búsqueda por Voz (Abierto): Asistente de traducción que responde a consultas en lenguaje natural.
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  static GeminiService get instance => _instance;

  static const String defaultModel = 'gemini-flash-lite-latest';

  /// Lista de modelos de alta disponibilidad ordenada por estabilidad y menor congestión (evita 503)
  static const List<String> modelosCandidatos = [
    'gemini-flash-lite-latest',
    'gemini-3.5-flash-lite',
    'gemini-flash-latest',
    'gemini-3.8-flash',
    'gemini-2.5-flash',
    'gemini-2.0-flash-lite',
    'gemini-1.5-flash-8b',
  ];

  /// Alias de compatibilidad hacia la lista de modelos
  static List<String> get modelosDisponibles => modelosCandidatos;

  /// Mensaje de contingencia estricto según IEEE 830 v3.2 (RF-11.e y Apéndice B.5.2)
  static const String mensajeContingenciaPalabraUnica =
      'Por favor consulta únicamente una palabra a la vez para tu práctica de vocabulario.';

  /// Valida la consulta de voz localmente según RF-11 antes de llamar a Gemini:
  /// - Si contiene consultas tipo "¿Cómo se dice [X] en inglés?", extrae [X].
  /// - Si el usuario dicta una oración completa o más de dos palabras sustantivas (ej: "yo quiero comprar pan en la tienda"),
  ///   NO envía la petición a la API y retorna inmediatamente el mensaje de contingencia.
  /// - Si la entrada es una palabra única (ej: "manzana", "lápiz"), retorna válida para inferencia.
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
    return ApiConfig.geminiApiKey;
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

  /// Inferencia con tolerancia a fallos, congestión y rotación automática de modelos (Failover).
  /// Si un modelo arroja error 503 ("high demand" / "UNAVAILABLE"), 404 o indisponibilidad:
  /// Captura el error en debugPrint e intenta inmediatamente con el siguiente modelo de la lista (hasta 3 intentos).
  /// Al tener éxito, memoriza el modelo activo para las siguientes llamadas de la sesión.
  Future<GenerateContentResponse> _generarContenido({
    required List<Content> content,
    required String apiKey,
    GenerationConfig? generationConfig,
  }) async {
    final candidatos = <String>[
      _modelName,
      ...modelosCandidatos.where((m) => m != _modelName),
    ];

    const int maxIntentos = 3;
    final int limite = candidatos.length > maxIntentos ? maxIntentos : candidatos.length;

    dynamic ultimoError;

    for (int i = 0; i < limite; i++) {
      final modelo = candidatos[i];

      // Hasta 2 intentos por modelo si se recibe un 503 temporal (esperando 1.5s)
      for (int subIntento = 0; subIntento < 2; subIntento++) {
        try {
          debugPrint(
            '[GEMINI] Intento ${i + 1}/$limite (subintento ${subIntento + 1}/2) con modelo: $modelo',
          );
          final model = GenerativeModel(
            model: modelo,
            apiKey: apiKey,
            generationConfig: generationConfig,
          );
          final response = await model.generateContent(content);

          // Si tuvo éxito y fue un modelo diferente, memorizarlo para la sesión
          if (_modelName != modelo) {
            debugPrint(
              '[GEMINI FAILOVER] ¡Éxito con modelo alternativo! Estableciendo como predeterminado: $modelo',
            );
            _modelName = modelo;
          }
          return response;
        } catch (e) {
          ultimoError = e;
          final errorStr = e.toString().toLowerCase();

          final es503 = errorStr.contains('503') ||
              errorStr.contains('high demand') ||
              errorStr.contains('unavailable');

          // Manejo de saturación 503: espera 1.5s y realiza reintento inmediato en el mismo modelo
          if (es503 && subIntento == 0) {
            debugPrint(
              '[GEMINI] Modelo "$modelo" reportó alta demanda temporal (503). Esperando 1.5s antes del reintento inmediato...',
            );
            await Future.delayed(const Duration(milliseconds: 1500));
            continue;
          }

          final esRotable = es503 ||
              errorStr.contains('404') ||
              errorStr.contains('not found') ||
              errorStr.contains('not supported');

          if (esRotable && (i + 1 < limite)) {
            debugPrint(
              '[GEMINI FAILOVER] Modelo "$modelo" persistió no disponible ($e). '
              'Rotando inmediatamente al siguiente modelo candidato: ${candidatos[i + 1]}...',
            );
            break; // Sale del bucle de subintentos para rotar al siguiente candidato
          }

          rethrow;
        }
      }
    }

    throw ultimoError ?? Exception('Ningún modelo candidato pudo procesar la solicitud tras $limite intentos.');
  }

  /// Diagnóstico automático: Descubre por código la lista exacta de modelos activos en Google AI Studio (ListModels)
  /// que admiten el método 'generateContent' con nuestra API Key.
  Future<List<String>> inspeccionarModelosDisponibles() async {
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
      final response = await _generarContenido(
        content: [Content.text('Test')],
        apiKey: key,
      );
      print('[GEMINI TEST EXITOSO con modelo $_modelName]: ${response.text}');
      return true;
    } catch (e) {
      print('[GEMINI TEST FALLIDO]: $e');
      print('[GEMINI ERROR DETALLADO]: ${e.toString()}');
      return false;
    }
  }

  /// Inferencia visual restringida: Identifica si la imagen contiene un objeto cotidiano
  /// que pertenezca estrictamente al nivel A1 de inglés.
  /// Si no es reconocido o no pertenece al catálogo A1, devuelve el mensaje de error controlado:
  /// "Objeto no reconocido o no disponible en el glosario A1".
  Future<GeminiObjectResult> identificarObjeto(
    Uint8List imageBytes, {
    String? apiKey,
    String? mimeType,
  }) async {
    if (imageBytes.isEmpty) {
      return GeminiObjectResult.error('La imagen capturada está vacía.');
    }

    final key = apiKey ?? activeApiKey;
    print('[GEMINI KEY CHECK]: ${key.length > 6 ? key.substring(0, 6) + "..." : key}');
    if (key.isEmpty || key == 'TU_API_KEY_AQUI') {
      print('[GEMINI ERROR DETALLADO]: ApiConfig.geminiApiKey está vacía o tiene el valor por defecto ("TU_API_KEY_AQUI").');
      debugPrint('ERROR REAL GEMINI: ApiConfig.geminiApiKey está vacía o tiene el valor por defecto ("TU_API_KEY_AQUI"). Configura tu clave en lib/config/api_config.dart o con --dart-define=GEMINI_API_KEY=...');
      return GeminiObjectResult.error('Servicio no disponible temporalmente.');
    }

    try {
      const promptText = '''
Eres un tutor de inglés y clasificador visual para estudiantes principiantes de nivel A1 en la aplicación educativa Air Sight.

OBJETIVO:
Analiza la imagen recibida e identifica el objeto cotidiano principal visible.

REGLA ESTRICTA DE VOCABULARIO A1:
Solo debes reconocer el objeto SI Y SOLO SI corresponde a un objeto cotidiano elemental de nivel A1 para principiantes.
Los objetos cotidianos válidos son de uso diario común, tales como:
- Salón de clase y estudio: bag, board, book, chair, desk, eraser, marker, notebook, pen, pencil, ruler, table, classroom, computer, laptop.
- Casa y cocina: bed, clock, door, lamp, mirror, window, cup, fork, glass, plate, spoon, sofa, key.
- Comida y frutas: apple, banana, bread, cheese, egg, milk, orange, rice, water.
- Animales comunes: bird, cat, cow, dog, duck, fish, horse, lion, mouse, pig, rabbit, turtle.
- Ropa y accesorios: boots, cap, dress, jacket, pants, shirt, shoes, skirt, socks, t-shirt.
- Transporte y naturaleza: bicycle, bus, car, boat, train, airplane, tree, flower, sun, star.
- Objetos personales elementales: watch, phone, bottle, hat.

REGLA DE EXCLUSIÓN:
Si la imagen:
1. No contiene ningún objeto reconocible o está vacía/borrosa.
2. Contiene objetos complejos, industriales, médicos, especializados, herramientas avanzadas o conceptos abstractos que NO pertenecen al vocabulario cotidiano básico de nivel A1.
3. No es un objeto básico para un estudiante principiante.
DEBES RETORNAR ESTRICTAMENTE:
{
  "recognized": false,
  "error": "Objeto no reconocido o no disponible en el glosario A1"
}

FORMATO DE ÉXITO (Si es un objeto cotidiano A1):
{
  "recognized": true,
  "wordEn": "<palabra en inglés en minúscula, ej: chair>",
  "wordEs": "<traducción principal en español, ej: silla>",
  "exampleSentence": "<frase corta y simple en inglés de nivel A1 usando la palabra, ej: The chair is brown.>",
  "exampleSentenceEs": "<traducción de la frase de ejemplo al español, ej: La silla es marrón.>",
  "category": "<categoría como Classroom, Home, Food, Animals, Clothes, etc.>"
}
''';

      final content = [
        Content.multi([
          TextPart(promptText),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      final response = await _generarContenido(
        content: content,
        apiKey: key,
        generationConfig: GenerationConfig(
          temperature: 0.1,
          maxOutputTokens: 120,
          responseMimeType: 'application/json',
        ),
      );
      final rawText = response.text;

      if (rawText == null || rawText.trim().isEmpty) {
        return GeminiObjectResult.error(
          'Objeto no reconocido o no disponible en el glosario A1',
        );
      }

      final jsonMap = _parseJsonResponse(rawText);
      final isRecognized = jsonMap['recognized'] == true;

      if (!isRecognized) {
        final errorMsg = (jsonMap['error'] as String?)?.isNotEmpty == true
            ? jsonMap['error'] as String
            : 'Objeto no reconocido o no disponible en el glosario A1';
        return GeminiObjectResult.error(errorMsg);
      }

      final wordEn = (jsonMap['wordEn'] as String? ?? '').trim().toLowerCase();
      final wordEs = (jsonMap['wordEs'] as String? ?? '').trim().toLowerCase();
      final exampleSentence = (jsonMap['exampleSentence'] as String? ?? '').trim();
      final exampleSentenceEs = (jsonMap['exampleSentenceEs'] as String? ?? '').trim();
      final category = (jsonMap['category'] as String? ?? 'Objetos cotidianos').trim();

      if (wordEn.isEmpty || wordEs.isEmpty) {
        return GeminiObjectResult.error(
          'Objeto no reconocido o no disponible en el glosario A1',
        );
      }

      return GeminiObjectResult.success(
        wordEn: wordEn,
        wordEs: wordEs,
        exampleSentence: exampleSentence.isNotEmpty
            ? exampleSentence
            : 'This is a $wordEn.',
        exampleSentenceEs: exampleSentenceEs.isNotEmpty
            ? exampleSentenceEs
            : 'Esto es un/a $wordEs.',
        category: category,
      );
    } on SocketException catch (e) {
      print('[GEMINI ERROR DETALLADO]: Conexión fallida: $e');
      debugPrint('ERROR REAL GEMINI: Conexión fallida: $e');
      return GeminiObjectResult.error(
        'Sin conexión a internet. Verifica tu conexión de red.',
      );
    } catch (e) {
      print('[GEMINI ERROR DETALLADO]: ${e.toString()}');
      debugPrint('ERROR REAL GEMINI: $e');
      final msg = _formatErrorMessage(e);
      if (msg.contains('SocketException') || msg.contains('Failed host lookup')) {
        return GeminiObjectResult.error('Sin conexión a internet. Verifica tu conexión de red.');
      }
      if (msg.contains('API_KEY_INVALID') || msg.contains('403') || msg.contains('401')) {
        return GeminiObjectResult.error('Servicio no disponible temporalmente.');
      }
      return GeminiObjectResult.error(
        'Objeto no reconocido o no disponible en el glosario A1',
      );
    }
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
    // Extrae [X] si viene envuelto en consultas tipo "¿Cómo se dice [X] en inglés?"
    // Si dicta una oración completa o más de dos palabras sustantivas, rechaza inmediatamente sin llamada a API.
    final validacion = validarConsultaPalabraIndividual(query);
    if (!validacion.esValida) {
      return GeminiVoiceResult.error(
        query: query,
        message: validacion.mensajeError ?? mensajeContingenciaPalabraUnica,
      );
    }

    final palabraAEnviar = validacion.palabraExtraida;

    final key = apiKey ?? activeApiKey;
    print('[GEMINI KEY CHECK]: ${key.length > 6 ? key.substring(0, 6) + "..." : key}');
    if (key.isEmpty || key == 'TU_API_KEY_AQUI') {
      print('[GEMINI ERROR DETALLADO]: ApiConfig.geminiApiKey está vacía o tiene el valor por defecto ("TU_API_KEY_AQUI").');
      debugPrint('ERROR REAL GEMINI: ApiConfig.geminiApiKey está vacía o tiene el valor por defecto ("TU_API_KEY_AQUI"). Configura tu clave en lib/config/api_config.dart o con --dart-define=GEMINI_API_KEY=...');
      return GeminiVoiceResult.error(
        query: query,
        message: 'ApiKey de Gemini no configurada ("TU_API_KEY_AQUI"). Configura tu clave en lib/config/api_config.dart.',
      );
    }

    try {
      final promptText = '''
Eres el tutor lingüístico accesible de Air Sight para estudiantes universitarios con discapacidad visual que aprenden inglés nivel A1.
El estudiante realizó la siguiente consulta de vocabulario: "$palabraAEnviar"

Reglas estrictas de respuesta pedagógica (Nivel A1):
1. Traduce ÚNICAMENTE la palabra o concepto léxico individual indicado: "$palabraAEnviar".
2. Si el término excede una palabra individual, responde ÚNICAMENTE:
{
  "exito": false,
  "mensaje": "$mensajeContingenciaPalabraUnica"
}

3. Si la consulta corresponde a una palabra individual o término léxico simple, genera siempre una oración de ejemplo sencilla (nivel A1) y responde ÚNICAMENTE en este formato JSON:
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

      final response = await _generarContenido(
        content: [Content.text(promptText)],
        apiKey: key,
        generationConfig: GenerationConfig(
          temperature: 0.2,
          maxOutputTokens: 120, // Evita respuestas largas y reduce el tiempo a menos de 1 segundo
          responseMimeType: 'application/json',
        ),
      );
      String rawText = response.text ?? '';
      rawText = rawText.replaceAll('```json', '').replaceAll('```', '').trim();

      return parseVoiceJsonResponse(rawText, query);
    } on SocketException catch (e) {
      print('[GEMINI ERROR DETALLADO]: Conexión fallida: $e');
      debugPrint('ERROR REAL GEMINI: Conexión fallida: $e');
      return GeminiVoiceResult.error(
        query: query,
        message: 'SocketException (sin conexión a internet): $e',
      );
    } catch (e) {
      print('[GEMINI ERROR DETALLADO]: ${e.toString()}');
      debugPrint('ERROR REAL GEMINI: $e');
      return GeminiVoiceResult.error(
        query: query,
        message: e.toString(),
      );
    }
  }

  /// Procesa y deserializa la respuesta del Tutor de Voz con Gemini Flash.
  /// Cumple estrictamente con el estándar IEEE 830 v3.2 (RF-11 y Apéndice B.5.2),
  /// soportando tanto la nomenclatura canónica del apéndice como claves legadas.
  static GeminiVoiceResult parseVoiceJsonResponse(String rawText, String query) {
    if (rawText.trim().isEmpty) {
      return GeminiVoiceResult.error(
        query: query,
        message: 'No se recibió respuesta del asistente de voz de Gemini.',
      );
    }

    final jsonMap = _parseJsonResponse(rawText);
    final bool exito = (jsonMap['exito'] == true) ||
        (jsonMap['success'] == true && jsonMap['exito'] != false);

    if (!exito) {
      final errorMsg = (jsonMap['mensaje'] as String? ??
              jsonMap['error'] as String? ??
              mensajeContingenciaPalabraUnica)
          .trim();
      return GeminiVoiceResult.error(query: query, message: errorMsg);
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
    );
  }

  /// Limpia y decodifica respuestas JSON que puedan venir dentro de bloques markdown ```json ... ```
  static Map<String, dynamic> _parseJsonResponse(String raw) {
    String rawText = raw.replaceAll('```json', '').replaceAll('```', '').trim();
    final firstBrace = rawText.indexOf('{');
    final lastBrace = rawText.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace >= firstBrace) {
      rawText = rawText.substring(firstBrace, lastBrace + 1).trim();
    }

    try {
      final decoded = jsonDecode(rawText);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'error': 'Formato inesperado: el JSON decodificado no es un Map', 'exito': false};
    } catch (e) {
      return {'error': 'FormatException al decodificar JSON: $e (Texto: "$rawText")', 'exito': false};
    }
  }

  static String _formatErrorMessage(dynamic error) {
    final str = error.toString();
    return str.replaceAll(RegExp(r'Exception: '), '');
  }
}
