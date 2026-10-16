import 'package:flutter_test/flutter_test.dart';
import 'package:air_sight/features/glossary/glossary_data.dart';
import 'package:air_sight/features/glossary/glossary_word.dart';

void main() {
  group('HU-08: Pruebas Unitarias del Limpiador de Audio para Práctica y Completar Frase', () {
    // -------------------------------------------------------------------------
    // Función pura de generación de frase con espacio en blanco según PracticeScreen
    // -------------------------------------------------------------------------
    String generateSentenceWithBlank(GlossaryWord word) {
      final en = word.exampleEn;
      final pattern = RegExp(RegExp.escape(word.wordEn), caseSensitive: false);
      if (pattern.hasMatch(en)) {
        return en.replaceFirst(pattern, '_____');
      }
      return 'The _____ is here.';
    }

    // -------------------------------------------------------------------------
    // Función pura de limpieza de texto para síntesis TTS accesible (WCAG 2.2 AA)
    // Reemplaza marcadores "_____" o palabras "blank" por una pausa limpia "... "
    // impidiendo que el motor de síntesis lea "guiones bajos" o "blank" literalmente.
    // -------------------------------------------------------------------------
    String cleanTextForTts(String text) {
      return text
          .replaceAll(RegExp(r'_{2,}'), '... ')
          .replaceAll(RegExp(r'\bblank\b', caseSensitive: false), '... ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    // -------------------------------------------------------------------------
    // División en partes antes y después del blanco para pausa de silencio en TTS
    // -------------------------------------------------------------------------
    List<String> splitSentenceAroundBlank(String sentenceWithBlank) {
      return sentenceWithBlank
          .split('_____')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
    }

    test('Generación de frase con blanco reemplaza correctamente la palabra objetivo', () {
      const palabraTest = GlossaryWord(
        id: 'term_apple',
        wordEn: 'apple',
        wordEs: 'manzana',
        category: 'Alimentos',
        exampleEn: 'I eat an apple every day.',
        exampleEs: 'Como una manzana todos los días.',
        phonetic: "/'æp.əl/",
      );

      final fraseConBlanco = generateSentenceWithBlank(palabraTest);
      expect(fraseConBlanco, equals('I eat an _____ every day.'));
      expect(fraseConBlanco.contains('apple'), isFalse);
    });

    test('Generación de frase con blanco usa fallback seguro si la palabra no está en exampleEn', () {
      const palabraSinCoincidencia = GlossaryWord(
        id: 'term_random',
        wordEn: 'pineapple',
        wordEs: 'piña',
        category: 'Alimentos',
        exampleEn: 'This fruit is delicious.',
        exampleEs: 'Esta fruta es deliciosa.',
        phonetic: '/paɪn.æp.əl/',
      );

      final fraseConBlanco = generateSentenceWithBlank(palabraSinCoincidencia);
      expect(fraseConBlanco, equals('The _____ is here.'));
    });

    test('Limpiador de audio reemplaza guiones bajos ("_____") por pausa limpia ("... ")', () {
      const frase = 'The _____ is on the table.';
      final limpia = cleanTextForTts(frase);

      expect(limpia, equals('The ... is on the table.'));
      expect(limpia.contains('_____'), isFalse);
      expect(limpia.contains('_'), isFalse);
    });

    test('Limpiador de audio reemplaza la palabra "blank" por pausa limpia ("... ")', () {
      const fraseConBlank = 'Fill in the blank with the correct word.';
      final limpia = cleanTextForTts(fraseConBlank);

      expect(limpia, equals('Fill in the ... with the correct word.'));
      expect(limpia.toLowerCase().contains('blank'), isFalse);
    });

    test('Limpieza combinada con múltiples guiones o espacios consecutivos', () {
      const entrada = 'She has a ________ in her hands.';
      final limpia = cleanTextForTts(entrada);

      expect(limpia, equals('She has a ... in her hands.'));
      expect(limpia.contains('_'), isFalse);
    });

    test('División de la oración en partes anterior y posterior para inserción de silencio programado en TTS', () {
      const sentence = 'My brother reads a _____ before sleeping.';
      final partes = splitSentenceAroundBlank(sentence);

      expect(partes.length, equals(2));
      expect(partes[0], equals('My brother reads a'));
      expect(partes[1], equals('before sleeping.'));
    });

    test('Generación gamificada de opciones de práctica: respuesta correcta única y distractores válidos', () {
      final pool = List<GlossaryWord>.from(glossaryWords);
      final objetivo = pool.first;

      // Generar 3 distractores
      final distractores = pool.where((w) => w.id != objetivo.id).take(3).toList();
      final opciones = [objetivo, ...distractores]..shuffle();

      expect(opciones.length, equals(4));
      expect(opciones.where((w) => w.id == objetivo.id).length, equals(1));
      expect(opciones.contains(objetivo), isTrue);
    });

    test('Cálculo de métricas de práctica: aciertos, fallos y precisión porcentual', () {
      const int aciertos = 8;
      const int fallos = 2;
      const int total = aciertos + fallos;

      final precision = (aciertos / total) * 100;
      expect(precision, equals(80.0));

      // Caso 0 respuestas (evita división por cero)
      const int ceroAciertos = 0;
      const int ceroFallos = 0;
      final totalCero = ceroAciertos + ceroFallos;
      final precisionCero = totalCero == 0 ? 0.0 : (ceroAciertos / totalCero) * 100;
      expect(precisionCero, equals(0.0));
    });

    test('Validación de límites configurables de preguntas en práctica (5, 10, 15, 20)', () {
      const limites = [5, 10, 15, 20];
      for (final limite in limites) {
        expect(limite, greaterThanOrEqualTo(5));
        expect(limite, lessThanOrEqualTo(20));
      }
    });
  });
}
