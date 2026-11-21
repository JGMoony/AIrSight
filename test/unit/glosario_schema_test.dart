import 'package:flutter_test/flutter_test.dart';
import 'package:air_sight/features/glossary/glossary_word.dart';
import 'package:air_sight/features/glossary/glossary_data.dart';

void main() {
  group('HU-05 y HU-10: Pruebas Unitarias de Esquema Canónico y Retrocompatibilidad de Glosario', () {
    test('GlossaryWord.toMap() exporta estrictamente las claves canónicas oficiales', () {
      const palabra = GlossaryWord(
        id: 'term_backpack_01',
        wordEn: 'backpack',
        wordEs: 'mochila',
        category: 'Útiles',
        exampleEn: 'My backpack is blue.',
        exampleEs: 'Mi mochila es azul.',
        phonetic: "/'bæk.pæk/",
        aliases: ['mochila', 'bolso', 'morral'],
        etiquetasIA: ['backpack', 'bag', 'school bag'],
      );

      final map = palabra.toMap();

      // Claves canónicas requeridas
      expect(map['id'], equals('term_backpack_01'));
      expect(map['wordEn'], equals('backpack'));
      expect(map['wordEs'], equals('mochila'));
      expect(map['category'], equals('Útiles'));
      expect(map['exampleEn'], equals('My backpack is blue.'));
      expect(map['exampleEs'], equals('Mi mochila es azul.'));
      expect(map['phonetic'], equals("/'bæk.pæk/"));
      expect(map['aliases'], containsAll(['mochila', 'bolso', 'morral']));
      expect(map['etiquetasIA'], containsAll(['backpack', 'bag']));

      // Verificación estricta: NO debe emitir claves obsoletas o legadas en español
      expect(map.containsKey('palabraEn'), isFalse);
      expect(map.containsKey('traduccion'), isFalse);
      expect(map.containsKey('categoria'), isFalse);
      expect(map.containsKey('fonetica'), isFalse);
      expect(map.containsKey('fraseEn'), isFalse);
      expect(map.containsKey('fraseEs'), isFalse);
      expect(map.containsKey('audio'), isFalse);
    });

    test('GlossaryWord.fromMap() soporta esquema canónico sin pérdida de datos', () {
      final mapaCanonico = {
        'id': 'term_apple',
        'wordEn': 'apple',
        'wordEs': 'manzana',
        'category': 'Alimentos',
        'exampleEn': 'I eat a fresh apple.',
        'exampleEs': 'Como una manzana fresca.',
        'phonetic': "/'æp.əl/",
        'aliases': ['manzana', 'fruta'],
        'etiquetasIA': ['apple', 'fruit'],
      };

      final word = GlossaryWord.fromMap(mapaCanonico);
      expect(word.id, equals('term_apple'));
      expect(word.wordEn, equals('apple'));
      expect(word.wordEs, equals('manzana'));
      expect(word.category, equals('Alimentos'));
      expect(word.exampleEn, equals('I eat a fresh apple.'));
      expect(word.exampleEs, equals('Como una manzana fresca.'));
      expect(word.phonetic, equals("/'æp.əl/"));
      expect(word.aliases, contains('manzana'));
      expect(word.etiquetasIA, contains('apple'));
    });

    test('GlossaryWord.fromMap() soporta esquema legado para retrocompatibilidad total', () {
      final mapaLegado = {
        'id': 'legacy_pencil_09',
        'palabraEn': 'pencil',
        'traduccion': 'lápiz',
        'categoria': 'Útiles escolares',
        'fonetica': 'pén-sil',
        'fraseEn': 'She writes with a pencil.',
        'fraseEs': 'Ella escribe con un lápiz.',
      };

      final word = GlossaryWord.fromMap(mapaLegado);

      // Los campos legados deben mapearse correctamente a las propiedades canónicas
      expect(word.id, equals('legacy_pencil_09'));
      expect(word.wordEn, equals('pencil'));
      expect(word.wordEs, equals('lápiz'));
      expect(word.category, equals('Útiles escolares'));
      expect(word.phonetic, equals('pén-sil'));
      expect(word.exampleEn, equals('She writes with a pencil.'));
      expect(word.exampleEs, equals('Ella escribe con un lápiz.'));
      expect(word.example, equals('She writes with a pencil.')); // Alias example -> exampleEn
    });

    test('GlossaryWord.normalize normaliza diacríticos, mayúsculas y acentos para búsqueda accesible', () {
      expect(GlossaryWord.normalize('LÁPIZ'), equals('lapiz'));
      expect(GlossaryWord.normalize('Café con Leche'), equals('cafe con leche'));
      expect(GlossaryWord.normalize('Móvil'), equals('movil'));
      expect(GlossaryWord.normalize('ÚTIL'), equals('util'));
      expect(GlossaryWord.normalize('   Camisa   '), equals('camisa'));
    });

    test('GlossaryWord.matches evalúa coincidencias exactas y parciales en inglés, español y categorías', () {
      final chairWord = glossaryWords.firstWhere((w) => w.wordEn.toLowerCase() == 'chair');

      expect(chairWord.matches('chair'), isTrue);
      expect(chairWord.matches('SILLA'), isTrue);
      expect(chairWord.matches('silla'), isTrue);
      expect(chairWord.matches(chairWord.category), isTrue);
      expect(chairWord.matches('xyzinexistente123'), isFalse);
    });

    test('Catálogo estático de glossary_data.dart mantiene coherencia léxica A1 (102 palabras)', () {
      expect(glossaryWords.length, equals(102));

      for (final w in glossaryWords) {
        expect(w.id, isNotEmpty, reason: 'La palabra ${w.wordEn} debe tener un ID');
        expect(w.wordEn, isNotEmpty, reason: 'La palabra ${w.id} debe tener término en inglés');
        expect(w.wordEs, isNotEmpty, reason: 'La palabra ${w.id} debe tener traducción en español');
        expect(w.category, isNotEmpty, reason: 'La palabra ${w.id} debe pertenecer a una categoría');
        expect(w.exampleEn, isNotEmpty, reason: 'La palabra ${w.id} debe tener oración de ejemplo');
        expect(w.phonetic, isNotEmpty, reason: 'La palabra ${w.id} debe tener transcripción fonética');
      }
    });
  });
}
