import 'package:flutter_test/flutter_test.dart';
import 'package:air_sight/services/gemini_service.dart';

void main() {
  group('HU-07 y RF-11: Pruebas del Filtro Léxico y Tutor por Voz', () {
    test('Filtro léxico rechaza consultas vacías o con sólo espacios', () {
      final resVacio = GeminiService.validarConsultaPalabraIndividual('');
      expect(resVacio.esValida, isFalse);
      expect(resVacio.mensajeError, contains('No se detectó audio'));

      final resEspacios = GeminiService.validarConsultaPalabraIndividual('   ');
      expect(resEspacios.esValida, isFalse);
      expect(resEspacios.mensajeError, contains('No se detectó audio'));
    });

    test('Filtro léxico rechaza oraciones complejas con múltiples palabras o frases (RF-11.e)', () {
      const frasesComplejas = [
        'yo quiero comprar pan en la tienda',
        'dime cómo llegar a la estación central de trenes',
        'esta es una oración demasiado larga para el tutor',
        'quiero aprender a hablar inglés fluido rápido',
        'por favor ayúdame a traducir este texto grande',
        'me gustaría saber qué hora es en este momento',
      ];

      for (final frase in frasesComplejas) {
        final res = GeminiService.validarConsultaPalabraIndividual(frase);
        expect(res.esValida, isFalse, reason: 'Debe rechazar la frase: "$frase"');
        expect(
          res.mensajeError,
          equals(GeminiService.mensajeContingenciaPalabraUnica),
          reason: 'El mensaje de error debe coincidir con la contingencia de palabra única',
        );
      }
    });

    test('Filtro léxico rechaza frases de 2 palabras que contienen verbos o conectores de oración', () {
      const frasesDosPalabras = [
        'yo quiero',
        'vamos comer',
        'tengo hambre',
        'es para',
        'en casa',
        'want buy',
      ];

      for (final frase in frasesDosPalabras) {
        final res = GeminiService.validarConsultaPalabraIndividual(frase);
        expect(res.esValida, isFalse, reason: 'Debe rechazar: "$frase"');
        expect(res.mensajeError, equals(GeminiService.mensajeContingenciaPalabraUnica));
      }
    });

    test('Filtro léxico acepta palabras individuales directas', () {
      final palabrasValidas = ['manzana', 'lápiz', 'cuaderno', 'perro', 'gato', 'door', 'table'];

      for (final palabra in palabrasValidas) {
        final res = GeminiService.validarConsultaPalabraIndividual(palabra);
        expect(res.esValida, isTrue, reason: 'Debe aceptar: "$palabra"');
        expect(res.palabraExtraida.toLowerCase(), equals(palabra.toLowerCase()));
        expect(res.mensajeError, isNull);
      }
    });

    test('Filtro léxico extrae el término clave desde patrones conversacionales de vocabulario A1', () {
      // 1. ¿Cómo se dice X en inglés?
      final r1 = GeminiService.validarConsultaPalabraIndividual('¿Cómo se dice lápiz en inglés?');
      expect(r1.esValida, isTrue);
      expect(r1.palabraExtraida, equals('lápiz'));

      // 2. Cómo se dice X (sin signos y sin 'en inglés')
      final r2 = GeminiService.validarConsultaPalabraIndividual('cómo se dice manzana');
      expect(r2.esValida, isTrue);
      expect(r2.palabraExtraida, equals('manzana'));

      // 3. Con artículo inicial ("el lápiz" -> "lápiz")
      final r3 = GeminiService.validarConsultaPalabraIndividual('¿Cómo se dice el lápiz en inglés?');
      expect(r3.esValida, isTrue);
      expect(r3.palabraExtraida, equals('lápiz'));

      // 4. ¿Qué significa X?
      final r4 = GeminiService.validarConsultaPalabraIndividual('¿Qué significa backpack en español?');
      expect(r4.esValida, isTrue);
      expect(r4.palabraExtraida, equals('backpack'));

      // 5. ¿Cómo se pronuncia X?
      final r5 = GeminiService.validarConsultaPalabraIndividual('¿Cómo se pronuncia water?');
      expect(r5.esValida, isTrue);
      expect(r5.palabraExtraida, equals('water'));

      // 6. Traduce X / Dime X
      final r6 = GeminiService.validarConsultaPalabraIndividual('traduce libro');
      expect(r6.esValida, isTrue);
      expect(r6.palabraExtraida, equals('libro'));

      final r7 = GeminiService.validarConsultaPalabraIndividual('dime ventana en inglés');
      expect(r7.esValida, isTrue);
      expect(r7.palabraExtraida, equals('ventana'));
    });

    test('Detección de intenciones pedagógicas de consulta oral (howToSay, whatDoesItMean, howToPronounce)', () {
      expect(
        GeminiService.detectarIntencion('¿Cómo se dice cuaderno en inglés?'),
        equals(VoiceQueryIntent.howToSay),
      );
      expect(
        GeminiService.detectarIntencion('traduce silla'),
        equals(VoiceQueryIntent.howToSay),
      );
      expect(
        GeminiService.detectarIntencion('¿Qué significa notebook?'),
        equals(VoiceQueryIntent.whatDoesItMean),
      );
      expect(
        GeminiService.detectarIntencion('dime el significado de chair'),
        equals(VoiceQueryIntent.whatDoesItMean),
      );
      expect(
        GeminiService.detectarIntencion('¿Cómo se pronuncia pencil?'),
        equals(VoiceQueryIntent.howToPronounce),
      );
      expect(
        GeminiService.detectarIntencion('fonética de apple'),
        equals(VoiceQueryIntent.howToPronounce),
      );
      // Término aislado toma por defecto howToSay
      expect(
        GeminiService.detectarIntencion('manzana'),
        equals(VoiceQueryIntent.howToSay),
      );
    });

    test('parseVoiceJsonResponse procesa correctamente respuestas JSON exitosas y de contingencia offline', () {
      // 1. Respuesta exitosa con bloque markdown
      const jsonMock = '''
      ```json
      {
        "exito": true,
        "terminoConsultado": "lápiz",
        "traduccionIngles": "pencil",
        "fonetica": "pén-sil",
        "fraseEjemploIngles": "I write with a pencil.",
        "fraseEjemploEspanol": "Escribo con un lápiz.",
        "respuestaHablada": "Lápiz se dice pencil y se pronuncia pén-sil."
      }
      ```
      ''';

      final resExito = GeminiService.parseVoiceJsonResponse(jsonMock, '¿Cómo se dice lápiz?');
      expect(resExito.success, isTrue);
      expect(resExito.wordOrTerm, equals('pencil'));
      expect(resExito.translation, equals('lápiz'));
      expect(resExito.phonetic, equals('pén-sil'));
      expect(resExito.exampleEn, equals('I write with a pencil.'));
      expect(resExito.explanation, contains('pén-sil'));

      // 2. Respuesta de contingencia por exceso léxico
      const jsonError = '''
      {
        "exito": false,
        "mensaje": "${GeminiService.mensajeContingenciaPalabraUnica}"
      }
      ''';

      final resError = GeminiService.parseVoiceJsonResponse(jsonError, 'oracion larga');
      expect(resError.success, isFalse);
      expect(resError.errorMessage, equals(GeminiService.mensajeContingenciaPalabraUnica));
    });
  });
}
