import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:air_sight/config/api_config.dart';
import 'package:air_sight/services/gemini_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas de GeminiService - Configuración y Singleton', () {
    test('GeminiService implementa Singleton y configuración de modelo', () {
      final s1 = GeminiService();
      final s2 = GeminiService.instance;

      expect(identical(s1, s2), isTrue);
      expect(s1.modelName, equals('gemini-3.8-flash'));

      s1.setModelName('test-model-custom');
      expect(s1.modelName, equals('test-model-custom'));
      s1.setModelName('gemini-3.8-flash'); // Restaurar
    });

    test('modelosCandidatos define lista de alta disponibilidad para failover', () {
      expect(GeminiService.modelosCandidatos, contains('gemini-3.8-flash'));
      expect(GeminiService.modelosCandidatos, contains('gemini-2.5-flash'));
      expect(GeminiService.modelosCandidatos, contains('gemini-2.0-flash'));
      expect(GeminiService.modelosCandidatos, contains('gemini-1.5-flash'));
      expect(GeminiService.modelosCandidatos, contains('gemini-1.5-flash-8b'));
    });

    test('Consumo transparente de ApiConfig y override en memoria para tests', () {
      final service = GeminiService.instance;

      // Por defecto lee ApiConfig.geminiApiKey
      service.setApiKey('');
      expect(service.activeApiKey, equals(ApiConfig.geminiApiKey));

      // Sobrescritura en memoria para testing
      service.setApiKey('AIzaSyCustomKeyOverride');
      expect(service.activeApiKey, equals('AIzaSyCustomKeyOverride'));

      // Limpiar override
      service.setApiKey('');
    });
  });

  group('Pruebas de Flujo 1: Cámara (Restringido a Objetos A1)', () {
    test('identificarObjeto valida bytes vacíos de imagen', () async {
      final service = GeminiService.instance;
      service.setApiKey('AIzaSyTestKey');

      final result = await service.identificarObjeto(Uint8List(0));
      expect(result.isRecognized, isFalse);
      expect(result.errorMessage, contains('vacía'));

      service.setApiKey('');
    });

    test('identificarObjeto retorna error amigable cuando la clave no está configurada', () async {
      final service = GeminiService.instance;
      service.setApiKey('TU_API_KEY_AQUI');

      final dummyBytes = Uint8List.fromList([1, 2, 3, 4]);
      final result = await service.identificarObjeto(dummyBytes);

      expect(result.isRecognized, isFalse);
      expect(result.errorMessage, equals('Servicio no disponible temporalmente.'));

      service.setApiKey('');
    });

    test('identificarObjetoA1 valida bytes vacíos de imagen', () async {
      final service = GeminiService.instance;
      service.setApiKey('AIzaSyTestKey');

      final result = await service.identificarObjetoA1(Uint8List(0));
      expect(result['exito'], isFalse);
      expect(result['mensaje'], contains('vacía'));

      service.setApiKey('');
    });

    test('identificarObjetoA1 retorna error amigable cuando la clave no está configurada', () async {
      final service = GeminiService.instance;
      service.setApiKey('TU_API_KEY_AQUI');

      final dummyBytes = Uint8List.fromList([1, 2, 3, 4]);
      final result = await service.identificarObjetoA1(dummyBytes);

      expect(result['exito'], isFalse);
      expect(result['mensaje'], equals('Servicio no disponible temporalmente.'));

      service.setApiKey('');
    });

    test('GeminiObjectResult modela éxito y error controlado conforme a especificación A1', () {
      final success = GeminiObjectResult.success(
        wordEn: 'chair',
        wordEs: 'silla',
        exampleSentence: 'The chair is comfortable.',
        exampleSentenceEs: 'La silla es cómoda.',
        category: 'Classroom',
      );

      expect(success.isRecognized, isTrue);
      expect(success.wordEn, equals('chair'));
      expect(success.wordEs, equals('silla'));
      expect(success.exampleSentence, equals('The chair is comfortable.'));
      expect(success.exampleEn, equals('The chair is comfortable.'));
      expect(success.exampleEs, equals('La silla es cómoda.'));
      expect(success.category, equals('Classroom'));

      final controlledError = GeminiObjectResult.error(
        'Objeto no reconocido o no disponible en el glosario A1',
      );

      expect(controlledError.isRecognized, isFalse);
      expect(
        controlledError.errorMessage,
        equals('Objeto no reconocido o no disponible en el glosario A1'),
      );
    });

    test('RF-03: Descarta objetos con confidence score menor a 0.70', () {
      expect(
        GeminiService.validarDeteccionRF03(etiqueta: 'laptop', confidence: 0.69),
        equals('Objeto no reconocido o no disponible en el glosario A1'),
      );
      expect(
        GeminiService.validarDeteccionRF03(etiqueta: 'chair', confidence: 0.50),
        equals('Objeto no reconocido o no disponible en el glosario A1'),
      );

      final resJsonBajo = GeminiService.parseObjectJsonResponse('''
      {
        "exito": true,
        "confidence": 0.65,
        "palabraIngles": "laptop",
        "traduccionEspanol": "computador portátil"
      }
      ''');
      expect(resJsonBajo['exito'], isFalse);
      expect(
        resJsonBajo['mensaje'],
        equals('Objeto no reconocido o no disponible en el glosario A1'),
      );
    });

    test('RF-03: Valida etiqueta contra el catálogo A1 y rechaza objetos fuera del glosario', () {
      expect(
        GeminiService.validarDeteccionRF03(etiqueta: 'helicopter', confidence: 0.95),
        equals('Objeto no reconocido o no disponible en el glosario A1'),
      );
      expect(
        GeminiService.validarDeteccionRF03(etiqueta: 'microscope', confidence: 0.88),
        equals('Objeto no reconocido o no disponible en el glosario A1'),
      );

      final resFueraCatalogo = GeminiService.parseObjectJsonResponse('''
      {
        "exito": true,
        "confidence": 0.92,
        "palabraIngles": "helicopter",
        "traduccionEspanol": "helicóptero"
      }
      ''');
      expect(resFueraCatalogo['exito'], isFalse);
      expect(
        resFueraCatalogo['mensaje'],
        equals('Objeto no reconocido o no disponible en el glosario A1'),
      );
    });

    test('RF-03: Acepta objetos con confidence >= 0.70 cuya etiqueta pertenece al catálogo A1', () {
      expect(
        GeminiService.validarDeteccionRF03(etiqueta: 'laptop', confidence: 0.70),
        equals('laptop'),
      );
      expect(
        GeminiService.validarDeteccionRF03(etiqueta: 'chair', confidence: 0.95),
        equals('chair'),
      );

      final resValido = GeminiService.parseObjectJsonResponse('''
      {
        "exito": true,
        "confidence": 0.85,
        "palabraIngles": "backpack",
        "traduccionEspanol": "morral",
        "categoria": "Objects",
        "fraseIngles": "The backpack is heavy.",
        "fraseEspanol": "El morral es pesado."
      }
      ''');
      expect(resValido['exito'], isTrue);
      expect(resValido['palabraIngles'], equals('backpack'));
      expect(resValido['confidence'], equals(0.85));
    });
  });

  group('Pruebas de Flujo 2: Búsqueda por Voz (Abierto con Lenguaje Natural)', () {
    test('consultarPorVoz valida consulta vacía', () async {
      final service = GeminiService.instance;
      service.setApiKey('AIzaSyTestKey');

      final result = await service.consultarPorVoz('   ');
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('No se detectó audio'));

      service.setApiKey('');
    });

    test('consultarPorVoz retorna error descriptivo cuando la clave no está configurada', () async {
      final service = GeminiService.instance;
      service.setApiKey('TU_API_KEY_AQUI');

      final result = await service.consultarPorVoz('¿Cómo se dice mariposa en inglés?');
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('ApiKey de Gemini no configurada'));

      service.setApiKey('');
    });

    test('validarConsultaPalabraIndividual extrae término y valida palabras individuales (RF-11)', () {
      // 1. Patrón común "¿Cómo se dice [X] en inglés?"
      final v1 = GeminiService.validarConsultaPalabraIndividual('Cómo se dice manzana en inglés');
      expect(v1.esValida, isTrue);
      expect(v1.palabraExtraida, equals('manzana'));

      // 2. Con signos interrogativos y artículo
      final v2 = GeminiService.validarConsultaPalabraIndividual('¿Cómo se dice el lápiz en inglés?');
      expect(v2.esValida, isTrue);
      expect(v2.palabraExtraida, equals('lápiz'));

      // 3. Palabra única directa
      final v3 = GeminiService.validarConsultaPalabraIndividual('manzana');
      expect(v3.esValida, isTrue);
      expect(v3.palabraExtraida, equals('manzana'));

      // 4. Consulta de significado
      final v4 = GeminiService.validarConsultaPalabraIndividual('¿Qué significa computer?');
      expect(v4.esValida, isTrue);
      expect(v4.palabraExtraida, equals('computer'));

      // 5. Oración completa - Rechazo inmediato local sin llamada a la API
      final v5 = GeminiService.validarConsultaPalabraIndividual('yo quiero comprar pan en la tienda');
      expect(v5.esValida, isFalse);
      expect(v5.mensajeError, equals(GeminiService.mensajeContingenciaPalabraUnica));

      // 6. Frase larga dentro de plantilla
      final v6 = GeminiService.validarConsultaPalabraIndividual('¿Cómo se dice yo quiero ir a la casa de mi amigo en inglés?');
      expect(v6.esValida, isFalse);
      expect(v6.mensajeError, equals(GeminiService.mensajeContingenciaPalabraUnica));
    });

    test('consultarPorVoz rechaza oraciones compuestas localmente sin consumir API', () async {
      final service = GeminiService.instance;
      // Clave ficticia, no debe alcanzarse la API
      service.setApiKey('AIzaSyDummyKey');

      final result = await service.consultarPorVoz('yo quiero comprar pan en la tienda');
      expect(result.success, isFalse);
      expect(result.errorMessage, equals(GeminiService.mensajeContingenciaPalabraUnica));

      service.setApiKey('');
    });

    test('GeminiVoiceResult modela traducción abierta, fonética y frase de ejemplo', () {
      final voiceResult = GeminiVoiceResult.success(
        query: 'mariposa',
        wordOrTerm: 'butterfly',
        translation: 'mariposa',
        phonetic: '/ˈbʌt.ə.flaɪ/',
        exampleEn: 'The butterfly has blue wings.',
        exampleEs: 'La mariposa tiene alas azules.',
        explanation: 'Butterfly significa mariposa en español.',
      );

      expect(voiceResult.success, isTrue);
      expect(voiceResult.wordOrTerm, equals('butterfly'));
      expect(voiceResult.term, equals('butterfly'));
      expect(voiceResult.translation, equals('mariposa'));
      expect(voiceResult.phonetic, equals('/ˈbʌt.ə.flaɪ/'));
      expect(voiceResult.exampleEn, equals('The butterfly has blue wings.'));
      expect(voiceResult.exampleEs, equals('La mariposa tiene alas azules.'));
      expect(voiceResult.explanation, contains('Butterfly significa mariposa'));
    });

    test('parseVoiceJsonResponse procesa formato canónico de Apéndice B.5.2 para palabra válida', () {
      const jsonText = '''
{
  "exito": true,
  "terminoConsultado": "lápiz",
  "traduccionIngles": "pencil",
  "fonetica": "pén-sil",
  "fraseEjemploIngles": "I write with my pencil.",
  "fraseEjemploEspanol": "Yo escribo con mi lápiz.",
  "respuestaHablada": "Lápiz se dice pencil. Por ejemplo: I write with my pencil, que significa: Yo escribo con mi lápiz."
}
''';

      final result = GeminiService.parseVoiceJsonResponse(jsonText, '¿Cómo se dice lápiz?');
      expect(result.success, isTrue);
      expect(result.wordOrTerm, equals('pencil'));
      expect(result.translation, equals('lápiz'));
      expect(result.phonetic, equals('pén-sil'));
      expect(result.exampleEn, equals('I write with my pencil.'));
      expect(result.exampleEs, equals('Yo escribo con mi lápiz.'));
      expect(result.explanation, contains('Lápiz se dice pencil'));
    });

    test('parseVoiceJsonResponse maneja rechazo de frases complejas con mensaje estricto RF-11.e', () {
      const jsonErrorText = '''
{
  "exito": false,
  "mensaje": "Por favor consulta únicamente una palabra a la vez para tu práctica de vocabulario."
}
''';

      final result = GeminiService.parseVoiceJsonResponse(
        jsonErrorText,
        '¿Cómo se dice yo quiero ir a la casa de mi amigo?',
      );
      expect(result.success, isFalse);
      expect(result.errorMessage, equals(GeminiService.mensajeContingenciaPalabraUnica));
      expect(
        result.errorMessage,
        equals('Por favor consulta únicamente una palabra a la vez para tu práctica de vocabulario.'),
      );
    });
  });

  group('Pruebas de Utilidades y Parseo Robusto de JSON en GeminiService', () {
    test('GeminiFlashApiService expone credenciales y endpoint oficial validado', () {
      expect(GeminiFlashApiService.instance, isA<GeminiService>());
      expect(identical(GeminiFlashApiService.instance, GeminiService.instance), isTrue);
      expect(GeminiFlashApiService.apiKey, equals('FAKE_TEST_API_KEY'));
      expect(GeminiFlashApiService.modelName, equals('gemini-3.8-flash'));
      expect(
        GeminiFlashApiService.baseUrl,
        equals('https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent'),
      );
    });

    test('extractCleanJson remueve bloques markdown ```json y texto circundante', () {
      const markdownJson = '''
```json
{
  "exito": true,
  "palabraIngles": "book",
  "traduccionEspanol": "libro"
}
```
''';
      final clean = GeminiService.extractCleanJson(markdownJson);
      expect(clean.startsWith('{'), isTrue);
      expect(clean.endsWith('}'), isTrue);
      expect(clean, contains('"palabraIngles": "book"'));
    });

    test('extractCleanJson procesa respuestas con texto previo y posterior al JSON', () {
      const noisyText = 'Aquí tienes el resultado solicitado:\n{"exito": true, "palabra": "pen"}\nEspero te sirva.';
      final clean = GeminiService.extractCleanJson(noisyText);
      expect(clean, equals('{"exito": true, "palabra": "pen"}'));
    });

    test('parseVoiceJsonResponse procesa JSON encapsulado en markdown ```json ... ```', () {
      const markdownVoiceJson = '''
```json
{
  "exito": true,
  "terminoConsultado": "reloj",
  "traduccionIngles": "clock",
  "fonetica": "klɒk",
  "fraseEjemploIngles": "The clock is on the wall.",
  "fraseEjemploEspanol": "El reloj está en la pared.",
  "respuestaHablada": "Reloj se dice clock y se pronuncia klɒk."
}
```
''';
      final result = GeminiService.parseVoiceJsonResponse(markdownVoiceJson, '¿Cómo se dice reloj?');
      expect(result.success, isTrue);
      expect(result.wordOrTerm, equals('clock'));
      expect(result.translation, equals('reloj'));
      expect(result.explanation, contains('clock'));
    });

    test('parseVoiceJsonResponse maneja fallback ante FormatException: Unterminated string', () {
      // Simulación del error capturado: se corta justo en "respuesta" sin cerrar comillas ni llaves
      const truncatedJson = '''
{
  "exito": true,
  "terminoConsultado": "lápiz",
  "traduccionIngles": "pencil",
  "fonetica": "pén-sil",
  "fraseEjemploIngles": "I write with a pencil.",
  "fraseEjemploEspanol": "Escribo con un lápiz.",
  "respuestaHablada": "Lápiz se dice pencil y se pronuncia
''';
      final result = GeminiService.parseVoiceJsonResponse(truncatedJson, '¿Cómo se dice lápiz?');
      expect(result.success, isTrue);
      expect(result.wordOrTerm, equals('pencil'));
      expect(result.translation, equals('lápiz'));
      expect(result.phonetic, equals('pén-sil'));
      expect(result.exampleEn, equals('I write with a pencil.'));
      expect(result.exampleEs, equals('Escribo con un lápiz.'));
      expect(result.explanation, isNotEmpty);
    });

    test('extractRegex extrae claves en cadenas JSON truncadas', () {
      const broken = '{"terminoConsultado": "apple", "traduccionIngles": "manzana", "respuesta": "Manzana se dice';
      expect(GeminiService.extractRegex(broken, 'terminoConsultado'), equals('apple'));
      expect(GeminiService.extractRegex(broken, 'traduccionIngles'), equals('manzana'));
      expect(GeminiService.extractRegex(broken, 'respuesta'), contains('Manzana se dice'));
    });
  });
}
