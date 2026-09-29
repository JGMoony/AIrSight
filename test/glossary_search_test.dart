import 'package:flutter_test/flutter_test.dart';
import 'package:air_sight/features/glossary/glossary_data.dart';
import 'package:air_sight/features/glossary/glossary_word.dart';

void main() {
  group('Pruebas de Búsqueda Normalizada y Variantes Léxicas en Español', () {
    test('Normalización de diacríticos y acentos', () {
      expect(GlossaryWord.normalize('Plátano'), equals('platano'));
      expect(GlossaryWord.normalize('BOLÍGRAFO'), equals('boligrafo'));
      expect(GlossaryWord.normalize('  computadora  '), equals('computadora'));
      expect(GlossaryWord.normalize('móvil'), equals('movil'));
    });

    test('Búsqueda de variantes dialectales y sinónimos en español', () {
      // Función auxiliar idéntica al filtrado de GlossaryScreen
      List<GlossaryWord> search(String query) {
        return glossaryWords.where((w) => w.matches(query)).toList();
      }

      // 1. banana -> plátano, guineo (con y sin tilde)
      expect(search('platano').any((w) => w.wordEn == 'banana'), isTrue);
      expect(search('plátano').any((w) => w.wordEn == 'banana'), isTrue);
      expect(search('guineo').any((w) => w.wordEn == 'banana'), isTrue);

      // 2. pen -> bolígrafo, esfero, lapicero, pluma
      expect(search('boligrafo').any((w) => w.wordEn == 'pen'), isTrue);
      expect(search('bolígrafo').any((w) => w.wordEn == 'pen'), isTrue);
      expect(search('esfero').any((w) => w.wordEn == 'pen'), isTrue);
      expect(search('lapicero').any((w) => w.wordEn == 'pen'), isTrue);
      expect(search('pluma').any((w) => w.wordEn == 'pen'), isTrue);

      // 3. backpack -> morral, maleta, mochila, bulto
      expect(search('morral').any((w) => w.wordEn == 'backpack'), isTrue);
      expect(search('maleta').any((w) => w.wordEn == 'backpack'), isTrue);
      expect(search('mochila').any((w) => w.wordEn == 'backpack'), isTrue);
      expect(search('bulto').any((w) => w.wordEn == 'backpack'), isTrue);

      // 4. eraser -> borrador, goma, goma de borrar
      expect(search('goma').any((w) => w.wordEn == 'eraser'), isTrue);
      expect(search('goma de borrar').any((w) => w.wordEn == 'eraser'), isTrue);

      // 5. board -> tablero, pizarra, pizarrón
      expect(search('pizarra').any((w) => w.wordEn == 'board'), isTrue);
      expect(search('pizarron').any((w) => w.wordEn == 'board'), isTrue);
      expect(search('pizarrón').any((w) => w.wordEn == 'board'), isTrue);

      // 6. refrigerator -> nevera, refrigerador, heladera
      expect(search('refrigerador').any((w) => w.wordEn == 'refrigerator'), isTrue);
      expect(search('heladera').any((w) => w.wordEn == 'refrigerator'), isTrue);

      // 7. glasses -> gafas, lentes, anteojos
      expect(search('lentes').any((w) => w.wordEn == 'glasses'), isTrue);
      expect(search('anteojos').any((w) => w.wordEn == 'glasses'), isTrue);

      // 8. umbrella -> sombrilla, paraguas
      expect(search('paraguas').any((w) => w.wordEn == 'umbrella'), isTrue);

      // 9. wallet -> billetera, cartera
      expect(search('cartera').any((w) => w.wordEn == 'wallet'), isTrue);

      // 10. socks -> medias, calcetines
      expect(search('calcetines').any((w) => w.wordEn == 'socks'), isTrue);

      // 11. jacket -> chaqueta, chamarra, campera
      expect(search('chamarra').any((w) => w.wordEn == 'jacket'), isTrue);
      expect(search('campera').any((w) => w.wordEn == 'jacket'), isTrue);

      // 12. t-shirt -> camiseta, playera, remera, polera
      expect(search('playera').any((w) => w.wordEn == 't-shirt'), isTrue);
      expect(search('remera').any((w) => w.wordEn == 't-shirt'), isTrue);
      expect(search('polera').any((w) => w.wordEn == 't-shirt'), isTrue);

      // 13. computer -> computador, computadora, ordenador, pc
      expect(search('computadora').any((w) => w.wordEn == 'computer'), isTrue);
      expect(search('ordenador').any((w) => w.wordEn == 'computer'), isTrue);

      // 14. laptop -> computador portátil, portátil, laptop
      expect(search('portatil').any((w) => w.wordEn == 'laptop'), isTrue);
      expect(search('portátil').any((w) => w.wordEn == 'laptop'), isTrue);

      // 15. headphones -> audífonos, auriculares, cascos
      expect(search('audifonos').any((w) => w.wordEn == 'headphones'), isTrue);
      expect(search('auriculares').any((w) => w.wordEn == 'headphones'), isTrue);
      expect(search('cascos').any((w) => w.wordEn == 'headphones'), isTrue);

      // 16. phone -> teléfono, celular, móvil
      expect(search('celular').any((w) => w.wordEn == 'phone'), isTrue);
      expect(search('movil').any((w) => w.wordEn == 'phone'), isTrue);
      expect(search('móvil').any((w) => w.wordEn == 'phone'), isTrue);

      // 17. television -> televisor, tele, televisión
      expect(search('tele').any((w) => w.wordEn == 'television'), isTrue);
      expect(search('television').any((w) => w.wordEn == 'television'), isTrue);
      expect(search('televisión').any((w) => w.wordEn == 'television'), isTrue);

      // 18. sandwich -> sándwich, emparedado
      expect(search('emparedado').any((w) => w.wordEn == 'sandwich'), isTrue);
      expect(search('sandwich').any((w) => w.wordEn == 'sandwich'), isTrue);
    });
  });
}
