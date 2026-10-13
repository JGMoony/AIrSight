import 'package:flutter_test/flutter_test.dart';
import 'package:air_sight/features/glossary/glossary_data.dart';
import 'package:air_sight/features/glossary/glossary_word.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas de extensión de GlossaryWord para Firestore e IA', () {
    test('Serialización y deserialización con etiquetasIA y Firestore toMap/fromMap', () {
      const word = GlossaryWord(
        id: 'w_chair',
        wordEn: 'chair',
        wordEs: 'silla',
        category: 'Classroom',
        exampleEn: 'This is a chair.',
        exampleEs: 'Esta es una silla.',
        aliases: ['seat', 'stool'],
        etiquetasIA: ['chair', 'seat', 'armchair'],
      );

      final map = word.toFirestore();
      expect(map['id'], equals('w_chair'));
      expect(map['wordEn'], equals('chair'));
      expect(map['wordEs'], equals('silla'));
      expect(map['category'], equals('Classroom'));
      expect(map['exampleEn'], equals('This is a chair.'));
      expect(map['exampleEs'], equals('Esta es una silla.'));
      expect(map['aliases'], equals(['seat', 'stool']));
      expect(map['etiquetasIA'], equals(['chair', 'seat', 'armchair']));

      final recovered = GlossaryWord.fromMap(map, id: 'w_chair');
      expect(recovered.id, equals('w_chair'));
      expect(recovered.wordEn, equals('chair'));
      expect(recovered.wordEs, equals('silla'));
      expect(recovered.etiquetasIA, equals(['chair', 'seat', 'armchair']));
      expect(recovered.etiquetas, equals(['chair', 'seat', 'armchair']));
    });

    test('matchesAiLabel empareja correctamente con nombres y etiquetas IA', () {
      const word = GlossaryWord(
        id: '1',
        wordEn: 'backpack',
        wordEs: 'morral',
        category: 'Objects',
        exampleEn: 'The backpack is heavy.',
        exampleEs: 'El morral es pesado.',
        aliases: ['mochila', 'maleta'],
        etiquetasIA: ['backpack', 'bag', 'schoolbag', 'luggage'],
      );

      expect(word.matchesAiLabel('backpack'), isTrue);
      expect(word.matchesAiLabel('BACKPACK'), isTrue);
      expect(word.matchesAiLabel('bag'), isTrue);
      expect(word.matchesAiLabel('schoolbag'), isTrue);
      expect(word.matchesAiLabel('mochila'), isTrue);
      expect(word.matchesAiLabel('car'), isFalse);
    });

    test('Fallback a aliases cuando etiquetasIA no está explícitamente configurado', () {
      const word = GlossaryWord(
        id: '2',
        wordEn: 'cat',
        wordEs: 'gato',
        category: 'Animals',
        exampleEn: 'The cat is sleeping.',
        exampleEs: 'El gato está durmiendo.',
        aliases: ['feline', 'pet'],
      );

      expect(word.etiquetas, equals(['feline', 'pet']));
      expect(word.toFirestore()['etiquetasIA'], equals(['feline', 'pet']));
    });

    test('Catálogo base en glossary_data.dart contiene 102 palabras válidas para seed', () {
      expect(glossaryWords.length, equals(102));
      for (final w in glossaryWords) {
        expect(w.id.isNotEmpty, isTrue);
        expect(w.wordEn.isNotEmpty, isTrue);
        expect(w.wordEs.isNotEmpty, isTrue);
        expect(w.category.isNotEmpty, isTrue);
        expect(w.exampleEn.isNotEmpty, isTrue);
        expect(w.exampleEs.isNotEmpty, isTrue);
      }
    });
  });
}
